# Let's Encrypt renewal for Cloudflare & NGINX

This script automates the renewal process for certificates issued by Let's Encrypt.

## Prequisites

* NGINX
* Certbot
* Certbot DNS Cloudfare plugin
  * Arch - certbot-dns-cloudflare
  * Ubuntu/Fedora/openSUSE - python3-certbot-dns-cloudflare
  
Please familiarise yourself with <https://certbot-dns-cloudflare.readthedocs.io/en/stable/> before continuing. The ini configuration is below.

## Setup Cloudflare configuration

Create a new config file

```bash
cd ~/
mkdir .secrets/
nano .secrets/cloudflare.ini
```

Use the following configuration

```conf
dns_cloudflare_email = "user@domain.tld"
dns_cloudflare_api_key = "Global API Key"
```

> Obtain your Global API key here: <https://dash.cloudflare.com/profile/api-tokens>

Once this is complete, create your SSL cert directory. Run as root:

```bash
mkdir -pv /etc/nginx/ssl/cloudflare/
```

## Setup Let's Encrypt on NGINX (for the first time)

Long story short, run as root:

```bash
certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/user/.secrets/cloudfare.ini
```

Follow the steps required for every domain (and subdomain) and then for every domain do:

This will create several files
as described in the generated /etc/letsencrypt/live/yourdomain/README

* `privkey.pem`  : the private key for your certificate.
* `fullchain.pem`: the certificate file used in most server software.
* `chain.pem`    : used for OCSP stapling in Nginx >=1.3.7.
* `cert.pem`     : will break many server configurations, and should not be used without reading further documentation (see link below).

Run as root

```bash
cd /etc/letsencrypt/live/yourdomain
cp * /etc/nginx/ssl/cloudflare
```

Every virtual hosts have its own folder in my home.

Therefore, for every virtual host (and for every certificate) my nginx.conf looks like

```conf
server {
    listen 443 ssl http2;
    server_name domain.tld www.domain.tld;
    # access_log /var/log/nginx/nginx.domain.tld.access.log;
    # error_log /var/log/nginx/nginx.domain.tld.error.log;

    location / {
        root   /var/www/html/domain.tld;
        index  index.html;
        }

    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
    ssl_certificate /etc/nginx/ssl/cloudflare/domain.tld.crt;
    ssl_certificate_key /etc/nginx/ssl/cloudflare/domain.tld.key;
    ssl_session_timeout 1d;
    #ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam.pem
    # ssl_dhparam /path/to/dhparam.pem;

    # intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # verify chain of trust of OCSP response using Root CA and Intermediate certs
    # Optionally, this will be for the Cloudflare Origin CA root certificate
    # Obtained: https://support.cloudflare.com/hc/en-us/articles/115000479507#h_30cc332c-8f6e-42d8-9c59-6c1f06650639 (step 4)
    ssl_trusted_certificate /etc/nginx/ssl/cloudflare/cloudflare_origin_rsa.pem;

    # replace with the IP address of your resolver
    resolver 127.0.0.1;
}

```

> Additionally, you can use <https://ssl-config.mozilla.org/> to generate your config for other servers

Where `www.domain.tld` is the domain.
There's another configuration for the document root, that differs from the one above for the line:

```conf
ssl.pemfile = "/etc/nginx/ssl/"
```

## Monthly renew, using webroot

You have to change the first lines of `renew.sh` according to your configuration.

You have to change the path of this script in the `letsencrypt-cloudflare.service` file according to your configuration.

After that, you can activate the montly renew:

```bash
cp letsencrypt-cloudflare.* /etc/systemd/system/
systemctl enable letsencrypt-cloudflare.timer
```

That's all.
