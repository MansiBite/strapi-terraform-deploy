#!/bin/bash
set -e

# Install Docker
sudo apt update -y
sudo apt install -y docker.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Pull and run Strapi container from Docker Hub
sudo docker pull mansibite/strapi-app
sudo docker run -d -p 1337:1337 --name strapi mansibite/strapi-app
