#!/bin/sh
set -e
cd $TASK_DIR && python3 -m unittest test_calc -v 2>&1 | grep -q 'OK'
