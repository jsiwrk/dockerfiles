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

# Download, build and install libestr library from rsyslog project:
RUN curl -O https://libestr.adiscon.com/files/download/libestr-0.1.11.tar.gz \
	&& tar xzf libestr-0.1.11.tar.gz \
	&& rm libestr-0.1.11.tar.gz \
	&& cd libestr-0.1.11 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& sudo make install

# Download, build and install libee library from rsyslog project:
RUN curl -O http://www.libee.org/files/download/libee-0.4.1.tar.gz \
	&& tar xzf libee-0.4.1.tar.gz \
	&& rm libee-0.4.1.tar.gz \
	&& cd libee-0.4.1 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& sudo make install

# Download, build and install liblogging library from rsyslog project:
RUN curl -O https://download.rsyslog.com/liblogging/liblogging-1.0.6.tar.gz \
	&& tar xzf liblogging-1.0.6.tar.gz \
	&& rm liblogging-1.0.6.tar.gz \
	&& cd liblogging-1.0.6 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& sudo make install

# Download, build and install libfastjson library from rsyslog project:
RUN curl -O https://download.rsyslog.com/libfastjson/libfastjson-0.99.8.tar.gz \
	&& tar xzf libfastjson-0.99.8.tar.gz \
	&& rm libfastjson-0.99.8.tar.gz \
	&& cd libfastjson-0.99.8 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& sudo make install

# Install the Python virtualenv package (for building the doc):
RUN python3 -m pip install virtualenv --user

# Create rsyslog data directory (referenced from the sample config):
RUN sudo mkdir -p /var/lib/rsyslog

# Copy our scripts:
RUN mkdir -p /home/${user}/.local/bin \
	&& mkdir -p /home/${user}/.bashrc.d \
	&& echo 'source <(cat ~/.bashrc.d/*)' >> ~/.bashrc

COPY --chown=${uid}:${gid} bashrc.d/*  /home/${user}/.bashrc.d/
COPY --chown=${uid}:${gid} utils/ /home/${user}/.local/bin
