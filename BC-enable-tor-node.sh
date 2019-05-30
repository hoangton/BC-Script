#!/bin/bash
# Step 1 Install tor

sudo apt-get update
sudo apt-get install -y tor

# Step 2 Generate hostname and private_key with eschalot
echo 'Step 2 Generate hostname and private_key with eschalot'
cd 
sudo apt install -y build-essential libssl-dev
sudo git clone https://github.com/ReclaimYourPrivacy/eschalot.git
cd eschalot
make
./eschalot -vp bc -t 1 > bconion
sed '1d' bconion > bconion-temp
sed -n 1p bconion-temp >hostname
sed '1d' bconion-temp > private_key

# Step 3 Create folder to store hostname and private-key for tor
echo 'Step 3 Create folder to store hostname and private-key for tor'
sudo mkdir /var/lib/tor/bitcoinc-service

sudo cp hostname /var/lib/tor/bitcoinc-service
sudo cp private_key /var/lib/tor/bitcoinc-service


# Step 4 append 2 line to Tor config
echo 'Step 4 append 2 line to Tor config'
echo "HiddenServiceDir /var/lib/tor/bitcoinc-service/" | sudo tee -a /etc/tor/torrc > /dev/null
echo "HiddenServicePort 9789 127.0.0.1:9789" | sudo tee -a /etc/tor/torrc > /dev/null


#Step 5 Update binconc.conf and restart wallet 
echo 'Step 5 Update binconc.conf and restart wallet '
echo 'server=1' > ~/.bitcoinc/bitcoinc.conf
echo 'maxconnections=128' >> ~/.bitcoinc/bitcoinc.conf
echo 'onion=127.0.0.1:9150' >> ~/.bitcoinc/bitcoinc.conf
echo 'discover=0' >> ~/.bitcoinc/bitcoinc.conf
echo 'listen=1 >> ~/.bitcoinc/bitcoinc.conf
echo 'addnode=ibt4q3cri3hs47f2.onion' >> ~/.bitcoinc/bitcoinc.conf
echo -n "externalip=" | cat - /var/lib/tor/bitcoinc-service/hostname >> ~/.bitcoinc/bitcoinc.conf

# Stop wallet 
./bitcoinc-cli stop && sleep 5
# Start wallet
./bitcoincd && sleep 5 && ./bitcoinc-cli walletsettings stakingstatus true
