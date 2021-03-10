#! /bin/bash

TOPDETAILED_FILE="/home/aksadmin/topDetailed_host.log"
LOG_ROTATE_FILE="/etc/logrotate.d/host-top.logrotate"
CRONJOB_FILE="/home/aksadmin/topcronjob"


start()
{
    # Start a top command to collect data.
    top -b -d 3 -H -w 512 >> $TOPDETAILED_FILE &

    # Create a log-rotate file.
    cat << EOT >> $LOG_ROTATE_FILE
$TOPDETAILED_FILE {
        su root root
        size 10M
        rotate 15
        missingok
        notifempty
        delaycompress
        compress
        copytruncate
        dateext
        dateformat -%Y-%m-%d-%s
        extension .log
}
EOT

    # Forcefully do a logrotate reload
    #logrotate -f /etc/logrotate.d/*
    #if [ $? -ne 0 ]; then
    #    echo "Error encountered while reloading logrotate. Exiting."
    #    exit 1;
    #fi

    # Set up a cron job.
    crontab -u root -l > $CRONJOB_FILE
    local var=$(cat $CRONJOB_FILE | grep "host-top.logrotate" | wc -l)
    if [[ $var -eq 0 ]]; then
	# Calls logrotate every 10 mins.
        echo "*/10  *  *  *  * /usr/sbin/logrotate /etc/logrotate.d/host-top.logrotate > /dev/null 2>&1" >> $CRONJOB_FILE
        crontab -u root $CRONJOB_FILE
        echo "Cron job is set."
    else
        echo "Cron job already exists."
    fi
}


stop()
{
    # Kill the cmd
    local pid=$(ps -eaf | grep -i "top -b -d 3 -H -w 512" | grep -v grep | awk '{print $2}')
    echo "Killing top process."
    kill -9 $pid

    # Remove crontab entry
    crontab -r

    # Delete log-rotate entry
    rm -rf $LOG_ROTATE_FILE
}

# Entry
case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    *)
        echo "Usage: $0 {start|stop}"
esac
