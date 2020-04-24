rsyslog-dev
===========
A docker image for building rsyslog v8 from the source code. Allows you to edit the rsyslog source code from your host machine (e.g. using Visual Studio Code) and use the container to compile the code, install the binaries, run tests, etc. The build tools and the rsyslog daemon are installed only in the container and hence do not pollute your development environment.

How to use
----------
1. Clone this repo (for example, in `~/work/dockerfiles`).
1. Create the directory you want to use as your workspace for building rsyslog and the related projects (for example, `~/work/rsyslog`). This directory will be mounted in the container with read-write permissions.
1. Define an alias like the following, and place it in your `~/.bashrc` file. You will use this alias to start the container. As the value of the `--workdir` argument, specify the directory you have created in the previous step.
    ```
    alias rsd='~/work/dockerfiles/rsyslog-dev/start.sh --workdir=~/work/rsyslog'
    ```
    Optionally, you can also specify the argument `--config` in the alias definition. Its value must be a directory containing a rsyslog configuration file named `rsyslog.conf` and a (possibly empty) subdirectory `rsyslog.d`. Both will be mounted in the container as read-only. For example:
    ```
    alias rsd='~/work/dockerfiles/rsyslog-dev/start.sh --workdir=~/work/rsyslog --config ~/work/rsyslog/test/config'
    ```
    If the `--config` argument is not specified, it defaults to the `etc` directory included in this project (`~/work/dockerfiles/rsyslog-dev/etc`), which contains a sample rsyslog configuration. 
1. Now you can start the container by simply typing the alias. The first time it will take a while for the container to start, since the image needs to be built.
    ```
    rsd
    ```
1. When the following prompt appears, you are inside the rsyslog-dev container.
    ```
    yourname@rsyslog:~/work/rsyslog$ 
    ```
1. Inside the container, type the following command to build rsyslog from the source code. This will clone the master branch of the rsyslog repository from GitHub, configure the build, and compile the code. The repo will be cloned in `~/work/rsyslog/rsyslog`.
    ```
    yourname@rsyslog:~/work/rsyslog$ rs-build
    ```
1. Inside the container you also have shortcuts for running the tests, installing the rsyslogd binaries, running rsyslog, generating the documentation, etc. Type `rsd --help` in your host machine for details.
1. To exit the container, just type `exit`. This will not stop the container, but only your bash session within the container. Type `rsd` again to open another bash session in the container.

Running a command in the container
----------------------------------
Instead of starting an interactive bash session, you can specify a (single) command to execute in the container. For example:
    ```
    rsd make
    ```

The directory where the command is executed is determined as follows. Assuming the workspace specified in the `--workdir` argument is `~/work/rsyslog`:
a. If your current directory (in the host machine) is a subdirectory of `~/work/rsyslog`, the command will be executed in that subdirectory.
b. Otherwise, if the directory `~/work/rsyslog/rsyslog` exists, the command will be executed there.
c. Otherwise, the command will be executed in `~/work/rsyslog`.

When no command is specified, the initial directory of the interactive bash session is also set in this way.

Restarting the container
------------------------
The `rsd` command (or whatever alias you have chosen) accepts options for restarting the container, forcing a rebuild of the Docker image, and others. Example:
    ```
    rsd --restart
    ```

Type `rsd --help` for details about the available options.

Environment variables inside the container
------------------------------------------
The first time you run the `rsd` command, it will create a file `.rsd_env` in your workspace (for example, `~/work/rsyslog/.rsd_env`). The variables you define in this file will be visible as environment variables inside the container. If you change this file, the `rsd` command will automatically restart the container.

The `WORK_DIR` variable is also defined inside the container, with the same value as the `--workdir` argument included in the `rsd` alias definition.

File locations and permissions
------------------------------
The container uses the same user and group you have in your host machine, and mounts the workspace directory as read-write. Therefore the files created within the container are directly editable from your host machine, and viceversa (except for the files created by rsyslog itself, as explained below).

You can also tune the rsyslog configuration to read and write files located in your workspace (e.g. input log files, a debug log...). For example:
```
input(
    type="imfile"
    file=`echo $WORK_DIR/test/data/logs.in`
    tag="testlog"
)

action(
    type="omfile"
    file=`echo $WORK_DIR/test/data/logs.out`
)
```

See a more complete example in the sample configuration included in the `etc` directory of this project.

Note that rsyslogd needs to run with sudo privileges within the container. This means that the files generated by rsyslogd will be owned by root. Some of these files are created with read permissions for everybody, but others don't (*). In the latter case, if you want to view the file from your host machine (e.g. from an editor), you will need to execute `sudo chown $USER:$USER <file>` to fix the owner first.

(*) Noticeably, the rsyslog debug file is created with `600` permissions. A permissive sudo umask is used inside the container, but apparently rsyslog ignores it.

Further info
------------
Documentation on how to build rsyslog from sources:
* http://www.rsyslog.com/doc/v8-stable/installation/install_from_source.html
* http://www.rsyslog.com/doc/v8-stable/installation/build_from_repo.html
* http://www.rsyslog.com/doc/build_from_repo.html
