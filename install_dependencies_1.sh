# install dependencies - part 1
set -v

sudo dnf install -y jq wget docker go python3-pip git curl
#sudo dnf install -y jq wget docker golang-1.19.2-1.fc37 python3-pip git curl
wget "https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-2.0.0.x86_64.rpm"
sudo rpm -ivh cosign-2.0.0.x86_64.rpm
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant
