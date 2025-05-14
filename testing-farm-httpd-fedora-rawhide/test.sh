#!/bin/bash

# Install httpd
sudo dnf install -y httpd

# Start httpd service
sudo systemctl start httpd

# Check if httpd service is active
sudo systemctl is-active httpd

# Check if httpd is running on port 80
curl http://localhost:80