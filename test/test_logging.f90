program test_logging
  !! Smoke test for the wf module.
  !!
  !! This test verifies that the wandb Fortran API compiles and that the
  !! sweep config builder produces valid JSON without requiring a live
  !! wandb server (offline mode).
  !!
  !! The actual wandb I/O calls are fenced behind an environment variable
  !! WANDB_MODE=offline so they do not need network access in CI.
  !!
  use wf
  use iso_c_binding, only: c_double, c_float

  implicit none

  integer :: failures = 0

  !-----------------------------------------------------------------------------
  ! Test 1: sweep config JSON builder
  !-----------------------------------------------------------------------------
  call test_sweep_config_json(failures)

  !-----------------------------------------------------------------------------
  ! Test 2: wandb offline init / log / finish round-trip
  !-----------------------------------------------------------------------------
  call test_offline_logging(failures)

  !-----------------------------------------------------------------------------
  ! Results
  !-----------------------------------------------------------------------------
  if(failures == 0)then
     write(*,*) "All tests passed."
     stop 0
  else
     write(*,'(I0," test(s) failed.")') failures
     stop 1
  end if


contains


  subroutine test_sweep_config_json(failures)
    !! Build a sweep config and verify the JSON contains expected substrings.
    integer, intent(inout) :: failures

    type(wandb_sweep_config_type) :: cfg
    character(len=:), allocatable :: json

    call cfg%set_method("bayes")
    call cfg%set_metric("val_loss", "minimize")
    call cfg%add_param_range("lr",      1.0e-4_c_double, 1.0e-2_c_double, &
                              distribution="log_uniform_values")
    call cfg%add_param_values("hidden", [16, 32, 64])
    call cfg%add_param_values("wd",     [1.0e-4_c_double, 1.0e-3_c_double])
    call cfg%add_param_values("act",    ["relu   ", "tanh   "])

    json = cfg%to_json()

    call assert_contains(json, '"method":"bayes"',          "method=bayes",   failures)
    call assert_contains(json, '"name":"val_loss"',         "metric name",    failures)
    call assert_contains(json, '"goal":"minimize"',         "metric goal",    failures)
    call assert_contains(json, '"log_uniform_values"',      "distribution",   failures)
    call assert_contains(json, '"values":[16,32,64]',       "int values",     failures)
    call assert_contains(json, '"relu"',                    "str value relu", failures)
    call assert_contains(json, '"tanh"',                    "str value tanh", failures)

    write(*,*) "[test_sweep_config_json] Done."
  end subroutine test_sweep_config_json


  subroutine test_offline_logging(failures)
    !! Call wandb_init in offline mode then log a few metrics.
    !! Verifies no crash rather than inspecting output.
    integer, intent(inout) :: failures

    ! Tell wandb not to sync so no network access is needed.
    ! (The env var may be set externally in CI; we set it here as a fallback.)
    call set_env("WANDB_MODE", "offline")

    call wandb_init(project="test-project", name="test-run-offline")
    call wandb_config_set("lr",        0.001_c_double)
    call wandb_config_set("epochs",    10)
    call wandb_config_set("optimizer", "adam")

    call wandb_log("training_loss",   0.5_c_double,  step=1)
    call wandb_log("validation_loss", 0.6_c_double,  step=1)
    call wandb_log("learning_rate",   0.001_c_double, step=1)
    call wandb_log("epoch",           1,             step=1)

    call wandb_finish()
    call wandb_shutdown()

    write(*,*) "[test_offline_logging] Done."
  end subroutine test_offline_logging


  subroutine assert_contains(str, substr, label, failures)
    character(len=*), intent(in)    :: str, substr, label
    integer,          intent(inout) :: failures
    if(index(str, substr) == 0)then
       write(*,'("FAIL: ",A," — expected substring: ",A)') label, substr
       failures = failures + 1
    end if
  end subroutine assert_contains


  subroutine set_env(name, value)
    !! Set an environment variable using the ISO C binding.
    use iso_c_binding, only: c_int, c_char, c_null_char
    character(len=*), intent(in) :: name, value
    interface
       integer(c_int) function setenv_c(name, value, overwrite) &
            bind(C, name="setenv")
         import :: c_int, c_char
         character(kind=c_char), intent(in) :: name(*)
         character(kind=c_char), intent(in) :: value(*)
         integer(c_int), value, intent(in)  :: overwrite
       end function setenv_c
    end interface
    integer(c_int) :: rc
    rc = setenv_c(name // c_null_char, value // c_null_char, 1_c_int)
  end subroutine set_env


end program test_logging
