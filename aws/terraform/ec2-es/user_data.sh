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
lsblk
mkdir -p /mnt/ebs
sudo chown ubuntu:ubuntu /mnt/ebs
mkdir -p /mnt/ebs/data
sudo chown ubuntu:ubuntu /mnt/ebs/data
mkfs.ext4 -F /dev/nvme1n1
mount /dev/nvme1n1 /mnt/ebs
sysctl -w vm.max_map_count=262144

# Configure system settings for ElasticSearch
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
docker compose up -d
