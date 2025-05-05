# Use the official RHEL 9 bootc base image (adjust version as needed)
# Check the Red Hat Ecosystem Catalog for the latest available version (e.g., 9.4)
FROM registry.redhat.com/rhel9/rhel-bootc:9.4

# Install the Apache web server package
RUN dnf install -y httpd && \
    # Clean up DNF cache
    dnf clean all

# Enable the httpd service to start on boot within the final system
RUN systemctl enable httpd.service

# Create a simple test page
RUN echo "Hello from RHEL Image Mode (bootc) with httpd!" > /var/www/html/index.html

# Optional: Open port 80 in the firewall within the image
# This makes testing easier once booted.
RUN firewall-cmd --add-service=http --permanent
# Note: firewall-cmd --reload isn't needed here; the permanent rule will apply on boot.

# You could add more custom configurations here if needed
