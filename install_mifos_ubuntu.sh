# Youtube: https://www.youtube.com/watch?v=4AVIAz0vbaA&t=4s

#!/bin/sh

# Tomcat installation on Ubuntu: 
# ==============================

# Install OpenJDK
sudo apt install default-jdk

# Create Tomcat User and Group (Do run as root). Create a new group and system user to run the Apache Tomcat service from the /opt/tomcat directory.
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# Set directory to download the tomcat
cd /tmp

# Now download tomcat.
curl -O https://downloads.apache.org/tomcat/tomcat-9/v9.0.36/bin/apache-tomcat-9.0.36.tar.gz

# To extract the tar.gz Tomcat file, create a new /opt/tomcat/ directory with the command:
sudo mkdir /opt/tomcat

# Now extract tomcat tarbal using the command
sudo tar xzvf apache-tomcat-9.0.36.tar.gz -C /opt/tomcat --strip-components=1


# Modify Tomcat User Permission
# =============================

# Move to the directory where the Tomcat installation is located:
cd /opt/tomcat

# Grant group ownership over the installation directory to the tomcat group with the command:
sudo chgrp -R tomcat /opt/tomcat

# Give it read access to the conf directory and its contents by typing:
sudo chmod -R g+r conf

# Followed by changing directory permissions to grant execute access with:
sudo chmod g+x conf

#  Finally, give the tomcat user ownership of the webapps, work, temp, and logs directories using the command:
sudo chown -R tomcat webapps/ work temp/ logs

# Create System Unit File
# ======================

# To configure the file, you first need to find the “JAVA_HOME” path. This is the exact location of the Java installation package.
sudo update-java-alternatives -l

# Create and open a new file in the /etc/system/system under the name tomcat.service:
sudo nano /etc/systemd/system/tomcat.service

#  Once the file opens, copy and paste the content below, changing the JAVA_HOME value to the information you found in the previous step.

[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment=’CATALINA_OPTS=-Xms512M –Xmx1024M –server –XX:+UserParallelGC’
Environment=’JAVA_OPTS=-Djava.awt.headless=true Djava.security.egd=file:/dev/./urandom’

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMast=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target

# Now save it and exit.

# For the changes to take place, reload the system daemon with the command:
sudo systemctl daemon-reload

# Now, you can finally start the Tomcat service:
sudo systemctl start tomcat

# Verify the Apache Tomcat service is running with the command:
sudo systemctl status tomcat

# Adjust Firewall
# ===============

#  Open Port 8080 to allow traffic through it with the command:
sudo ufw allow 8080/tcp

# If the port is open, you should be able to see the Apache Tomcat splash page. Type the following in the browser window:
http://server_ip:8080
or
http://localhost:8080

# Configure Web Management Interface
# ==================================

# Open the users file with the command:
sudo nano /opt/tomcat/conf/tomcat=users.xml

# Scroll down and find the section specifying Tomcat users. Modify it by adding the following:

------
<tomcat-users>
<! --
Comments
-- >
<role rolename=”admin-gui”/>
<role rolename=”manager-gui”/>
<user username=”admin” password=”Your_Password” roles=”admin-gui, manager-gui”/>
</tomcat-users>
-----
# Save and Exit the file.

# Configure Remote Access
# =======================

# First, open the manager file:
sudo nano /opt/tomcat/webapps/manager/META-INF/context.xml

# Next, decide whether to grant access from a) anywhere or b) from a specific IP address.


---------------
<Context antiResourceLocking=”false” privileged=”true”>
<! --

<Valve className=”org.apache.catalina.valves.RemoteAddrValve”
allow=”127\.\d+\.\d+\.\d+|::1|0000:1” />

-- >

</Context>
------------------

# To allow access from a specific IP address, add the IP to the previous command, as follows:
-----------
<Context antiResourceLocking=”false” privileged=”true”>
<! --

<Valve className=”org.apache.catalina.valves.RemoteAddrValve”
allow=”127\.\d+\.\d+\.\d+|::1|0000:1|THE.IP.ADDRESS.” />

-- >

</Context>
--------------

# Repeat the same process for the host-manager file.

# Start by opening the file with the command:
sudo nano /opt/tomcat/latest/webapps/host-manager/META-INF/context.xml

# Followed by granting access from a) anywhere or b) from a specific IP address (as in the previous step).
