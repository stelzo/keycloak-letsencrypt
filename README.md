# Keycloak with Let’s Encrypt :closed_lock_with_key:

Maybe it's just me, but I think the current effort to get Keycloak running with renewing Let’s Encrypt certificates is too ... keystores.

This will just use plain fullchain.pem and privkey.pem. Maybe not the right thing for big businesses but sufficient for many others.

The plan is to use nginx for https and proxy to the http Keycloak server. Keycloak wants some stuff to be over https so we will give him nginx as a socket proxy.

You need
- docker-compose
- certbot
- nginx

This is basically a dockerized version of [this article](https://www.datamate.org/installation-keycloak-sso-ubuntu-18-04/). Many thanks to Christoph Dyllick-Brenzinger!

## Setup
Clone this repo :neutral_face:
```sh
$ git clone https://github.com/stelzo/keycloak-letsencrypt.git
```

### Let’s Encrypt/certbot
If you don't have certbot yet, [install it](https://certbot.eff.org/).

Get your certificate.
For this to work, your domain needs to point to the server you are running this on.
If you already have nginx, stop it (`systemctl stop nginx` for me). I know there are flags for nginx, do as you like.  
```sh
$ sudo certbot certonly --standalone --preferred-challenges http -d <your-domain>
```

For renewals you can open `/etc/letsencrypt/renewal/<yourdomain>.conf` and add a custom command to be executed when the certbot updated your certifcates.
```sh
renew_hook = nginx -s reload
```
If you like to restart your keycloak server, this would be `docker-compose -f /opt/security/docker-compose.yml restart keycloak`.

### nginx 
Create a new nginx config for keycloak in `/etc/nginx/sites-available/` with the content of the file `example.com.conf` in this repository.

Do not forget to replace `<your-domain>` with your domain. :neutral_face:

Check if you made any mistakes `nginx -t` and start nginx again `systemctl start nginx`.

Nginx is now ready to proxy every request to your domain to port 8080 on your machine.

### docker-compose

Take a look into the `docker-compose.yml`.
1. You should change the postgres-data volume if you want to persist the data to your liking and... pick a safe password!
2. Create your admin account with `KEYCLOAK_USER` and `KEYCLOAK_PASSWORD` environment variables.
3. Mount the `standalone.xml` from this repository by changing the first path (host path) `/opt/security/standalone.xml`.
4. Start the container. `docker-compose up -d`.

You are ready to go! Visit `https://yourdomain.com/`.

If you want to import a realm on startup, you can mount your realm.json somewhere and set the path (in the container) with environment `KEYCLOAK_IMPORT=<your-realm-path>.json`. Then add `-Dkeycloak.profile.feature.upload_scripts=enabled` to the commands.

### management account

The WildFly (Application Server Keycloak runs on) management console does not currently work with the nginx proxy (as seen in the article) but it starts on port 9990 on your machine if you need it. It is only http though.

Add an account.
```sh
$ docker exec keycloak /opt/jboss/keycloak/bin/add-user.sh -u <username> -p <password> -cw
```

Reload the server inside the container.
```sh
$ docker exec keycloak /opt/jboss/keycloak/bin/jboss-cli.sh --connect --command=reload
```

You can reach it at `http://yourdomain.com:9990/management`.

## License
Author: Christopher Sieh <stelzo@steado.de>

This project is licensed under the MIT License.
