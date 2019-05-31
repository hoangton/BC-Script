#!/bin/bash
# Step 1 Install tor

apt-get update
apt-get install -y tor

# Step 2 Generate hostname and private_key with eschalot
echo 'Step 2 Generate hostname and private_key with eschalot'
cd 
apt install -y build-essential libssl-dev git
git clone https://github.com/ReclaimYourPrivacy/eschalot.git
cd eschalot
make
./eschalot -vp b -t 1 > bconion && sleep 20
sed '1d' bconion > bconion-temp
sed -n 1p bconion-temp >hostname
sed '1d' bconion-temp > private_key

# Step 3 Create folder to store hostname and private-key for tor
echo 'Step 3 Create folder to store hostname and private-key for tor'
mkdir /var/lib/tor/bitcoinc-service
chown -R root.root /var/lib/tor/bitcoinc-service
cp hostname /var/lib/tor/bitcoinc-service
cp private_key /var/lib/tor/bitcoinc-service


# Step 4 append 2 line to Tor config
echo 'Step 4 append 2 line to Tor config'
#echo "HiddenServiceDir /var/lib/tor/bitcoinc-service/" | sudo tee -a /etc/tor/torrc > /dev/null
#echo "HiddenServicePort 9789 127.0.0.1:9789" | sudo tee -a /etc/tor/torrc > /dev/null

cat >> /etc/tor/torrc << EOF 
HiddenServiceDir /var/lib/tor/bitcoinc-service
HiddenServicePort 9789 127.0.0.1:9789
EOF 

# Step 5 Restart Tor
echo 'Step 5 Restart Tor'
sed '6i\
owner /var/lib/tor/bitcoinc-service/** rwk,' /etc/apparmor.d/system_tor
/etc/init.d/apparmor restart
/etc/init.d/tor restart
/sbin/mdadm --monitor --pid-file /run/mdadm/monitor.pid --daemonise --scan --syslog
/usr/bin/tor --defaults-torrc /usr/share/tor/tor-service-defaults-torrc -f /etc/tor/torrc --RunAsDaemon 0 &


#Step 6 Update binconc.conf and restart wallet 
echo 'Step 6 Update binconc.conf and restart wallet '
echo 'daemon=1' > ~/.bitcoinc/bitcoinc.conf
echo 'onlynet=onion' >> ~/.bitcoinc/bitcoinc.conf
echo 'server=1' >> ~/.bitcoinc/bitcoinc.conf
echo 'maxconnections=128' >> ~/.bitcoinc/bitcoinc.conf
echo 'onion=127.0.0.1:9150' >> ~/.bitcoinc/bitcoinc.conf
echo 'discover=0' >> ~/.bitcoinc/bitcoinc.conf
echo 'listen=1' >> ~/.bitcoinc/bitcoinc.conf
echo 'addnode=ibt4q3cri3hs47f2.onion' >> ~/.bitcoinc/bitcoinc.conf
echo -n "externalip=" |sudo cat - /var/lib/tor/bitcoinc-service/hostname >> ~/.bitcoinc/bitcoinc.conf

# Stop wallet 
cd
./bitcoinc-cli stop && sleep 5

# Start wallet
cd
./bitcoincd && sleep 5 && ./bitcoinc-cli walletsettings stakingstatus true
