.. _neural_fortran_example:

neural-fortran Example
======================

This example shows that ``wf`` is completely independent of the ML
framework.  It uses `neural-fortran <https://github.com/modern-fortran/neural-fortran>`_
to train the same sin(x) approximation and logs identical metrics.

Source: ``example/neural_fortran_logging/train_with_wandb.f90``

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
    fpm run --example neural_fortran_logging

Key code
--------

.. code-block:: fortran

    use neural
    use wf

    ! initialise wandb
    call wandb_init(project="wandb-fortran-nf", name="sine-neural-fortran")
    call wandb_config_set("num_epochs",    num_epochs)
    call wandb_config_set("learning_rate", real(learning_rate, kind=8))
    call wandb_config_set("framework",     "neural-fortran")

    ! training loop
    do epoch = 1, num_epochs
       ! ... neural-fortran forward / backward / update ...
       if (mod(epoch, 10) == 0) then
          call wandb_log("epoch",           epoch,                     step=epoch)
          call wandb_log("training_loss",   real(train_loss, kind=8),  step=epoch)
          call wandb_log("validation_loss", real(val_loss,   kind=8),  step=epoch)
          call wandb_log("learning_rate",   real(learning_rate,kind=8),step=epoch)
       end if
    end do

    call wandb_finish()
    call wandb_shutdown()

fpm dependency
--------------

.. code-block:: toml

    [[example]]
    name = "neural_fortran_logging"
    source-dir = "example/neural_fortran_logging"
    main = "train_with_wandb.f90"
    [example.dependencies]
    neural-fortran = { git = "https://github.com/modern-fortran/neural-fortran" }

Framework-agnostic design
--------------------------

The only framework requirement is that you import ``wf``.  The
``wandb_log``, ``wandb_config_set``, and ``wandb_init`` calls are identical
regardless of the ML library used for training — athena, neural-fortran, or
any other Fortran framework.
