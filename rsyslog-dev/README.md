rsyslog-dev
===========
A dockerfile that sets up a container environment for building rsyslog v8 from the source code.

Based on the following references, among others:
* http://www.rsyslog.com/doc/v8-stable/installation/install_from_source.html
* http://www.rsyslog.com/doc/v8-stable/installation/build_from_repo.html
* http://www.rsyslog.com/doc/build_from_repo.html

You can use the container in various ways. You can for example use the following Docker Compose file to mount directories in your host machine for the rsyslog source code and the rsyslog configuration files. This will allow you to edit the source code and the configuration directly from your machine, and build and run rsyslog within the container.
```yaml
version: '2'

services:
  rsyslog:
    container_name: rsyslog
    image: jsiwrk/rsyslog-dev
    network_mode: "bridge"
    volumes:
      - ~/work/rsyslog:/root/work/rsyslog:rw
      - ./config/rsyslog.d:/etc/rsyslog.d:ro
```

Follow these steps:
1. In your host machine, clone the rsyslog Git repo you want to work with. Let's assume the cloned repo is located in `~/work/rsyslog` in your host machine (if you want to use any other directory, change the mounted path above).
1. Create a directory where you will run `docker-compose` from. For example, `~/work/docker/rsyslog`. In that directory, create a `docker-compose.yml` file with the above content.
1. Create also a subdirectory `~/work/docker/rsyslog/config/rsyslog.d`. You can put there the additional rsyslog configuration files you want to use.
1. Start the container as follows:
    ```
    $ cd ~/work/docker/rsyslog
    $ docker-compose up -d
    ```
1. Now a container named `rsyslog` is running with your rsyslog source code and configuration files mounted. However, the installed rsyslog binaries are still the official ones. In the next steps we will recompile and reinstall rsyslog within the container from the source code in your host machine.
1. First you need to run `autoreconf` to initialize the build environment. This step is needed only once.
    ```
    $ docker exec rsyslog autoreconf -fvi
    ```
1. You also need to run `configure` to define the rsyslog features to be built and installed. This step is needed only once, or whenever you want to change the features. For example, to enable `imfile`, `omprog` and the testbench, run the following command:
    ```
    $ docker exec rsyslog ./configure --enable-imfile --enable-omprog --enable-testbench --enable-imdiag --enable-omstdout
    ```
1. Now the environment is ready to build rsyslog from the source code in your host machine. Simply type:
    ```
    $ docker exec rsyslog make
    ```
1. And to install rsyslog:
    ```
    $ docker exec rsyslog make install
    ```
1. At this point the container has your own rsyslog installed, but rsyslog is still not running. To start the daemon, type:
    ```
    $ docker exec rsyslog rsyslogd
    ```
1. Or, if you prefer to start a shell session in the container:
    ```
    $ docker exec -ti rsyslog bash
    ```
1. If you want to run the tests, type:
    ```
    $ docker exec rsyslog make check
    ```
1. If you want to run an individual test, type:
    ```
    $ docker exec rsyslog make check TESTS="test-to-run.sh"
    ```

To stop the container, run the following:
```
$ docker-compose stop
```

Note that by simply stopping the container, the container state is kept. This includes the installed rsyslog binaries and the internal rsyslog state files, so these will remain the same when you start the container again with `docker-compose up`.

If you want to clear the binaries and the state files, remove the container as follows:
```
$ docker-compose down
```

In this way, when you start the container again with `docker-compose up`, it will be clean. You will need to execute again the `make install` step to reinstall your compiled binaries. Note however that you do not need to run `make` again (or `autoreconf` or `./configure`), since the compiled binaries are kept in your host machine, not within the container.
