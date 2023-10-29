#!/bin/sh

# Mifos installation on Ubuntu: 22.04 
# ==============================

# Installing System Updates and Prerequisites
sudo apt update && sudo upgrade -y

# Installation of Java
sudo apt install openjdk-11-jdk -y

# To extract the tar.gz Tomcat file, create a new /opt/tomcat/ directory with the command:
sudo mkdir /opt/tomcat

# Create Tomcat User and Group (Do run as root). Create a new group and system user to run the Apache Tomcat service from the /opt/tomcat directory.
sudo groupadd tomcat
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat 

# Set directory to download the tomcat
cd /usr/src

# Now download tomcat.
wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.15/bin/apache-tomcat-10.1.15.tar.gz

# Now extract tomcat tarbal using the command
sudo tar xzvf apache-tomcat-10.1.15.tar.gz -C /opt/tomcat --strip-components=1

# Modify Tomcat User Permission
# =============================

# Move to the directory where the Tomcat installation is located:
cd /opt/tomcat

# Grant group ownership over the installation directory to the tomcat group with the command:
sudo chgrp -R tomcat /opt/tomcat
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

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
 
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
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
sudo systemctl start tomcat

# Verify the Apache Tomcat service is running with the command:
sudo systemctl status tomcat

# Adjust Firewall
# ===============
#  Open Port 8080 to allow traffic through it with the command:
sudo ufw allow 8080/tcp

# If the port is open, you should be able to see the Apache Tomcat splash page. Type the following in the browser window:
# http://server_ip:8080 or http://localhost:8080

# Configure Web Management Interface
# ==================================

# Open the users file with the command:
sudo nano /opt/tomcat/conf/tomcat=users.xml

# Scroll down and find the section specifying Tomcat users. Modify it by adding the following:
# Copy and paste the below

 <!-- user manager can access only the manager section -->
 <role rolename="manager-gui" />
 <user username="manager" password="_SECRET_PASSWORD_" roles="manager-gui" />
 
 <!-- user admin can access manager and admin section both -->
 <role rolename="admin-gui" />
 <user username="admin" password="_SECRET_PASSWORD_" roles="manager-gui,admin-gui" />

# Save and Exit the file.

sudo nano /opt/tomcat/webapps/manager/META-INF/context.xml
# Comment out the section added for IP address restriction to allow connections from anywhere.

<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  ...
</Context>

# Save and Exit the file.

sudo nano /opt/tomcat/webapps/host-manager/META-INF/context.xml
# Comment out the same section to allow connections from anywhere.

<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!--<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  ...
</Context>

# Save and Exit the file.

sudo systemctl restart tomcat

# Test the Tomcat Installation
# http://<your_domain_or_IP_address>:8080

# Tomcat web application manager dashboard is available:
# http://<your_domain_or_IP_address>:8080/manager/html

# Tomcat virtual host manager dashboard is available:
# http://<your_domain_or_IP_address>:8080/host-manager/html

# Install mariadb databases
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.8/ubuntu focal main'
sudo apt update 
sudo apt install mariadb-server mariadb-client libmariadb-dev -y 

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf
cd /etc/mysql/mariadb.conf.d/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/50-server.cnf

sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service 

mysql -u root -p << MYSQL_SCRIPT
create database `fineract_tenants`;
create database `fineract_default`;
./gradlew migrateTenantListDB -PdbName=mifosplatform-tenants
./gradlew migrateTenantDB -PdbName=mifostenant-default
exit 
MYSQL_SCRIPT
