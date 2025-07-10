#!/bin/bash

# Update system
dnf update -y

# Install required packages
dnf install -y git curl wget unzip

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
mv /tmp/eksctl /usr/local/bin

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install session manager plugin for AWS CLI
dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Configure AWS CLI with region
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/config << EOF
[default]
region = ${region}
output = json
EOF
chown -R ec2-user:ec2-user /home/ec2-user/.aws

# Create useful aliases
cat >> /home/ec2-user/.bashrc << 'EOF'

# Useful aliases
alias k='kubectl'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# kubectl completion
source <(kubectl completion bash)
complete -F __start_kubectl k

# eksctl completion
source <(eksctl completion bash)
EOF

# Set up bash completion
dnf install -y bash-completion

# Create a welcome message
cat > /etc/motd << 'EOF'
=====================================
    AWS Bastion Host (Amazon Linux 2023)
=====================================

Installed tools:
- AWS CLI v2
- kubectl
- eksctl
- Helm
- Docker
- Session Manager Plugin

Usage:
- Use 'aws configure' to set up credentials if needed
- Use 'eksctl create cluster' to create EKS clusters
- Use 'kubectl' to manage Kubernetes resources

=====================================
EOF

# Log installation completion
echo "$(date): Bastion host setup completed" >> /var/log/user-data.log
