#!/bin/bash

# Add go-agent to sources list for apt
echo "deb https://download.gocd.org /" | sudo tee /etc/apt/sources.list.d/gocd.list

# Add go-agent key apt-key
curl https://download.gocd.org/GOCD-GPG-KEY.asc | sudo apt-key add -

# Run update to pull latest go-agent into apt
sudo apt-get update

# Install go-agent
sudo apt-get install go-agent

# Configure go-sever for agent
sudo sed -i -e 's/localhost:8153/gocd.agiledefense.lab/' /usr/share/go-agent/wrapper-config/wrapper-properties.conf

# Start and enable go-agent
sudo systemctl start go-agent
sudo systemctl enable go-agent

# Download sonar-scanner zip file
wget -O sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.2.2472-linux.zip

# Install unzip to unzip zipfile (not installed by default)
sudo apt-get -y install unzip

# Unzip sonar-scanner files
sudo unzip sonar-scanner.zip -d /etc

# Rename directory for better management and linking
sudo mv /etc/sonar-scanner-* /etc/sonar

# Configure default sonar server
sudo sed -i -e 's/#sonar.host.url=http:\/\/localhost:9000/sonar.host.url=http:\/\/sonar.agiledefense.lab/' /etc/sonar/conf/sonar-scanner.properties

# Create symlinks to binaries so they're availabel on system PATH
sudo ln -s /etc/sonar/bin/sonar-scanner /usr/bin/sonar-scanner
sudo ln -s /etc/sonar/bin/sonar-scanner-debug /usr/bin/sonar-scanner-debug

# Install pip3 apt package
sudo apt install -y python3-pip

# Pip install dependency-check (use sudo so it installs bin file on PATH)
sudo pip3 install dependency-check

# Install Java 11 for dependency-check
sudo apt install -y openjdk-11-jdk-headless

# Generate SSH key for go user
sudo su - go -c 'ssh-keygen -b 2048 -t rsa -f /var/go/.ssh/id_rsa -q -N ""'


# Register Key with GitHub
registration_status=$(curl -G -X POST -v --data-urlencode "key=$(sudo cat /var/go/.ssh/id_rsa.pub)" --data-urlencode "host=$(hostname)" "http://gocd.agiledefense.lab:6523/register-ssh-key")
if [[ "$registration_status" == *"successful"* ]]
then
	echo "Sucessfully registered ssh key with GoCD-Agent github account"
else
	echo "Failed to register: $registration_status" && exit 1
fi

# Perform initial pull to add ssh-key to known hosts
sudo su - go -c 'if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi; git clone git@github.com:Agile-Defense/GoAgentPullTest.git'
sudo rm -rf /var/go/GoAgentPullTest
sudo rm -rf sonar-scanner.zip
sudo rm -rf configure_default_agent.sh

