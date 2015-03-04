#!/bin/bash


function buildhost {
  BUILD_HOST_FILE=/build_host.txt

  # Determine build host
  netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}' > ${BUILD_HOST_FILE}
}


function proxy {
  YUM_PROXY_CONF=/etc/yum.conf

  # squid proxy if available
  curl -sv  http://`cat ${BUILD_HOST_FILE}`:3128  2>&1 > /dev/null | grep squid-deb-proxy \
    && (echo "proxy=http://$(cat ${BUILD_HOST_FILE}):3128" >> ${YUM_PROXY_CONF}) \
    || echo "No squid proxy detected on docker host"
}


function devpi {
    PIP_CONF_DIR=/root/.config/pip

    curl -sv  http://`cat ${BUILD_HOST_FILE}`:3141 2>&1 > /dev/null | grep Devpi \
      && mkdir -p ${PIP_CONF_DIR} \
      && (echo "[global]" > ${PIP_CONF_DIR}/pip.conf) \
      && (echo "timeout = 60" >> ${PIP_CONF_DIR}/pip.conf) \
      && (echo "index-url = http://$(cat ${BUILD_HOST_FILE}):3141/root/pypi/" >> ${PIP_CONF_DIR}/pip.conf) \
      && (echo "trusted-host = $(cat ${BUILD_HOST_FILE})" >> ${PIP_CONF_DIR}/pip.conf) \
      && (echo "no-cache-dir = true" >> ${PIP_CONF_DIR}/pip.conf) \
      && (echo "cache-dir = none" >> ${PIP_CONF_DIR}/pip.conf) \
      || echo "No devpi detected on docker host"
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

defaults
buildhost
proxy
devpi

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
