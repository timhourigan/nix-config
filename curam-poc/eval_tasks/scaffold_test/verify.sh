#!/bin/sh
set -e
cd $TASK_DIR && python3 -c 'from greet.hello import hello; assert hello("x") == "Hello, x!"'
