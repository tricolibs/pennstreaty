#!/bin/bash

#This needs to run as root. Hopefully it'll be idempotent.
#Since you presumably don't have the pennstreaty user and
#git checkout yet, copy it from your local machine to run.

#install packages
apt install aptitude htop docker.io docker-compose-v2 make
snap install --classic emacs

#set up container logging via syslog
DOCKER_CONTAINERS_LOG=$(
cat <<'DCL'
$template DockerContainerLogs,"/var/log/docker/%hostname%_%syslogtag:R,ERE,1,ZERO:.*container_name/([^\[]+)--end%.log"

if $syslogtag contains 'container_name'  then -?DockerContainerLogs

& stop
DCL
		     )
DOCKER_DAEMON_LOG=$(
cat <<'DDL'
$template DockerLogs, "/var/log/docker/daemon.log"

if $programname startswith 'dockerd' then -?DockerLogs

& stop
DDL
		 )
DOCKER_DAEMON_CONF=$(
cat <<'DDC'
{
  "log-driver": "syslog",
  "log-opts": {
    "tag": "container_name/{{.Name}}",
    "labels": "staging",
    "syslog-facility": "daemon"
  }
}
DDC
		  )
LOGROTATE_CONF=$(
cat <<'LC'
/var/log/docker/*.log
{
	rotate 4
	weekly
	missingok
	notifempty
	compress
	delaycompress
}
LC
	      )
echo "$DOCKER_DAEMON_CONF" > /etc/docker/daemon.json
echo "$LOGROTATE_CONF" > /etc/logrotate.d/docker
echo "$DOCKER_DAEMON_LOG" > /etc/rsyslog.d/49-docker-daemon.conf
echo "$DOCKER_CONTAINERS_LOG" > /etc/rsyslog.d/48-docker-containers.conf
systemctl restart docker
systemctl restart rsyslog

#make pennstreaty user, generate ssh key
USERNAME=pennstreaty
groupadd -f $USERNAME
id $USERNAME || useradd --gid $USERNAME --groups docker --create-home --shell /bin/bash $USERNAME
[ -f /home/$USERNAME/.ssh/id_rsa.pub ] || su $USERNAME -c ssh-keygen

