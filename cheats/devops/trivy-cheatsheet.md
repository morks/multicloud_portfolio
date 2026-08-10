# Trivy Cheat Sheet

## Installation & Setup

```bash
# Install on macOS via Homebrew
brew install trivy

# Install on Debian / Ubuntu
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main \
  | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy

# Install on RHEL / CentOS / Fedora
sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-64bit.rpm

# Run Trivy as a Docker container (no local install required)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image my-image:latest

# Check installed version
trivy --version

# Update the vulnerability database only (useful before offline use)
trivy image --download-db-only

# Update Trivy itself (Homebrew)
brew upgrade trivy

# List installed plugins
trivy plugin list

# Install a plugin (e.g. trivy-plugin-referrer)
trivy plugin install github.com/aquasecurity/trivy-plugin-referrer
```

---

## Container Image Scanning

```bash
# Scan a remote image (pulled from registry)
trivy image my-image:latest

# Scan only HIGH and CRITICAL vulnerabilities
trivy image --severity HIGH,CRITICAL my-image:latest

# Show only unfixed vulnerabilities (skip vulnerabilities with no fix available)
trivy image --ignore-unfixed my-image:latest

# Combine severity filter and ignore-unfixed
trivy image --severity HIGH,CRITICAL --ignore-unfixed my-image:latest

# Scan a specific OS family (useful for distroless images)
trivy image --os-family alpine my-image:latest

# Scan by digest (immutable reference)
trivy image my-image@sha256:abc123def456...

# Scan a locally saved image tarball (exported via docker save)
docker save my-image:latest -o my-image.tar
trivy image --input my-image.tar

# List all detected packages in an image
trivy image --list-all-pkgs my-image:latest

# Scan only OS packages (skip language-specific libs)
trivy image --scanners vuln --vuln-type os my-image:latest

# List operating system types that Trivy supports
trivy image --help | grep -A 20 "os-family"
```

---

## Filesystem & Directory Scanning

```bash
# Scan the current directory for vulnerabilities and misconfigs
trivy fs .

# Scan a specific path
trivy fs /path/to/project

# Scan only for vulnerabilities (language packages: npm, pip, go.sum, Gemfile.lock, etc.)
trivy fs --scanners vuln .

# Explicitly target language lock files
trivy fs --scanners vuln my-repo/

# Ignore specific paths or files via .trivyignore
trivy fs --ignorefile .trivyignore .

# Skip directories during scan
trivy fs --skip-dirs vendor,node_modules .

# Skip individual files
trivy fs --skip-files "**/*_test.go" .

# Scan a container root filesystem (unpacked image layers)
trivy rootfs /path/to/rootfs

# Run all scanners: vulnerabilities, misconfigs, and secrets
trivy fs --scanners vuln,misconfig,secret .
```

---

## Repository Scanning

```bash
# Scan a remote GitHub repository
trivy repo https://github.com/my-org/my-repo

# Scan a specific branch
trivy repo --branch main https://github.com/my-org/my-repo

# Scan a specific tag
trivy repo --tag v1.2.3 https://github.com/my-org/my-repo

# Scan a specific commit
trivy repo --commit abc1234def5678 https://github.com/my-org/my-repo

# Scan a local git repository
trivy repo /path/to/local/my-repo

# Detect misconfigurations and secrets in addition to vulnerabilities
trivy repo --scanners vuln,misconfig,secret https://github.com/my-org/my-repo

# Scan only for secrets in a remote repo
trivy repo --scanners secret https://github.com/my-org/my-repo
```

---

## Infrastructure as Code (IaC) Scanning

```bash
# Scan all IaC files in the current directory
# (Terraform, CloudFormation, Kubernetes YAML, Helm, Dockerfile)
trivy config .

# Scan a specific directory with Terraform files
trivy config ./terraform/

# Scan a Helm chart directory
trivy config ./helm/my-chart/

# Scan Kubernetes manifests
trivy config ./k8s/

# Specify check namespaces (OPA/Rego built-in policies)
trivy config --check-namespaces builtin.dockerfile.DS . 

# Show passed checks in addition to failures
trivy config --include-non-failures .

# Use custom OPA/Rego policies
trivy config --config-policy ./policies/ --policy-namespaces custom .

# Scan only for specific misconfig types
trivy config --misconfig-scanners terraform,dockerfile .

# Scan CloudFormation templates explicitly
trivy config --file-patterns "*.cf.yaml" ./cloudformation/
```

---

## Secret Detection

```bash
# Scan the filesystem for hardcoded secrets
trivy fs --scanners secret .

# Scan a container image for secrets
trivy image --scanners secret my-image:latest

# Scan a repository for secrets
trivy repo --scanners secret https://github.com/my-org/my-repo

# What Trivy detects by default:
# - AWS Access Key IDs & Secret Access Keys
# - GitHub Personal Access Tokens & OAuth tokens
# - Google API Keys & Service Account credentials
# - Slack tokens and Webhook URLs
# - Generic API keys, passwords, and private keys
# - Azure / GCP / Kubernetes service account tokens

# Enable only specific built-in secret rules (via trivy.yaml or --config)
# secret:
#   enable-builtin-rules:
#     - aws-access-key-id
#     - github-pat

# Add custom secret patterns (in trivy.yaml)
# secret:
#   config: trivy-secret.yaml
# trivy-secret.yaml example:
# rules:
#   - id: my-custom-secret
#     category: General
#     title: My Custom API Key
#     regex: "MY_KEY_[A-Za-z0-9]{32}"
#     severity: CRITICAL

# Scan and suppress a false-positive secret by CVE/rule ID in .trivyignore
# (add the rule ID, e.g.: my-custom-secret)
```

---

## Kubernetes Cluster Scanning

```bash
# Scan the entire cluster (uses current kubeconfig context)
trivy k8s --report all cluster

# Scan with a summary report (default view)
trivy k8s --report summary cluster

# Scan a specific namespace
trivy k8s -n my-namespace --report all cluster

# Scan a specific Kubernetes resource
trivy k8s deployment/my-app
trivy k8s pod/my-pod -n my-namespace

# Scan all resources in a namespace
trivy k8s --report all -n production all

# NSA hardening guide compliance report
trivy k8s --compliance=nsa --report all cluster

# CIS Benchmark compliance report
trivy k8s --compliance=k8s-cis --report all cluster

# Save output to a file
trivy k8s --report all --format json --output cluster-report.json cluster

# Scan only specific severity levels
trivy k8s --severity HIGH,CRITICAL --report all cluster

# Scan with a specific kubeconfig
trivy k8s --kubeconfig ~/.kube/my-cluster-config --report all cluster
```

---

## SBOM – Software Bill of Materials

```bash
# Generate a CycloneDX SBOM from a container image
trivy image --format cyclonedx --output sbom.cdx.json my-image:latest

# Generate an SPDX SBOM (JSON format)
trivy image --format spdx-json --output sbom.spdx.json my-image:latest

# Generate an SPDX SBOM (tag-value text format)
trivy image --format spdx --output sbom.spdx my-image:latest

# Scan an existing SBOM file for vulnerabilities
trivy sbom sbom.cdx.json
trivy sbom sbom.spdx.json

# Generate SBOM from a filesystem
trivy fs --format cyclonedx --output sbom.cdx.json .

# Generate SBOM from a repository
trivy repo --format spdx-json --output sbom.spdx.json https://github.com/my-org/my-repo

# Attach SBOM as an OCI attestation (requires cosign)
cosign attest --predicate sbom.cdx.json --type cyclonedx my-image:latest

# Verify and download SBOM attestation
cosign verify-attestation --type cyclonedx my-image:latest | jq '.payload | @base64d | fromjson'
```

---

## Output Formats & Reports

```bash
# Default table output (human-readable)
trivy image --format table my-image:latest

# JSON output (for programmatic processing)
trivy image --format json --output results.json my-image:latest

# SARIF output (for GitHub Advanced Security / code scanning)
trivy image --format sarif --output trivy-results.sarif my-image:latest

# GitHub Dependency Snapshot format
trivy image --format github --output github-deps.json my-image:latest

# CycloneDX SBOM output
trivy image --format cyclonedx --output sbom.cdx.json my-image:latest

# SPDX JSON SBOM output
trivy image --format spdx-json --output sbom.spdx.json my-image:latest

# Custom template-based output (HTML report example)
trivy image --format template \
  --template "@/usr/local/share/trivy/templates/html.tpl" \
  --output report.html my-image:latest

# Exit with code 1 if any vulnerability is found (for CI/CD gates)
trivy image --exit-code 1 my-image:latest

# Exit with code 1 only on HIGH or CRITICAL findings
trivy image --exit-code 1 --severity HIGH,CRITICAL my-image:latest

# Exit codes:
# 0 = no vulnerabilities found (or below threshold)
# 1 = vulnerabilities found matching criteria
```

---

## CI/CD Integration

```bash
# GitHub Actions – scan image and upload SARIF to Security tab
# .github/workflows/trivy.yml
# ---
# name: Trivy Security Scan
# on: [push, pull_request]
# jobs:
#   trivy:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Build image
#         run: docker build -t my-image:${{ github.sha }} .
#       - name: Run Trivy vulnerability scanner
#         uses: aquasecurity/trivy-action@master
#         with:
#           image-ref: my-image:${{ github.sha }}
#           format: sarif
#           output: trivy-results.sarif
#           severity: HIGH,CRITICAL
#           ignore-unfixed: true
#       - name: Upload SARIF to GitHub Security tab
#         uses: github/codeql-action/upload-sarif@v3
#         with:
#           sarif_file: trivy-results.sarif

# GitLab CI – scan and fail pipeline on CRITICAL findings
# .gitlab-ci.yml
# ---
# trivy-scan:
#   image: aquasec/trivy:latest
#   script:
#     - trivy image --exit-code 0 --severity MEDIUM,HIGH --format json
#         --output gl-container-scanning-report.json $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
#     - trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed
#         $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
#   artifacts:
#     reports:
#       container_scanning: gl-container-scanning-report.json

# Scan image in a pipeline (generic shell example)
trivy image \
  --exit-code 1 \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --format table \
  my-registry.io/my-image:${BUILD_TAG}

# Scan IaC before terraform apply
trivy config --exit-code 1 --severity HIGH,CRITICAL ./terraform/

# Cache the vulnerability DB in CI to speed up runs
trivy image --cache-dir /tmp/trivy-cache my-image:latest
```

---

## Configuration File (trivy.yaml)

```bash
# Trivy reads trivy.yaml from the current directory or ~/.trivy/trivy.yaml
# Generate a default config template
trivy --generate-default-config

# Example trivy.yaml:
# ---
# severity:
#   - HIGH
#   - CRITICAL
#
# ignore-unfixed: true
#
# skip-dirs:
#   - vendor
#   - node_modules
#   - .git
#
# skip-files:
#   - "**/*_test.go"
#
# db-repository: ghcr.io/aquasecurity/trivy-db
#
# cache-dir: /tmp/trivy-cache
#
# format: table
#
# output: ""
#
# exit-code: 1
#
# vulnerability:
#   type:
#     - os
#     - library
#
# secret:
#   config: trivy-secret.yaml
#
# misconfiguration:
#   include-non-failures: false

# Use a custom config file location
trivy image --config /path/to/my-trivy.yaml my-image:latest
```

---

## Tips & Tricks

```bash
# .trivyignore – suppress false positives by CVE ID
# Create a .trivyignore file in the project root:
# CVE-2021-44228          # Log4Shell – accepted risk
# CVE-2023-12345          # Not applicable in our environment
# *.go                    # Glob to skip all Go files (misconfig scanner)

# .trivyignore with expiry dates (trivy >= 0.46)
# CVE-2021-44228 exp:2024-12-31  # Re-evaluate after this date

# Speed up CI with a shared cache directory
trivy image --cache-dir /mnt/shared/trivy-cache my-image:latest

# Air-gapped / offline scanning (download DB first on an internet-connected machine)
trivy image --download-db-only
# Copy ~/.cache/trivy to the air-gapped machine, then:
trivy image --skip-db-update --offline-scan my-image:latest

# Scan Java applications (JAR/WAR/EAR scanning enabled by default)
trivy image --scanners vuln openjdk:17

# Show all installed packages, even those without vulnerabilities
trivy image --list-all-pkgs my-image:latest

# VEX (Vulnerability Exploitability eXchange) – suppress false positives with a VEX document
# Create a VEX file (OpenVEX format):
# {
#   "@context": "https://openvex.dev/ns/v0.2.0",
#   "statements": [{
#     "vulnerability": {"name": "CVE-2021-44228"},
#     "products": [{"@id": "pkg:oci/my-image"}],
#     "status": "not_affected",
#     "justification": "vulnerable_code_not_in_execute_path"
#   }]
# }
trivy image --vex my-vex.json my-image:latest

# Check which version of the vulnerability DB is in use
trivy image --format json my-image:latest | jq '.Metadata.DBVersion'

# Scan a Helm chart rendered output (pipe through helm template)
helm template my-release ./my-chart | trivy config -

# Filter by package type (only npm vulnerabilities)
trivy fs --vuln-type library --scanners vuln ./my-node-app

# Debug mode – verbose output for troubleshooting
trivy image --debug my-image:latest

# Print the Trivy config that will be used (dry run)
trivy image --show-suppress my-image:latest
```
