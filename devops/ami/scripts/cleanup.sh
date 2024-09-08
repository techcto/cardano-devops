#Remove all authorized keys
echo "Perform Cleanup!"
rm -Rf /root/.ssh
rm -Rf /home/ubuntu/.ssh
rm -Rf /tmp/*

#https://forums.aws.amazon.com/thread.jspa?threadID=227092
systemctl stop apt-daily.timer
systemctl stop apt-daily-upgrade.timer
rm /var/lib/systemd/timers/stamp-apt-daily.timer
rm /var/lib/systemd/timers/stamp-apt-daily-upgrade.timer