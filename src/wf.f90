module wf
  !! Fortran interface to Weights & Biases (wandb) experiment tracking.
  !!
  !! This is the user-facing API module.  It re-exports the public symbols
  !! from the feature modules in src/wf/:
  !!
  !!   - wf_run    — wandb_init, wandb_log, wandb_finish, wandb_shutdown
  !!   - wf_config — wandb_config_set, wandb_config_get
  !!   - wf_sweep  — wandb_sweep_config_type, wandb_sweep, wandb_agent,
  !!                 wandb_sweep_start_agent, wandb_sweep_next_params,
  !!                 wandb_sweep_run_done
  !!
  !! ## Quick start
  !!
  !! ```fortran
  !! use wf
  !!
  !! call wandb_init(project="my_project", name="run-01")
  !! call wandb_config_set("learning_rate", 0.001d0)
  !! call wandb_config_set("epochs", 100)
  !!
  !! do epoch = 1, 100
  !!    ! ... training ...
  !!    call wandb_log("loss", loss_val, step=epoch)
  !! end do
  !!
  !! call wandb_finish()
  !! ```
  !!
  !! ## Prerequisites
  !!
  !! - Python >= 3.8 with `wandb` installed (`pip install wandb`)
  !! - Link against `libwandb_fortran` (which itself links Python)
  !!
  use wf_run, only: &
       wandb_init,     &
       wandb_log,      &
       wandb_finish,   &
       wandb_shutdown
  use wf_config, only: &
       wandb_config_set, &
       wandb_config_get
  use wf_sweep, only: &
       wandb_sweep_config_type,  &
       wandb_sweep,              &
       wandb_agent,              &
       wandb_sweep_start_agent,  &
       wandb_sweep_next_params,  &
       wandb_sweep_run_done
  implicit none

end module wf
