#!/bin/sh
set -e
cd $TASK_DIR && python3 -m unittest -v 2>&1 | grep -q 'OK'
