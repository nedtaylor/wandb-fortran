.. _sweep_example:

Sweep Example
=============

This example demonstrates a wandb hyperparameter sweep driven from Fortran.
It trains an ATHENA network to approximate sin(x), logs intermediate MSE during
training, and reports ``final_mse`` so the sweep controller can rank runs.

Source: ``example/sweep/src/main.f90``

Hyperparameters searched
------------------------

* ``learning_rate`` (log-uniform in ``[1e-3, 1.0]``)
* ``num_hidden`` (values: ``4``, ``8``, ``16``, ``32``)
* ``activation`` (values: ``"tanh"``, ``"relu"``, ``"sigmoid"``)

Metrics logged
--------------

* ``mse`` (every 500 iterations)
* ``final_mse``

Running
-------

.. code-block:: bash

    source tools/setup_env.sh
    fpm run --example sweep

Key code
--------

.. code-block:: fortran

    use athena
    use wf

    type(wandb_sweep_config_type) :: sweep_config
    character(len=256) :: sweep_id

    ! Configure and register a Bayesian sweep
    call sweep_config%set_method("bayes")
    call sweep_config%set_metric("final_mse", "minimize")
    call sweep_config%add_param_range("learning_rate", &
         min_val=1.0e-3_real32, max_val=1.0_real32, &
         distribution="log_uniform_values")
    call sweep_config%add_param_values("num_hidden", [4, 8, 16, 32])
    call sweep_config%add_param_values("activation", &
         ["tanh   ", "relu   ", "sigmoid"])

    call wandb_sweep(config=sweep_config, project="athena-sweep", sweep_id=sweep_id)
    call wandb_sweep_start_agent(sweep_id=trim(sweep_id), project="athena-sweep", count=5)

    ! Per-run loop
    call wandb_sweep_next_params(params_json)
    call wandb_config_get("learning_rate", lr, default_value=0.01_real32)
    call wandb_config_get("num_hidden", num_hidden, default_value=8)
    call wandb_config_get("activation", activation, default_value="tanh")

    ! ... train model ...
    call wandb_log("mse", mse, step=n)
    call wandb_log("final_mse", mse)
    call wandb_sweep_run_done()

    call wandb_shutdown()

fpm dependency
--------------

The sweep example pulls in ATHENA automatically via fpm:

.. code-block:: toml

    [[example]]
    name = "sweep"
    source-dir = "example/sweep/src"
    main = "main.f90"
    [example.dependencies]
    athena = { git = "https://github.com/nedtaylor/athena", tag = "v2.0.0" }
