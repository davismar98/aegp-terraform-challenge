#!/bin/bash
# Simple script to install Python 3 and run a basic HTTP server

# Update package list and install Python 3 and pip
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip

# Create a directory for our simple app
mkdir -p /var/www/html

# Create a simple index.html file
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World</title>
    <style>
        body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f0f0f0; }
        .container { text-align: center; padding: 20px; background-color: #fff; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello, World!</h1>
        <p>This page is served by a Python HTTP server on port 8080.</p>
        <p>Hostname: $(hostname)</p>
    </div>
</body>
</html>
EOF

# Create a systemd service to run the Python HTTP server
cat <<EOF > /etc/systemd/system/hello-world.service
[Unit]
Description=Simple Python HTTP Server for Hello World
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hello-world-server

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable hello-world.service
sudo systemctl start hello-world.service

# (Optional) Install Azure CLI for diagnostics if needed - uncomment if necessary
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
