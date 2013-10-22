#!/bin/bash

# LABPAGES
# Maintainer: Julien Bianchi <contact@jubianchi.fr>
# App Version: 0.1

### BEGIN INIT INFO
# Provides:          labpages
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LabPages web hook
# Description:       LabPages web hook
### END INIT INFO

NAME="labpages"
DESC="LabPages web hook"

APP_ROOT="/home/git/labpages"
APP_LOG="/var/log/labpages"
APP_CONFIG="$APP_ROOT/config"
APP_USER="git"
APP_PORT="8080"
APP_ENV=production

LABPAGES_EXEC="bundle exec rackup"
LABPAGES_PID_PATH="/var/run/labpages/$NAME.pid"
LABPAGES_LOG_PATH="$APP_LOG/labpages.log"
LABPAGES_DAEMON_OPTS="-p $APP_PORT -P $LABPAGES_PID_PATH -E $APP_ENV $APP_ROOT/config.ru > $LABPAGES_LOG_PATH 2>&1 &"

SIDEKIQ_EXEC="bundle exec sidekiq"
SIDEKIQ_PID_PATH="/var/run/labpages/sidekiq.pid"
SIDEKIQ_DAEMON_OPTS="-d -C $APP_CONFIG/sidekiq.yml -r $APP_ROOT/app/workers.rb -e $APP_ENV"

execute() {
    cd $APP_ROOT
    sudo -u $APP_USER -H bash -l -c "$1"
}

check_labpages_pid() {
    if [ -f $LABPAGES_PID_PATH ]; then
        LABPAGES_PID=$(cat $LABPAGES_PID_PATH)

        if [ -z $LABPAGES_PID ]; then
            LABPAGES_PID=0
            LABPAGES_STATUS=0
        else
            LABPAGES_STATUS=$(ps aux | grep $LABPAGES_PID | grep -v grep | wc -l)
        fi
    else
        LABPAGES_STATUS=0
        LABPAGES_PID=0
    fi
}

start_labpages() {
    check_labpages_pid

    if [ "$LABPAGES_PID" -ne 0 -a "$LABPAGES_STATUS" -ne 0 ]; then
        # Program is running, exit with error code 1.
        echo "Error! $DESC $NAME is currently running!"
        return 1
    else
        if [ `whoami` = root ]; then
            execute "$LABPAGES_EXEC $LABPAGES_DAEMON_OPTS > $LABPAGES_LOG_PATH 2>&1"

            echo -n "Starting $NAME"

            while [ "$LABPAGES_PID" -eq 0 ]
            do
                echo -n "."
                sleep 1
                check_labpages_pid
            done

            echo -e "\n$DESC started ($LABPAGES_PID)"
        fi
  fi
}

stop_labpages() {
    check_labpages_pid

    if [ "$LABPAGES_PID" -ne 0 -a "$LABPAGES_STATUS" -ne 0 ]; then
        ## Program is running, stop it.
        kill -SIGINT $LABPAGES_PID
        rm -f "$LABPAGES_PID_PATH" > /dev/null
        echo "$NAME stopped"
    else
        ## Program is not running, exit with error.
        echo "Error! $NAME not started!"
        return 1
    fi
}

status_labpages() {
    check_labpages_pid

    if [ "$LABPAGES_PID" -ne 0 -a "$LABPAGES_STATUS" -ne 0 ]; then
        echo "$NAME with PID $LABPAGES_PID is running."
    else
        echo "$NAME is not running."
        return 1
    fi
}

check_sidekiq_pid() {
    if [ -f $SIDEKIQ_PID_PATH ]; then
        SIDEKIQ_PID=$(cat $SIDEKIQ_PID_PATH)

        if [ -z $SIDEKIQ_PID ]; then
            SIDEKIQ_PID=0
            SIDEKIQ_STATUS=0
        else
            SIDEKIQ_STATUS=$(ps aux | grep $SIDEKIQ_PID | grep -v grep | wc -l)
        fi
    else
        SIDEKIQ_STATUS=0
        SIDEKIQ_PID=0
    fi
}

start_sidekiq() {
    check_sidekiq_pid

    if [ "$SIDEKIQ_PID" -ne 0 -a "$SIDEKIQ_STATUS" -ne 0 ]; then
        # Program is running, exit with error code 1.
        echo "Error! Sidekiq is currently running!"
        return 1
    else
        if [ `whoami` = root ]; then
            execute "$SIDEKIQ_EXEC $SIDEKIQ_DAEMON_OPTS"

            echo -n "Starting sidekiq"

            while [ "$SIDEKIQ_PID" -eq 0 ]
            do
                echo -n "."
                sleep 1
                check_sidekiq_pid;
            done

            echo -e "\nSidekiq started ($SIDEKIQ_PID)"
        fi
  fi
}

stop_sidekiq() {
    check_sidekiq_pid

    if [ "$SIDEKIQ_PID" -ne 0 -a "$SIDEKIQ_STATUS" -ne 0 ]; then
        ## Program is running, stop it.
        kill -SIGINT $SIDEKIQ_PID
        rm -f "$SIDEKIQ_PID_PATH" > /dev/null
        echo "Sidekiq stopped"
    else
        ## Program is not running, exit with error.
        echo "Error! Sidekiq not started!"
        return 1
    fi
}

status_sidekiq() {
    check_sidekiq_pid

    if [ "$SIDEKIQ_PID" -ne 0 -a "$SIDEKIQ_STATUS" -ne 0 ]; then
        echo "Sidekiq with PID $SIDEKIQ_PID is running."
    else
        echo "Sidekiq is not running."
        return 1
    fi
}

start() {
    start_sidekiq
    STATUS=$?

    start_labpages

    return $(expr $STATUS + $?)
}

stop() {
    stop_sidekiq
    STATUS=$?

    stop_labpages

    return $(expr $STATUS + $?)
}

restart() {
    stop
    start
}

status() {
    status_labpages
    STATUS=$?

    status_sidekiq

    return $(expr $STATUS + $?)
}

## Check to see if we are running as root first.
## Found at http://www.cyberciti.biz/tips/shell-root-user-check-script.html
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  status)
        status
        ;;
  *)
        echo "Usage: sudo service $NAME {start|stop|restart|reload|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
