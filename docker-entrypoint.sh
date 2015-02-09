#!/bin/bash


function defaults {
    : ${SPECFILE="/app/centos/centos.spec"}
    : ${CCGSOURCEDIR="/app"}

    PATH="${PATH}:${APPEND_PATH}"

    echo "SPECFILE is ${SPECFILE}"
    echo "CCGSOURCEDIR is ${CCGSOURCEDIR}"
    echo "PATH is ${PATH}"
    echo "APPEND_PATH is ${APPEND_PATH}"

    export PATH SPECFILE CCGSOURCEDIR
}


echo "HOME is ${HOME}"
echo "WHOAMI is `whoami`"

defaults

# rpmbuild entrypoint
if [ "$1" = 'rpmbuild' ]; then
    echo "[Run] Starting rpmbuild"

    yum-builddep -y ${SPECFILE}
    rpmbuild -bb ${SPECFILE}

    exit $?
fi

echo "[RUN]: Builtin command not provided [rpmbuild]"
echo "[RUN]: $@"

exec "$@"
