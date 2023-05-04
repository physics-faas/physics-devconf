# install dependencies
dnf install -y jq wget docker go python3-pip
wget "https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-2.0.0.x86_64.rpm"
sudo rpm -ivh cosign-2.0.0.x86_64.rpm
systemctl start docker

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl

# Install the clients
wget https://github.com/knative/client/releases/download/knative-v1.9.2/kn-linux-amd64
mv kn-linux-amd64 kn
chmod +x kn
sudo mv kn /usr/local/bin
kn version

wget https://github.com/knative/func/releases/download/knative-v1.9.3/func_linux_amd64
mv func_linux_amd64 func
chmod +x func
sudo mv func /usr/local/bin
func version

# Install kind
go install sigs.k8s.io/kind@v0.18.0
cp /root/go/bin/kind /usr/local/bin/
kind --version

