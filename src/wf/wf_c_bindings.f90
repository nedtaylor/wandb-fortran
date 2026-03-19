module wf_c_bindings
  !! C interface declarations for the wandb-fortran library.
  !! Internal use only — applications should use module wf__wandb.
  use iso_c_binding, only: c_int, c_double, c_char
  implicit none
  private

  public :: wandb_init_c
  public :: wandb_log_metric_c
  public :: wandb_config_set_int_c
  public :: wandb_config_set_real_c
  public :: wandb_config_set_str_c
  public :: wandb_finish_c
  public :: wandb_shutdown_c
  public :: wandb_config_get_int_c
  public :: wandb_config_get_real_c
  public :: wandb_config_get_str_c
  public :: wandb_sweep_c
  public :: wandb_agent_c
  public :: wandb_sweep_start_agent_c
  public :: wandb_sweep_params_c
  public :: wandb_sweep_run_done_c

  interface

    integer(c_int) function wandb_init_c(project, name, entity, sweep_id) &
         bind(C, name="wandb_init_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: project(*)
      character(kind=c_char), intent(in) :: name(*)
      character(kind=c_char), intent(in) :: entity(*)
      character(kind=c_char), intent(in) :: sweep_id(*)
    end function wandb_init_c

    subroutine wandb_log_metric_c(key, value, step) &
         bind(C, name="wandb_log_metric_c")
      import :: c_char, c_double, c_int
      character(kind=c_char), intent(in) :: key(*)
      real(c_double), value, intent(in) :: value
      integer(c_int), value, intent(in) :: step
    end subroutine wandb_log_metric_c

    subroutine wandb_config_set_int_c(key, value) &
         bind(C, name="wandb_config_set_int_c")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: key(*)
      integer(c_int), value, intent(in) :: value
    end subroutine wandb_config_set_int_c

    subroutine wandb_config_set_real_c(key, value) &
         bind(C, name="wandb_config_set_real_c")
      import :: c_char, c_double
      character(kind=c_char), intent(in) :: key(*)
      real(c_double), value, intent(in) :: value
    end subroutine wandb_config_set_real_c

    subroutine wandb_config_set_str_c(key, value) &
         bind(C, name="wandb_config_set_str_c")
      import :: c_char
      character(kind=c_char), intent(in) :: key(*)
      character(kind=c_char), intent(in) :: value(*)
    end subroutine wandb_config_set_str_c

    subroutine wandb_finish_c() bind(C, name="wandb_finish_c")
    end subroutine wandb_finish_c

    subroutine wandb_shutdown_c() bind(C, name="wandb_shutdown_c")
    end subroutine wandb_shutdown_c

    integer(c_int) function wandb_config_get_int_c(key, default_value) &
         bind(C, name="wandb_config_get_int_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: key(*)
      integer(c_int), value, intent(in)  :: default_value
    end function wandb_config_get_int_c

    real(c_double) function wandb_config_get_real_c(key, default_value) &
         bind(C, name="wandb_config_get_real_c")
      import :: c_double, c_char
      character(kind=c_char), intent(in) :: key(*)
      real(c_double), value, intent(in)  :: default_value
    end function wandb_config_get_real_c

    integer(c_int) function wandb_config_get_str_c(key, buf, buf_len) &
         bind(C, name="wandb_config_get_str_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in)  :: key(*)
      character(kind=c_char), intent(out) :: buf(*)
      integer(c_int), value, intent(in)   :: buf_len
    end function wandb_config_get_str_c

    integer(c_int) function wandb_sweep_c( &
         config_json, project, entity, sweep_id_buf, sweep_id_buf_len) &
         bind(C, name="wandb_sweep_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in)  :: config_json(*)
      character(kind=c_char), intent(in)  :: project(*)
      character(kind=c_char), intent(in)  :: entity(*)
      character(kind=c_char), intent(out) :: sweep_id_buf(*)
      integer(c_int), value, intent(in)   :: sweep_id_buf_len
    end function wandb_sweep_c

    integer(c_int) function wandb_agent_c(sweep_id, project, entity, count) &
         bind(C, name="wandb_agent_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: sweep_id(*)
      character(kind=c_char), intent(in) :: project(*)
      character(kind=c_char), intent(in) :: entity(*)
      integer(c_int), value, intent(in)  :: count
    end function wandb_agent_c

    integer(c_int) function wandb_sweep_start_agent_c( &
         sweep_id, project, entity, count) &
         bind(C, name="wandb_sweep_start_agent_c")
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: sweep_id(*)
      character(kind=c_char), intent(in) :: project(*)
      character(kind=c_char), intent(in) :: entity(*)
      integer(c_int), value, intent(in)  :: count
    end function wandb_sweep_start_agent_c

    integer(c_int) function wandb_sweep_params_c(buf, buf_len, timeout_s) &
         bind(C, name="wandb_sweep_params_c")
      import :: c_int, c_char, c_double
      character(kind=c_char), intent(out) :: buf(*)
      integer(c_int), value, intent(in)   :: buf_len
      real(c_double), value, intent(in)   :: timeout_s
    end function wandb_sweep_params_c

    subroutine wandb_sweep_run_done_c() &
         bind(C, name="wandb_sweep_run_done_c")
    end subroutine wandb_sweep_run_done_c

  end interface

end module wf_c_bindings
