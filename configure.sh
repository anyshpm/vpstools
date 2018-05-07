#!/bin/sh

yum -y update
yum -y install wget vim

#cronie ntpdate
yum -y install cronie ntpdate
systemctl enable crond
systemctl start crond
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
if [ $(grep ntpdate /etc/crontab | wc -l) -eq 0 ]
then
    echo '0 0  *  *  * root ntpdate pool.ntp.org' >> /etc/crontab
    ntpdate pool.ntp.org
fi

#sudo
yum -y install sudo
useradd anyshpm
passwd anyshpm
echo 'anyshpm	ALL=(ALL)	ALL' > /etc/sudoers.d/anyshpm

#hostname
read hostname
hostnamectl set-hostname $hostname

#zabbix
rpm -i http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
yum -y install zabbix-agent
sed -i 's/^Hostname=/#Hostname=/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Server=.*/Server=locvps.anyshpm.info/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^ServerActive=.*/ServerActive=locvps.anyshpm.info/g' /etc/zabbix/zabbix_agentd.conf
echo $(head -n 64 /dev/urandom | md5sum | head -c 32)$(head -n 64 /dev/urandom | md5sum | head -c 32) > /etc/zabbix/zabbix_agentd.d/zabbix_agentd.psk
cat /etc/zabbix/zabbix_agentd.d/zabbix_agentd.psk
cat << EOF > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_psk.conf
TLSConnect=psk
TLSAccept=psk
TLSPSKFile=/etc/zabbix/zabbix_agentd.d/zabbix_agentd.psk
TLSPSKIdentity=$(hostname)
EOF
systemctl enable zabbix-agent
systemctl start zabbix-agent

#swap
if [ $(cat /proc/swaps | wc -l) -eq 1 -a $(grep swap /etc/fstab | grep -v '^#' | wc -l) -eq 0 ]
then
    dd if=/dev/zero of=/root/swap bs=256 count=8388616
    mkswap /root/swap
    echo "/root/swap swap swap defaults    0  0" >> /etc/fstab
    echo "vm.swappiness=60" >> /etc/sysctl.conf
    sysctl -p
    swapon /root/swap
fi
