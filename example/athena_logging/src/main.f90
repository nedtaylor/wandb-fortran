program athena_logging
  !! Demonstration of wandb logging with an ATHENA neural network training loop.
  !!
  !! This example trains a small fully-connected network to approximate sin(x)
  !! over [0, 2*pi] using the ATHENA library, while logging:
  !!   - epoch
  !!   - training_loss
  !!   - validation_loss
  !!   - learning_rate
  !!
  !! ## Prerequisites
  !!
  !! 1. Source the Python environment:
  !!    ```bash
  !!    source tools/setup_env.sh
  !!    ```
  !! 2. Build and run:
  !!    ```bash
  !!    fpm run --example athena_logging
  !!    ```
  !!
  use athena
  use wf
  use coreutils, only: real32

  implicit none

  !-----------------------------------------------------------------------------
  ! hyper-parameters
  !-----------------------------------------------------------------------------
  integer,   parameter :: num_epochs    = 200
  integer,   parameter :: num_hidden    = 16
  integer,   parameter :: val_size      = 40
  real(real32), parameter :: learning_rate = 0.01_real32
  real(real32), parameter :: pi           = 4.0_real32 * atan(1.0_real32)

  !-----------------------------------------------------------------------------
  ! network and data
  !-----------------------------------------------------------------------------
  type(network_type) :: net
  type(array_type)   :: x_in(1), y_tgt(1,1)
  type(array_type), pointer :: loss_ptr

  real(real32) :: x(1,1), y(1,1)
  real(real32) :: x_val(1,val_size), y_val(1,val_size), y_pred(1,val_size)
  real(real32) :: train_loss, val_loss
  integer :: epoch, i

  !-----------------------------------------------------------------------------
  ! set random seed for reproducibility
  !-----------------------------------------------------------------------------
  call random_seed()

  !-----------------------------------------------------------------------------
  ! initialise wandb run
  !-----------------------------------------------------------------------------
  write(*,*) "Initialising wandb run..."
  call wandb_init(project="wandb-fortran-athena", name="sine-demo")

  ! log hyper-parameters to wandb config
  call wandb_config_set("num_epochs",    num_epochs)
  call wandb_config_set("num_hidden",    num_hidden)
  call wandb_config_set("learning_rate", real(learning_rate, kind=8))
  call wandb_config_set("val_size",      val_size)
  call wandb_config_set("activation",    "tanh")
  call wandb_config_set("framework",     "ATHENA")

  write(*,*) "wandb run initialised."

  !-----------------------------------------------------------------------------
  ! build validation set  sin(x) normalised to [0,1]
  !-----------------------------------------------------------------------------
  do i = 1, val_size
     x_val(1,i) = (real(i - 1, real32) * 2.0_real32 * pi) / real(val_size, real32)
     y_val(1,i) = (sin(x_val(1,i)) + 1.0_real32) / 2.0_real32
  end do

  !-----------------------------------------------------------------------------
  ! build network
  !-----------------------------------------------------------------------------
  call net%add(full_layer_type( &
       num_inputs=1, num_outputs=num_hidden, activation="tanh"))
  call net%add(full_layer_type( &
       num_outputs=1, activation="sigmoid"))
  call net%compile( &
       optimiser  = base_optimiser_type(learning_rate=learning_rate), &
       loss_method= "mse", &
       metrics    = ["loss"], &
       verbose    = 0)
  call net%set_batch_size(1)

  call x_in(1)%allocate(array_shape=[1,1])
  call y_tgt(1,1)%allocate(array_shape=[1,1])

  !-----------------------------------------------------------------------------
  ! training loop
  !-----------------------------------------------------------------------------
  write(*,'(A7,2A14)') "epoch", "train_loss", "val_loss"
  write(*,*) repeat("-", 35)

  do epoch = 1, num_epochs

     ! one stochastic gradient step on a random training sample
     call random_number(x)
     x = x * 2.0_real32 * pi
     y = (sin(x) + 1.0_real32) / 2.0_real32

     x_in(1)%val  = x
     y_tgt(1,1)%val = y

     call net%set_batch_size(1)
     call net%forward(x)
     net%expected_array = y_tgt
     loss_ptr => net%loss_eval(1, 1)
     call loss_ptr%grad_reverse()
     call net%update()

     train_loss = loss_ptr%val(1,1)

     ! compute validation loss every 10 epochs
     if (mod(epoch, 10) == 0) then
        y_pred = net%predict(input=x_val)
        val_loss = sum((y_pred - y_val)**2) / real(val_size, real32)

        write(*,'(I7,2F14.6)') epoch, train_loss, val_loss

        ! log metrics to wandb
        call wandb_log("epoch",          epoch,      step=epoch)
        call wandb_log("training_loss",  train_loss, step=epoch)
        call wandb_log("validation_loss",val_loss,   step=epoch)
        call wandb_log("learning_rate",  real(learning_rate, kind=8), step=epoch)
     end if

  end do

  !-----------------------------------------------------------------------------
  ! finish
  !-----------------------------------------------------------------------------
  call wandb_finish()
  call wandb_shutdown()

  write(*,*) ""
  write(*,*) "Training complete. Check your wandb dashboard for results."

end program athena_logging
