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

### nginx

Create a new nginx config for keycloak in `/etc/nginx/sites-available/<your-domain>.conf` with the following content.

```
server {
  server_name <your-domain>;
  allow all;
  listen 80;

  location / {
    proxy_pass          http://localhost:8080/;
    proxy_set_header    Host               $host;
    proxy_set_header    X-Real-IP          $remote_addr;
    proxy_set_header    X-Forwarded-For    $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Host   $host;
    proxy_set_header    X-Forwarded-Server $host;
    proxy_set_header    X-Forwarded-Port   443;
    proxy_set_header    X-Forwarded-Proto  https;
  }
}
```

Symlink your config to the enabled sites.
```sh
$ sudo ln -s /etc/nginx/sites-available/<your-domain>.conf /etc/nginx/sites-enabled/<your-domain>.conf
```

Check if you made any mistakes with `nginx -t` and restart `sudo service nginx restart`.

### Let’s Encrypt/certbot
If you don't have certbot yet, [install it](https://certbot.eff.org/).

Get your certificate.
For this to work, your domain needs to point to the server you are running this on.
```sh
$ sudo certbot --nginx
```

### docker-compose

Take a look into the `docker-compose.yml`.
1. Change the postgres-data volume if you want to persist the data to somewhere else and... pick a safe password!
2. Create your admin account with `KEYCLOAK_USER` and `KEYCLOAK_PASSWORD` environment variables.
3. Mount the `standalone.xml` from this repository by changing the first path (host path) `/opt/security/standalone.xml`.
4. Start the container. `docker-compose up -d`.

You are ready to go! Visit `https://<your-domain>/`.

You can restart your Keycloak server with `docker-compose -f /path/to/docker-compose.yml restart keycloak`.

### Management Console

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
