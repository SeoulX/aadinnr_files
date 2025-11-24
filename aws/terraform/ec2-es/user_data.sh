#!/bin/bash

# Wait until user ubuntu exists (typically handled by cloud-init for Ubuntu AMIs)
for i in {1..30}; do
  id ubuntu &>/dev/null && break
  echo "Waiting for user ubuntu to exist..."
  sleep 2
done

# Optionally, you can log if ubuntu user never appeared (should not happen in official Ubuntu AMIs)
if ! id ubuntu &>/dev/null; then
  echo "User ubuntu not found after waiting, aborting."
  exit 1
fi

# Update the package index
apt-get update -y
# Install packages to allow apt to use a repository over HTTPS
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
# Update the package index again
apt-get update -y
# Install Docker Engine, containerd, and Docker Compose
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Start and enable Docker service
systemctl start docker
systemctl enable docker
# Add ubuntu user to docker group (allows running docker without sudo)
usermod -aG docker ubuntu
# Install Docker Compose standalone (optional - plugin version is installed above)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# Verify installation (logs will be in /var/log/cloud-init-output.log)
docker --version
docker compose version
# Optional: Pull a test image to verify everything works
docker pull hello-world
# Create a simple test to verify Docker is working
echo "Docker installation completed at $(date)" >> /home/ubuntu/docker-install.log
echo "Docker version: $(docker --version)" >> /home/ubuntu/docker-install.log
chown ubuntu:ubuntu /home/ubuntu/docker-install.log
# Setup EBS volume
# Dynamically find the additional EBS volume (not the root volume)
# On NVMe instances, device order can vary, so we identify by:
# 1. Finding the root device (has partitions and is mounted)
# 2. Finding the other NVMe device that's not the root

echo "Detecting EBS volumes..."
# Wait for NVMe devices to be available
for i in {1..30}; do
  if lsblk -n -d -o NAME | grep -q "^nvme"; then
    echo "NVMe devices detected"
    break
  fi
  echo "Waiting for NVMe devices... (attempt $i/30)"
  sleep 2
done

# Find root device (has partitions and is mounted at /)
ROOT_DEVICE=$(lsblk -n -d -o NAME,MOUNTPOINT | grep -E "\s/$" | awk '{print $1}' | head -1)
if [ -n "$ROOT_DEVICE" ]; then
  ROOT_DEVICE="/dev/${ROOT_DEVICE}"
  echo "Root device identified: $ROOT_DEVICE"
else
  # Fallback: find device with partitions (root usually has partitions)
  ROOT_DEVICE=$(lsblk -n -d -o NAME | while read dev; do
    if lsblk -n "/dev/$dev" | grep -q "part"; then
      echo "/dev/$dev"
      break
    fi
  done | head -1)
  echo "Root device identified (by partitions): $ROOT_DEVICE"
fi

# Find additional EBS volume (the other NVMe device, not root, no partitions, ~1000GB)
EBS_DEVICE=""
for dev in /dev/nvme*n1; do
  if [ ! -b "$dev" ]; then
    continue
  fi
  # Skip if this is the root device
  if [ "$dev" = "$ROOT_DEVICE" ]; then
    continue
  fi
  # Check if it has no partitions (additional EBS volumes typically don't have partitions initially)
  if ! lsblk -n "$dev" | grep -q "part"; then
    # Get size in GB and check if it's close to 1000GB (allowing some variance)
    SIZE_GB=$(lsblk -b -d -o SIZE "$dev" | awk '{printf "%.0f", $1/1024/1024/1024}')
    if [ "$SIZE_GB" -ge 900 ] && [ "$SIZE_GB" -le 1100 ]; then
      EBS_DEVICE="$dev"
      echo "Additional EBS volume identified: $EBS_DEVICE (${SIZE_GB}GB)"
      break
    fi
  fi
done

# Fallback: if not found by size, use the first non-root NVMe device
if [ -z "$EBS_DEVICE" ]; then
  for dev in /dev/nvme*n1; do
    if [ ! -b "$dev" ]; then
      continue
    fi
    if [ "$dev" != "$ROOT_DEVICE" ]; then
      EBS_DEVICE="$dev"
      echo "Additional EBS volume identified (fallback): $EBS_DEVICE"
      break
    fi
  done
fi

if [ -z "$EBS_DEVICE" ] || [ ! -b "$EBS_DEVICE" ]; then
  echo "ERROR: Additional EBS volume not found"
  echo "Available devices:"
  lsblk
  exit 1
fi

echo "Using EBS device: $EBS_DEVICE"

# Create mount point
mkdir -p /mnt/ebs

# Check if volume is already formatted (has a filesystem)
if ! blkid "$EBS_DEVICE" > /dev/null 2>&1; then
  echo "Formatting $EBS_DEVICE with ext4 filesystem..."
  mkfs.ext4 -F "$EBS_DEVICE"
else
  echo "$EBS_DEVICE already has a filesystem, skipping format"
fi

# Mount the volume
mount "$EBS_DEVICE" /mnt/ebs

# Add to /etc/fstab for persistent mounting across reboots
if ! grep -q "$EBS_DEVICE" /etc/fstab; then
  echo "$EBS_DEVICE /mnt/ebs ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
  echo "Added $EBS_DEVICE to /etc/fstab for persistent mounting"
fi

# Create data directory with proper permissions for Elasticsearch
# Elasticsearch container runs as UID 1000 (elasticsearch user)
mkdir -p /mnt/ebs/data
# Set ownership to UID 1000:GID 1000 (elasticsearch user in container)
sudo chown 1000:1000 /mnt/ebs/data
# Set permissions to allow read/write/execute for owner and group
sudo chmod 775 /mnt/ebs/data
echo "Set permissions on /mnt/ebs/data for Elasticsearch (UID 1000:GID 1000)"

# Configure system settings for ElasticSearch (immediate effect)
sudo sysctl -w vm.max_map_count=262144

# Configure system settings for ElasticSearch (persistent across reboots)
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf > /dev/null

export HOSTNAME=$(hostname)
export HOST_IP=$(hostname -I | awk '{print $1}')

# Create docker-compose.yaml only if it doesn't exist (recovery scenario)
DOCKER_COMPOSE_FILE="/home/ubuntu/docker-compose.yaml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  {
    echo "version: '2.2'"
    echo "services:"
    echo "  app:"
    echo "    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.7"
    echo "    container_name: \${HOSTNAME}"
    echo "    environment:"
    echo "      - node.name=\${HOSTNAME}"
    echo "      - cluster.name=mmi-aws-elasticsearch-cluster"
    echo "      - network.publish_host=\${HOST_IP}"
    echo "      - discovery.seed_hosts=10.0.3.6,10.0.3.7,10.0.3.8,10.0.3.9"
    echo "      - cluster.initial_master_nodes=10.0.3.5,10.0.3.6,10.0.3.7,10.0.3.8,10.0.3.9"
    echo "      - bootstrap.memory_lock=true"
    echo "      - action.destructive_requires_name=true"
    echo "      - indices.query.bool.max_clause_count=4096"
    echo "      - \"ES_JAVA_OPTS=-Xms10g -Xmx10g\""
    echo "      - node.roles=data,ingest"
    echo "    ulimits:"
    echo "      memlock:"
    echo "        soft: -1"
    echo "        hard: -1"
    echo "    volumes:"
    echo "      - /mnt/ebs/data:/usr/share/elasticsearch/data"
    echo "    ports:"
    echo "      - 9200:9200"
    echo "      - 9300:9300"
    echo "    restart: always"
  } > "$DOCKER_COMPOSE_FILE"
  chown ubuntu:ubuntu "$DOCKER_COMPOSE_FILE"
fi

cd /home/ubuntu
# Ensure Elasticsearch data directory has correct permissions before starting
sudo chown -R 1000:1000 /mnt/ebs/data
sudo chmod -R 775 /mnt/ebs/data
export HOSTNAME=$(hostname)
export HOST_IP=$(hostname -I | awk '{print $1}')
sudo sysctl -w vm.max_map_count=262144
docker compose up -d
