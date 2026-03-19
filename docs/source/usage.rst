.. _usage:

Usage
=====

Quick start
-----------

.. code-block:: fortran

    use wf

    ! 1. Initialise a run
    call wandb_init(project="my-project", name="run-01")

    ! 2. Log hyper-parameters (shown on the wandb Config panel)
    call wandb_config_set("learning_rate", 0.001d0)
    call wandb_config_set("epochs",        100)
    call wandb_config_set("optimiser",     "adam")

    ! 3. Log metrics inside your training loop
    do epoch = 1, 100
       ! ... training ...
       call wandb_log("training_loss",   train_loss,  step=epoch)
       call wandb_log("validation_loss", val_loss,    step=epoch)
       call wandb_log("learning_rate",   lr,          step=epoch)
    end do

    ! 4. Finish the run
    call wandb_finish()
    call wandb_shutdown()

API Reference
-------------

Initialisation
~~~~~~~~~~~~~~

.. code-block:: fortran

    call wandb_init(project [, name] [, entity] [, sweep_id])

Starts a wandb run.  ``project`` is required; ``name`` and ``entity`` are
optional.  Pass ``sweep_id`` when running inside a hyperparameter sweep.

Logging metrics
~~~~~~~~~~~~~~~

.. code-block:: fortran

    call wandb_log(key, value [, step])

``value`` may be ``integer``, ``real(real32)``, or ``real(real64)``.
``step`` is optional; omit it to let wandb auto-increment.

Configuration / hyper-parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: fortran

    call wandb_config_set(key, value)   ! set  (integer, real32, real64, character)
    call wandb_config_get(key, value [, default_value])  ! read back (sweep params)

Finishing
~~~~~~~~~

.. code-block:: fortran

    call wandb_finish()    ! finish current run, keep Python alive
    call wandb_shutdown()  ! full teardown (call once, at program end)

Hyperparameter sweeps
---------------------

**Using a raw JSON config string:**

.. code-block:: fortran

    character(len=256) :: sweep_id
    call wandb_sweep( &
         '{"method":"bayes","metric":{"name":"val_loss","goal":"minimise"},'  &
       // '"parameters":{"lr":{"min":0.0001,"max":0.01},'                      &
       // '"hidden":{"values":[16,32,64]}}}',                                  &
         project="my-project", sweep_id=sweep_id)

**Using the config builder:**

.. code-block:: fortran

    type(wandb_sweep_config_type) :: cfg
    character(len=256) :: sweep_id

    call cfg%set_method("bayes")
    call cfg%set_metric("val_loss", "minimise")
    call cfg%add_param_range("lr", 1e-4_real64, 1e-2_real64, &
                              distribution="log_uniform_values")
    call cfg%add_param_values("hidden", [16, 32, 64])

    call wandb_sweep(cfg, project="my-project", sweep_id=sweep_id)

    call wandb_sweep_start_agent(sweep_id, "my-project", count=5)
    do i = 1, 5
       call wandb_sweep_next_params(params_json)
       ! read sampled values
       call wandb_config_get("lr",     lr)
       call wandb_config_get("hidden", hidden)
       ! ... train and log ...
       call wandb_sweep_run_done()
    end do
    call wandb_shutdown()

Offline mode
------------

Set the ``WANDB_MODE`` environment variable to run without network access
(useful in CI and on HPC clusters):

.. code-block:: bash

    WANDB_MODE=offline fpm run --example athena_logging

Syncing offline runs later:

.. code-block:: bash

    wandb sync wandb/offline-run-*/
