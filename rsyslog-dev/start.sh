#!/bin/bash -e

function usage {
	echo 'Usage: start.sh [options] [command]'
	echo
	echo 'Starts the rsyslog-dev container, if not started yet, and optionally executes a'
	echo 'command within it. If no command is specified, starts an interactive bash session'
	echo 'in the container.'
	echo
	echo 'Options:'
	echo '  --restart          restart the container. This is done automatically if the'
	echo '                     WORK_DIR/.rsd_env file (see below) has changed.'
	echo '  --rebuild          rebuild the container. This is done automatically if the image'
	echo '                     does not exist yet. Implies --restart.'
	echo '  --workdir DIR      working directory (default: ~/work/rsyslog). The "rsyslog" and'
	echo '                     "rsyslog-doc" repos will be downloaded in this directory. It is'
	echo '                     mounted inside the container as read-write, with the same path.'
	echo '  --config DIR       config directory (default: "etc" directory next to this script).'
	echo '                     Must contain a rsyslog.conf file and rsyslog.d directory. Both'
	echo '                     are mounted as read-only to the "etc" directory in the container.'
	echo '  --hosts HOSTS      host names defined in /etc/hosts that must also be resolvable'
	echo '                     within the container. A list of host names separated by spaces.'
	echo '  --image NAME       name of the docker image (default: rsyslog-dev)'
	echo '  --container NAME   name of the docker container (default: rsyslog-dev)'
	echo '  -h,--help          show this help message'
	echo
	echo 'Environment variables defined inside the container:'
	echo '  WORK_DIR           same value as --workdir'
	echo '  BUILD_OPTS         build options. Defined in WORK_DIR/.rsd_env'
	echo '  (others)           any other variable defined in WORK_DIR/.rsd_env'
	echo
	echo 'Auxiliary commands inside the container:'
	echo '  rs-build           checkout rsyslog (if not done yet), configure build, and make'
	echo '  rs-check [PREFIX]  run the tests (make check), or only those named PREFIX-*.sh'
	echo '  rs-install         install the compiled rsyslogd (make install)'
	echo '  rs-run [ARGS]      run rsyslogd (e.g. "rs-run -n &" to run in non-daemon mode)'
	echo '  rs-kill            kill rsyslogd'
	echo '  rs-build-doc       checkout rsyslog-doc (if not done yet) and generate the HTML doc'
	echo
	echo 'Tip: in ~/.bashrc, define an alias for this script that sets the desired options. E.g.:'
	echo '  alias rsd="~/work/dockerfiles/rsyslog-dev/start.sh --workdir ~/work/rsyslog --config ~/work/rsyslog/test/config"'
	echo
}

src_dir=$(dirname "$0")
work_dir=~/work/rsyslog
config_dir=$src_dir/etc
image_name=rsyslog-dev
container_name=rsyslog-dev
rebuild=false
restart=false

positional_args=()
while [[ $# -gt 0 ]]; do
    opt="$1"
    case $opt in
        -h|--help)
            usage
            exit 0
        ;;
        --restart)
			restart=true
            shift
        ;;
        --rebuild)
			rebuild=true
			restart=true
            shift
        ;;
        --workdir)
            work_dir="$2"
            shift
            shift
        ;;
        --config)
            config_dir="$2"
            shift
            shift
        ;;
        --hosts)
            known_hosts="$2"
            shift
            shift
        ;;
        --image)
            image_name="$2"
            shift
            shift
        ;;
        --container)
            container_name="$2"
            shift
            shift
        ;;
        *)
            positional_args+=("$1")
            shift
        ;;
    esac
done

# Check if the container is running:
if [[ $(docker ps --filter "name=^/$container_name$" --format '{{.Names}}') == $container_name ]]; then
	running=true
else
	running=false
fi

# Create default environment variables file for container, if not present:
env_file=$work_dir/.rsd_env
if [[ ! -e "$env_file" ]]; then
	tee "$env_file" >/dev/null <<-_EOT_
		BUILD_OPTS=--enable-imfile --enable-omprog --enable-testbench --enable-imdiag --enable-omstdout

		# Uncomment these variables to enable debug:
		#RSYSLOG_DEBUG=Debug NoStdOut
		#RSYSLOG_DEBUGLOG=$work_dir/test/data/__rsyslog-debug.log
	_EOT_
fi

# Create bash history file for container, if not present:
bash_history_file=$work_dir/.rsd_bash_history
if [[ ! -e "$bash_history_file" ]]; then
	touch $bash_history_file
fi

# Build the image if it does not exist yet, or if requested via argument:
if [[ "$rebuild" == "true" || "$(docker images -q $image_name)" == "" ]]; then
	echo "Building the $image_name docker image..."
	docker build \
		--build-arg "user=$USER" \
		--build-arg "group=$(id --group --name $USER)" \
		--build-arg "uid=$(id --user $USER)" \
		--build-arg "gid=$(id --group $USER)" \
		--build-arg "work_dir=$work_dir" \
		-t $image_name \
		$src_dir

	echo "Pruning unused docker images..."
	docker image prune -f
fi

# Detect if the environment variables file has been modified since the container was started:
if [[ "$running" == "true" && "$restart" == "false"  ]]; then
	started_at=$(docker inspect --format='{{.State.StartedAt}}' $container_name)
	start_time=$(date +%s --date=$started_at)
	update_time=$(date +%s -r $env_file)
	if (( $update_time > start_time)); then
		echo "Environment file (.rsd_env) modified, the container will be restarted"
		restart=true
	fi
fi

# Stop the container if a restart is required:
if [[ "$restart" == "true" && "$running" == "true" ]]; then
	echo "Stopping the $container_name container..."
	docker stop $container_name
	running=false
fi

# Start the container in the background if not already running:
if [[ "$running" == "false" ]]; then
	echo "Starting the $container_name container..."

	known_host_mappings=
	for host_name in $known_hosts; do
		host_ip=$(getent hosts $host_name | awk '{ print $1 ; exit }')
		if [[ ! -z "$host_ip" ]]; then
			known_host_mappings="$known_host_mappings --add-host $host_name:$host_ip"
		fi
	done

	docker run --name $container_name \
		-d --rm \
		--volume $work_dir:$work_dir \
		--volume $bash_history_file:$HOME/.bash_history \
		--volume $config_dir/rsyslog.conf:/etc/rsyslog.conf:ro \
		--volume $config_dir/rsyslog.d:/etc/rsyslog.d:ro \
		--env WORK_DIR=$work_dir \
		--env-file=$env_file \
		--net=host \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--security-opt apparmor=unconfined \
		$known_host_mappings \
		$image_name \
		tail -f /dev/null
fi

if [[ "${#positional_args[*]}" == 0 ]]; then
	# Launch an interactive shell in the container:
	docker exec -ti --env CURRENT_DIR=$PWD $container_name bash
else
	# Execute a specific command in the container:
	docker exec -ti --env CURRENT_DIR=$PWD $container_name bash -i -c "${positional_args[*]}"
fi
