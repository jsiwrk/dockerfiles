FROM ubuntu:16.04

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
RUN apt-get update && apt-get install -y \
	python3

RUN mkdir -p /root/work

WORKDIR /root/work

# Download, build and install libestr library from rsyslog project:
RUN curl -O http://libestr.adiscon.com/files/download/libestr-0.1.10.tar.gz \
	&& tar xzf libestr-0.1.10.tar.gz \
	&& rm libestr-0.1.10.tar.gz \
	&& cd libestr-0.1.10 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& make install

# Download, build and install libee library from rsyslog project:
RUN curl -O http://www.libee.org/files/download/libee-0.4.1.tar.gz \
	&& tar xzf libee-0.4.1.tar.gz \
	&& rm libee-0.4.1.tar.gz \
	&& cd libee-0.4.1 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& make install

# Download, build and install liblogging library from rsyslog project:
RUN curl -O http://download.rsyslog.com/liblogging/liblogging-1.0.6.tar.gz \
	&& tar xzf liblogging-1.0.6.tar.gz \
	&& rm liblogging-1.0.6.tar.gz \
	&& cd liblogging-1.0.6 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& make install

# Download, build and install libfastjson library from rsyslog project:
RUN curl -O http://download.rsyslog.com/libfastjson/libfastjson-0.99.8.tar.gz \
	&& tar xzf libfastjson-0.99.8.tar.gz \
	&& rm libfastjson-0.99.8.tar.gz \
	&& cd libfastjson-0.99.8 \
	&& ./configure --libdir=/usr/lib --includedir=/usr/include \
	&& make \
	&& make install

# Download rsyslog and build it:
RUN git clone https://github.com/rsyslog/rsyslog.git \
	&& cd rsyslog \
	&& git checkout master \
	&& autoreconf -fvi \
	&& ./configure --enable-imfile --enable-omprog --enable-testbench --enable-imdiag --enable-omstdout \
	&& make \
	&& make install

# Create rsyslog working and config directories:
RUN mkdir -p /var/lib/rsyslog \
	&& mkdir -p /etc/rsyslog.d

# Copy rsyslog main config file:
COPY ./etc/rsyslog.conf /etc/

WORKDIR /root/work/rsyslog

ENTRYPOINT ["tail", "-f", "/dev/null"]

# To start the rsyslog daemon, run 'rsyslogd -n' inside the container.
# To stop the daemon, run 'kill $(cat /var/run/rsyslogd.pid)'.

# Or you can use this entrypoint:
# ENTRYPOINT [ "rsyslogd", "-f", "/etc/rsyslog.conf", "-n" ]
