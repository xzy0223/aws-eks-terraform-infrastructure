#!/bin/bash

# EKS Node Bootstrap Script
# This script configures the EC2 instance to join the EKS cluster

set -o xtrace

# Bootstrap the node to join the EKS cluster
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_arguments}

# Optional: Install additional packages or perform custom configuration
# Add any custom initialization logic here

# Signal that the instance is ready
echo "EKS node bootstrap completed successfully"
