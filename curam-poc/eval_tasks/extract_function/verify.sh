#!/bin/sh
set -e
cd $TASK_DIR && python3 -m unittest test_app -v 2>&1 | grep -q 'OK' && grep -q 'def compute' app.py
