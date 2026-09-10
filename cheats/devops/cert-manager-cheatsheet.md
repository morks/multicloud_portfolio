# cert-manager Cheat Sheet

## Overview

**cert-manager** is a Kubernetes-native certificate management controller that automatically provisions and renews TLS certificates from Let's Encrypt, Vault, or custom CAs.

| | |
|---|---|
| **Strengths** | Fully automated cert lifecycle · multiple issuer backends (ACME, Vault, CA, self-signed) · Ingress annotation integration · cmctl CLI · wildcard cert support · CNCF project |
| **Weaknesses** | Debugging failed cert issuance is complex (multi-step chain) · misconfigured issuers fail silently · version upgrades require CRD migration care · ACME DNS-01 setup can be fiddly |
| **Best for** | Automated TLS for K8s Ingress & services, Let's Encrypt integration, internal PKI with Vault backend, mTLS certificate provisioning |

---

## Installation & Setup

```bash
# Add Jetstack Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Verify pods are running
kubectl get pods -n cert-manager

# Check CRDs were installed
kubectl get crds | grep cert-manager.io

# Check cert-manager version
kubectl -n cert-manager get deploy cert-manager \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## ClusterIssuers & Issuers

```bash
# Let's Encrypt – HTTP-01 challenge (ClusterIssuer)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
EOF

# Let's Encrypt – DNS-01 challenge (e.g. Route53)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-dns-key
    solvers:
    - dns01:
        route53:
          region: eu-central-1
          hostedZoneID: ZXXXXXXXXXXXXX
EOF

# Self-signed ClusterIssuer (for testing / internal PKI bootstrap)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
EOF

# CA Issuer (sign with your own CA cert stored in a Secret)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca
spec:
  ca:
    secretName: internal-ca-key-pair   # must contain tls.crt + tls.key
EOF

# List all ClusterIssuers and their status
kubectl get clusterissuers
kubectl describe clusterissuer letsencrypt-prod
```

---

## Certificate Resources

```bash
# Create a Certificate resource
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-tls
  namespace: my-namespace
spec:
  secretName: my-app-tls-secret   # K8s Secret that will hold the cert
  duration: 2160h                  # 90 days
  renewBefore: 360h                # renew 15 days before expiry
  dnsNames:
    - my-app.example.com
    - www.my-app.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
EOF

# Check certificate status (READY = True means cert is issued)
kubectl get certificate -n my-namespace
kubectl describe certificate my-app-tls -n my-namespace

# Check the TLS secret that was created
kubectl get secret my-app-tls-secret -n my-namespace
kubectl get secret my-app-tls-secret -n my-namespace \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates

# List all certificates across all namespaces
kubectl get certificates -A
```

---

## Ingress Integration

```bash
# Annotate an Ingress to auto-issue a certificate
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-namespace
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"   # triggers cert issuance
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - my-app.example.com
      secretName: my-app-tls-secret   # cert-manager will populate this
  rules:
    - host: my-app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-svc
                port:
                  number: 80
EOF

# Use a namespace-scoped Issuer instead
# annotations:
#   cert-manager.io/issuer: "my-local-issuer"
```

---

## Debugging & Troubleshooting

```bash
# Hierarchy: Certificate → CertificateRequest → Order → Challenge
# Work down the chain to find the failure

# Check Certificate
kubectl describe certificate my-app-tls -n my-namespace

# Check CertificateRequest (created automatically)
kubectl get certificaterequest -n my-namespace
kubectl describe certificaterequest my-app-tls-xxxxx -n my-namespace

# Check Order (ACME only)
kubectl get order -n my-namespace
kubectl describe order my-app-tls-xxxxx -n my-namespace

# Check Challenge (ACME only – shows DNS/HTTP challenge status)
kubectl get challenge -n my-namespace
kubectl describe challenge my-app-tls-xxxxx -n my-namespace

# cert-manager controller logs
kubectl logs -n cert-manager \
  -l app.kubernetes.io/component=controller -f

# webhook logs (if admission errors occur)
kubectl logs -n cert-manager \
  -l app.kubernetes.io/component=webhook -f

# Common issues:
# - Challenge stuck "pending"  → check DNS/HTTP-01 solver reachability
# - "rate limit" from LE       → use letsencrypt-staging for tests
# - Secret not created         → check ClusterIssuer is Ready
```

---

## Renewal & Rotation

```bash
# cert-manager auto-renews when (expiryTime - renewBefore) is reached
# Default renewBefore: 1/3 of certificate duration

# Check when a cert will be renewed
kubectl get certificate my-app-tls -n my-namespace \
  -o jsonpath='{.status.renewalTime}'

# Check actual expiry stored in the Secret
kubectl get secret my-app-tls-secret -n my-namespace \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -noout -enddate

# Force manual renewal (delete the CertificateRequest – cert-manager recreates it)
kubectl delete certificaterequest -n my-namespace \
  $(kubectl get certificaterequest -n my-namespace \
    -o jsonpath='{.items[?(@.metadata.ownerReferences[0].name=="my-app-tls")].metadata.name}')

# Or use cmctl (see below)
cmctl renew my-app-tls -n my-namespace
```

---

## cmctl CLI

```bash
# Install cmctl (macOS)
brew install cmctl

# Or download binary
curl -fsSL https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_$(uname -s)_$(uname -m).tar.gz \
  | tar xz && sudo mv cmctl /usr/local/bin/

# Check cert-manager API availability
cmctl check api

# Inspect a certificate (decoded, human-readable)
cmctl inspect secret my-app-tls-secret -n my-namespace

# Manually trigger renewal of a Certificate
cmctl renew my-app-tls -n my-namespace

# Renew all certificates in a namespace
cmctl renew --all -n my-namespace

# Renew all certificates across all namespaces
cmctl renew --all --all-namespaces

# Convert old v1alpha2/v1beta1 manifests to v1
cmctl convert -f old-certificate.yaml
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [cert-manager.io/docs](https://cert-manager.io/docs/) | cert-manager documentation — installation, issuers, certificates, ACME, troubleshooting, and API reference. |
| **Terraform Provider (cert-manager)** | [registry.terraform.io/alex-emery/cert-manager](https://registry.terraform.io/providers/alex-emery/cert-manager/latest/docs) | Community Terraform provider — manage cert-manager Certificates, ClusterIssuers, and Issuers as infrastructure code. |
| **OpenTofu Provider (cert-manager)** | [search.opentofu.org/alex-emery/cert-manager](https://search.opentofu.org/provider/alex-emery/cert-manager/latest) | cert-manager provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
