module wf_run
  !! Run lifecycle: initialise a wandb run, log metrics, finish and shutdown.
  use iso_c_binding, only: c_int, c_double, c_char, c_null_char, c_float
  use wf_c_bindings
  implicit none
  private

  public :: wandb_init
  public :: wandb_log
  public :: wandb_finish
  public :: wandb_shutdown

  !! Log a scalar metric to the current wandb run.
  interface wandb_log
    module procedure wandb_log_real64
    module procedure wandb_log_real32
    module procedure wandb_log_integer
  end interface wandb_log

contains

  !-----------------------------------------------------------------------------
  ! wandb_init
  !-----------------------------------------------------------------------------
  subroutine wandb_init(project, name, entity, sweep_id)
    !! Initialise a wandb run.
    !!
    !! @param project   Project name (required).
    !! @param name      Run display name (optional).
    !! @param entity    wandb entity / team (optional).
    !! @param sweep_id  Sweep ID returned by wandb_sweep.  When supplied,
    !!                  the run joins the sweep and its wandb.config is
    !!                  populated with the sweep-sampled hyperparameters.
    character(len=*), intent(in)           :: project
    character(len=*), intent(in), optional :: name
    character(len=*), intent(in), optional :: entity
    character(len=*), intent(in), optional :: sweep_id

    integer(c_int) :: rc
    character(len=:), allocatable :: c_name, c_entity, c_sweep_id

    if(present(name))then
       c_name = name // c_null_char
    else
       c_name = c_null_char
    end if

    if(present(entity))then
       c_entity = entity // c_null_char
    else
       c_entity = c_null_char
    end if

    if(present(sweep_id))then
       c_sweep_id = trim(sweep_id) // c_null_char
    else
       c_sweep_id = c_null_char
    end if

    rc = wandb_init_c( &
         project // c_null_char, &
         c_name,    &
         c_entity,  &
         c_sweep_id &
    )

    if(rc /= 0)then
       write(0,*) "[wf] WARNING: wandb_init failed (rc=", rc, ")"
       write(0,*) "  Logging will be silently skipped."
    end if

  end subroutine wandb_init


  !-----------------------------------------------------------------------------
  ! wandb_log  (real64)
  !-----------------------------------------------------------------------------
  subroutine wandb_log_real64(key, value, step)
    character(len=*), intent(in)           :: key
    real(c_double),   intent(in)           :: value
    integer,          intent(in), optional :: step

    integer(c_int) :: c_step

    c_step = -1_c_int
    if(present(step)) c_step = int(step, c_int)
    call wandb_log_metric_c(key // c_null_char, value, c_step)

  end subroutine wandb_log_real64


  !-----------------------------------------------------------------------------
  ! wandb_log  (real32)
  !-----------------------------------------------------------------------------
  subroutine wandb_log_real32(key, value, step)
    character(len=*), intent(in)           :: key
    real(c_float),    intent(in)           :: value
    integer,          intent(in), optional :: step

    call wandb_log_real64(key, real(value, c_double), step)

  end subroutine wandb_log_real32


  !-----------------------------------------------------------------------------
  ! wandb_log  (integer)
  !-----------------------------------------------------------------------------
  subroutine wandb_log_integer(key, value, step)
    character(len=*), intent(in)           :: key
    integer,          intent(in)           :: value
    integer,          intent(in), optional :: step

    call wandb_log_real64(key, real(value, c_double), step)

  end subroutine wandb_log_integer


  !-----------------------------------------------------------------------------
  ! wandb_finish
  !-----------------------------------------------------------------------------
  subroutine wandb_finish()
    !! Finish the current wandb run (calls wandb.finish()) but keeps the
    !! Python interpreter alive.  Safe to call between sweep runs.
    !! For the very last teardown call wandb_shutdown() as well.
    call wandb_finish_c()
  end subroutine wandb_finish


  !-----------------------------------------------------------------------------
  ! wandb_shutdown
  !-----------------------------------------------------------------------------
  subroutine wandb_shutdown()
    !! Shut down the Python interpreter and release all resources.
    !! Call once after all wandb runs (including sweep runs) are finished.
    !! No wandb calls should be made after this.
    call wandb_shutdown_c()
  end subroutine wandb_shutdown

end module wf_run
