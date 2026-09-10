# Keycloak Cheat Sheet

## Installation & Setup

```bash
# Docker – development mode (no TLS required)
docker run -d \
  --name keycloak \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:latest start-dev

# Docker – production mode (requires hostname + TLS)
docker run -d \
  --name keycloak \
  -p 8443:8443 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=changeme \
  -e KC_HOSTNAME=keycloak.example.com \
  quay.io/keycloak/keycloak:latest start

# Helm – Bitnami chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak \
  --set auth.adminUser=admin \
  --set auth.adminPassword=changeme \
  --namespace keycloak --create-namespace

# Helm – Codecentric chart
helm repo add codecentric https://codecentric.github.io/helm-charts
helm install keycloak codecentric/keycloak \
  --namespace keycloak --create-namespace

# Verify pods
kubectl get pods -n keycloak

# Access admin console
open http://localhost:8080/admin
```

---

## kcadm.sh — Admin CLI

```bash
# kcadm.sh lives inside the Keycloak container
alias kcadm="docker exec keycloak /opt/keycloak/bin/kcadm.sh"
# or on the host if KC is installed locally
export KCADM=/opt/keycloak/bin/kcadm.sh

# Login (creates ~/.keycloak/kcadm.config)
kcadm config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password changeme

# List realms
kcadm get realms --fields realm,enabled

# Create realm
kcadm create realms -s realm=my-realm -s enabled=true

# Delete realm
kcadm delete realms/my-realm

# List users in a realm
kcadm get users -r my-realm

# Create user
kcadm create users -r my-realm \
  -s username=alice \
  -s email=alice@example.com \
  -s enabled=true

# Set user password
kcadm set-password -r my-realm \
  --username alice \
  --new-password secret123 \
  --temporary false

# List clients
kcadm get clients -r my-realm --fields clientId,id,enabled

# Get client by clientId
kcadm get clients -r my-realm -q clientId=my-app

# List groups
kcadm get groups -r my-realm

# Create group
kcadm create groups -r my-realm -s name=developers

# List realm roles
kcadm get roles -r my-realm
```

---

## Realms & Clients

```bash
# Create OIDC client (confidential)
kcadm create clients -r my-realm \
  -s clientId=my-app \
  -s protocol=openid-connect \
  -s publicClient=false \
  -s standardFlowEnabled=true \
  -s serviceAccountsEnabled=false \
  -s 'redirectUris=["https://app.example.com/callback"]' \
  -s 'webOrigins=["https://app.example.com"]'

# Create public OIDC client (SPA)
kcadm create clients -r my-realm \
  -s clientId=my-spa \
  -s protocol=openid-connect \
  -s publicClient=true \
  -s 'redirectUris=["https://spa.example.com/*"]'

# Get client secret
CLIENT_ID=$(kcadm get clients -r my-realm -q clientId=my-app --fields id -c | jq -r '.[0].id')
kcadm get clients/$CLIENT_ID/client-secret -r my-realm

# Regenerate client secret
kcadm create clients/$CLIENT_ID/client-secret -r my-realm

# Create SAML client
kcadm create clients -r my-realm \
  -s clientId=https://sp.example.com/saml \
  -s protocol=saml \
  -s 'attributes={"saml.assertion.signature":"true"}'

# Create client scope
kcadm create client-scopes -r my-realm \
  -s name=custom-scope \
  -s protocol=openid-connect

# Add protocol mapper (add custom claim to token)
kcadm create clients/$CLIENT_ID/protocol-mappers/models -r my-realm \
  -s name=department \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-usermodel-attribute-mapper \
  -s 'config={"user.attribute":"department","claim.name":"department","jsonType.label":"String","access.token.claim":"true"}'
```

---

## Users & Groups

```bash
# List all users
kcadm get users -r my-realm

# Search users by username
kcadm get users -r my-realm -q username=alice

# Get specific user
USER_ID=$(kcadm get users -r my-realm -q username=alice --fields id -c | jq -r '.[0].id')

# Update user attribute
kcadm update users/$USER_ID -r my-realm \
  -s 'attributes={"department":["engineering"]}'

# Disable user
kcadm update users/$USER_ID -r my-realm -s enabled=false

# Delete user
kcadm delete users/$USER_ID -r my-realm

# Add user to group
GROUP_ID=$(kcadm get groups -r my-realm -q name=developers --fields id -c | jq -r '.[0].id')
kcadm update users/$USER_ID/groups/$GROUP_ID -r my-realm -s realm=my-realm

# Assign realm role to user
kcadm add-roles -r my-realm --uusername alice --rolename editor

# Assign client role to user
kcadm add-roles -r my-realm --uusername alice \
  --cclientid my-app \
  --rolename my-client-role

# Configure LDAP user federation
kcadm create components -r my-realm \
  -s name=my-ldap \
  -s providerId=ldap \
  -s providerType=org.keycloak.storage.UserStorageProvider \
  -s 'config={"connectionUrl":["ldap://ldap.example.com"],"usersDn":["ou=users,dc=example,dc=com"],"bindDn":["cn=admin,dc=example,dc=com"],"bindCredential":["ldappassword"],"usernameLDAPAttribute":["uid"],"uuidLDAPAttribute":["uid"],"userObjectClasses":["inetOrgPerson"]}'

# Sync LDAP users
kcadm create user-storage/$COMPONENT_ID/sync -r my-realm \
  -s action=triggerFullSync
```

---

## Roles & Permissions

```bash
# Create realm role
kcadm create roles -r my-realm -s name=editor -s description="Can edit content"

# Create client role
kcadm create clients/$CLIENT_ID/roles -r my-realm \
  -s name=read-data \
  -s description="Read-only access"

# Make composite role (realm role includes another role)
ROLE_ID=$(kcadm get roles/editor -r my-realm --fields id -c | jq -r '.id')
kcadm add-roles -r my-realm \
  --rname editor \
  --rolename viewer               # add viewer to editor composite role

# List roles of a user
kcadm get users/$USER_ID/role-mappings -r my-realm

# List client roles of a user
kcadm get users/$USER_ID/role-mappings/clients/$CLIENT_ID -r my-realm

# Assign role to group
kcadm add-roles -r my-realm \
  --gname developers \
  --rolename editor

# Enable fine-grained authorization on client
kcadm update clients/$CLIENT_ID -r my-realm \
  -s authorizationServicesEnabled=true

# List authorization resources
kcadm get clients/$CLIENT_ID/authz/resource-server/resource -r my-realm
```

---

## Identity Providers (Social/Enterprise)

```bash
# Add GitHub social IdP
kcadm create identity-provider/instances -r my-realm \
  -s alias=github \
  -s providerId=github \
  -s 'config={"clientId":"GITHUB_CLIENT_ID","clientSecret":"GITHUB_CLIENT_SECRET"}'

# Add Google social IdP
kcadm create identity-provider/instances -r my-realm \
  -s alias=google \
  -s providerId=google \
  -s 'config={"clientId":"GOOGLE_CLIENT_ID","clientSecret":"GOOGLE_CLIENT_SECRET"}'

# Add Microsoft (Azure AD) OIDC IdP
kcadm create identity-provider/instances -r my-realm \
  -s alias=microsoft \
  -s providerId=oidc \
  -s 'config={"clientId":"APP_ID","clientSecret":"APP_SECRET","authorizationUrl":"https://login.microsoftonline.com/TENANT_ID/oauth2/v2.0/authorize","tokenUrl":"https://login.microsoftonline.com/TENANT_ID/oauth2/v2.0/token","jwksUrl":"https://login.microsoftonline.com/TENANT_ID/discovery/v2.0/keys","issuer":"https://login.microsoftonline.com/TENANT_ID/v2.0"}'

# Add SAML IdP
kcadm create identity-provider/instances -r my-realm \
  -s alias=my-saml-idp \
  -s providerId=saml \
  -s 'config={"singleSignOnServiceUrl":"https://idp.example.com/sso","wantAuthnRequestsSigned":"false"}'

# Add IdP attribute mapper (map upstream claim → local attribute)
kcadm create identity-provider/instances/github/mappers -r my-realm \
  -s name=username-mapper \
  -s identityProviderMapper=oidc-user-attribute-idp-mapper \
  -s 'config={"claim":"login","user.attribute":"username","syncMode":"INHERIT"}'

# List configured IdPs
kcadm get identity-provider/instances -r my-realm --fields alias,providerId,enabled
```

---

## Tokens & Sessions

```bash
# Get access token (Resource Owner Password – for testing only)
curl -s -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -d grant_type=password \
  -d client_id=my-app \
  -d client_secret=MY_SECRET \
  -d username=alice \
  -d password=secret123 | jq .

# Client Credentials Grant (service-to-service)
curl -s -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -d grant_type=client_credentials \
  -d client_id=my-service \
  -d client_secret=MY_SECRET | jq .

# Token introspection
curl -s -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token/introspect \
  -d token=ACCESS_TOKEN \
  -d client_id=my-app \
  -d client_secret=MY_SECRET | jq .

# UserInfo endpoint
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  http://localhost:8080/realms/my-realm/protocol/openid-connect/userinfo | jq .

# OpenID Connect discovery
curl -s http://localhost:8080/realms/my-realm/.well-known/openid-configuration | jq .

# Refresh access token
curl -s -X POST http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -d grant_type=refresh_token \
  -d client_id=my-app \
  -d client_secret=MY_SECRET \
  -d refresh_token=REFRESH_TOKEN | jq .

# List active sessions for a user
kcadm get users/$USER_ID/sessions -r my-realm

# Logout user (revoke all sessions)
kcadm delete users/$USER_ID/sessions -r my-realm

# List all active sessions in realm
kcadm get sessions -r my-realm
```

---

## Kubernetes / Operator

```bash
# Install Keycloak Operator (OLM)
kubectl apply -f https://operatorhub.io/install/keycloak-operator.yaml

# Or via kustomize
kubectl apply -k https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/refs/heads/main/kubernetes/

# Create Keycloak instance via CRD
kubectl apply -f - <<EOF
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 1
  db:
    vendor: postgres
    host: postgres-service
    database: keycloak
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
  http:
    tlsSecret: keycloak-tls-secret
  hostname:
    hostname: keycloak.example.com
EOF

# Create realm via CRD
kubectl apply -f - <<EOF
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: my-realm-import
  namespace: keycloak
spec:
  keycloakCRName: keycloak
  realm:
    realm: my-realm
    enabled: true
    clients:
      - clientId: my-app
        protocol: openid-connect
        publicClient: true
EOF

# Check operator status
kubectl get keycloak -n keycloak
kubectl get keycloakrealmimport -n keycloak

# Import realm from JSON file
kubectl create configmap realm-import \
  --from-file=realm.json=./my-realm-export.json \
  -n keycloak
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [keycloak.org/documentation](https://www.keycloak.org/documentation) | Keycloak documentation — getting started, server admin guide, securing apps, and operator guides. |
| **Keycloak GitHub** | [github.com/keycloak/keycloak](https://github.com/keycloak/keycloak) | Keycloak source code, releases, issue tracker, and community discussions. |
| **Terraform Provider** | [registry.terraform.io/mrparkers/keycloak](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs) | Community Terraform provider — manages realms, clients, users, roles, identity providers, and LDAP federation. |
| **OpenTofu Provider** | [search.opentofu.org/mrparkers/keycloak](https://search.opentofu.org/provider/mrparkers/keycloak/latest) | Keycloak provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
