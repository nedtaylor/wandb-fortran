.. _tutorials:

Tutorials
=========

Welcome to the wandb-fortran tutorials!
These guides will help you get started with using wandb-fortran in your
Fortran-based neural network training projects.
The tutorials are framework-agnostic, so you can apply the same principles
regardless of the ML library you use — whether it's
[athena](https://github.com/nedtaylor/athena),
[neural-fortran](https://github.com/modern-fortran/neural-fortran),
[fiats](https://github.com/BerkeleyLab/fiats),
or something else.

Advanced features like sweeps are also covered,
so you can perform hyperparameter optimisation with wandb
without leaving your Fortran code.

.. toctree::
   :maxdepth: 1
   :caption: Using wandb-fortran with different frameworks:
   :titlesonly:

   athena
   neural_fortran
   fiats

.. toctree::
   :maxdepth: 1
   :caption: Advanced wandb-fortran features:
   :titlesonly:

   sweep
