#
FROM muccg/python-base:centos6-2.7
MAINTAINER ccg <ccgdevops@googlegroups.com>

RUN yum install -y \
    autoconf \
    automake \
    createrepo \
    rpm-build \
    tar \
    yum-utils \
    && yum clean all

VOLUME ["/app", "/data"]

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV HOME /data
WORKDIR /data

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rpmbuild"]
