import breathe

extensions = [
    "breathe",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
]

html_theme = "sphinx_rtd_theme"

# Breathe config — points to Doxygen XML output
breathe_projects = {"python": "../../../../docs/ringbuffer/python/doxygen/xml"}
breathe_default_project = "python"

# Project metadata
project = "swtr_ringbuffer Python"
copyright = "2019, Eric Bruno"
