[![MIT workflow](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/license/mit/ "View MIT license")
[![Documentation Status](https://readthedocs.org/projects/athena/badge/?version=latest)](https://wandb-fortran.readthedocs.io/en/latest/?badge=latest "athena ReadTheDocs")
[![FPM](https://img.shields.io/badge/fpm-0.13.0-purple)](https://github.com/fortran-lang/fpm "View Fortran Package Manager")
[![GCC compatibility](https://img.shields.io/badge/gcc-15.2.0-green)](https://gcc.gnu.org/gcc-13/ "View GCC")

# wandb-fortran

A standalone Fortran interface to [Weights & Biases](https://wandb.ai) (wandb or W&B)
experiment tracking.

Log training metrics, hyper-parameters, and hyperparameter sweeps directly
from Fortran — no Python in your training loop required.

> **Note:** This library has been developed with the assistance of LLM AI code
> agents and has not yet been thoroughly tested in production.

---

How it works
------------

`wandb-fortran` embeds the Python interpreter at runtime using the Python C API,
imports `wandb`, and forwards every Fortran API call to Python.  You get the
full wandb feature set (real-time dashboards, sweep search, artifact tracking)
with a clean Fortran interface.

```
┌──────────────────────────────┐
│  Your Fortran training code  │
│  use wf                      │
│  call wandb_log(...)         │
└──────────┬───────────────────┘
           │ iso_c_binding
┌──────────▼───────────────────┐
│  wf_wandb_c.c  (C bridge)    │
│  Embeds Python interpreter   │
└──────────┬───────────────────┘
           │ Python C API
┌──────────▼───────────────────┐
│  wandb Python package        │
│  → wandb server / cloud      │
└──────────────────────────────┘
```

---



Documentation
-----

wandb-fortran is distributed with the following directories:

| Directory | Description |
|---|---|
|  _docs/_    |  Compilable documentation |
|  _example/_ |  A set of example programs utilising the wandb-fortran library |
|  _src/_ |      Source code  |
|  _tools/_ |    Additional shell script tools for environment setup |
|  _test/_  |    A set of test programs to check functionality of the library works after compilation |


Tutorials and documentation are provided on the [docs](http://wandb-fortran.readthedocs.io/) website.

Refer to the [API Documentation section](#api-documentation) later in this document to see how to access the API-specific documentation.


Setup
-----

The wandb-fortran library can be obtained from the git repository.
Use the following commands to get started:

```bash
git clone https://github.com/nedtaylor/wandb-fortran.git
cd wandb-fortran
```


### Dependencies

The library has the following dependencies:


| Requirement | Version |
|-------------|---------|
| gfortran (or compatible) | ≥ 13 |
| [fpm](https://fpm.fortran-lang.org) | ≥ 0.13 |
| [CMake](https://cmake.org) | ≥ 3.21 |
| Python + dev headers | ≥ 3.8 |
| wandb Python package | ≥ 0.25 |

The library has been developed and tested using the following compilers:
- gfortran -- gcc 15.2.0

### Python and wandb prerequisites

To utilise wandb, it must be installed and the necessary paths be made available to the Fortran compiler.

To install wandb, use pip:

```bash
pip install wandb
```

Next, if wanting to log data on the wandb website, then a wandb account will be needed and the user needs to be logged in.
Note, wandb can be run in offline mode without an account, which will be briefly mentioned later.

To create an account for wandb and set up an API key, follow the [quickstart guide](https://docs.wandb.ai/models/quickstart) provided on the [W&B documentation](https://docs.wandb.ai).

Once an account has been set up, log in from the terminal and follow any necessary prompts:

```bash
wandb login
```

Next, the Python flags and paths will need to be configured such that the current shell instance has the right paths pointed to.

Source the `setup_env.sh` script (note, this requires using the `source` command, not just executing it):

```bash
# If you use conda or a virtualenv, activate it first.
conda activate my_env
source tools/setup_env.sh

# Or force a specific interpreter explicitly.
PYTHON=/opt/homebrew/Caskroom/miniconda/base/envs/my_env/bin/python \
    source tools/setup_env.sh
```

When a conda environment or virtualenv is active, `setup_env.sh` now prefers that environment's `python` automatically.

### Building with fpm

```bash
fpm build
# or
./build_fpm.sh
```

### Building and installing with CMake

The repository also provides a CMake build for projects that prefer a
traditional configure/build/install flow.

```bash
cmake -S . -B build-cmake
cmake --build build-cmake
ctest --test-dir build-cmake --output-on-failure
cmake --install build-cmake --prefix "$HOME/.local"
```

This installs:

- `libwandb_fortran.a` into the chosen library prefix
- `wandb.h` into the chosen include prefix
- the generated Fortran module files (`*.mod`) into the chosen include prefix

If you want CMake to use a specific Python interpreter, pass it during
configuration:

```bash
cmake -S . -B build-cmake \
  -DPython3_EXECUTABLE=/path/to/python
```

The selected interpreter must have the `wandb` package installed.

### Testing with fpm an example

```bash
fpm run --example athena_logging
fpm run --example neural_fortran_logging
```

### Testing (offline — no wandb account needed)

```bash
WANDB_MODE=offline fpm test
```


Usage
-----

## Using as an fpm dependency

wandb-fortran can be used as a dependency in your Fortran project using the Fortran Package Manager (fpm).
Before doing so, ensure that the Python environment is set up as described in the previous section.

To use the library, simply add it as a dependency in your `fpm.toml`:

```toml
[dependencies]
wandb-fortran = { git = "https://github.com/nedtaylor/wandb-fortran" }
```

Then source `tools/setup_env.sh` before running `fpm build`.

## Example usage

The following is a minimal example of how to use the library in your Fortran code:

```fortran
use wf

! Initialise a run
call wandb_init(project="my-project", name="experiment-01")

! Log hyper-parameters (shown on the Config panel)
call wandb_config_set("learning_rate", 0.001d0)
call wandb_config_set("epochs",        200)
call wandb_config_set("optimizer",     "adam")

! Training loop
do epoch = 1, 200
   ! ... train ...
   call wandb_log("training_loss",   train_loss, step=epoch)
   call wandb_log("validation_loss", val_loss,   step=epoch)
   call wandb_log("learning_rate",   lr,         step=epoch)
end do

! Finish
call wandb_finish()
call wandb_shutdown()
```


API documentation
-----------------

API documentation can be generated using FORD (Fortran Documenter).
To do so, follow the installation guide on the [FORD website](https://forddocs.readthedocs.io/en/stable/) to ensure FORD is installed.
Once FORD is installed, run the following command in the root directory of the git repository:

```
  ford ford.md
```

Contributing
------------

Please note that this project adheres to the [Contributing Guide](CONTRIBUTING.md). If you want to contribute to this project, please first read through the guide.
If you have any questions, please either discuss then in [issues](https://github.com/nedtaylor/wandb-fortran/issues), or contact [Ned Taylor](mailto:n.t.taylor@exeter.ac.uk?subject=wandb-fortran%20-%20contribution%20request).


License
-------
This work is licensed under an [MIT license](https://opensource.org/license/mit/).



Acknowledgements
----------------

This library has been developed by heavily relying on LLM AI code agents and has not yet been thoroughly tested in production.
