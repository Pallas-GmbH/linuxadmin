timedatectl set-timezone Europe/Berlin
apt-get install unzip
apt install needrestart -y
apt-get install net-tools -y
apt autoremove -y
apt-get install snmpd -y
SCP:/root/linuxadmin/scripts/customerscripts/p2/libs/snmpd.conf:/etc/snmp/snmpd.conf
/etc/init.d/snmpd restart
SCP:/root/linuxadmin/scripts/globalscripts/libs/disableipv6.sh:/root/disableipv6.sh
/root/disableipv6.sh
sudo systemctl disable apport.service
SCP:/root/.welcome:/root/.welcome
grep -q "source /root/.welcome" /root/.bashrc || echo "source /root/.welcome" >> /root/.bashrc
SCP:/root/linuxadmin/scripts/customerscripts/p2/libs/p2-ca.crt:/usr/local/share/ca-certificates/p2-ca.crt
update-ca-certificates
rm /root/disableipv6.sh
