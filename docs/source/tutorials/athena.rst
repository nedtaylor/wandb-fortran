ATHENA Example
==============

This example trains an ATHENA neural network to approximate sin(x) and logs
metrics to wandb every 10 epochs.

Source: ``example/athena_logging/train_with_wandb.f90``

Metrics logged
--------------

* ``epoch``
* ``training_loss``
* ``validation_loss``
* ``learning_rate``

Running
-------

.. code-block:: bash

    source tools/setup_env.sh
    fpm run --example athena_logging

Key code
--------

.. code-block:: fortran

    use athena
    use wf__wandb

    ! initialise wandb
    call wandb_init(project="wandb-fortran-athena", name="sine-demo")
    call wandb_config_set("num_epochs",    num_epochs)
    call wandb_config_set("num_hidden",    num_hidden)
    call wandb_config_set("learning_rate", real(learning_rate, kind=8))

    ! training loop
    do epoch = 1, num_epochs
       ! ... ATHENA forward / backward / update ...
       if (mod(epoch, 10) == 0) then
          call wandb_log("epoch",           epoch,      step=epoch)
          call wandb_log("training_loss",   train_loss, step=epoch)
          call wandb_log("validation_loss", val_loss,   step=epoch)
          call wandb_log("learning_rate",   real(learning_rate, kind=8), step=epoch)
       end if
    end do

    call wandb_finish()
    call wandb_shutdown()

fpm dependency
--------------

The example pulls in ATHENA automatically via fpm:

.. code-block:: toml

    [[example]]
    name = "athena_logging"
    source-dir = "example/athena_logging"
    main = "train_with_wandb.f90"
    [example.dependencies]
    athena = { git = "https://github.com/nedtaylor/athena", tag = "v2.0.0" }
