#!/bin/bash


function proxy {
  BUILD_HOST_FILE=/build_host.txt
  YUM_PROXY_CONF=/etc/yum.conf

  # Determine build host
  netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}' > ${BUILD_HOST_FILE}

  # squid proxy if available
  curl -sv  http://`cat ${BUILD_HOST_FILE}`:3128  2>&1 > /dev/null | grep squid-deb-proxy \
    && (echo "proxy=http://$(cat ${BUILD_HOST_FILE}):3128" >> ${YUM_PROXY_CONF}) \
    || echo "No squid proxy detected on docker host"
}


function defaults {
    : ${SPECFILE="/app/centos/centos.spec"}
    : ${CCGSOURCEDIR="/app"}
    : ${TOPDIR="/data/rpmbuild"}

    PATH="${PATH}:${APPEND_PATH}"

    echo "SPECFILE is ${SPECFILE}"
    echo "CCGSOURCEDIR is ${CCGSOURCEDIR}"
    echo "PATH is ${PATH}"
    echo "APPEND_PATH is ${APPEND_PATH}"
    echo "TOPDIR is ${TOPDIR}"

    export TOPDIR PATH SPECFILE CCGSOURCEDIR
}


echo "HOME is ${HOME}"
echo "WHOAMI is `whoami`"

proxy
defaults

# rpmbuild entrypoint
if [ "$1" = 'rpmbuild' ]; then
    echo "[Run] Starting rpmbuild"

    yum-builddep -y ${SPECFILE}
    rpmbuild --define "_topdir ${TOPDIR}" -bb ${SPECFILE}

    # Horrible hack to fix perm issues on CI
    chmod -R o+w ${TOPDIR}

    exit $?
fi

echo "[RUN]: Builtin command not provided [rpmbuild]"
echo "[RUN]: $@"

exec "$@"
