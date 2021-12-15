user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
  worker_connections  1024;
}


http {
  server {
    listen 80;
    location / {
      proxy_pass http://${API_ADDRESS}:${API_PORT}/;
    }
  }
}