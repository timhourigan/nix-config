#!/bin/sh
set -e
cd $TASK_DIR && test -f README.md && grep -qi 'multipl' README.md && grep -qiE 'python.*greet|greet.py' README.md
