#!/usr/bin/env bash
set -e

# begin configuration
# change user and group to your 

domains=( domain.tld www.domain.tld )
email=user@domain.tld
w_root=/home/user
user=user
group=user

# end configuration

if [ "$EUID" -ne 0 ]; then
    echo  "Please run as root"
    exit 1
fi


for domain in "${domains[@]}"; do
    /usr/bin/certbot certonly --agree-tos --renew-by-default --dns-cloudflare --dns-cloudflare-credentials /home/$user/.secrets/cloudflare.ini --email $email -d $domain
    cat /etc/letsencrypt/live/$domain/privkey.pem  /etc/letsencrypt/live/$domain/cert.pem > ssl.pem
    cp ssl.pem /etc/nginx/ssl/$domain.pem
    cp /etc/letsencrypt/live/$domain/fullchain.pem /etc/nginx/ssl/
    chown -R $user:$group /etc/nginx/
    rm ssl.pem
done