#!/bin/sh
set -e
cd $TASK_DIR && python3 -m unittest -v 2>&1 | grep -q 'OK' && printf 'a\nb\nc\n' | python3 headtool.py --limit 2 | grep -c '^' | grep -q '^2$'
