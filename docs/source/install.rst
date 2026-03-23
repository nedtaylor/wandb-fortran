.. _install:

Installation
============

Prerequisites
-------------

* **gfortran** >= 9  (or any Fortran 2008+ compiler)
* **fpm** >= 0.8  — `Fortran Package Manager <https://fpm.fortran-lang.org>`_
* **CMake** >= 3.21
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

    # If you use conda or a virtualenv, activate it first.
    conda activate my_env
    source tools/setup_env.sh

    # Or specify a conda / venv interpreter explicitly.
    PYTHON=/opt/homebrew/Caskroom/miniconda/base/envs/my_env/bin/python \
        source tools/setup_env.sh

When a conda environment or virtualenv is active, ``setup_env.sh`` prefers
that environment's ``python`` automatically.

This sets ``FPM_CFLAGS``, ``FPM_LDFLAGS``, and
``DYLD_LIBRARY_PATH`` on macOS.

Building
--------

With fpm:

.. code-block:: bash

    fpm build

Or use the convenience script (sources ``setup_env.sh`` automatically):

.. code-block:: bash

    ./build_fpm.sh

    # With a specific Python interpreter
    PYTHON=/path/to/python3 ./build_fpm.sh

With CMake:

.. code-block:: bash

    cmake -S . -B build-cmake
    cmake --build build-cmake

.. code-block:: bash

    ctest --test-dir build-cmake --output-on-failure
    cmake --install build-cmake --prefix "$HOME/.local"

If you want to force a specific Python interpreter for the CMake build,
configure with:

.. code-block:: bash

    cmake -S . -B build-cmake \
      -DPython3_EXECUTABLE=/path/to/python

The selected interpreter must provide both the Python development files and the
``wandb`` package.

The CMake install step places:

* ``libwandb_fortran.a`` in the install library directory
* ``wandb.h`` in the install include directory
* generated Fortran module files (``*.mod``) in the install include directory

Running tests
-------------

.. code-block:: bash

    source tools/setup_env.sh
    WANDB_MODE=offline fpm test

For the CMake build:

.. code-block:: bash

    ctest --test-dir build-cmake --output-on-failure

Using as a dependency
---------------------

Add to your project's ``fpm.toml``:

.. code-block:: toml

    [dependencies]
    wandb-fortran = { git = "https://github.com/nedtaylor/wandb-fortran" }

Then set the Python flags before building your project via ``fpm``.
