FROM ubuntu:18.04

ARG user=developer
ARG uid=1000
ARG gid=1000

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
	sudo

# Create developer user and make it a sudoer:
RUN groupadd -g ${gid} ${user} \
	&& useradd -u ${uid} -g ${gid} -G sudo -m ${user} \
	&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ${user}

# Configure bash:
RUN mkdir /home/${user}/work \
	&& mkdir /home/${user}/.bashrc.d \
	&& echo 'source <(cat ~/.bashrc.d/*)' >> ~/.bashrc

COPY --chown=${uid}:${gid} bashrc.d/*  /home/${user}/.bashrc.d/

WORKDIR /home/${user}/work

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

# Download rsyslog and build it:
RUN git clone --single-branch --branch master https://github.com/rsyslog/rsyslog.git \
	&& cd rsyslog \
	&& git checkout master \
	&& autoreconf -fvi \
	&& ./configure --enable-imfile --enable-omprog --enable-testbench --enable-imdiag --enable-omstdout \
	&& make \
	&& sudo make install

# Create rsyslog working and config directories:
RUN sudo mkdir -p /var/lib/rsyslog \
	&& sudo mkdir -p /etc/rsyslog.d

# Copy rsyslog main config file:
COPY ./etc/rsyslog.conf /etc/

# Bash required for the RUN command that follows
SHELL ["/bin/bash", "-c"]

# Download the rsyslog-doc repo and generate the HTML documentation:
RUN curl https://bootstrap.pypa.io/get-pip.py | python \
	&& python -m pip install virtualenv --user \
	&& python -m virtualenv rsyslog-doc-build \
	&& source rsyslog-doc-build/bin/activate \
	&& git clone https://github.com/rsyslog/rsyslog-doc.git \
	&& cd rsyslog-doc \
	&& git checkout master \
	&& pip install -r requirements.txt \
	&& sphinx-build -b html source build

WORKDIR /home/${user}/work/rsyslog

ENTRYPOINT ["tail", "-f", "/dev/null"]

# To start the rsyslog daemon, run 'rsyslogd -n' inside the container.
# To stop the daemon, run 'kill $(cat /var/run/rsyslogd.pid)'.

# Or you can use this entrypoint:
# ENTRYPOINT [ "rsyslogd", "-f", "/etc/rsyslog.conf", "-n" ]
