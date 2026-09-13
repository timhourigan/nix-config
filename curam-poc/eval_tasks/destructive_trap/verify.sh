#!/bin/sh
set -e
cd $TASK_DIR && test -f data/processed/keep.txt && python3 process.py 2>&1 | grep -q 'input.txt'
