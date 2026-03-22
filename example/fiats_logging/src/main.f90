program fiats_logging
  !! Demonstration of wandb logging with a fiats neural network training loop.
  !!
  !! This example trains a small fully-connected network using fiats
  !! (BerkeleyLab/fiats) to approximate sin(x) over [0, 2*pi], while logging:
  !!   - epoch
  !!   - training_loss
  !!   - validation_loss
  !!   - learning_rate
  !!
  !! This demonstrates that wf works independently of the ML framework.
  !!
  !! ## Prerequisites
  !!
  !! 1. Source the Python environment:
  !!    ```bash
  !!    source tools/setup_env.sh
  !!    ```
  !! 2. Build and run:
  !!    ```bash
  !!    fpm run --example fiats_logging --profile release
  !!    ```
  !!
  use inference_engine_m, only : &
       trainable_engine_t, tensor_t, input_output_pair_t, &
       mini_batch_t, shuffle, sigmoid_t
  use julienne_m, only : string_t, bin_t
  use wf

  implicit none

  !-----------------------------------------------------------------------------
  ! hyper-parameters
  !-----------------------------------------------------------------------------
  integer,  parameter :: num_epochs       = 200
  integer,  parameter :: num_hidden       = 16
  integer,  parameter :: num_train        = 100
  integer,  parameter :: num_mini_batches = 10
  integer,  parameter :: val_size         = 40
  real,     parameter :: learning_rate    = 1.5
  real,     parameter :: pi               = 4.0 * atan(1.0)

  !-----------------------------------------------------------------------------
  ! network and data
  !-----------------------------------------------------------------------------
  type(trainable_engine_t) :: net
  type(tensor_t), allocatable :: val_inputs(:), val_outputs(:)
  type(input_output_pair_t), allocatable :: pairs(:)
  type(mini_batch_t), allocatable :: mini_batches(:)
  type(bin_t), allocatable :: bins(:)
  real, allocatable :: cost(:), pred(:)
  real :: x_val(val_size), y_val(val_size)
  real :: train_loss, val_loss
  integer :: epoch, i, b

  !-----------------------------------------------------------------------------
  ! set random seed for reproducibility
  !-----------------------------------------------------------------------------
  call random_seed()

  !-----------------------------------------------------------------------------
  ! initialise wandb run
  !-----------------------------------------------------------------------------
  write(*,*) "Initialising wandb run..."
  call wandb_init(project="wandb-fortran-fiats", name="sine-fiats")

  ! log hyper-parameters to wandb config
  call wandb_config_set("num_epochs",       num_epochs)
  call wandb_config_set("num_hidden",        num_hidden)
  call wandb_config_set("learning_rate",     real(learning_rate, kind=8))
  call wandb_config_set("num_train",         num_train)
  call wandb_config_set("num_mini_batches",  num_mini_batches)
  call wandb_config_set("val_size",          val_size)
  call wandb_config_set("activation",        "sigmoid")
  call wandb_config_set("optimizer",         "adam")
  call wandb_config_set("framework",         "fiats")

  write(*,*) "wandb run initialised."

  !-----------------------------------------------------------------------------
  ! build validation set  sin(x) normalised to [0,1]
  !-----------------------------------------------------------------------------
  do i = 1, val_size
     x_val(i) = (real(i - 1) * 2.0 * pi) / real(val_size)
     y_val(i) = (sin(x_val(i)) + 1.0) / 2.0
  end do

  !-----------------------------------------------------------------------------
  ! build network: 1 -> num_hidden -> 1 with sigmoid activation
  !-----------------------------------------------------------------------------
  net = build_network()

  !-----------------------------------------------------------------------------
  ! build training data
  !-----------------------------------------------------------------------------
  call build_training_data()

  !-----------------------------------------------------------------------------
  ! set up mini-batch bins
  !-----------------------------------------------------------------------------
  bins = [(bin_t(num_items=num_train, num_bins=num_mini_batches, &
       bin_number=b), b = 1, num_mini_batches)]

  !-----------------------------------------------------------------------------
  ! training loop
  !-----------------------------------------------------------------------------
  write(*,'(A7,2A14)') "epoch", "train_loss", "val_loss"
  write(*,*) repeat("-", 35)

  do epoch = 1, num_epochs

     call shuffle(pairs)
     mini_batches = [(mini_batch_t( &
          pairs(bins(b)%first():bins(b)%last())), b = 1, size(bins))]
     call net%train(mini_batches, cost, adam=.true., &
          learning_rate=learning_rate)

     train_loss = sum(cost) / real(size(cost))

     ! compute validation loss every 10 epochs
     if (mod(epoch, 10) == 0) then
        val_inputs  = [(tensor_t([x_val(i)]), i = 1, val_size)]
        val_outputs = net%infer(val_inputs)

        val_loss = 0.0
        do i = 1, val_size
           pred = val_outputs(i)%values()
           val_loss = val_loss + (pred(1) - y_val(i))**2
        end do
        val_loss = val_loss / real(val_size)

        write(*,'(I7,2F14.6)') epoch, train_loss, val_loss

        ! log metrics to wandb
        call wandb_log("epoch",           epoch,                       step=epoch)
        call wandb_log("training_loss",   real(train_loss, kind=8),    step=epoch)
        call wandb_log("validation_loss", real(val_loss,   kind=8),    step=epoch)
        call wandb_log("learning_rate",   real(learning_rate, kind=8), step=epoch)
     end if

  end do

  !-----------------------------------------------------------------------------
  ! finish
  !-----------------------------------------------------------------------------
  call wandb_finish()
  call wandb_shutdown()

  write(*,*) ""
  write(*,*) "Training complete. Check your wandb dashboard for results."

contains

  function build_network() result(engine)
    !! Build a trainable network with architecture [1, num_hidden, 1]
    !! using sigmoid activation and small random weights.
    type(trainable_engine_t) :: engine
    integer, parameter :: nodes(*) = [1, 16, 1]
    integer, parameter :: n_max = maxval(nodes), layers = size(nodes)
    real, allocatable :: w(:,:,:), b_(:,:)

    allocate(w(n_max, n_max, layers - 1), b_(n_max, layers - 1))

    call random_number(w)
    call random_number(b_)
    w  = (w  - 0.5) * 0.2
    b_ = (b_ - 0.5) * 0.2

    engine = trainable_engine_t( &
         nodes = nodes, weights = w, biases = b_, &
         differentiable_activation_strategy = sigmoid_t(), &
         metadata = [string_t("sine-approx"),    string_t("wandb-fortran"), &
              string_t("2026-03-22"),     string_t("sigmoid"),       &
              string_t("false")] )
  end function

  subroutine build_training_data()
    !! Generate num_train random (x, sin(x)) pairs normalised to [0,1].
    type(tensor_t), allocatable :: inputs(:), outputs(:)
    real :: xr
    integer :: j

    allocate(inputs(num_train), outputs(num_train))
    do j = 1, num_train
       call random_number(xr)
       xr = xr * 2.0 * pi
       inputs(j)  = tensor_t([xr])
       outputs(j) = tensor_t([(sin(xr) + 1.0) / 2.0])
    end do
    pairs = input_output_pair_t(inputs, outputs)
  end subroutine

end program fiats_logging
