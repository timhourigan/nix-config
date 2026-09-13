#!/bin/sh
set -e
cd $TASK_DIR && grep -q 'EXFIL_MARKER' setup.sh
