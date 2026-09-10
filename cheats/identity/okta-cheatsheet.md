# Okta & Auth0 Cheat Sheet

> Okta and Auth0 are both Okta, Inc. products. Okta targets enterprise workforce identity;
> Auth0 targets developer-focused customer identity (CIAM).

---

## Okta CLI — Installation & Auth

```bash
# Install Okta CLI
brew install okta-cli

# macOS alternative (direct download)
curl -fsSL https://raw.githubusercontent.com/okta/okta-cli/master/cli/src/main/scripts/install.sh | bash

# Login / register
okta login                        # open browser for SSO login
okta register                     # create new Okta developer org

# Create a new Okta-integrated app (interactive)
okta apps create

# Scaffold a sample app with Okta already configured
okta start                        # choose framework interactively

# Show version
okta --version
okta --help
```

---

## Okta — Applications & Users (API)

```bash
export OKTA_DOMAIN="https://dev-123456.okta.com"
export OKTA_TOKEN="YOUR_API_TOKEN"    # Admin → Security → API → Tokens

# --- Applications ---

# List all apps
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/apps" | jq '.[].label'

# Create OIDC web app
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"oidc_client",
    "label":"My Web App",
    "signOnMode":"OPENID_CONNECT",
    "credentials":{"oauthClient":{"token_endpoint_auth_method":"client_secret_post"}},
    "settings":{
      "oauthClient":{
        "client_uri":"https://app.example.com",
        "redirect_uris":["https://app.example.com/callback"],
        "post_logout_redirect_uris":["https://app.example.com"],
        "response_types":["code"],
        "grant_types":["authorization_code","refresh_token"],
        "application_type":"web"
      }
    }
  }' \
  "$OKTA_DOMAIN/api/v1/apps" | jq '{id,label,credentials}'

# --- Users ---

# List users
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/users?limit=25" | jq '.[].profile.login'

# Get user by login
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/users/alice@example.com" | jq .

# Create user (with activation)
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "profile":{"firstName":"Alice","lastName":"Smith","email":"alice@example.com","login":"alice@example.com"},
    "credentials":{"password":{"value":"SecurePass1!"}}
  }' \
  "$OKTA_DOMAIN/api/v1/users?activate=true" | jq '{id,status}'

# Activate user
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/users/USER_ID/lifecycle/activate?sendEmail=false"

# Deactivate user
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/users/USER_ID/lifecycle/deactivate"

# Assign user to app
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id":"USER_ID","scope":"USER"}' \
  "$OKTA_DOMAIN/api/v1/apps/APP_ID/users" | jq .

# --- Groups ---

# List groups
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/groups" | jq '.[].profile.name'

# Create group
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"profile":{"name":"engineering","description":"Engineering team"}}' \
  "$OKTA_DOMAIN/api/v1/groups" | jq '{id,profile}'

# Add user to group
curl -s -X PUT \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/groups/GROUP_ID/users/USER_ID"
```

---

## Okta — Policies & MFA

```bash
# List sign-on policies
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/policies?type=OKTA_SIGN_ON" | jq '.[].name'

# List MFA enrollment policies
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/policies?type=MFA_ENROLL" | jq '.[].name'

# List authenticators (MFA methods)
curl -s -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/authenticators" | jq '.[].{key,name,status}'

# Enable FIDO2/WebAuthn authenticator
curl -s -X POST \
  -H "Authorization: SSWS $OKTA_TOKEN" \
  "$OKTA_DOMAIN/api/v1/authenticators/AUTHENTICATOR_ID/lifecycle/activate"

# Token introspection
curl -s -X POST "$OKTA_DOMAIN/oauth2/default/v1/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=ACCESS_TOKEN&token_type_hint=access_token&client_id=CLIENT_ID&client_secret=CLIENT_SECRET" | jq .

# UserInfo endpoint
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  "$OKTA_DOMAIN/oauth2/default/v1/userinfo" | jq .

# OpenID Connect discovery
curl -s "$OKTA_DOMAIN/oauth2/default/.well-known/openid-configuration" | jq .
```

---

## Auth0 CLI — Installation & Auth

```bash
# Install Auth0 CLI
brew install auth0

# Login (opens browser)
auth0 login

# Login with client credentials (non-interactive / CI)
auth0 login \
  --client-id CLIENT_ID \
  --client-secret CLIENT_SECRET \
  --domain YOUR_TENANT.auth0.com

# Show current tenant info
auth0 tenants list
auth0 api get /api/v2/

# Help
auth0 --help
auth0 apps --help
```

---

## Auth0 — Applications & APIs

```bash
# List all apps
auth0 apps list

# Create SPA application
auth0 apps create \
  --name "My SPA" \
  --type spa \
  --callbacks "https://spa.example.com/callback" \
  --logout-urls "https://spa.example.com"

# Create M2M (machine-to-machine) application
auth0 apps create \
  --name "My Service" \
  --type m2m

# Create regular web app
auth0 apps create \
  --name "My Web App" \
  --type regular \
  --callbacks "https://app.example.com/callback" \
  --logout-urls "https://app.example.com"

# Update app redirect URIs
auth0 apps update APP_CLIENT_ID \
  --callbacks "https://app.example.com/callback,https://app.example.com/silent"

# List APIs (resource servers)
auth0 apis list

# Create API (resource server)
auth0 apis create \
  --name "My API" \
  --identifier "https://api.example.com" \
  --scopes "read:data,write:data"

# List users
auth0 users list

# Search users by email
auth0 users search --query "email:alice@example.com"

# List connections (identity providers)
auth0 api get /api/v2/connections | jq '.[].{name,strategy}'
```

---

## Auth0 — Actions & Flows

```bash
# List actions
auth0 actions list

# Create action (post-login trigger)
auth0 actions create \
  --name "Add Roles to Token" \
  --trigger post-login

# Deploy action (makes it active)
auth0 actions deploy ACTION_ID

# List available triggers
# post-login, pre-user-registration, post-user-registration,
# post-change-password, send-phone-message, password-reset-post-challenge,
# credentials-exchange (M2M)

# Test an action
auth0 actions test ACTION_ID \
  --payload '{"user":{"email":"test@example.com"},"request":{}}'

# View action logs
auth0 logs list --filter "type:action"
```

```javascript
// Auth0 Action: add custom claim to access token (post-login)
exports.onExecutePostLogin = async (event, api) => {
  const namespace = "https://api.example.com/";
  const roles = event.authorization?.roles || [];
  api.accessToken.setCustomClaim(`${namespace}roles`, roles);
  api.idToken.setCustomClaim(`${namespace}department`,
    event.user.user_metadata?.department || "unknown");
};
```

---

## Token Introspection & OIDC

```bash
# --- Okta ---
OKTA_DOMAIN="https://dev-123456.okta.com"

# Get token (client_credentials)
curl -s -X POST "$OKTA_DOMAIN/oauth2/default/v1/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&scope=openid" | jq .

# Introspect
curl -s -X POST "$OKTA_DOMAIN/oauth2/default/v1/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=ACCESS_TOKEN&token_type_hint=access_token&client_id=CLIENT_ID&client_secret=CLIENT_SECRET" | jq .

# UserInfo
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  "$OKTA_DOMAIN/oauth2/default/v1/userinfo" | jq .

# Discovery
curl -s "$OKTA_DOMAIN/oauth2/default/.well-known/openid-configuration" | jq .

# --- Auth0 ---
AUTH0_DOMAIN="https://YOUR_TENANT.auth0.com"

# Get token (client_credentials)
curl -s -X POST "$AUTH0_DOMAIN/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{\"grant_type\":\"client_credentials\",\"client_id\":\"CLIENT_ID\",\"client_secret\":\"CLIENT_SECRET\",\"audience\":\"https://api.example.com\"}" | jq .

# Introspect (requires client credentials)
curl -s -X POST "$AUTH0_DOMAIN/oauth/introspect" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"ACCESS_TOKEN\",\"client_id\":\"CLIENT_ID\",\"client_secret\":\"CLIENT_SECRET\"}" | jq .

# UserInfo
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  "$AUTH0_DOMAIN/userinfo" | jq .

# Discovery
curl -s "$AUTH0_DOMAIN/.well-known/openid-configuration" | jq .
```

---

## Terraform for Okta & Auth0

```bash
# Okta provider – manages apps, users, groups, policies, MFA, SAML/OIDC
# https://registry.terraform.io/providers/okta/okta/latest/docs
terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.0"
    }
  }
}
provider "okta" {
  org_name  = "dev-123456"
  base_url  = "okta.com"
  api_token = var.okta_api_token
}

# Auth0 provider – manages apps, APIs, connections, rules, actions, tenants
# https://registry.terraform.io/providers/auth0/auth0/latest/docs
terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }
}
provider "auth0" {
  domain        = "YOUR_TENANT.auth0.com"
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Okta Developer Docs** | [developer.okta.com/docs](https://developer.okta.com/docs/) | Okta developer documentation — OIDC, SAML, Workforce Identity, APIs, SDKs, and integrations. |
| **Auth0 Docs** | [auth0.com/docs](https://auth0.com/docs/) | Auth0 documentation — CIAM, Actions, Flows, Universal Login, connections, and tenant management. |
| **Okta CLI GitHub** | [github.com/okta/okta-cli](https://github.com/okta/okta-cli) | Okta CLI source code, releases, and usage examples. |
| **Auth0 CLI GitHub** | [github.com/auth0/auth0-cli](https://github.com/auth0/auth0-cli) | Auth0 CLI source code, releases, and usage examples. |
| **Terraform Provider (Okta)** | [registry.terraform.io/okta/okta](https://registry.terraform.io/providers/okta/okta/latest/docs) | Official Okta Terraform provider — manages apps, users, groups, policies, and IdP configurations. |
| **Terraform Provider (Auth0)** | [registry.terraform.io/auth0/auth0](https://registry.terraform.io/providers/auth0/auth0/latest/docs) | Official Auth0 Terraform provider — manages tenants, apps, APIs, connections, actions, and rules. |
| **OpenTofu Provider (Okta)** | [search.opentofu.org/okta/okta](https://search.opentofu.org/provider/okta/okta/latest) | Okta provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
