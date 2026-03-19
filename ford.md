project: 
summary: A standalone Fortran interface to Weights & Biases (wandb) 
         experiment tracking via the Python C API.
src_dir: ./src
output_dir: docs/html
output: html
preprocess: false
predocmark: !!
fpp_extensions: f90
                F90
display: public
         protected
source: true
graph: true
search: true
md_extensions: markdown.extensions.toc
coloured_edges: true
sort: permission-alpha
author: Ned Thaddeus Taylor
github: https://github.com/nedtaylor
print_creation_date: true
creation_date: %Y-%m-%d %H:%M %z
project_github: https://github.com/nedtaylor/wandb-fortran
extra_vartypes: real32
proc_internals: true
extra_filetypes: c h

{!README.md!}
