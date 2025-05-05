Okay, let's outline how you can test `httpd` (Apache web server) within a RHEL system managed using the `bootc`-based "Image Mode". This involves building a custom bootable container image that includes `httpd`, creating a bootable disk image from it, and then booting a VM from that disk image to perform the test.

**Prerequisites:**

1.  **RHEL Subscription:** You need access to Red Hat container images, which requires a valid RHEL subscription (including the no-cost Developer Subscription).
2.  **Podman:** You need `podman` installed on a Linux machine to build the container image.
3.  **QEMU/KVM (or other VM software):** You need a virtualization tool to boot the generated disk image. QEMU/KVM is common on Linux.
4.  **Red Hat Login:** You'll need to log in to the Red Hat registry using `podman login registry.redhat.com`.

**Steps:**

**Step 1: Define the Bootable Container Image (`Containerfile`)**

Create a file named `Containerfile` in a new directory. This file defines how your custom bootable OS image is built.

```Containerfile
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
```

**Step 2: Build the OCI Container Image**

Navigate to the directory containing your `Containerfile` and run the build command:

```bash
# Log in to the Red Hat registry (if you haven't already)
podman login registry.redhat.com

# Build the image
podman build -t my-rhel-bootc-httpd .
```

This will create a local OCI container image tagged `my-rhel-bootc-httpd`.

**Step 3: Create a Bootable Disk Image (e.g., QCOW2 for QEMU/KVM)**

Now, convert the OCI image you just built into a bootable disk image format. `bootc` itself, often via helper scripts or containers, handles this.

One common method involves running a command using the image itself (or an image builder container) to produce the disk image:

```bash
# Create a directory to hold the output disk image
mkdir ./disk

# Run the image builder command using podman
# This command runs the bootc image builder functionality *from within* your custom image
# to generate a QCOW2 disk image in the ./disk directory.
podman run --rm --privileged --pid=host \
    -v ./disk:/output \
    --security-opt label=disable \
    localhost/my-rhel-bootc-httpd \
    bootc-image-builder --type qcow2 --local /output/rhel-httpd.qcow2

# Check if the disk image was created
ls -lh ./disk/rhel-httpd.qcow2
```

* `--privileged` and `--pid=host`: Often required for the image builder to interact correctly with the system to create disk images.
* `-v ./disk:/output`: Mounts your local `disk` directory into the container at `/output`.
* `--security-opt label=disable`: May be needed to avoid SELinux permission issues when writing the disk image.
* `localhost/my-rhel-bootc-httpd`: Refers to the image you built locally.
* `bootc-image-builder ...`: These are arguments passed *to the entrypoint/command* within your container image, telling it to build a `qcow2` disk image. The `--local` flag indicates it should use the image context it's running from.

**Step 4: Boot the Disk Image in a Virtual Machine**

Use QEMU/KVM (or your preferred hypervisor) to boot the generated QCOW2 image. We'll also forward a host port (e.g., 8080) to the guest's port 80.

```bash
qemu-system-x86_64 \
    -m 2048 \
    -nographic \
    -hda ./disk/rhel-httpd.qcow2 \
    -net user,hostfwd=tcp::8080-:80 \
    -net nic
```

* `-m 2048`: Allocate 2GB RAM to the VM.
* `-nographic`: Run in console mode (useful for servers). Remove this if you prefer a graphical console.
* `-hda ./disk/rhel-httpd.qcow2`: Use the generated disk image.
* `-net user,hostfwd=tcp::8080-:80`: Set up user-mode networking and forward TCP traffic from port 8080 on your host machine to port 80 inside the VM.
* `-net nic`: Provide a virtual network card.

The VM will start booting. You should see the RHEL boot process in your terminal.

**Step 5: Test `httpd`**

Once the VM has booted up (you should see a login prompt or systemd logs indicating boot completion):

1.  **From your Host Machine:** Open a web browser or use `curl` to access the web server via the forwarded port:
    ```bash
    curl http://localhost:8080
    ```
    You should see the output: `Hello from RHEL Image Mode (bootc) with httpd!`

2.  **Inside the VM (Optional):**
    * Log in to the VM console (credentials might be default root/no password initially, or configured via cloud-init if added to the image build).
    * Check the status of the `httpd` service: `systemctl status httpd`
    * Check if it's listening: `ss -tlnp | grep :80`
    * Test locally within the VM: `curl http://localhost`

**Troubleshooting:**

* **Connection Refused (from host):** Double-check the `qemu` port forwarding (`-net user,hostfwd...`). Ensure no firewall on your *host* machine is blocking port 8080. Verify `httpd` is running *inside* the VM (`systemctl status httpd`). Check the VM's internal firewall (`firewall-cmd --list-all`).
* **`httpd` not running in VM:** Check boot logs (`journalctl -u httpd`) inside the VM for errors. Ensure `systemctl enable httpd.service` was included in the `Containerfile`.
* **SELinux Issues:** Temporarily disable SELinux inside the VM (`setenforce 0`) to see if it's the cause. If so, you may need to adjust SELinux policies (though the default `httpd` policy is usually sufficient).
* **Build/Disk Creation Errors:** Check `podman` logs. Ensure you're logged into `registry.redhat.com`. Ensure you have sufficient disk space. Try the `--security-opt label=disable` flag if you suspect SELinux issues during the disk build.

This process demonstrates how to embed a service like `httpd` into a RHEL bootc image and verify its operation after booting, following the principles of immutable infrastructure provided by Image Mode.
