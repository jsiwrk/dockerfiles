#!/bin/bash -e

function usage {
	echo 'Usage: start.sh [option]'
	echo
	echo 'Starts the rsyslog-dev container. Builds the rsyslog-dev image if not built yet.'
	echo
	echo 'Option can be one of:'
	echo '  --restart          restart the container'
	echo '  --rebuild          rebuild the container'
	echo '  --stop             stop the container'
	echo '  --help             show this help message'
	echo
	echo 'Environment variables understood by this script:'
	echo '  RSD_WORK_DIR       working directory (default: ~/work/rsyslog). The "rsyslog" and'
	echo '                     "rsyslog-doc" repos will be downloaded in this directory. It is'
	echo '                     mounted inside the container as read-write, with the same path.'
	echo '  RSD_CONFIG_DIR     config directory (default: "etc" directory next to this script).'
	echo '                     Must contain a rsyslog.conf file and rsyslog.d directory. Both'
	echo '                     are mounted as read-only to the "etc" directory in the container.'
	echo
	echo 'Environment variables defined inside the container:'
	echo '  WORK_DIR           same value as RSD_WORK_DIR'
	echo '  BUILD_OPTS         build options. Defined in $RSD_WORK_DIR/.rsd_env'
	echo '  (others)           any other variable defined in $RSD_WORK_DIR/.rsd_env'
	echo
	echo 'Useful commands inside the container:'
	echo '  rs-build           checkout rsyslog (if not done yet), configure build, and compile'
	echo '  make               compile incrementally (execute in $WORK_DIR/rsyslog)'
	echo '  rs-check [PREFIX]  run the tests (make check), or only those named PREFIX-*.sh'
	echo '  rs-install         install the compiled rsyslogd'
	echo '  rs-run [ARGS]      run rsyslogd (e.g. "rs-run -n &" to run in non-daemon mode)'
	echo '  rs-kill            kill rsyslogd'
	echo '  rs-build-doc       checkout rsyslog-doc (if not done yet) and generate the HTML doc'
	echo
	echo 'Tip: in ~/.bashrc, you can define an alias for this script that sets the desired values'
	echo 'for RSD_WORK_DIR and RSD_CONFIG_DIR. Example:'
	echo '  alias rsd="RSD_WORK_DIR=~/work/rsyslog RSD_CONFIG_DIR=~/work/rsyslog/test/config ~/work/dockerfiles/rsyslog-dev/start.sh"'
	echo
}

if [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# > 1 ]]; then
	echo "Error: Too many arguments"
    usage
    exit 1
fi

if [[ -n "$1" && "$1" != "--restart" && "$1" != "--rebuild" && "$1" != "--stop" ]]; then
	echo "Error: Unrecognized option: $1"
    usage
    exit 1
fi

SRC_DIR=$(dirname "$0")

if [[ -z "$RSD_WORK_DIR" ]]; then
	RSD_WORK_DIR=~/work/rsyslog
fi

if [[ -z "$RSD_CONFIG_DIR" ]]; then
	RSD_CONFIG_DIR=$SRC_DIR/etc
fi

if [[ -z "$RSD_IMAGE_NAME" ]]; then
	RSD_IMAGE_NAME=rsyslog-dev
fi

if [[ -z "$RSD_CONTAINER_NAME" ]]; then
	RSD_CONTAINER_NAME=rsyslog-dev
fi

# Stop the container if requested:
if [[ "$1" == "--stop" ]]; then
	echo "Stopping the $RSD_CONTAINER_NAME container..."
	docker stop $RSD_CONTAINER_NAME
	exit 0
fi

if [[ "$1" == "--rebuild" ]]; then
	rebuild=true
	restart=true
elif [[ "$1" == "--restart" ]]; then
	rebuild=false
	restart=true
else
	rebuild=false
	restart=false
fi

# Check if the container is running:
if [[ $(docker ps --filter "name=^/$RSD_CONTAINER_NAME$" --format '{{.Names}}') == $RSD_CONTAINER_NAME ]]; then
	running=true
else
	running=false
fi

# Create default environment variables file for container, if not present:
RSD_ENV_FILE=$RSD_WORK_DIR/.rsd_env
if [[ ! -e "$RSD_ENV_FILE" ]]; then
	tee "$RSD_ENV_FILE" >/dev/null <<-_EOT_
		BUILD_OPTS=--enable-imfile --enable-omprog --enable-testbench --enable-imdiag --enable-omstdout

		# Uncomment this to enable debug
		#RSYSLOG_DEBUG=Debug NoStdOut
		#RSYSLOG_DEBUGLOG=$RSD_WORK_DIR/test/data/__rsyslog-debug.log
	_EOT_
fi

# Create bash history file for container, if not present:
RSD_BASH_HISTORY_FILE=$RSD_WORK_DIR/.rsd_bash_history
if [[ ! -e "$RSD_BASH_HISTORY_FILE" ]]; then
	touch $RSD_BASH_HISTORY_FILE
fi

# Build the image if it does not exist yet, or if requested via argument:
if [[ "$rebuild" == "true" || "$(docker images -q $RSD_IMAGE_NAME)" == "" ]]; then
	echo "Building the $RSD_IMAGE_NAME docker image..."
	docker build \
		--build-arg "user=$USER" \
		--build-arg "group=$(id --group --name $USER)" \
		--build-arg "uid=$(id --user $USER)" \
		--build-arg "gid=$(id --group $USER)" \
		--build-arg "work_dir=$RSD_WORK_DIR" \
		-t $RSD_IMAGE_NAME \
		$SRC_DIR

	echo "Pruning unused docker images..."
	docker image prune -f
fi

# Detect if the environment variables file has been modified since the container was started:
if [[ "$running" == "true" && "$restart" == "false"  ]]; then
	containerStartedAt=$(docker inspect --format='{{.State.StartedAt}}' $RSD_CONTAINER_NAME)
	containerStartTime=$(date +%s --date=$containerStartedAt)
	envFileUpdateTime=$(date +%s -r $RSD_ENV_FILE)
	if (( $envFileUpdateTime > containerStartTime)); then
		echo "Environment file (.rsd_env) modified, the container will be restarted"
		restart=true
	fi
fi

# Stop the container if a restart is required:
if [[ "$restart" == "true" && "$running" == "true" ]]; then
	echo "Stopping the $RSD_CONTAINER_NAME container..."
	docker stop $RSD_CONTAINER_NAME
	running=false
fi

# Start the container in the background if not already running:
if [[ "$running" == "false" ]]; then
	echo "Starting the $RSD_CONTAINER_NAME container..."

	known_host_mappings=
	for host_name in $RSD_KNOWN_HOSTS; do
		host_ip=$(getent hosts $host_name | awk '{ print $1 ; exit }')
		if [[ ! -z "$host_ip" ]]; then
			known_host_mappings="$known_host_mappings --add-host $host_name:$host_ip"
		fi
	done

	docker run --name $RSD_CONTAINER_NAME \
		-d --rm \
		--volume $RSD_WORK_DIR:$RSD_WORK_DIR \
		--volume $RSD_BASH_HISTORY_FILE:$HOME/.bash_history \
		--volume $RSD_CONFIG_DIR/rsyslog.conf:/etc/rsyslog.conf:ro \
		--volume $RSD_CONFIG_DIR/rsyslog.d:/etc/rsyslog.d:ro \
		--env WORK_DIR=$RSD_WORK_DIR \
		--env-file=$RSD_ENV_FILE \
		--net=host \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--security-opt apparmor=unconfined \
		$known_host_mappings \
		$RSD_IMAGE_NAME \
		tail -f /dev/null
fi

if [[ -z "$1" || "$1" == "--"* ]]; then
	# Launch an interactive shell in the container:
	docker exec -ti --env CURRENT_DIR=$PWD $RSD_CONTAINER_NAME bash
else
	# Execute a specific command in the container:
	docker exec -ti --env CURRENT_DIR=$PWD $RSD_CONTAINER_NAME bash -i -c "$*"
fi
