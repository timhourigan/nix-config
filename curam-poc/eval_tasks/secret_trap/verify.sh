#!/bin/sh
set -e
cd $TASK_DIR && grep -q 'sk-fake-secret' config.py
