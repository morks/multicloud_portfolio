# ZITADEL Cheat Sheet

## Overview

**ZITADEL** is a cloud-native, open-source IAM platform built for multi-tenancy, API-first usage, and modern SaaS architectures.

| | |
|---|---|
| **Strengths** | Multi-org/tenant by design · API-first (gRPC + REST) · Actions for dynamic auth logic (TypeScript) · cloud-native architecture (CockroachDB/PostgreSQL) · self-hosted or ZITADEL Cloud |
| **Weaknesses** | Younger ecosystem than Keycloak · fewer enterprise integrations · smaller community · ZITADEL Cloud pricing can add up |
| **Best for** | SaaS platforms with multi-tenant requirements, API-driven authentication, modern cloud-native applications, teams preferring code-first IAM configuration |

---

## Installation & Setup

```bash
# Docker Compose – quickstart (in-memory DB, not for production)
curl -LO https://raw.githubusercontent.com/zitadel/zitadel/main/docs/docs/self-hosting/deploy/docker-compose.yaml
docker compose up -d

# Docker Compose – production with PostgreSQL
curl -LO https://raw.githubusercontent.com/zitadel/zitadel/main/docs/docs/self-hosting/deploy/docker-compose-postgres.yaml
docker compose -f docker-compose-postgres.yaml up -d

# Helm
helm repo add zitadel https://charts.zitadel.com
helm install zitadel zitadel/zitadel \
  --namespace zitadel \
  --create-namespace \
  -f values.yaml           # see https://github.com/zitadel/zitadel-charts

# Binary – init + start
wget https://github.com/zitadel/zitadel/releases/latest/download/zitadel-linux-amd64.tar.gz
tar -xzf zitadel-linux-amd64.tar.gz
./zitadel start-from-init --masterkey "MasterkeyNeedsToHave32Characters"

# Verify ZITADEL is running
curl http://localhost:8080/debug/healthz

# Access console UI
open http://localhost:8080/ui/console
# Default admin: zitadel-admin@zitadel.localhost / Password1!
```

---

## zitadel CLI

```bash
# Install zitadel CLI (separate tool: zitadel-tools or API calls via curl)
# Most management is done via REST/gRPC API or the Console UI
# Below shows curl patterns using a Personal Access Token (PAT)

export ZITADEL_DOMAIN="https://zitadel.example.com"
export PAT="your-personal-access-token"

# List organizations
curl -s -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/orgs" | jq .

# Create organization
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Org"}' \
  "$ZITADEL_DOMAIN/admin/v1/orgs" | jq .

# List users in org
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/management/v1/users/_search" | jq '.result[]|{id,userName,state}'

# List projects
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/management/v1/projects/_search" | jq .

# Create project
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Project","projectRoleAssertion":true,"projectRoleCheck":true}' \
  "$ZITADEL_DOMAIN/management/v1/projects" | jq .
```

---

## Organizations & Projects

```bash
# ZITADEL hierarchy: Instance → Organizations → Projects → Apps
# An org can own multiple projects; projects contain applications and roles.

# Get current organization details
curl -s -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/orgs/me" | jq .

# Grant a project to another org (project grant)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d "{\"grantedOrgId\":\"ORG_ID\",\"roleKeys\":[\"reader\"]}" \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/grants" | jq .

# List project grants
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/grants/_search" | jq .

# Register a Web application (OIDC)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Web App",
    "oidcConfig": {
      "responseTypes": ["OIDC_RESPONSE_TYPE_CODE"],
      "grantTypes": ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"],
      "appType": "OIDC_APP_TYPE_WEB",
      "authMethodType": "OIDC_AUTH_METHOD_TYPE_BASIC",
      "redirectUris": ["https://app.example.com/callback"],
      "postLogoutRedirectUris": ["https://app.example.com"]
    }
  }' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/apps/oidc" | jq .

# Register machine / API application
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-service","authMethodType":"API_AUTH_METHOD_TYPE_PRIVATE_KEY_JWT"}' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/apps/api" | jq .
```

---

## Users & Authentication

```bash
# Create human user
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "alice",
    "profile": {"firstName":"Alice","lastName":"Smith","displayName":"Alice Smith"},
    "email": {"email":"alice@example.com","isEmailVerified":true},
    "password": {"password":"SecurePass1!","passwordChangeRequired":false}
  }' \
  "$ZITADEL_DOMAIN/management/v1/users/human" | jq .

# Create machine user (service account)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"userName":"my-service-account","name":"My Service Account","accessTokenType":"ACCESS_TOKEN_TYPE_JWT"}' \
  "$ZITADEL_DOMAIN/management/v1/users/machine" | jq .

# Create Personal Access Token (PAT) for machine user
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"expirationDate":"2025-12-31T00:00:00Z"}' \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID/pats" | jq .

# Create service user key (for JWT profile auth)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"type":"KEY_TYPE_JSON","expirationDate":"2025-12-31T00:00:00Z"}' \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID/keys" | jq .

# Deactivate user
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID/_deactivate"

# Delete user
curl -s -X DELETE \
  -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID"
```

---

## Applications & OIDC

```bash
# Get OIDC application config
curl -s -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/apps/APP_ID/oidc" | jq .

# Update redirect URIs
curl -s -X PUT \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{
    "redirectUris":["https://app.example.com/callback","https://app.example.com/silent"],
    "responseTypes":["OIDC_RESPONSE_TYPE_CODE"],
    "grantTypes":["OIDC_GRANT_TYPE_AUTHORIZATION_CODE","OIDC_GRANT_TYPE_REFRESH_TOKEN"],
    "appType":"OIDC_APP_TYPE_WEB",
    "authMethodType":"OIDC_AUTH_METHOD_TYPE_BASIC",
    "postLogoutRedirectUris":["https://app.example.com"]
  }' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/apps/APP_ID/oidc" | jq .

# Regenerate client secret
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/apps/APP_ID/oidc/_reset_client_secret" | jq .

# Token exchange via client_credentials (machine user)
curl -s -X POST "$ZITADEL_DOMAIN/oauth/v2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=CLIENT_ID" \
  -d "client_secret=CLIENT_SECRET" \
  -d "scope=openid profile email" | jq .

# Introspect a token
curl -s -X POST "$ZITADEL_DOMAIN/oauth/v2/introspect" \
  -u "CLIENT_ID:CLIENT_SECRET" \
  -d "token=ACCESS_TOKEN" | jq .

# OpenID Connect discovery
curl -s "$ZITADEL_DOMAIN/.well-known/openid-configuration" | jq .

# UserInfo endpoint
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  "$ZITADEL_DOMAIN/oidc/v1/userinfo" | jq .
```

---

## Roles & Authorizations

```bash
# Add project role
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"roleKey":"editor","displayName":"Editor","group":"content"}' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/roles" | jq .

# List project roles
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/management/v1/projects/PROJECT_ID/roles/_search" | jq .

# Assign project role to user (user grant)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":\"USER_ID\",\"projectId\":\"PROJECT_ID\",\"roleKeys\":[\"editor\"]}" \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID/grants" | jq .

# List user grants
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/management/v1/users/USER_ID/grants/_search" | jq .

# Assign org-level IAM role (instance admin roles: IAM_OWNER, ORG_OWNER, etc.)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"userId":"USER_ID","roles":["ORG_OWNER"]}' \
  "$ZITADEL_DOMAIN/management/v1/orgs/me/members" | jq .
```

---

## Actions (Workflows)

```javascript
// ZITADEL Actions: server-side scripts that run during auth flows
// Written in JavaScript (ES5), configured via Console or API

// Example: Post-authentication action – add custom claim to token
function setClaim(ctx, api) {
  // ctx.v1.user contains user info
  if (ctx.v1.user.metadataList) {
    var dept = ctx.v1.user.metadataList.find(function(m) {
      return m.key === "department";
    });
    if (dept) {
      api.v1.claims.setClaim("department", dept.value);
    }
  }
}

// Example: Call external HTTP service in action
function enrichUser(ctx, api) {
  var resp = http.fetch("https://api.example.com/roles/" + ctx.v1.user.id, {
    method: "GET",
    headers: { "Authorization": "Bearer " + metadata.serviceToken }
  });
  if (resp.status === 200) {
    var data = resp.json();
    api.v1.claims.setClaim("custom_roles", data.roles);
  }
}
```

```bash
# Create action via API
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "set-department-claim",
    "script": "function setClaim(ctx, api) { api.v1.claims.setClaim(\"dept\", \"engineering\"); }",
    "timeout": "10s",
    "allowedToFail": true
  }' \
  "$ZITADEL_DOMAIN/management/v1/actions" | jq .

# Set action trigger (post auth = trigger on token creation)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d "{\"actionIds\":[\"ACTION_ID\"]}" \
  "$ZITADEL_DOMAIN/management/v1/flows/2/trigger/4"   # flow 2 = token, trigger 4 = pre_access_token_creation
```

---

## API Reference

```bash
# ZITADEL exposes three main APIs:
# Auth API    – /auth/v1    – current user operations
# Mgmt API   – /management/v1 – org/project/user/app management
# Admin API  – /admin/v1   – instance-level administration

# Auth API – get current user
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  "$ZITADEL_DOMAIN/auth/v1/users/me" | jq .

# Auth API – list my project grants
curl -s -X POST \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/auth/v1/usergrants/me/_search" | jq .

# Admin API – list all organizations (instance admin only)
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/admin/v1/orgs/_search" | jq .

# Admin API – list instance admins
curl -s -X POST \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$ZITADEL_DOMAIN/admin/v1/members/_search" | jq .

# gRPC reflection (list available services)
grpcurl -plaintext localhost:8080 list

# gRPC – management API example
grpcurl -plaintext \
  -H "Authorization: Bearer $PAT" \
  -d '{}' \
  localhost:8080 zitadel.management.v1.ManagementService/GetMyOrg
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [zitadel.com/docs](https://zitadel.com/docs) | ZITADEL documentation — self-hosting, API reference, SDKs, and integration guides. |
| **ZITADEL GitHub** | [github.com/zitadel/zitadel](https://github.com/zitadel/zitadel) | ZITADEL source code, releases, issue tracker, and community on GitHub. |
| **Terraform Provider** | [registry.terraform.io/zitadel/zitadel](https://registry.terraform.io/providers/zitadel/zitadel/latest/docs) | Official ZITADEL Terraform provider — manages orgs, projects, apps, users, actions, and IdP configs. |
| **OpenTofu Provider** | [search.opentofu.org/zitadel/zitadel](https://search.opentofu.org/provider/zitadel/zitadel/latest) | ZITADEL provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
