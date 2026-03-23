.. _fiats_example:

fiats Example
=============

This example trains a `fiats <https://github.com/BerkeleyLab/fiats>`_ neural
network to approximate sin(x) and logs metrics to wandb every 10 epochs.

Fiats (Functional Inference and Training for Surrogates) is a deep learning
library from Berkeley Lab designed for high-performance computing applications
in modern Fortran.  It uses functional programming patterns and ``do concurrent``
for parallelism.

@note::

   This example uses an older release of fiats (0.14.0) to ensure compatibility with GNU Fortran
   (``gfortran``).  Later releases require ``flang-new``, ``nagfor``, or ``ifx``.
   As the wandb-fortran library was developed first with athena in mind (which is most compatible with gfortran),
   the fiats example was developed and tested with the latest gfortran-compatible release of fiats.

Source: ``example/fiats_logging/src/main.f90``

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
    fpm run --example fiats_logging --profile release

.. note::

   The ``--profile release`` flag is recommended for fiats as it can
   significantly improve training performance.

Key code
--------

.. code-block:: fortran

    use inference_engine_m, only : &
      trainable_engine_t, tensor_t, input_output_pair_t, &
      mini_batch_t, shuffle, sigmoid_t
    use julienne_m, only : string_t, bin_t
    use wf

    ! initialise wandb
    call wandb_init(project="wandb-fortran-fiats", name="sine-fiats")
    call wandb_config_set("num_epochs",    num_epochs)
    call wandb_config_set("num_hidden",    num_hidden)
    call wandb_config_set("learning_rate", real(learning_rate, kind=8))
    call wandb_config_set("framework",     "fiats")

    ! training loop (mini-batch with Adam optimiser)
    do epoch = 1, num_epochs
       call shuffle(pairs)
       mini_batches = [(mini_batch_t( &
            pairs(bins(b)%first():bins(b)%last())), b = 1, size(bins))]
       call net%train(mini_batches, cost, adam=.true., &
            learning_rate=learning_rate)

       if (mod(epoch, 10) == 0) then
          call wandb_log("epoch",           epoch,                       step=epoch)
          call wandb_log("training_loss",   real(train_loss, kind=8),    step=epoch)
          call wandb_log("validation_loss", real(val_loss,   kind=8),    step=epoch)
          call wandb_log("learning_rate",   real(learning_rate, kind=8), step=epoch)
       end if
    end do

    call wandb_finish()
    call wandb_shutdown()

Differences from athena and neural-fortran examples
----------------------------------------------------

While the network architecture (1 → 16 → 1) and task (sin(x) approximation)
are the same across all three examples, there are a few key differences when
using fiats:

* **Optimiser**: fiats uses the Adam optimiser (``adam=.true.``), whereas the
  athena and neural-fortran examples use plain SGD.  This means the learning
  rate is typically higher (1.5 vs 0.01).
* **Activation function**: fiats 0.14.0 provides sigmoid, ReLU, GELU, and
  Swish.  Sigmoid is used for all layers, compared to tanh (hidden) + sigmoid
  (output) in the other examples.
* **Training style**: fiats uses mini-batch training with
  ``input_output_pair_t`` and ``mini_batch_t``, rather than single-sample
  stochastic gradient descent.
* **Weight initialisation**: weights and biases are explicitly constructed as
  arrays and passed to the ``trainable_engine_t`` constructor.

fpm dependency
--------------

.. note::

   Due to compiler compatibility requirements, the fiats example is disabled by default.
   To enable building and running the fiats example, use the
   ``--features fiats_gfortran`` or ``--features fiats_flang`` flag when running with fpm.
   Due to conflicting julienne dependencies of the different fiats releases, a clean build
   is required when switching between fiats_gfortran and fiats_flang features. This is
   achieved by running ``fpm clean --all`` before building or running the example.

To run the fiats example, use the ``fiats_gfortran`` or ``fiats_flang`` feature flag when running with fpm:

```bash
fpm run --example fiats_logging --profile release --features fiats_gfortran
```

or

```bash
fpm run --example fiats_logging --profile release --features fiats_flang
```


Framework-agnostic design
--------------------------

As with the other examples, the only wandb-related requirement is ``use wf``.
The ``wandb_log``, ``wandb_config_set``, and ``wandb_init`` calls are identical
regardless of the ML library used for training — athena, neural-fortran, fiats,
or any other Fortran framework.
