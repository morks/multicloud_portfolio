# HAProxy Cheat Sheet

## Installation & Setup

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y haproxy

# RHEL / CentOS / Fedora
sudo yum install -y haproxy      # CentOS 7
sudo dnf install -y haproxy      # CentOS 8+ / Fedora

# macOS via Homebrew
brew install haproxy

# Check installed version (shows compile-time options)
haproxy -v
haproxy -vv                      # verbose: all options and limits

# systemctl lifecycle commands
sudo systemctl start   haproxy
sudo systemctl stop    haproxy
sudo systemctl reload  haproxy   # graceful reload – zero downtime
sudo systemctl restart haproxy
sudo systemctl enable  haproxy   # start on boot
sudo systemctl status  haproxy

# Test / validate configuration file before applying
haproxy -c -f /etc/haproxy/haproxy.cfg

# Test alternate config (useful before live reload)
haproxy -c -f /etc/haproxy/haproxy.cfg.new

# Default config file location
# /etc/haproxy/haproxy.cfg

# Default log location (syslog → rsyslog)
# /var/log/haproxy.log
```

---

## Configuration Structure

```haproxy
#---------------------------------------------------------------------
# global – process-wide settings (run once at startup)
#---------------------------------------------------------------------
global
    log         /dev/log  local0          # send logs to syslog
    log         /dev/log  local1 notice
    chroot      /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user  haproxy
    group haproxy
    daemon

    # Performance tuning
    maxconn        50000                  # max total connections
    nbthread       4                      # worker threads (CPUs)
    cpu-map        auto:1/1-4 0-3         # pin threads to CPUs

#---------------------------------------------------------------------
# defaults – inherited by all frontends and backends
#---------------------------------------------------------------------
defaults
    log     global
    mode    http                          # http or tcp
    option  httplog                       # structured HTTP log lines
    option  dontlognull                   # skip logging empty connections
    option  forwardfor                    # add X-Forwarded-For header
    option  http-server-close             # reset server connection after each req
    option  redispatch                    # retry on a different server on failure

    timeout connect  5s                   # time to establish connection to backend
    timeout client   30s                  # max inactivity time on client side
    timeout server   30s                  # max inactivity time on server side
    timeout http-request  10s             # max time to receive full HTTP request
    timeout http-keep-alive 2s            # keep-alive idle timeout
    timeout queue    1m                   # max wait time in queue when maxconn reached
    timeout tunnel   1h                   # for WebSocket / TCP tunnels

    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 503 /etc/haproxy/errors/503.http

#---------------------------------------------------------------------
# frontend – listens for client connections
#---------------------------------------------------------------------
frontend fe_http
    bind *:80
    default_backend be_app

#---------------------------------------------------------------------
# backend – defines server pool and load-balancing policy
#---------------------------------------------------------------------
backend be_app
    balance roundrobin
    option  httpchk GET /health
    server  app1 10.0.1.10:8080 check
    server  app2 10.0.1.11:8080 check

#---------------------------------------------------------------------
# listen – combined frontend + backend (convenient for TCP services)
#---------------------------------------------------------------------
listen mysql_cluster
    bind *:3306
    mode tcp
    balance leastconn
    server db1 10.0.2.10:3306 check
    server db2 10.0.2.11:3306 check
```

---

## Frontend

```haproxy
frontend fe_main
    # Bind on all interfaces, port 80
    bind *:80

    # Bind on specific IP
    bind 203.0.113.10:80

    # Bind with SSL/TLS (certificate bundle)
    bind *:443 ssl crt /etc/haproxy/certs/example.com.pem alpn h2,http/1.1

    # Bind on IPv6
    bind :::80 v4v6                       # dual-stack: also accepts IPv4

    # Define ACLs
    acl is_api     path_beg   /api/
    acl is_static  path_end   .jpg .png .css .js
    acl is_mobile  hdr_sub(User-Agent) -i Mobile

    # Route based on ACLs
    use_backend  be_api     if is_api
    use_backend  be_static  if is_static

    # Fallback backend
    default_backend be_web

    # HTTP request rules
    http-request redirect scheme https  if !{ ssl_fc }        # force HTTPS
    http-request set-header X-Forwarded-Proto https            if { ssl_fc }
    http-request deny                   if { src 10.0.99.0/24 } # block subnet

    # Capture request header for logging
    http-request capture req.hdr(User-Agent) len 100

    # Capture cookie value for logging
    http-request capture cookie session_id len 32
```

---

## Backend

```haproxy
backend be_web
    balance roundrobin

    # Health check: HTTP GET /health, expect 200
    option httpchk GET /health HTTP/1.1\r\nHost:\ example.com

    # Cookie-based session persistence
    cookie SERVERID insert nocache indirect

    server web1 10.0.1.10:8080 check weight 3 cookie web1
    server web2 10.0.1.11:8080 check weight 2 cookie web2
    server web3 10.0.1.12:8080 check weight 1 cookie web3 backup

    # Server template – creates web4..web10 dynamically
    server-template web 4-10 10.0.1.0:8080 check

backend be_api
    balance leastconn
    option  httpchk GET /api/health
    http-check expect status 200

    server api1 10.0.2.10:8080 check inter 5s fall 3 rise 2
    server api2 10.0.2.11:8080 check inter 5s fall 3 rise 2

backend be_static
    balance uri                           # same URI always goes to same server
    server cdn1 10.0.3.10:80 check
    server cdn2 10.0.3.11:80 check

backend be_db
    mode tcp
    balance source                        # IP hash – sticky for DB connections
    server db1 10.0.4.10:5432 check
    server db2 10.0.4.11:5432 check
```

---

## Load Balancing Algorithms

```haproxy
# roundrobin – requests distributed evenly (default, weight-aware)
# Best for: stateless apps with homogeneous servers
backend be_roundrobin
    balance roundrobin
    server s1 10.0.1.10:80 check weight 2   # gets 2x the requests
    server s2 10.0.1.11:80 check weight 1

# leastconn – new connection goes to server with fewest active connections
# Best for: long-lived connections (DB, WebSocket, file downloads)
backend be_leastconn
    balance leastconn
    server s1 10.0.1.10:80 check
    server s2 10.0.1.11:80 check

# source – IP hash; same client IP always hits same server
# Best for: apps without shared session store
backend be_source
    balance source
    hash-type consistent                  # consistent hashing – fewer remaps on change
    server s1 10.0.1.10:80 check
    server s2 10.0.1.11:80 check

# uri – hash on the request URI (path + query)
# Best for: cache servers – same URL always hits same cache node
backend be_uri
    balance uri
    hash-type consistent
    server cache1 10.0.1.10:80 check
    server cache2 10.0.1.11:80 check

# url_param – hash on a specific query parameter
# Best for: sharding by customer_id, user_id, etc.
backend be_url_param
    balance url_param customer_id
    server s1 10.0.1.10:80 check
    server s2 10.0.1.11:80 check

# hdr – hash on a specific request header value
# Best for: routing by API key, tenant, or custom shard header
backend be_hdr
    balance hdr(X-Tenant-ID)
    server s1 10.0.1.10:80 check
    server s2 10.0.1.11:80 check

# random – random server selection (scales better than roundrobin for very large pools)
backend be_random
    balance random
    server s1 10.0.1.10:80 check
    server s2 10.0.1.11:80 check
    server s3 10.0.1.12:80 check

# first – use first available server until maxconn; then overflow to next
# Best for: conserving resources, scale-down scenarios
backend be_first
    balance first
    maxconn 100
    server s1 10.0.1.10:80 check maxconn 100
    server s2 10.0.1.11:80 check maxconn 100
```

---

## Health Checks

```haproxy
backend be_app
    # HTTP health check (default: TCP check if option httpchk not set)
    option httpchk GET /health HTTP/1.1\r\nHost:\ example.com
    http-check expect status 200        # pass only if 200 returned

    # Timing: check every 3s, fail after 3 bad checks, recover after 2 good
    server app1 10.0.1.10:8080 check inter 3s fall 3 rise 2
    server app2 10.0.1.11:8080 check inter 3s fall 3 rise 2

backend be_tcp
    # TCP check – just verify port is open
    option tcp-check
    tcp-check connect
    server db1 10.0.2.10:5432 check inter 5s fall 2 rise 3

backend be_redis
    # TCP check with protocol exchange
    option tcp-check
    tcp-check connect
    tcp-check send PING\r\n
    tcp-check expect string +PONG
    server redis1 10.0.3.10:6379 check

backend be_agent
    # Agent check – backend server reports its own weight/status
    # Server runs a small TCP daemon on port 9000 responding with "100%\n"
    server app1 10.0.1.10:8080 check agent-check agent-port 9000 agent-inter 5s
```

```bash
# View health status via runtime API
echo "show health" | sudo socat stdio /run/haproxy/admin.sock

# Show server states
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
```

---

## SSL/TLS Termination

```haproxy
global
    # Modern TLS defaults (applied to all binds unless overridden)
    ssl-default-bind-options   prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11
    ssl-default-bind-ciphers   ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    tune.ssl.default-dh-param  2048

frontend fe_https
    bind *:443 ssl crt /etc/haproxy/certs/example.com.pem alpn h2,http/1.1
    # /etc/haproxy/certs/example.com.pem = fullchain.pem + privkey.pem concatenated:
    #   cat fullchain.pem privkey.pem > /etc/haproxy/certs/example.com.pem

    # HSTS
    http-response set-header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"

    # OCSP stapling
    bind *:443 ssl crt /etc/haproxy/certs/ ca-file /etc/ssl/ca-bundle.crt verify optional crl-file /etc/ssl/crl.pem

    default_backend be_app

frontend fe_http_redirect
    bind *:80
    # Redirect all HTTP → HTTPS
    http-request redirect scheme https code 301

# SSL passthrough – TLS is NOT terminated; raw TCP forwarded to backend
frontend fe_passthrough
    bind *:8443
    mode tcp
    option tcplog
    default_backend be_tls_app

backend be_tls_app
    mode tcp
    balance source
    server tls1 10.0.1.10:8443 check
    server tls2 10.0.1.11:8443 check
```

```bash
# Create PEM bundle from Let's Encrypt (Certbot)
cat /etc/letsencrypt/live/example.com/fullchain.pem \
    /etc/letsencrypt/live/example.com/privkey.pem \
    > /etc/haproxy/certs/example.com.pem
chmod 600 /etc/haproxy/certs/example.com.pem

# Reload HAProxy to pick up renewed certificate
sudo systemctl reload haproxy
```

---

## ACLs & Content Switching

```haproxy
frontend fe_main
    bind *:80
    bind *:443 ssl crt /etc/haproxy/certs/example.com.pem

    # ── ACL definitions ────────────────────────────────────────────
    # Path-based routing
    acl is_api        path_beg          /api/
    acl is_v2         path_beg          /v2/
    acl is_static     path_end          .jpg .jpeg .png .gif .ico .svg .css .js .woff2

    # Host-based routing
    acl host_app      hdr(host)    -i  app.example.com
    acl host_admin    hdr(host)    -i  admin.example.com

    # Method-based
    acl is_post       method            POST
    acl is_get        method            GET

    # Source IP
    acl is_internal   src               10.0.0.0/8 192.168.0.0/16

    # Header matching
    acl has_api_key   req.hdr(X-API-Key) -m found
    acl json_request  req.hdr(Content-Type) -i application/json

    # ── Combining ACLs ─────────────────────────────────────────────
    # AND: both conditions must be true (default when multiple acl on same use_backend line)
    use_backend be_api_write  if is_api is_post

    # OR: either condition sufficient
    use_backend be_media      if is_static || host_app

    # NOT: negate
    http-request deny         if !is_internal !has_api_key

    # ── Content-based routing ──────────────────────────────────────
    use_backend be_api        if is_api
    use_backend be_v2         if is_v2
    use_backend be_static_cdn if is_static
    use_backend be_admin      if host_admin is_internal

    default_backend be_web

backend be_api
    balance leastconn
    server api1 10.0.2.10:8080 check
    server api2 10.0.2.11:8080 check

backend be_static_cdn
    balance uri
    server cdn1 10.0.3.10:80 check
    server cdn2 10.0.3.11:80 check

backend be_web
    balance roundrobin
    server web1 10.0.1.10:8080 check
    server web2 10.0.1.11:8080 check
```

---

## Runtime API (Stats Socket)

```bash
# Enable stats socket in global section
# stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
# stats timeout 30s

# General info and version
echo "show info"        | sudo socat stdio /run/haproxy/admin.sock

# All statistics (CSV format)
echo "show stat"        | sudo socat stdio /run/haproxy/admin.sock

# Pretty-print stat for a specific backend
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock \
  | cut -d',' -f1,2,5,7,18,19,48 | column -s, -t

# Active sessions
echo "show sess"        | sudo socat stdio /run/haproxy/admin.sock
echo "show sess age > 60" | sudo socat stdio /run/haproxy/admin.sock   # older than 60s

# Server management
echo "disable server be_app/app1"         | sudo socat stdio /run/haproxy/admin.sock
echo "enable  server be_app/app1"         | sudo socat stdio /run/haproxy/admin.sock

# Change server weight at runtime
echo "set weight be_app/app1 50"          | sudo socat stdio /run/haproxy/admin.sock

# Drain server (finish existing sessions, reject new)
echo "set server be_app/app1 state drain" | sudo socat stdio /run/haproxy/admin.sock

# Set server back to ready
echo "set server be_app/app1 state ready" | sudo socat stdio /run/haproxy/admin.sock

# Set server address at runtime
echo "set server be_app/app1 addr 10.0.1.20 port 8080" | sudo socat stdio /run/haproxy/admin.sock

# Kill a specific session by ID
echo "shutdown session 0x7f12345678"      | sudo socat stdio /run/haproxy/admin.sock

# Health check status
echo "show health"      | sudo socat stdio /run/haproxy/admin.sock

# Watch stats live (refresh every 2s)
watch -n2 'echo "show info" | socat stdio /run/haproxy/admin.sock | grep -E "^(Uptime|CurrConns|MaxConn|Requests)"'
```

---

## Stats Dashboard

```haproxy
# Enable the built-in HTML stats page
frontend fe_stats
    bind *:8404                           # listen on dedicated port
    mode http
    stats enable
    stats uri       /stats               # URL path: http://host:8404/stats
    stats realm     HAProxy\ Statistics
    stats auth      admin:SuperSecret    # Basic auth (user:password)
    stats refresh   5s                   # auto-refresh interval
    stats hide-version                   # don't expose HAProxy version
    stats show-legends                   # show column descriptions
    stats show-node                      # show hostname in title

    # Enable admin actions from browser (enable/disable servers)
    stats admin if TRUE

# Alternatively, define stats as a dedicated listen block
listen stats_page
    bind            *:8404
    mode            http
    stats           enable
    stats uri       /haproxy-stats
    stats realm     HAProxy\ Statistics
    stats auth      monitor:M0nitorPass!
    stats refresh   10s
    stats show-legends
    stats admin if LOCALHOST
    no log                               # don't log stats page polls
```

---

## Logging & Monitoring

```haproxy
global
    # Send logs to local rsyslog
    log 127.0.0.1:514 local0             # UDP syslog
    log /dev/log      local1 notice      # Unix socket

defaults
    log     global
    option  httplog                      # enable rich HTTP log line
    option  dontlognull                  # skip connections with no data

frontend fe_main
    bind *:80

    # Capture request headers into log
    http-request capture req.hdr(Host)          len 40
    http-request capture req.hdr(User-Agent)    len 100
    http-request capture req.hdr(Referer)       len 200

    # Capture response header
    http-response capture res.hdr(Content-Type) len 30

    # Custom log format
    log-format "%ci:%cp [%tr] %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta %ST %B %tsc %ac/%fc/%bc/%sc/%rc %{+Q}r"
    # %ci=client IP %cp=port %tr=request time %ft=frontend %b=backend %s=server
    # %TR=request read %Tw=queue wait %Tc=connect %Tr=response %Ta=total active
    # %ST=status %B=bytes %tsc=termination state
```

```bash
# rsyslog config to write HAProxy logs to dedicated file
# /etc/rsyslog.d/49-haproxy.conf:
#   $AddUnixListenSocket /dev/log
#   if $programname == 'haproxy' then /var/log/haproxy.log
#   & stop

# Reload rsyslog after config change
sudo systemctl restart rsyslog

# Stream HAProxy access logs live
tail -f /var/log/haproxy.log

# Top 10 client IPs
awk '{print $6}' /var/log/haproxy.log | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# Count HTTP status codes
grep -oP 'ST \K[0-9]+' /var/log/haproxy.log | sort | uniq -c | sort -rn

# Average total request time (Ta field)
grep -oP '%Ta=\K[0-9]+' /var/log/haproxy.log | awk '{s+=$1;c++} END{print s/c "ms avg"}'

# Prometheus exporter (haproxy_exporter)
# Binary: https://github.com/prometheus/haproxy_exporter
haproxy_exporter \
  --haproxy.scrape-uri="unix:/run/haproxy/admin.sock?stats" \
  --web.listen-address=":9101"

# Prometheus scrape config snippet
# scrape_configs:
#   - job_name: haproxy
#     static_configs:
#       - targets: ['localhost:9101']
```

---

## Tips & Tricks

```haproxy
#---------------------------------------------------------------------
# Graceful reload (zero downtime)
# HAProxy opens new sockets, drains old connections, then exits old process
#---------------------------------------------------------------------
# sudo systemctl reload haproxy
# Under the hood: haproxy -sf $(cat /var/run/haproxy.pid)

#---------------------------------------------------------------------
# Stick tables – session persistence without cookies
#---------------------------------------------------------------------
backend be_app
    stick-table type ip size 100k expire 30m
    stick on src                          # pin client IP to server for 30 min
    server app1 10.0.1.10:8080 check
    server app2 10.0.1.11:8080 check

#---------------------------------------------------------------------
# Slowloris protection – limit request read time
#---------------------------------------------------------------------
defaults
    timeout http-request 10s             # max time to receive full HTTP request headers

#---------------------------------------------------------------------
# Retry failed requests on a different server
#---------------------------------------------------------------------
defaults
    option redispatch                    # retry on new server if connection fails
    retries 3                            # attempt 3 times before error

#---------------------------------------------------------------------
# Abort connection when client disconnects mid-request
#---------------------------------------------------------------------
defaults
    option  abortonclose                 # useful for queued requests

#---------------------------------------------------------------------
# HTTP compression
#---------------------------------------------------------------------
frontend fe_main
    bind *:80
    compression algo gzip
    compression type text/html text/plain text/css application/json application/javascript

#---------------------------------------------------------------------
# HTTP/2 support (HAProxy 1.8+)
#---------------------------------------------------------------------
frontend fe_https
    bind *:443 ssl crt /etc/haproxy/certs/example.com.pem alpn h2,http/1.1

#---------------------------------------------------------------------
# PROXY protocol – pass original client IP to backend over TCP
#---------------------------------------------------------------------
backend be_app
    server app1 10.0.1.10:8080 check send-proxy-v2

frontend fe_from_lb
    bind *:8080 accept-proxy              # receive PROXY protocol header

#---------------------------------------------------------------------
# Multi-thread configuration (HAProxy 1.8+)
# Preferred over multi-process (nbproc) since HAProxy 2.x
#---------------------------------------------------------------------
global
    nbthread   8
    cpu-map    auto:1/1-8 0-7

#---------------------------------------------------------------------
# maxqueue – cap the connection queue per backend
#---------------------------------------------------------------------
backend be_app
    maxconn  200                         # max concurrent connections
    # queue is unlimited by default; cap it to avoid memory pressure
    server app1 10.0.1.10:8080 check maxconn 100 maxqueue 50

#---------------------------------------------------------------------
# Keep-alive to backends
#---------------------------------------------------------------------
backend be_app
    option http-server-close              # reset per request (default safe choice)
    # option http-keep-alive             # persistent connection to server

#---------------------------------------------------------------------
# Dynamic certificate loading (HAProxy 2.2+)
# Drop a new PEM into /etc/haproxy/certs/ and run:
#---------------------------------------------------------------------
# echo "add ssl crt-list /etc/haproxy/certs.lst <<\n/etc/haproxy/certs/new.pem\n" \
#   | socat stdio /run/haproxy/admin.sock

#---------------------------------------------------------------------
# Health-check timeout tuning
#---------------------------------------------------------------------
backend be_slow_app
    timeout check 5s                     # override default check timeout
    server app1 10.0.1.10:8080 check inter 10s fall 5 rise 2
```
