#!/bin/bash
sudo yum update -y  # updates the package list and upgrades installed packages on the system
sudo yum install -y httpd
sudo systemctl -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
#Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo  #downloads the Jenkins repository conf>
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key  #imports the GPG key for the Jenkins repository. This ke>
sudo yum upgrade -y #  upgrades packages again, which might be necessary to ensure that any new dependencies required by Jenkins are>
sudo dnf install java-11-amazon-corretto -y  # installs Amazon Corretto 11, which is a required dependency for Jenkins.
sudo yum install jenkins -y  #installs Jenkins itself
sudo systemctl enable jenkins  #enables the Jenkins service to start automatically at boot time
sudo systemctl start jenkins
# Update package list and install dependencies
sudo yum update -y
sudo amazon-linux-extras install docker
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install kubelet, kubeadm, and kubectl
sudo amazon-linux-extras install -y kubernetes1.18

# Start and enable kubelet
sudo systemctl start kubelet
sudo systemctl enable kubelet

# Initialize Kubernetes master node (Only if this is the master node)
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Setup kubeconfig for the ec2-user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install a network plugin (Flannel in this case)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
