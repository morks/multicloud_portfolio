# NGINX Cheat Sheet

## Installation & Setup

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y nginx

# RHEL / CentOS / Fedora
sudo yum install -y nginx          # CentOS 7
sudo dnf install -y nginx          # CentOS 8+ / Fedora

# macOS via Homebrew
brew install nginx

# Check installed version
nginx -v
nginx -V          # includes compile-time flags and modules

# systemctl lifecycle commands
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx       # graceful reload – no dropped connections
sudo systemctl enable nginx       # start on boot
sudo systemctl status nginx

# Test configuration syntax before applying
sudo nginx -t
sudo nginx -T                     # dump full merged config to stdout

# Send signals directly (no systemd)
nginx -s reload                   # reload config
nginx -s stop                     # fast shutdown
nginx -s quit                     # graceful shutdown

# Default config location
# /etc/nginx/nginx.conf

# Default log locations
# /var/log/nginx/access.log
# /var/log/nginx/error.log
```

---

## Configuration Structure

```nginx
# /etc/nginx/nginx.conf – minimal annotated skeleton

user  nginx;
worker_processes  auto;          # auto = one per CPU core

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;    # max simultaneous connections per worker
    # use epoll;                 # Linux – usually set automatically
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Custom log format
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout  65;
    gzip  on;

    # Include all virtual-host configs from conf.d/
    include /etc/nginx/conf.d/*.conf;

    # Include all sites enabled (Debian convention)
    include /etc/nginx/sites-enabled/*;
}
```

---

## Server Blocks (Virtual Hosts)

```nginx
# Plain HTTP server block
server {
    listen       80;
    listen       [::]:80;             # IPv6
    server_name  www.example.com example.com;

    root  /var/www/example.com/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
}

# HTTPS server block with SSL
server {
    listen       443 ssl;
    listen       [::]:443 ssl;
    server_name  www.example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    root  /var/www/example.com/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}

# Default server (catch-all) – returns 444 for unknown hosts
server {
    listen      80 default_server;
    listen      [::]:80 default_server;
    server_name _;
    return      444;
}

# Wildcard server_name
server {
    server_name  *.example.com;       # matches any subdomain
    # ...
}

# 301 redirect HTTP → HTTPS
server {
    listen      80;
    server_name example.com www.example.com;
    return 301  https://$host$request_uri;
}

# Multiple domains on one HTTPS server
server {
    listen      443 ssl;
    server_name app.example.com api.example.com;

    ssl_certificate     /etc/ssl/certs/multi.pem;
    ssl_certificate_key /etc/ssl/private/multi.key;
    # ...
}
```

---

## SSL/TLS

```nginx
# Modern TLS settings (Mozilla Intermediate profile)
ssl_protocols              TLSv1.2 TLSv1.3;
ssl_ciphers                ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers  off;

# Session cache (improves performance)
ssl_session_cache    shared:SSL:10m;
ssl_session_timeout  1d;
ssl_session_tickets  off;

# HSTS – tell browsers to always use HTTPS (max 2 years)
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# OCSP Stapling
ssl_stapling        on;
ssl_stapling_verify on;
resolver            1.1.1.1 8.8.8.8 valid=300s;
resolver_timeout    5s;

# Diffie-Hellman parameter (generate once: openssl dhparam -out /etc/ssl/dhparam.pem 2048)
ssl_dhparam /etc/ssl/dhparam.pem;
```

```bash
# Let's Encrypt – Certbot with NGINX plugin
sudo apt install -y certbot python3-certbot-nginx

# Obtain and install certificate (auto-edits nginx config)
sudo certbot --nginx -d example.com -d www.example.com

# Renew all certificates (add to cron or systemd timer)
sudo certbot renew --quiet

# Dry-run renewal test
sudo certbot renew --dry-run

# Generate self-signed certificate (dev / internal use)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/selfsigned.key \
  -out    /etc/ssl/certs/selfsigned.crt \
  -subj "/CN=localhost"
```

---

## Reverse Proxy

```nginx
server {
    listen      80;
    server_name app.example.com;

    location / {
        proxy_pass         http://127.0.0.1:3000;    # upstream app

        # Forward original client info
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # Use HTTP/1.1 for keep-alive support
        proxy_http_version 1.1;
        proxy_set_header   Connection "";

        # Timeouts
        proxy_connect_timeout  10s;
        proxy_read_timeout     60s;
        proxy_send_timeout     60s;

        # Buffering (disable for streaming / SSE)
        proxy_buffering        on;
        proxy_buffer_size      4k;
        proxy_buffers          8 16k;
    }

    # WebSocket proxy (e.g. Socket.IO, live-reload)
    location /ws/ {
        proxy_pass          http://127.0.0.1:3000;
        proxy_http_version  1.1;
        proxy_set_header    Upgrade    $http_upgrade;
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Host       $host;
        proxy_read_timeout  3600s;    # keep WebSocket alive
    }
}
```

---

## Load Balancing

```nginx
# Define upstream group
upstream backend_app {
    # Default: round-robin
    server app1.internal:8080 weight=3;
    server app2.internal:8080 weight=2;
    server app3.internal:8080;          # weight defaults to 1
    server app4.internal:8080 backup;   # used only when others are down
    server app5.internal:8080 down;     # temporarily disabled

    # Keep persistent connections to upstream
    keepalive 32;
}

# Least-connections – send to server with fewest active connections
upstream backend_lc {
    least_conn;
    server app1.internal:8080;
    server app2.internal:8080;
}

# IP-hash – sticky sessions by client IP
upstream backend_sticky {
    ip_hash;
    server app1.internal:8080;
    server app2.internal:8080;
}

# Random (requires nginx 1.15.1+)
upstream backend_random {
    random two least_conn;
    server app1.internal:8080;
    server app2.internal:8080;
    server app3.internal:8080;
}

# Upstream using a Unix socket (e.g. PHP-FPM, Gunicorn)
upstream php_fpm {
    server unix:/run/php/php8.2-fpm.sock;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
    }
}
```

---

## Location Blocks & URL Rewriting

```nginx
server {
    listen 80;
    server_name example.com;

    # Exact match – highest priority
    location = /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # Preferential prefix match (no regex checked after this)
    location ^~ /static/ {
        root /var/www/assets;
        expires 30d;
    }

    # Case-sensitive regex
    location ~ \.php$ {
        include        fastcgi_params;
        fastcgi_pass   unix:/run/php/php8.2-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Case-insensitive regex
    location ~* \.(jpg|jpeg|png|gif|ico|svg|webp)$ {
        root    /var/www/example.com/html;
        expires 365d;
        access_log off;
    }

    # Standard prefix match (lowest priority)
    location / {
        root  /var/www/example.com/html;
        # Try file → directory → 404
        try_files $uri $uri/ /index.html =404;
    }

    # Permanent redirect (301)
    location /old-page {
        return 301 /new-page;
    }

    # Rewrite (internal, no browser redirect)
    location /api/ {
        rewrite ^/api/(.*)$ /v2/$1 last;
    }

    # Named location used with try_files
    location @fallback {
        proxy_pass http://backend_app;
    }

    # Conditional rewrite – redirect trailing slash
    rewrite ^/(.*)/$ /$1 permanent;
}
```

---

## Caching

```nginx
http {
    # Define cache zone: 10 MB key zone, 1 GB disk, 1 day inactivity TTL
    proxy_cache_path /var/cache/nginx
                     levels=1:2
                     keys_zone=my_cache:10m
                     max_size=1g
                     inactive=60m
                     use_temp_path=off;

    server {
        listen 80;
        server_name example.com;

        location / {
            proxy_pass             http://backend_app;
            proxy_cache            my_cache;
            proxy_cache_valid      200 302  10m;   # cache 200/302 for 10 min
            proxy_cache_valid      404      1m;
            proxy_cache_use_stale  error timeout updating
                                   http_500 http_502 http_503 http_504;
            proxy_cache_lock       on;

            # Expose cache HIT/MISS status in response headers
            add_header X-Cache-Status $upstream_cache_status;

            # Bypass cache if query param or cookie present
            proxy_cache_bypass $arg_nocache $cookie_session;
            proxy_no_cache     $arg_nocache $cookie_session;
        }

        # FastCGI (PHP) caching
        location ~ \.php$ {
            include          fastcgi_params;
            fastcgi_pass     unix:/run/php/php8.2-fpm.sock;
            fastcgi_cache    my_cache;
            fastcgi_cache_valid 200 5m;
            add_header       X-FastCGI-Cache $upstream_cache_status;
        }

        # Microcaching – cache dynamic content for 1 second
        # Dramatically reduces origin load under traffic spikes
        location /api/ {
            proxy_pass          http://backend_app;
            proxy_cache         my_cache;
            proxy_cache_valid   200 1s;
            proxy_cache_lock    on;
        }
    }
}
```

---

## Rate Limiting & Security

```nginx
http {
    # Define limit zones in http block
    limit_req_zone  $binary_remote_addr zone=req_limit:10m  rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    server {
        listen 80;
        server_name example.com;

        # Apply rate limit – allow burst of 20, no delay
        location /api/ {
            limit_req  zone=req_limit burst=20 nodelay;
            limit_conn conn_limit 10;       # max 10 concurrent connections per IP
            proxy_pass http://backend_app;
        }

        # IP whitelist / blacklist
        location /admin/ {
            allow  10.0.0.0/8;
            allow  192.168.1.100;
            deny   all;
        }

        # HTTP Basic Authentication
        location /private/ {
            auth_basic           "Restricted Area";
            auth_basic_user_file /etc/nginx/.htpasswd;  # htpasswd -c /etc/nginx/.htpasswd admin
        }

        # Limit upload body size (default 1m)
        client_max_body_size 50m;

        # Security headers
        add_header X-Frame-Options            "SAMEORIGIN"            always;
        add_header X-Content-Type-Options     "nosniff"               always;
        add_header X-XSS-Protection           "1; mode=block"         always;
        add_header Referrer-Policy            "strict-origin-when-cross-origin" always;
        add_header Content-Security-Policy    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
        add_header Permissions-Policy         "geolocation=(), microphone=()" always;

        # Hide NGINX version from error pages and headers
        server_tokens off;
    }
}
```

---

## NGINX Ingress Controller (Kubernetes)

```bash
# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux

# Check rollout status
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller

# Install kubectl ingress-nginx plugin (krew)
kubectl krew install ingress-nginx
kubectl ingress-nginx --help
kubectl ingress-nginx logs -n ingress-nginx
kubectl ingress-nginx backends -n ingress-nginx
```

```yaml
# IngressClass resource (required for Kubernetes 1.18+)
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx

---
# Ingress resource with common annotations
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # Rewrite /app/* → /*  on the backend
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    # Rate limiting – 10 req/s per IP
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "20"
    # Force HTTPS redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # Client body size
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    # Custom NGINX snippet
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Custom-Header "hello" always;
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-example-com-tls      # kubectl create secret tls ...
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /app(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: my-app-svc
                port:
                  number: 80
          - path: /api(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: my-api-svc
                port:
                  number: 8080

---
# SSL passthrough (TLS handled by backend, not ingress)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ssl-passthrough-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tls-app-svc
                port:
                  number: 443
```

---

## Logging & Monitoring

```nginx
http {
    # Custom log format with timing and cache status
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" '
                        'rt=$request_time uct=$upstream_connect_time '
                        'uht=$upstream_header_time urt=$upstream_response_time '
                        'cs=$upstream_cache_status';

    access_log /var/log/nginx/access.log detailed;

    # Conditional logging – skip health check requests
    map $request_uri $loggable {
        ~^/health  0;
        default    1;
    }
    access_log /var/log/nginx/access.log detailed if=$loggable;

    server {
        # Stub status – exposes connection metrics at /nginx_status
        location /nginx_status {
            stub_status;
            allow 127.0.0.1;
            allow 10.0.0.0/8;
            deny  all;
        }
    }
}
```

```bash
# Error log levels: debug | info | notice | warn | error | crit | alert | emerg
error_log /var/log/nginx/error.log warn;

# Stream access log in real time
tail -f /var/log/nginx/access.log

# Count requests per status code
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Top 10 requesting IPs
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Average response time
awk -F'rt=' '{print $2}' /var/log/nginx/access.log | awk '{sum+=$1;cnt++} END{print sum/cnt}'

# NGINX Amplify agent install (cloud monitoring SaaS)
# curl https://amplify.nginx.com/install | API_KEY='<your-key>' sh
```

---

## Tips & Tricks

```nginx
# Useful built-in variables
# $host          – request Host header (lowercase)
# $uri           – request URI without args
# $args          – query string
# $request_uri   – full original URI including args
# $remote_addr   – client IP
# $scheme        – http or https
# $server_name   – matched server_name
# $upstream_addr – upstream server address used

# map directive – efficient conditional logic
map $http_user_agent $is_bot {
    default    0;
    ~*bot      1;
    ~*crawl    1;
    ~*spider   1;
}

server {
    if ($is_bot) {
        return 403;
    }
}

# Geo module – vary behaviour by country/IP block
geo $limit {
    default        0;
    10.0.0.0/8     1;   # internal network
    192.168.0.0/16 1;
}

# HTTP/2 – just add http2 to listen directive
listen 443 ssl;
http2  on;   # nginx >= 1.25.1

# Enable gzip compression
gzip              on;
gzip_comp_level   5;
gzip_min_length   256;
gzip_proxied      any;
gzip_types        text/plain text/css application/json application/javascript
                  application/xml text/xml image/svg+xml;
```

```bash
# Dump full merged nginx configuration (great for debugging includes)
sudo nginx -T

# Test config and show which file/line has an error
sudo nginx -t

# Validate nginx.conf in CI (Docker-based)
docker run --rm \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine nginx -t

# Generate htpasswd entry (openssl)
printf "admin:$(openssl passwd -apr1 'MySecret')\n" | sudo tee /etc/nginx/.htpasswd

# Quick benchmark with wrk
wrk -t4 -c100 -d30s http://localhost/

# Common error fixes
# 413 Request Entity Too Large   → increase client_max_body_size
# 502 Bad Gateway                → upstream app not running / wrong port
# 504 Gateway Timeout            → increase proxy_read_timeout
# 431 Request Header Too Large   → increase large_client_header_buffers

large_client_header_buffers 4 16k;   # fix for 431 errors

# Rotate logs without restart
sudo nginx -s reopen
# or use logrotate with: postrotate kill -USR1 $(cat /var/run/nginx.pid); endscript
```
