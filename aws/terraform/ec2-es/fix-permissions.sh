#!/bin/bash

# SSH key path - adjust if your key is in a different location
SSH_KEY="$HOME/Downloads/terraform_key_pair.cer"

# Instance DNS names
INSTANCES=(
  "ec2-18-142-227-181.ap-southeast-1.compute.amazonaws.com"
  "ec2-13-215-206-195.ap-southeast-1.compute.amazonaws.com"
  "ec2-54-151-197-160.ap-southeast-1.compute.amazonaws.com"
  "ec2-54-251-18-55.ap-southeast-1.compute.amazonaws.com"
)

echo "Fixing Elasticsearch permissions on all instances..."
echo "=================================================="

for HOST in "${INSTANCES[@]}"; do
  echo ""
  echo "Processing: $HOST"
  echo "----------------------------------------"
  
  ssh -o IdentitiesOnly=yes -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$HOST" << 'EOF'
    echo "Fixing permissions..."
    lsblk
    sudo chown -R 1000:1000 /mnt/ebs/data
    sudo chmod -R 775 /mnt/ebs/data
    cd /home/ubuntu
    export HOSTNAME=$(hostname)
    export HOST_IP=$(hostname -I | awk '{print $1}')
    docker compose restart
    echo "✓ Permissions fixed and Elasticsearch restarted"
EOF

  if [ $? -eq 0 ]; then
    echo "✓ Successfully processed $HOST"
  else
    echo "✗ Failed on $HOST"
  fi
done

echo ""
echo "=================================================="
echo "Done!"

