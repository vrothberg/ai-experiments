#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Installing httpd..."
sudo dnf install -y httpd

echo "Starting httpd service..."
sudo systemctl start httpd

echo "Checking httpd service status..."
sudo systemctl is-active httpd

echo "Httpd installed and started successfully."
