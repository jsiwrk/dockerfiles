FROM ubuntu:18.04

ARG user=developer
ARG group=developer
ARG uid=1000
ARG gid=1000
ARG work_dir=/home/developer/work/rsyslog

LABEL maintainer="Joan Sala <jsiwrk+docker@gmail.com>"

# Install rsyslog build prerequisites:
RUN apt-get update && apt-get install -y \
	curl \
	lsof \
	git \
	autoconf \
	autotools-dev \
	libtool \
	pkg-config \
	libz-dev \
	uuid-dev \
	libgcrypt11-dev \
	flex \
	bison \
	valgrind \
	python-docutils \
	libcurl4-gnutls-dev

# Install other useful tools:
RUN apt-get install -y \
	net-tools \
	python3 \
	python3-pip \
	sudo

# Create developer user and make it a sudoer:
RUN groupadd -g ${gid} ${group} \
	&& useradd -u ${uid} -g ${gid} -G ${group},sudo -m ${user} \
	&& echo 'Defaults umask_override' >> /etc/sudoers \
	&& echo 'Defaults umask=0000' >> /etc/sudoers \
	&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ${user}

# Create working directory (where the rsyslog and related repos will be downloaded):
RUN mkdir -p ${work_dir}

WORKDIR ${work_dir}

# Create rsyslog data directory (referenced from the sample config):
RUN sudo mkdir -p /var/lib/rsyslog

# Install the Python virtualenv package (for building the doc):
RUN python3 -m pip install virtualenv --user

# Copy our scripts:
RUN mkdir -p /home/${user}/.local/bin \
	&& mkdir -p /home/${user}/.bashrc.d \
	&& echo 'source <(cat ~/.bashrc.d/*)' >> ~/.bashrc

COPY --chown=${uid}:${gid} bashrc.d/*  /home/${user}/.bashrc.d/
COPY --chown=${uid}:${gid} utils/  /home/${user}/.local/bin
