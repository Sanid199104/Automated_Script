#!/bin/bash

set -e

# -------------------------
# CONFIGURATION
# -------------------------
APP_NAME="Quickbase-app"
DOCKER_IMAGE="yourdockerhubusername/Quickbase-app"
EC2_USER="ec2-user"
EC2_HOST="your-ec2-public-ip"
PEM_FILE="path/to/your-key.pem"  # Local path to SSH private key
PORT_ON_HOST=80

# -------------------------
# STEP 1: Build Docker Image
# -------------------------
echo "Building Docker image..."
docker build -t $DOCKER_IMAGE .

# -------------------------
# STEP 2: Push to Docker Hub
# -------------------------
echo "Pushing Docker image to Docker Hub..."
docker login
docker push $DOCKER_IMAGE

# -------------------------
# STEP 3: Deploy to EC2
# -------------------------
echo "Deploying to EC2 instance..."

ssh -o StrictHostKeyChecking=no -i $PEM_FILE $EC2_USER@$EC2_HOST << EOF
    echo "Connected to EC2"

    # Install Docker if not installed
    if ! command -v docker &> /dev/null
    then
        echo "Installing Docker..."
        sudo yum update -y
        sudo yum install -y docker
        sudo service docker start
        sudo usermod -a -G docker $EC2_USER
        newgrp docker
    fi

    echo "Pulling Docker image..."
    docker pull $DOCKER_IMAGE

    echo "Stopping existing container (if any)..."
    docker rm -f $APP_NAME || true

    echo "Running new container..."
    docker run -d -p $PORT_ON_HOST:5000 --name $APP_NAME $DOCKER_IMAGE

    echo "App should be accessible at http://$EC2_HOST/"
EOF

echo "Deployment Completed Successfully"
