# Install Docker

```
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo apt install -y docker-compose
```

# Docker image pull

```
docker pull guacamole/guacamole
docker pull guacamole/guacd
docker pull mariadb
```

# Grab the latest sql info from the latest images

Run this command to retrive the db.sql:

`docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql`

# Create initial DB docker-compose.yml and additional config

```
version: '3'
services:
  guacdb:
    container_name: guacamoledb
    image: mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'
      MYSQL_DATABASE: 'guacamole_db'
      MYSQL_USER: 'guacamole_user'
      MYSQL_PASSWORD: 'MariaDBUserPass'
    volumes:
      - './db-data:/var/lib/mysql'
volumes:
  db-data:
```

After saving the files please run: `docker-compose up -d`

Next you need to copy the SQL file into the docker container:

`docker cp initdb.sql guacamoledb:/initdb.sql`

Next, input it to the DB by running:

```
docker exec -it guacamoledb bash
cat /initdb.sql | mariadb -u root -p guacamole_db
exit
```

And now turn off the DB by running: `docker-compose down`

# Complete the docker-compose.yml with all the necessary images

Backup your docker-compose files by typing: `cp docker-compose.yml docker-compose.yml.bak`

Then edit **docker-compose.yml** to include additional config:

```
version: '3'
services:
  guacdb:
    container_name: guacamoledb
    image: mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'
      MYSQL_DATABASE: 'guacamole_db'
      MYSQL_USER: 'guacamole_user'
      MYSQL_PASSWORD: 'MariaDBUserPass'
    volumes:
      - './db-data:/var/lib/mysql'
  guacd:
    container_name: guacd
    image: guacamole/guacd
    restart: unless-stopped
  guacamole:
    container_name: guacamole
    image: guacamole/guacamole
    restart: unless-stopped
    ports:
      - 8080:8080
    environment:
      GUACD_HOSTNAME: "guacd"
      MYSQL_HOSTNAME: "guacdb"
      MYSQL_DATABASE: "guacamole_db"
      MYSQL_USER: "guacamole_user"
      MYSQL_PASSWORD: "MariaDBUserPass"
      TOTP_ENABLED: "true"
    depends_on:
      - guacdb
      - guacd
volumes:
  db-data:
```

Now run `docker-compose up -d` and Guacamole should be up and running on your server.

# Access Guacamole

Open your browser and put in your Guacamole IP with port 8080, for example:

http://mylocalip.home:8080/guacamole

The original username/password are **guacadmin/guacadmin**
For security reason I included TOTP in my installation guide, so be sure to have your Google Authenticator prepared.
Otherwise, make sure that you remove **TOTP_ENABLED: "true"** line from your **docker-compose.yml** file.

# Configuring SSL/TLS

We will enable TLS connections via an Nginx reverse proxy.
In this example both Guacamole containers and nginx are installed on same Ubuntu host.
Ngnix is not running in Docker container, but directly on host.

## Configure DNS record

In order to use Let's Encrpyt certbot in a later step, a DNS record for IP of your nginx/guacamole server is required.
For this, you can use No-IP as free D(DNS) provider, just take note that you will have to confirm domain name every 30 days in free tier.
In my case, I will be using **mydomain.ddns.net** to reference the relevant hostname in further configuration.

## Install Nginx

1. Install: `sudo apt update && sudo apt install nginx -y`

2. Create config file: `sudo vi /etc/nginx/sites-available/guacamole`

3. Add basic config without SSL yet: 
```
server {
    listen 80;
    server_name mydomain.ddns.net;

    location / {
        proxy_pass http://localhost:8080; # Or the correct port of your Guacamole container
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }
}
```

4. Enable the config:
```
sudo ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

5. Test functionality without SSL/TLS:
   Visit http://mydomain.ddns.net:8080/guacamole, if it loads Guacamole login page, everything is in order.

7. Run Certbot to Obtain and Configure SSL: `sudo certbot --nginx -d holyguacamole.ddns.net`

8. Restart Ngnix: `sudo systemctl restart nginx`

9. Test functionality with SSL/TLS:
   Visit https://mydomain.ddns.net/guacamole, if it loads Guacamole login page (via SSL/TLS), everything is in order.

## Disable HTTP access

1. Edit **docker-compose.yml** to exclude port mapping 8080:8080

`sudo vi docker-compose.yml`
```
version: '3'
services:
  guacdb:
    container_name: guacamoledb
    image: mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'MariaDBRootPass'
      MYSQL_DATABASE: 'guacamole_db'
      MYSQL_USER: 'guacamole_user'
      MYSQL_PASSWORD: 'MariaDBUserPass'
    volumes:
      - './db-data:/var/lib/mysql'
  guacd:
    container_name: guacd
    image: guacamole/guacd
    restart: unless-stopped
  guacamole:
    container_name: guacamole
    image: guacamole/guacamole
    restart: unless-stopped
#    ports:
#      - 8080:8080
    environment:
      GUACD_HOSTNAME: "guacd"
      MYSQL_HOSTNAME: "guacdb"
      MYSQL_DATABASE: "guacamole_db"
      MYSQL_USER: "guacamole_user"
      MYSQL_PASSWORD: "MariaDBUserPass"
      #TOTP_ENABLED: "true"
    depends_on:
      - guacdb
      - guacd
volumes:
  db-data:
```

2. Find the Guacamole container’s IP:

`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' guacamole`

This will return IP of Docker container running Guacamole, for example 172.18.0.5.

**NOTE: Currently this will have to be run on each server or container restart, and nginx config updated!**

3. Edit the Ngnix config file to specify that container IP, rather than localhost:

`sudo vi /etc/nginx/sites-available/guacamole`
```
server {
    server_name mydomain.ddns.net;

    location / {
        proxy_pass http://172.19.0.4:8080; # Or the correct port of your Guacamole container
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        # WebSocket Support - RESOLVES RDP LATENCY ISSUES!
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mydomain.ddns.net/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mydomain.ddns.net/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = mydomain.ddns.net) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name mydomain.ddns.net;
    return 404; # managed by Certbot
}

```

4. Restart Ngnix: `sudo systemctl restart nginx`

# Summary

After performing these steps, you should have an instance of Guacamole running on Ubuntu LTS 22.04 within a Docker container, which can be accessed over HTTPS via Ngnix/certbot which are running on Ubuntu host.



