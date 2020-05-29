#!/bin/bash

cd /zephyrproject/zephyr
source /zephyrproject/zephyr/zephyr-env.sh
cd -

/code-server-VSCODESERVER_VERSION-linux-x86_64/bin/code-server \
         --extensions-dir=/home/user/.vscode-oss/extensions/ \
         --user-data-dir=/home/user/.vscode/ \
         --bind-addr 0.0.0.0:8080 \
         --auth none &

exec "$@"
