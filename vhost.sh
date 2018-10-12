Create_nginx_apache_mod-php_conf() {
  # Nginx/Tengine/OpenResty
  [ ! -d ${web_install_dir}/conf/vhost ] && mkdir ${web_install_dir}/conf/vhost
  cat > ${web_install_dir}/conf/vhost/${domain}.conf << EOF
server {
  ${Nginx_conf}
  server_name ${domain}${moredomainame};
  ${N_log}
  index index.html index.htm index.php;
  root ${vhostdir};
  ${Nginx_redirect}
  ${anti_hotlinking}
  location / {
    try_files \$uri @apache;
  }
  location @apache {
    proxy_pass http://127.0.0.1:88;
    include proxy.conf;
  }
  location ~ .*\.(php|php5|cgi|pl)?$ {
    proxy_pass http://127.0.0.1:88;
    include proxy.conf;
  }
  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
    expires 30d;
    access_log off;
  }
  location ~ .*\.(js|css)?$ {
    expires 7d;
    access_log off;
  }
  location ~ /\.ht {
    deny all;
  }
}
EOF
