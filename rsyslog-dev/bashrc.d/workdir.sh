cd $WORK_DIR

if [[ -n "$CURRENT_DIR" && "$CURRENT_DIR" == "$WORK_DIR"/* ]]; then
	cd $CURRENT_DIR
elif [[ -d rsyslog ]]; then
	cd rsyslog
fi
