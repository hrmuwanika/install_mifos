#!/bin/sh

# Mifos installation on Ubuntu: 22.04 
# ==============================

# Installing System Updates and Prerequisites
sudo apt update && sudo upgrade -y

# To extract the tar.gz Tomcat file, create a new /opt/tomcat/ directory with the command:
sudo mkdir /opt/tomcat

# Create Tomcat User and Group (Do run as root). Create a new group and system user to run the Apache Tomcat service from the /opt/tomcat directory.
sudo groupadd tomcat
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# Set directory to download the tomcat
cd /usr/src

# Now download tomcat.
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.17/bin/apache-tomcat-10.1.17.tar.gz 

# Now extract tomcat tarbal using the command
sudo tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1 

# Modify Tomcat User Permission
# =============================

# Move to the directory where the Tomcat installation is located:
cd /opt/tomcat

# Grant group ownership over the installation directory to the tomcat group with the command:
sudo chown -R tomcat:tomcat /opt/tomcat/ 
sudo chmod -R u+x /opt/tomcat/bin 

# Give it read access to the conf directory and its contents by typing:
sudo chmod -R g+r conf

# Followed by changing directory permissions to grant execute access with:
sudo chmod g+x conf

#  Finally, give the tomcat user ownership of the webapps, work, temp, and logs directories using the command:
sudo chown -R tomcat webapps/ work temp/ logs

# Create System Unit File
# ======================
# Create and open a new file in the /etc/system/system under the name tomcat.service:
sudo cat <<EOF >  /etc/systemd/system/tomcat.service

[Unit]
Description=Apache Tomcat 10 Web Application Server
After=network.target
 
[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-1.18.0-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

# For the changes to take place, reload the system daemon with the command:
sudo systemctl daemon-reload

# Now, you can finally start the Tomcat service:
sudo systemctl start tomcat.service
sudo systemctl enable tomcat.service 

# Verify the Apache Tomcat service is running with the command:
sudo systemctl status tomcat

# Adjust Firewall
# ===============
#  Open Port 8080 to allow traffic through it with the command:
sudo ufw allow 8080/tcp

# If the port is open, you should be able to see the Apache Tomcat splash page. Type the following in the browser window:
# http://server_ip:8080 or http://localhost:8080
