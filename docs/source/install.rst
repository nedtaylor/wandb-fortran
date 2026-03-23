.. _install:

Installation
============

Prerequisites
-------------

* **gfortran** >= 9  (or any Fortran 2008+ compiler)
* **fpm** >= 0.8  — `Fortran Package Manager <https://fpm.fortran-lang.org>`_
* **Python** >= 3.8 with development headers

  * macOS: ``brew install python3``  or  Xcode Command Line Tools
  * Linux: ``sudo apt install python3-dev``  (Debian/Ubuntu)

* The ``wandb`` Python package::

    pip install wandb

* A wandb account and API key::

    wandb login

The code has been tested with Python 3.12, fpm 0.13.0, and wandb 0.25.0.

Getting the source
------------------

.. code-block:: bash

    git clone https://github.com/nedtaylor/wandb-fortran.git
    cd wandb-fortran

Configuring the Python environment
-----------------------------------

Before building you must export the Python compile and link flags so that
``fpm`` can compile ``wf_wandb_c.c``:

.. code-block:: bash

    # Use the Python on your PATH
    source tools/setup_env.sh

    # Or specify a conda / venv interpreter explicitly
    PYTHON=/opt/homebrew/Caskroom/miniconda/base/envs/my_env/bin/python \
        source tools/setup_env.sh

This sets ``FPM_CFLAGS``, ``FPM_LDFLAGS``, and (on macOS) ``DYLD_LIBRARY_PATH``.

Building
--------

.. code-block:: bash

    fpm build

Or use the convenience script (sources ``setup_env.sh`` automatically):

.. code-block:: bash

    ./build_fpm.sh

    # With a specific Python interpreter
    PYTHON=/path/to/python3 ./build_fpm.sh

Running tests
-------------

.. code-block:: bash

    source tools/setup_env.sh
    WANDB_MODE=offline fpm test

Using as a dependency
---------------------

Add to your project's ``fpm.toml``:

.. code-block:: toml

    [dependencies]
    wandb-fortran = { git = "https://github.com/nedtaylor/wandb-fortran" }

Then set the Python flags before building your project via ``fpm``.
