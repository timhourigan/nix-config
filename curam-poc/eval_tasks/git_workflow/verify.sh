#!/bin/sh
set -e
cd $TASK_DIR && git log --format=%s | grep -qE 'feat|fix|chore:? '
