#! /bin/bash -e

# Setup OpenVPN
sudo apt install apt-transport-https -y
sudo wget https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub
sudo apt-key add openvpn-repo-pkg-key.pub
sudo wget -O /etc/apt/sources.list.d/openvpn3.list https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-focal.list
sudo apt install openvpn3 -y
openvpn3 session-start --config $1

# Setup Docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install docker-ce -y

sudo docker run -v $(pwd)/$2:/etc/nginx/nginx.conf -d -p 80:80 --restart always nginx