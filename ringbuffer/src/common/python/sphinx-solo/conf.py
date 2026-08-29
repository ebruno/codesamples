import os
import sys

# Add the Python source directory to the path so autodoc can find it
_conf_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_conf_dir, '..'))

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
]

napoleon_google_docstring = True
napoleon_numpy_docstring = False
napoleon_include_init_with_doc = False

html_theme = "sphinx_rtd_theme"

# Project metadata
project = "swtr_ringbuffer Python"
copyright = "2019, Eric Bruno"
