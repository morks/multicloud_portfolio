# Cloudflare Cheat Sheet (flarectl & wrangler)

## Installation & Setup

```bash
# Install wrangler (Cloudflare Workers CLI) globally via npm
npm install -g wrangler

# Install flarectl (Cloudflare DNS/Zone management CLI) via Homebrew
brew install cloudflare/cloudflare/flarectl

# Check versions
wrangler --version
flarectl --version

# Authenticate wrangler (opens browser → OAuth)
wrangler login

# Check current wrangler identity
wrangler whoami

# Set flarectl environment variables (add to ~/.zshrc or ~/.bashrc)
export CF_API_TOKEN="your-api-token-here"
export CF_API_EMAIL="you@example.com"

# Alternatively use Global API Key (less recommended)
export CF_API_KEY="your-global-api-key"

# Verify flarectl authentication
flarectl user info

# Generate a scoped API token via dashboard
# → https://dash.cloudflare.com/profile/api-tokens
```

---

## DNS Records (flarectl)

```bash
# List all zones (domains) in the account
flarectl zone list

# Show details for a specific zone
flarectl zone info --zone my-zone.com

# List all DNS records for a zone
flarectl dns list --zone my-zone.com

# Create an A record (proxied through Cloudflare CDN)
flarectl dns create --zone my-zone.com \
  --name www \
  --type A \
  --content 203.0.113.10 \
  --proxy

# Create an A record (DNS-only, no proxy)
flarectl dns create --zone my-zone.com \
  --name api \
  --type A \
  --content 203.0.113.20

# Create a CNAME record (proxied)
flarectl dns create --zone my-zone.com \
  --name shop \
  --type CNAME \
  --content my-shop.myshopify.com \
  --proxy

# Create an MX record
flarectl dns create --zone my-zone.com \
  --name my-zone.com \
  --type MX \
  --content mail.my-zone.com \
  --priority 10

# Create a TXT record (e.g. SPF or domain verification)
flarectl dns create --zone my-zone.com \
  --name my-zone.com \
  --type TXT \
  --content "v=spf1 include:_spf.google.com ~all"

# Update an existing DNS record by ID
flarectl dns update --zone my-zone.com \
  --id <record-id> \
  --content 203.0.113.99 \
  --proxy

# Delete a DNS record by ID
flarectl dns delete --zone my-zone.com --id <record-id>

# List records and grep for a specific hostname
flarectl dns list --zone my-zone.com | grep www
```

---

## DNS Records (Cloudflare API via curl)

```bash
# Set variables for convenience
export CF_API_TOKEN="your-api-token-here"
export CF_ZONE_ID="your-zone-id-here"   # find in zone dashboard → Overview

# List all DNS records for a zone
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | jq '.result[] | {id, name, type, content}'

# Create an A record via API
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "staging",
    "content": "203.0.113.50",
    "ttl": 120,
    "proxied": false
  }'

# Create a proxied CNAME record via API
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "blog",
    "content": "my-blog.netlify.app",
    "proxied": true
  }'

# Delete a DNS record by ID
export RECORD_ID="your-record-id"
curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}"

# Get zone ID for a domain name
curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=my-zone.com" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[0].id'
```

---

## Workers (wrangler)

```bash
# Initialize a new Worker project
wrangler init my-worker

# Start local development server (hot reload)
wrangler dev

# Deploy Worker to Cloudflare's network
wrangler deploy

# Deploy to a specific environment
wrangler deploy --env production

# Stream live logs from a deployed Worker
wrangler tail my-worker

# Stream logs from a specific environment
wrangler tail my-worker --env production

# List all Workers in the account
wrangler deployments list

# Delete a Worker
wrangler delete my-worker

# --- Secrets ---

# Add / update a secret (prompted for value)
wrangler secret put MY_API_KEY

# List all secrets for a Worker
wrangler secret list

# Delete a secret
wrangler secret delete MY_API_KEY

# --- KV Namespaces ---

# Create a KV namespace
wrangler kv namespace create my-kv-store

# List all KV namespaces
wrangler kv namespace list

# Put a value into KV
wrangler kv key put --namespace-id <namespace-id> "my-key" "my-value"

# Get a value from KV
wrangler kv key get --namespace-id <namespace-id> "my-key"

# List keys in a KV namespace
wrangler kv key list --namespace-id <namespace-id>

# Delete a key from KV
wrangler kv key delete --namespace-id <namespace-id> "my-key"

# Delete a KV namespace
wrangler kv namespace delete --namespace-id <namespace-id>

# --- R2 Buckets (via wrangler) ---

# Create an R2 bucket
wrangler r2 bucket create my-bucket

# List all R2 buckets
wrangler r2 bucket list

# Delete an R2 bucket
wrangler r2 bucket delete my-bucket

# Upload a file to R2
wrangler r2 object put my-bucket/path/to/file.txt --file ./local-file.txt

# Download a file from R2
wrangler r2 object get my-bucket/path/to/file.txt --file ./downloaded-file.txt

# Delete an object from R2
wrangler r2 object delete my-bucket/path/to/file.txt
```

---

## Pages

```bash
# Create a new Cloudflare Pages project
wrangler pages project create my-pages-site

# Deploy a local build directory to Pages
wrangler pages deploy ./dist --project-name my-pages-site

# Deploy with a specific branch (creates preview deployment)
wrangler pages deploy ./dist --project-name my-pages-site --branch feature/my-feature

# List all Pages projects
wrangler pages project list

# List all deployments for a project
wrangler pages deployment list --project-name my-pages-site

# Tail live logs for a Pages deployment
wrangler pages deployment tail --project-name my-pages-site

# Add a custom domain to a Pages project (via dashboard or API)
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/pages/projects/my-pages-site/domains" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"name": "www.my-zone.com"}'

# List custom domains for a Pages project
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/pages/projects/my-pages-site/domains" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[].name'
```

---

## R2 Object Storage

```bash
# Create an R2 bucket
wrangler r2 bucket create my-bucket

# Create a bucket in the EU jurisdiction (data residency)
wrangler r2 bucket create my-eu-bucket --jurisdiction eu

# List all R2 buckets
wrangler r2 bucket list

# Delete an R2 bucket (must be empty)
wrangler r2 bucket delete my-bucket

# Upload an object
wrangler r2 object put my-bucket/images/logo.png --file ./logo.png

# Upload with custom content type
wrangler r2 object put my-bucket/data/report.json \
  --file ./report.json \
  --content-type application/json

# Download an object
wrangler r2 object get my-bucket/images/logo.png --file ./logo-download.png

# Delete an object
wrangler r2 object delete my-bucket/images/logo.png

# Set CORS configuration for a bucket via API
curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/r2/buckets/my-bucket/cors" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "rules": [{
      "allowedOrigins": ["https://my-zone.com"],
      "allowedMethods": ["GET", "HEAD"],
      "allowedHeaders": ["*"],
      "maxAgeSeconds": 3600
    }]
  }'

# Get CORS configuration for a bucket
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/r2/buckets/my-bucket/cors" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq .
```

---

## Zero Trust / Tunnel

```bash
# Install cloudflared (Cloudflare Tunnel daemon)
brew install cloudflare/cloudflare/cloudflared

# Authenticate cloudflared with your Cloudflare account
cloudflared tunnel login

# Create a new tunnel
cloudflared tunnel create my-tunnel

# List all tunnels
cloudflared tunnel list

# Route DNS to a tunnel (creates a CNAME in your zone)
cloudflared tunnel route dns my-tunnel app.my-zone.com

# Run a tunnel (connects the local service to Cloudflare)
cloudflared tunnel run my-tunnel

# Run a tunnel with inline ingress (no config file)
cloudflared tunnel --url http://localhost:3000 run my-tunnel

# Delete a tunnel
cloudflared tunnel delete my-tunnel

# --- Tunnel config file example (~/.cloudflared/config.yml) ---
# tunnel: <tunnel-id>
# credentials-file: /home/user/.cloudflared/<tunnel-id>.json
#
# ingress:
#   - hostname: app.my-zone.com
#     service: http://localhost:3000
#   - hostname: api.my-zone.com
#     service: http://localhost:8080
#   - service: http_status:404
# ---------------------------------------------------------------

# Run tunnel using config file
cloudflared tunnel --config ~/.cloudflared/config.yml run

# --- Cloudflare Access ---

# List Access applications (via API)
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/apps" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[] | {id, name, domain}'

# Create an Access application protecting a hostname
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/apps" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "Internal Dashboard",
    "domain": "dashboard.my-zone.com",
    "type": "self_hosted",
    "session_duration": "8h"
  }'

# Generate a cloudflared access token for a protected app
cloudflared access token --app-url https://dashboard.my-zone.com
```

---

## SSL/TLS & Security

```bash
# Get current SSL/TLS mode for a zone via API
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/ssl" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result.value'

# Set SSL/TLS mode (off | flexible | full | strict)
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/ssl" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": "strict"}'

# Enable Always Use HTTPS redirect
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/always_use_https" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": "on"}'

# Enable HSTS (HTTP Strict Transport Security)
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_header" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "value": {
      "strict_transport_security": {
        "enabled": true,
        "max_age": 31536000,
        "include_subdomains": true,
        "preload": true
      }
    }
  }'

# Enable minimum TLS version (1.2 recommended)
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/min_tls_version" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": "1.2"}'

# Create a WAF firewall rule (block a country, e.g. block CN)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/firewall/rules" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '[{
    "filter": {
      "expression": "(ip.geoip.country eq \"CN\")",
      "paused": false
    },
    "action": "block",
    "description": "Block traffic from CN"
  }]'

# List existing firewall rules
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/firewall/rules" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[] | {id, description, action}'

# Enable Bot Fight Mode
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/bot_management" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"fight_mode": true}'
```

---

## Cache & Performance

```bash
# Purge entire zone cache (all cached content)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything": true}'

# Purge specific URLs from cache
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "files": [
      "https://my-zone.com/images/hero.jpg",
      "https://my-zone.com/css/style.css"
    ]
  }'

# Purge by cache tag (requires Enterprise plan)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"tags": ["product-images", "homepage"]}'

# Set caching level (aggressive | basic | simplified)
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/cache_level" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": "aggressive"}'

# Set browser cache TTL (in seconds, 0 = respect existing headers)
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/browser_cache_ttl" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": 14400}'

# Enable Auto Minify for JS, CSS, HTML
curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/minify" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value": {"css": "on", "html": "on", "js": "on"}}'

# Create a Page Rule (redirect example)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/pagerules" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "targets": [{"target": "url", "constraint": {"operator": "matches", "value": "http://my-zone.com/*"}}],
    "actions": [{"id": "always_use_https"}],
    "status": "active",
    "priority": 1
  }'

# List all page rules
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/pagerules?status=active" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[] | {id, status, targets, actions}'
```

---

## Account & Zone Management (flarectl)

```bash
# List all zones (domains) under the account
flarectl zone list

# Show detailed info for a specific zone
flarectl zone info --zone my-zone.com

# List all accounts accessible to the token
flarectl user memberships

# Show currently authenticated user
flarectl user info

# Enable Cloudflare proxy on a DNS record (orange cloud)
# → Use flarectl dns update with --proxy flag (see DNS section above)

# Disable proxy on a DNS record (grey cloud / DNS-only)
flarectl dns update --zone my-zone.com --id <record-id> --content 203.0.113.10

# Purge all cache for a zone via flarectl
flarectl zone cache-purge --zone my-zone.com --everything

# Get zone analytics overview via API
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/analytics/dashboard?since=-1440&until=0" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result.totals'

# List all WAF packages for a zone
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/firewall/waf/packages" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq '.result[] | {id, name}'

# Check zone activation status
flarectl zone list | grep my-zone.com
```

---

## Tips & Tricks

```bash
# Store common IDs as environment variables to avoid repetition
export CF_ZONE_ID="$(curl -s "https://api.cloudflare.com/client/v4/zones?name=my-zone.com" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq -r '.result[0].id')"
export CF_ACCOUNT_ID="$(curl -s "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" | jq -r '.result[0].id')"

# Bulk DNS import via CSV file (BIND zone file format)
# Create a file named my-zone.com.txt in BIND format, then import:
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/import" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -F "file=@my-zone.com.txt" \
  -F 'proxied=false'

# Export DNS records as BIND zone file
curl -s "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/export" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" > my-zone.com.txt

# Use Terraform Cloudflare provider for IaC
# → Provider: registry.terraform.io/providers/cloudflare/cloudflare
# → Key resources: cloudflare_zone, cloudflare_record, cloudflare_worker_script,
#                  cloudflare_tunnel, cloudflare_access_application
# terraform {
#   required_providers {
#     cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.0" }
#   }
# }

# Retrieve Cloudflare's IP ranges (useful for firewall allowlists)
curl -s https://api.cloudflare.com/client/v4/ips | jq '.result | {ipv4_cidrs, ipv6_cidrs}'

# Add rate limiting rule via API (max 100 requests/minute per IP to /api/*)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/rate_limits" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "match": {
      "request": {"methods": ["GET","POST"], "url_pattern": "my-zone.com/api/*"}
    },
    "threshold": 100,
    "period": 60,
    "action": {"mode": "ban", "timeout": 600}
  }'

# Test a Worker locally with a custom binding
wrangler dev --local --port 8787

# Run wrangler commands without browser login (CI/CD)
# → Set CLOUDFLARE_API_TOKEN env var instead of running wrangler login
export CLOUDFLARE_API_TOKEN="your-api-token-here"
wrangler deploy

# Check Cloudflare system status
curl -s https://www.cloudflarestatus.com/api/v2/status.json | jq '.status.description'
```
