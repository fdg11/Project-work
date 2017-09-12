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
	index index.php index.html;

	gzip on; 
        gzip_disable "msie6";
        gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;

        location ~ /\. {
                deny all; 
        }

        location ~* /(?:uploads|files)/.*\.php$ {
                deny all; 
        }

        location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
                access_log off;
                log_not_found off;
                expires max; 
        }

	location / {
        	try_files \$uri \$uri/ /index.php?\$args;
    	}	

	location ~ \.php$ {
		try_files \$uri =404;
               	fastcgi_pass   unix:/run/php/php7.0-fpm.sock;
               	fastcgi_index index.php;
               	fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
	       	include /etc/nginx/fastcgi_params;
        }

}
EOF

curl -sO https://wordpress.org/wordpress-4.8.1.tar.gz
tar -xvzf wordpress-4.8.1.tar.gz -C /www --strip-components=1

systemctl enable nginx && systemctl restart nginx
systemctl enable php7.0-fpm && systemctl restart php7.0-fpm


