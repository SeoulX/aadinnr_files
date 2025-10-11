#!/bin/bash

# Script to help generate base64 encoded credentials for ArgoCD
# Run this script to generate the values you need for your configuration files

echo "🔐 ArgoCD Credentials Generator"
echo "================================"
echo ""

# Function to generate base64 encoded values
generate_docker_token() {
    echo "📦 Docker Hub Token Generation:"
    echo "1. Go to Docker Hub -> Account Settings -> Security"
    echo "2. Create a new Access Token"
    echo "3. Run this command with your credentials:"
    echo "   echo -n 'your-username:your-access-token' | base64"
    echo ""
    read -p "Enter your Docker Hub username: " docker_username
    read -s -p "Enter your Docker Hub access token: " docker_token
    echo ""
    
    if [ ! -z "$docker_username" ] && [ ! -z "$docker_token" ]; then
        encoded_token=$(echo -n "${docker_username}:${docker_token}" | base64)
        echo "✅ Your encoded Docker Hub token:"
        echo "$encoded_token"
        echo ""
    fi
}

generate_git_credentials() {
    echo "🔑 Git Repository SSH Key Generation:"
    echo "1. Generate SSH key (if you don't have one):"
    echo "   ssh-keygen -t rsa -b 4096 -C 'your-email@example.com'"
    echo "2. Add the public key to your Git provider"
    echo "3. Run this command to encode your private key:"
    echo "   cat ~/.ssh/id_rsa | base64 -w 0"
    echo ""
    read -p "Enter path to your SSH private key (default: ~/.ssh/id_rsa): " ssh_key_path
    ssh_key_path=${ssh_key_path:-~/.ssh/id_rsa}
    
    if [ -f "$ssh_key_path" ]; then
        encoded_key=$(cat "$ssh_key_path" | base64 -w 0)
        echo "✅ Your encoded SSH private key:"
        echo "$encoded_key"
        echo ""
    else
        echo "❌ SSH key not found at $ssh_key_path"
        echo ""
    fi
    
    read -p "Enter your Git repository URL (e.g., git@github.com:username/repo.git): " git_url
    if [ ! -z "$git_url" ]; then
        encoded_url=$(echo -n "$git_url" | base64)
        echo "✅ Your encoded Git URL:"
        echo "$encoded_url"
        echo ""
    fi
}

# Main menu
while true; do
    echo "Choose an option:"
    echo "1) Generate Docker Hub credentials"
    echo "2) Generate Git repository credentials"
    echo "3) Generate both"
    echo "4) Exit"
    echo ""
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            generate_docker_token
            ;;
        2)
            generate_git_credentials
            ;;
        3)
            generate_docker_token
            generate_git_credentials
            ;;
        4)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please enter 1-4."
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
    clear
done
