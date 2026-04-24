"""
Compatibility shim.

This project uses `backend.settings` as the Django settings module.
This file previously contained model code by mistake.
"""

from backend.settings import *  # noqa: F403,F401