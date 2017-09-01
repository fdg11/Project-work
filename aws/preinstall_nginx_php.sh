#!/usr/bin/env bash

apt-get update && apt-get upgrade -y
apt-get autoremove -y && apt-get autoclean

curl -sL http://nginx.org/keys/nginx_signing.key | apt-key add -

echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list

apt-get update && apt-get install nginx php-fpm php-mysql php-ldap -y

sed -i 's/user\ \ nginx;/user www-data;/g' /etc/nginx/nginx.conf

mkdir -p /run/php /www

cat <<EOF > /etc/nginx/conf.d/main.conf
server {
    listen       80 default;
    root   /www/;
    index index.php;

location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
               access_log        off;
               expires           max;
}

location ~ \.php$ {
         try_files \$uri =404;
               fastcgi_pass   unix:/run/php/php7.0-fpm.sock;
               fastcgi_index index.php;
               fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
	       include /etc/nginx/fastcgi_params;
         }

    location ~ /\.ht {
        deny  all;
    }
}
EOF

systemctl enable nginx && systemctl restart nginx
systemctl enable php7.0-fpm && systemctl restart php7.0-fpm


