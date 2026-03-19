program neural_fortran_logging
  !! Demonstration of wandb logging with a neural-fortran training loop.
  !!
  !! This example trains a small fully-connected network using neural-fortran
  !! to approximate sin(x) over [0, 2*pi], while logging:
  !!   - epoch
  !!   - training_loss
  !!   - validation_loss
  !!   - learning_rate
  !!
  !! This demonstrates that wf__wandb works independently of the ML framework.
  !!
  !! ## Prerequisites
  !!
  !! 1. Source the Python environment:
  !!    ```bash
  !!    source tools/setup_env.sh
  !!    ```
  !! 2. Build and run:
  !!    ```bash
  !!    fpm run --example neural_fortran_logging
  !!    ```
  !!
  use nf
  use wf

  implicit none

  integer, parameter :: sp = kind(1.0)

  !-----------------------------------------------------------------------------
  ! hyper-parameters
  !-----------------------------------------------------------------------------
  integer,     parameter :: num_epochs    = 200
  integer,     parameter :: val_size      = 40
  real(sp),    parameter :: learning_rate = 0.01_sp
  real(sp),    parameter :: pi            = 4.0_sp * atan(1.0_sp)

  !-----------------------------------------------------------------------------
  ! network and data
  !-----------------------------------------------------------------------------
  type(network) :: net

  real(sp), allocatable :: x(:), y(:)
  real(sp) :: x_val(val_size), y_val(val_size)
  real(sp) :: y_pred(val_size)
  real(sp) :: train_loss, val_loss
  real(sp) :: tmp_out(1)
  integer  :: epoch, i

  !-----------------------------------------------------------------------------
  ! set random seed for reproducibility
  !-----------------------------------------------------------------------------
  call random_seed()

  !-----------------------------------------------------------------------------
  ! initialise wandb run
  !-----------------------------------------------------------------------------
  write(*,*) "Initialising wandb run..."
  call wandb_init(project="wandb-fortran-nf", name="sine-neural-fortran")

  ! log hyper-parameters to wandb config
  call wandb_config_set("num_epochs",    num_epochs)
  call wandb_config_set("learning_rate", real(learning_rate, kind=8))
  call wandb_config_set("val_size",      val_size)
  call wandb_config_set("framework",     "neural-fortran")

  write(*,*) "wandb run initialised."

  !-----------------------------------------------------------------------------
  ! build validation data  sin(x) normalised to [0,1]
  !-----------------------------------------------------------------------------
  do i = 1, val_size
     x_val(i)  = (real(i - 1, sp) * 2.0_sp * pi) / real(val_size, sp)
     y_val(i)  = (sin(x_val(i)) + 1.0_sp) / 2.0_sp
  end do

  !-----------------------------------------------------------------------------
  ! build network:  1 → 16 (tanh) → 1 (sigmoid)
  !-----------------------------------------------------------------------------
  net = network([input(1), dense(16, activation=tanhf()), dense(1)])

  !-----------------------------------------------------------------------------
  ! training loop
  !-----------------------------------------------------------------------------
  write(*,'(A7,2A14)') "epoch", "train_loss", "val_loss"
  write(*,*) repeat("-", 35)

  allocate(x(1), y(1))

  do epoch = 1, num_epochs

     ! single stochastic gradient step on a random training sample
     call random_number(x(1))
     x(1) = x(1) * 2.0_sp * pi
     y(1) = (sin(x(1)) + 1.0_sp) / 2.0_sp

     call net%forward(x)
     call net%backward(y)
     call net%update(optimizer=sgd(learning_rate=learning_rate))

     train_loss = sum((net%predict(x) - y)**2)

     ! compute validation loss every 10 epochs
     if (mod(epoch, 10) == 0) then
        val_loss = 0.0_sp
        do i = 1, val_size
           tmp_out   = net%predict(x_val(i:i))
           y_pred(i) = tmp_out(1)
           val_loss  = val_loss + (y_pred(i) - y_val(i))**2
        end do
        val_loss = val_loss / real(val_size, sp)

        write(*,'(I7,2F14.6)') epoch, train_loss, val_loss

        ! log metrics to wandb
        call wandb_log("epoch",          epoch,                    step=epoch)
        call wandb_log("training_loss",  real(train_loss, kind=8), step=epoch)
        call wandb_log("validation_loss",real(val_loss,   kind=8), step=epoch)
        call wandb_log("learning_rate",  real(learning_rate,kind=8),step=epoch)
     end if

  end do

  deallocate(x, y)

  !-----------------------------------------------------------------------------
  ! finish
  !-----------------------------------------------------------------------------
  call wandb_finish()
  call wandb_shutdown()

  write(*,*) ""
  write(*,*) "Training complete. Check your wandb dashboard for results."

end program neural_fortran_logging
