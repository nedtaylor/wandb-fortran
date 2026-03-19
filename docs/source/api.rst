.. _api:

API Reference
=============

The full Fortran API documentation is generated using FORD (Fortran Automatic Documentation).

You can browse the complete API documentation here:

.. raw:: html

   <div style="margin: 20px 0;">
      <a href="_static/ford/index.html" target="_blank" class="btn btn-primary">
         📚 Open FORD API Documentation
      </a>
   </div>


Module ``wf``
--------------------

The single public module provides the full wandb Fortran interface.

Exported procedures
~~~~~~~~~~~~~~~~~~~

``wandb_init``
^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_init(project [, name] [, entity] [, sweep_id])
      character(len=*), intent(in)           :: project
      character(len=*), intent(in), optional :: name
      character(len=*), intent(in), optional :: entity
      character(len=*), intent(in), optional :: sweep_id

Initialise a wandb run.  Must be the first wandb call.

``wandb_log``
^^^^^^^^^^^^^

.. code-block:: fortran

    interface wandb_log
      subroutine wandb_log(key, value [, step])
        character(len=*), intent(in)           :: key
        <integer|real32|real64>,  intent(in)   :: value
        integer, intent(in), optional          :: step
    end interface

Log a scalar metric.  Overloaded for ``integer``, ``real(real32)``, and
``real(real64)``.

``wandb_config_set``
^^^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    interface wandb_config_set
      subroutine wandb_config_set(key, value)
        character(len=*), intent(in)           :: key
        <integer|real32|real64|character>, intent(in) :: value
    end interface

Set a hyper-parameter in the run config panel.

``wandb_config_get``
^^^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    interface wandb_config_get
      subroutine wandb_config_get(key, value [, default_value])
        character(len=*), intent(in)           :: key
        <integer|real32|real64|character>, intent(out) :: value
        <same type>, intent(in), optional      :: default_value
    end interface

Read back a config value (set by the sweep agent, or set by ``wandb_config_set``).

``wandb_sweep``
^^^^^^^^^^^^^^^

.. code-block:: fortran

    interface wandb_sweep
      subroutine wandb_sweep(config_json,  project, sweep_id [, entity])
      subroutine wandb_sweep(config_obj,   project, sweep_id [, entity])
    end interface

Register a hyperparameter sweep.  Accepts either a raw JSON string or a
``wandb_sweep_config_type`` object.

``wandb_sweep_start_agent``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_sweep_start_agent(sweep_id, project, count [, entity])

Start a sweep agent in a background Python thread.

``wandb_sweep_next_params``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_sweep_next_params(params_json [, timeout_s])

Block until the sweep agent has sampled the next set of hyperparameters and
called ``wandb.init()``.

``wandb_sweep_run_done``
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_sweep_run_done()

Signal that the current sweep run's training is complete.

``wandb_finish``
^^^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_finish()

Finish the current run.  Keeps Python alive (safe between sweep runs).

``wandb_shutdown``
^^^^^^^^^^^^^^^^^^

.. code-block:: fortran

    subroutine wandb_shutdown()

Full teardown of the Python interpreter.  Call once at program exit.

Derived type ``wandb_sweep_config_type``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: fortran

    type :: wandb_sweep_config_type
    contains
      procedure :: set_method        ! "bayes" | "grid" | "random"
      procedure :: set_metric        ! (name, goal)
      procedure :: add_param_range   ! (name, min, max [, distribution])
      procedure :: add_param_values  ! (name, integer(:)|real32(:)|real64(:)|character(:))
      procedure :: to_json           ! returns JSON string
    end type
