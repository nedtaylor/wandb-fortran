# Configuration file for the Sphinx documentation builder.
import datetime
import os
import sys
import subprocess
import shutil

def run_ford(app):
    """Run FORD to generate Fortran API documentation"""
    ford_dir = os.path.abspath(os.path.join(app.confdir, "..", ".."))
    ford_output = os.path.join(app.outdir, "_static", "ford")
    project_file = os.path.join(ford_dir, "ford.md")

    print(f"Running FORD with config: {project_file}")
    result = subprocess.run(["ford", project_file, "-o", ford_output], cwd=ford_dir, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"FORD output:\n{result.stdout}")
        print(f"FORD errors:\n{result.stderr}")
    else:
        print("FORD documentation generated successfully")


def setup(app):
    app.connect("builder-inited", run_ford)

# -- Project information -------------------------------------------------------
project   = 'wandb-fortran'
copyright = f'{datetime.date.today().year}, wandb-fortran-developers'

# Identify the branch of the documentation
on_rtd = os.environ.get('READTHEDOCS') == 'True'
if on_rtd:
    git_branch = os.environ.get("READTHEDOCS_GIT_IDENTIFIER", "main")
else:
    git_branch = "main"  # or get from git directly with subprocess


# -- General configuration -----------------------------------------------------
extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.intersphinx',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
    'sphinx_rtd_theme',
    'sphinx.ext.extlinks',
    'sphinx_copybutton'
]

extlinks = {
    'git': ('https://github.com/nedtaylor/wandb-fortran/blob/' + git_branch + '/%s', 'git: %s')
}

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'sphinx': ('https://www.sphinx-doc.org/en/master/', None),
}
intersphinx_disabled_domains = ['std']

templates_path   = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', 'build']

# -- HTML output ---------------------------------------------------------------
html_theme = "sphinx_rtd_theme"
html_static_path = ["_static"]

html_theme_options = {
    'logo_only': False,
    'prev_next_buttons_location': 'bottom',
    'style_external_links': False,
    'vcs_pageview_mode': '',
    # 'style_nav_header_background': 'white',
    'flyout_display': 'hidden',
    'version_selector': True,
    'language_selector': True,
    # Toc options
    'collapse_navigation': True,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False,
    'use_edit_page_button': True,
    'use_repository_button': True,
}

html_context = {
    "display_github": True,
    "github_repo": "wandb-fortran",
    "github_user": "nedtaylor",
    "github_version": "main",
    "conf_py_path": "/docs/source/",
}
