# Keycloak Let’s Encrypt :closed_lock_with_key:

The current effort to get Keycloak running with renewing Let’s Encrypt certificates is too ... keystores for me.

This repo will just use Let's Encrypt. Maybe not the right thing for big businesses but sufficient for many others.

## tldr

Use the patched docker image `stelzo/keycloak:latest` or build it yourself with `Dockerfile` in this repo.

## detailed setup guide

You need to have installed:

- [docker-compose](https://docs.docker.com/compose/install/)
- [Certbot](https://certbot.eff.org/)
- [Nginx](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/)

Then start with cloning the repo.

```sh
$ git clone https://github.com/stelzo/keycloak-letsencrypt.git
```

Create a new Nginx config for Keycloak in `/etc/nginx/sites-available/<your-domain>.conf` with the following content.

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

Create a symlink from your config to the enabled sites.

```sh
$ sudo ln -s /etc/nginx/sites-available/<your-domain>.conf /etc/nginx/sites-enabled/<your-domain>.conf
```

Check if you made any mistakes with `sudo nginx -t` and let Nginx load the new config `sudo nginx -s reload`.

Get your SSL certificate.
For this to work, your domain needs to point to the server you are running this on.

```sh
$ sudo certbot --nginx
```

Now take a look into the `docker-compose.yml`.

1. **Change the passwords**!
2. Create your admin account with `KEYCLOAK_USER` and `KEYCLOAK_PASSWORD` environment variables.
3. Start the containers. `docker-compose up -d`.

**You are ready to go!** Visit `https://<your-domain>/`.

You can restart your Keycloak server with `docker-compose -f /path/to/docker-compose.yml restart keycloak`.

## Management Console

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

## Credit

This is basically a dockerized version of [this article](https://www.datamate.org/installation-keycloak-sso-ubuntu-18-04/). Many thanks to Christoph Dyllick-Brenzinger!

## License

[MIT](https://choosealicense.com/licenses/mit/)
