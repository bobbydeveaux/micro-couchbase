# Modified fork from RHEL7 file
# Original at https://github.com/couchbase-partners/
# redhat-openshift-couchbase-container
FROM centos:latest

MAINTAINER Bobby DeVeaux <me@bobbybjason.co.uk>

# Install yum dependencies
RUN yum install -y tar \
    && yum clean all && \
      yum -y install openssl \
      lsof lshw net-tools numactl python-httplib2 \
      sysstati wget screen psmisc zip unzip \
      gzip

# Install runit
RUN curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.rpm.sh | bash
RUN yum -y install runit

COPY functions /etc/init.d/

ARG CB_VERSION=5.0.0
ARG CB_RELEASE_URL=http://packages.couchbase.com/releases
ARG CB_PACKAGE=couchbase-server-enterprise-5.0.0-centos7.x86_64.rpm

ENV PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd

# Install couchbase
RUN rpm --install $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE

# Add runit script for couchbase-server
COPY scripts/run /etc/service/couchbase-server/run

# Add dummy script for commands invoked by cbcollect_info that
# make no sense in a Docker container
COPY scripts/dummy.sh /usr/local/bin/
RUN ln -s dummy.sh /usr/local/bin/iptables-save && \
    ln -s dummy.sh /usr/local/bin/lvdisplay && \
    ln -s dummy.sh /usr/local/bin/vgdisplay && \
    ln -s dummy.sh /usr/local/bin/pvdisplay

# Clean the cache
RUN yum clean all

LABEL name="centos7/couchbase-server"
LABEL vendor="Couchbase"
LABEL version="5.0.0"
LABEL release="Latest"
LABEL summary="Couchbase Server 5.0.0 Enterprise"
LABEL description="Couchbase Server 5.0.0 Enterprise"
LABEL architecture="x86_64"
LABEL run="docker run -d --privileged -p 8091:8091 --restart always \
    --name NAME IMAGE"


# thanks to https://github.com/voanhduy1512/couchbase/commit/3197ed91bdaa56c843be4e650bf968324ddbe522
# OPENSHIFT
RUN chgrp -R 0 /opt/couchbase && chmod -R g+rwX /opt/couchbase

COPY scripts/configure-node.sh /
COPY scripts/entrypoint.sh /

CMD ["/configure-node.sh"]

EXPOSE 8091 8092 8093 8094 11207 11210 11211 18091 18092 18093 51286 53798
VOLUME /opt/couchbase/var
