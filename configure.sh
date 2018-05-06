#!/bin/sh

yum -y update
yum -y install wget vim


yum -y install cronie
systemctl enable crond
systemctl start crond
if [ $(grep ntpdate /etc/crontab | wc -l) -eq 0 ]
then
    echo '0 0  *  *  * root ntpdate pool.ntp.org' >> /etc/crontab
fi

yum -y install sudo
useradd anyshpm
passwd anyshpm
echo 'anyshpm	ALL=(ALL)	ALL' > /etc/sudoers.d/anyshpm

hostnamectl set-hostname peakservers.anyshpm.info

#zabbix
rpm -i http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
yum -y install zabbix-agent
sed -i 's/^Hostname=/#Hostname=/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Server=.*/Server=locvps.anyshpm.info/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^ServerActive=.*/ServerActive=locvps.anyshpm.info/g' /etc/zabbix/zabbix_agentd.conf
systemctl enable zabbix-agent
systemctl start zabbix-agent
