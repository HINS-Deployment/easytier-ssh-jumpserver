#!/bin/bash

set -e

echo "=== Initializing SSH Configuration ==="

mkdir -p /root/.ssh
chmod 700 /root/.ssh

mkdir -p /var/run/sshd

if [ -f /etc/ssh/ssh_host_rsa_key ] && [ -f /etc/ssh/ssh_host_ecdsa_key ] && [ -f /etc/ssh/ssh_host_ed25519_key ]; then
    echo "SSH host keys already exist"
else
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/ssh/sftp-server
AllowAgentForwarding yes
AllowTcpForwarding yes
EOF

if [ -n "$SSH_PASSWORD" ]; then
    echo "root:$SSH_PASSWORD" | chpasswd
    echo "SSH password set for root user"
fi

if [ -f /root/.ssh/authorized_keys ]; then
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    echo "SSH authorized_keys found, public key authentication enabled"
fi

echo "=== SSH Initialization Complete ==="
