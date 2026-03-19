wandb-fortran documentation
============================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   install
   usage
   tutorials
   api

Overview
--------

**wandb-fortran** (``wf__wandb``) is a standalone Fortran interface to
`Weights & Biases <https://wandb.ai>`_ experiment tracking.

It embeds the Python interpreter at runtime via the Python C API, imports
the ``wandb`` Python package, and forwards all Fortran API calls to Python —
giving you the full wandb feature set (dashboards, sweeps, artifacts) without
any Python in your training loop.

Indices and tables
------------------

* :ref:`genindex`
* :ref:`search`
