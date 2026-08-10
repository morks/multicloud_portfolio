# Ansible Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install ansible

# Installation via pip
pip3 install ansible ansible-lint

# Check version
ansible --version

# Ansible directory structure (Best Practice)
# inventory/
# ├── production/
# │   ├── hosts.ini
# │   └── group_vars/
# ├── staging/
# │   └── hosts.ini
# playbooks/
# ├── site.yml
# ├── webserver.yml
# └── database.yml
# roles/
# ├── common/
# ├── nginx/
# └── postgresql/
# ansible.cfg

# Shell completion
pip install argcomplete
activate-global-python-argcomplete
```

---

## Configuration (ansible.cfg)

```ini
# ansible.cfg (in the project directory)
[defaults]
inventory          = inventory/
remote_user        = ansible
private_key_file   = ~/.ssh/ansible_key
host_key_checking  = False
retry_files_enabled = False
stdout_callback    = yaml
collections_path   = ./collections
roles_path         = ./roles

# Parallelization
forks              = 20

# Logging
log_path           = ./ansible.log

[privilege_escalation]
become             = True
become_method      = sudo
become_user        = root
become_ask_pass    = False

[ssh_connection]
ssh_args           = -o ControlMaster=auto -o ControlPersist=60s
pipelining         = True
```

---

## Inventory

```ini
# inventory/hosts.ini – static Inventory
[webserver]
web01.beispiel.de ansible_user=ubuntu
web02.beispiel.de ansible_user=ubuntu ansible_port=2222

[datenbank]
db01.beispiel.de ansible_user=ec2-user
db02.beispiel.de ansible_user=ec2-user

[loadbalancer]
lb01.beispiel.de

# Variables for a group
[webserver:vars]
http_port=80
https_port=443
app_version=1.5.0

# Group of groups
[produktion:children]
webserver
datenbank
loadbalancer

# Host with IP
192.168.1.100 ansible_user=root ansible_ssh_private_key_file=~/.ssh/key.pem
```

```yaml
# inventory/hosts.yml – YAML format (recommended)
all:
  children:
    webserver:
      hosts:
        web01.beispiel.de:
          ansible_user: ubuntu
          http_port: 80
        web02.beispiel.de:
          ansible_user: ubuntu
    datenbank:
      hosts:
        db01.beispiel.de:
          ansible_user: ec2-user
  vars:
    ansible_ssh_private_key_file: ~/.ssh/ansible_key
```

```bash
# Dynamic Inventory (e.g. AWS)
pip install boto3 botocore
ansible-inventory -i aws_ec2.yaml --list
ansible-inventory -i aws_ec2.yaml --graph

# Inventory from multiple sources
# inventory/
# ├── hosts.ini
# ├── aws_ec2.yaml
# └── group_vars/

# Test / show Inventory
ansible-inventory -i inventory/ --list
ansible-inventory -i inventory/ --graph

# Show hosts of a group
ansible webserver --list-hosts
```

---

## Ad-hoc Commands

```bash
# Ping (test connection)
ansible all -m ping
ansible webserver -m ping
ansible all -m ping -i inventory/hosts.ini

# Execute shell command
ansible all -m shell -a "uptime"
ansible webserver -m shell -a "df -h"

# Copy file
ansible all -m copy \
  -a "src=./config.conf dest=/etc/app/config.conf mode=0644"

# Install package
ansible all -m apt \
  -a "name=nginx state=present" \
  --become

# Start / stop service
ansible webserver -m service \
  -a "name=nginx state=started enabled=yes" \
  --become

# Create user
ansible all -m user \
  -a "name=deploy state=present shell=/bin/bash groups=sudo" \
  --become

# Delete file
ansible all -m file \
  -a "path=/tmp/test.txt state=absent"

# Create directory
ansible all -m file \
  -a "path=/opt/my-app state=directory mode=0755 owner=deploy"

# Show facts of a host
ansible web01.beispiel.de -m setup
ansible web01.beispiel.de -m setup -a "filter=ansible_distribution*"

# Run with specific user
ansible all -m shell -a "whoami" --become-user=deploy --become

# Limit parallel execution
ansible all -m ping -f 5           # max 5 parallel
```

---

## Playbooks

```yaml
# playbooks/webserver.yml
---
- name: Set up webserver
  hosts: webserver
  become: true
  vars:
    app_version: "1.5.0"
    app_port: 8080

  pre_tasks:
    - name: Update system
      apt:
        update_cache: yes
        cache_valid_time: 3600

  tasks:
    - name: Install Nginx
      package:
        name: nginx
        state: present

    - name: Copy Nginx configuration
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/my-app
        mode: '0644'
      notify: Restart Nginx

    - name: Activate site
      file:
        src: /etc/nginx/sites-available/my-app
        dest: /etc/nginx/sites-enabled/my-app
        state: link

    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: reloaded

  post_tasks:
    - name: Output deployment info
      debug:
        msg: "App {{ app_version }} deployed on {{ inventory_hostname }}"
```

```bash
# Run playbook
ansible-playbook playbooks/webserver.yml

# With inventory file
ansible-playbook -i inventory/production/ playbooks/webserver.yml

# Dry-Run (Check Mode)
ansible-playbook playbooks/webserver.yml --check

# Verbose mode
ansible-playbook playbooks/webserver.yml -v    # simple
ansible-playbook playbooks/webserver.yml -vvv  # very verbose

# Specific hosts / groups
ansible-playbook playbooks/webserver.yml --limit web01.beispiel.de
ansible-playbook playbooks/webserver.yml --limit "webserver:!web02"

# Run specific tags
ansible-playbook playbooks/webserver.yml --tags nginx,config
ansible-playbook playbooks/webserver.yml --skip-tags debug

# Pass extra variables
ansible-playbook playbooks/webserver.yml \
  --extra-vars "app_version=1.6.0 env=production"

# Extra variables from file
ansible-playbook playbooks/webserver.yml \
  --extra-vars "@vars/prod.yml"

# Start at specific task
ansible-playbook playbooks/webserver.yml \
  --start-at-task="Copy Nginx configuration"

# Step-by-step (confirm interactively)
ansible-playbook playbooks/webserver.yml --step

# Decrypt password vault
ansible-playbook playbooks/webserver.yml \
  --ask-vault-pass
# or:
ansible-playbook playbooks/webserver.yml \
  --vault-password-file ~/.vault_pass
```

---

## Roles

```bash
# Create role (scaffold)
ansible-galaxy role init my-role

# Role structure
# my-role/
# ├── defaults/       # Default variables (lowest priority)
# │   └── main.yml
# ├── vars/           # Role variables (high priority)
# │   └── main.yml
# ├── tasks/          # Main tasks
# │   └── main.yml
# ├── handlers/       # Handler
# │   └── main.yml
# ├── templates/      # Jinja2-Templates
# ├── files/          # Static files
# ├── meta/           # Role metadata (dependencies)
# │   └── main.yml
# └── README.md

# Use role in Playbook
cat << 'EOF' > playbooks/site.yml
---
- hosts: webserver
  roles:
    - common
    - nginx
    - { role: app-deploy, app_version: "1.5.0" }
EOF

# Install roles from Ansible Galaxy
ansible-galaxy install geerlingguy.nginx
ansible-galaxy install geerlingguy.docker

# Install from requirements.yml
ansible-galaxy install -r requirements.yml

# requirements.yml example
cat << 'EOF' > requirements.yml
roles:
  - name: geerlingguy.nginx
    version: 3.2.0
  - name: geerlingguy.postgresql
    version: 3.4.3

collections:
  - name: community.general
    version: ">=7.0.0"
  - name: amazon.aws
    version: ">=6.0.0"
EOF

# List installed roles
ansible-galaxy role list
```

---

## Variables & Priority

```yaml
# Priority order (highest first):
# 1. extra vars (--extra-vars)
# 2. task vars
# 3. block vars
# 4. role vars (vars/)
# 5. set_fact
# 6. registered vars
# 7. host_vars/ (per host)
# 8. group_vars/all
# 9. group_vars/<group>
# 10. inventory vars
# 11. role defaults (defaults/)

# group_vars/webserver.yml
app_port: 8080
app_workers: 4
log_level: info

# host_vars/web01.beispiel.de.yml
app_port: 8090     # overrides Group-Var for this host
```

```yaml
# Register and use variables in tasks
- name: Read app version
  command: /opt/app/bin/app --version
  register: app_version_result

- name: Output version
  debug:
    msg: "Version: {{ app_version_result.stdout }}"

- name: Only for specific version
  debug:
    msg: "New version!"
  when: "'1.5' in app_version_result.stdout"
```

---

## Ansible Vault (Encrypting Secrets)

```bash
# Encrypt file
ansible-vault encrypt vars/secrets.yml

# Decrypt file
ansible-vault decrypt vars/secrets.yml

# View file (without decrypting)
ansible-vault view vars/secrets.yml

# Create file (directly encrypted)
ansible-vault create vars/secrets.yml

# Edit file
ansible-vault edit vars/secrets.yml

# Change password
ansible-vault rekey vars/secrets.yml

# Encrypt single value (for inline use)
ansible-vault encrypt_string 'secretPassword' --name 'db_password'

# Vault password file (do not commit to Git!)
echo "myVaultPassword" > ~/.vault_pass
chmod 600 ~/.vault_pass
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Multiple Vault IDs (for different passwords)
ansible-vault encrypt_string 'secret' \
  --vault-id dev@~/.vault_pass_dev \
  --name 'db_password'
```

---

## Jinja2 Templates

```jinja2
{# templates/nginx.conf.j2 #}
server {
    listen {{ http_port | default(80) }};
    server_name {{ inventory_hostname }};

    location / {
        proxy_pass http://127.0.0.1:{{ app_port }};
    }
}

{# Conditions #}
{% if ssl_enabled | default(false) %}
    listen 443 ssl;
    ssl_certificate {{ ssl_cert_path }};
{% endif %}

{# Loops #}
upstream backend {
{% for host in groups['webserver'] %}
    server {{ hostvars[host]['ansible_default_ipv4']['address'] }}:{{ app_port }};
{% endfor %}
}

{# Filter #}
{{ app_name | upper }}
{{ version | regex_replace('^v', '') }}
{{ my_list | join(', ') }}
{{ my_dict | to_nice_json }}
{{ value | default('fallback') }}
```

---

## Collections & Galaxy

```bash
# Install collections
ansible-galaxy collection install community.general
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install azure.azcollection
ansible-galaxy collection install google.cloud
ansible-galaxy collection install kubernetes.core

# Collection from requirements.yml
ansible-galaxy collection install -r requirements.yml

# Show installed collections
ansible-galaxy collection list

# Collection info
ansible-galaxy collection info community.general

# Create custom collection
ansible-galaxy collection init my_org.my_collection
```

---

## Useful Modules

```yaml
# File management
- copy: src=datei.conf dest=/etc/datei.conf mode=0644 owner=root
- template: src=config.j2 dest=/etc/config.conf
- file: path=/opt/app state=directory mode=0755
- lineinfile: path=/etc/hosts line="10.0.0.1 db.local"
- replace: path=/etc/app.conf regexp='DEBUG=true' replace='DEBUG=false'

# Package management
- apt: name=nginx state=present update_cache=yes         # Debian/Ubuntu
- yum: name=httpd state=latest                           # RHEL/CentOS
- dnf: name=podman state=present                         # Fedora/RHEL 8+
- package: name=curl state=present                       # OS-agnostic

# Services
- service: name=nginx state=started enabled=yes
- systemd: name=myapp daemon_reload=yes state=restarted

# Users & Groups
- user: name=deploy shell=/bin/bash groups=sudo state=present
- group: name=deploy state=present
- authorized_key: user=deploy key="{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

# Git
- git: repo=https://github.com/org/repo.git dest=/opt/app version=main

# Archive
- unarchive: src=app.tar.gz dest=/opt/ remote_src=yes

# Docker
- community.docker.docker_image: name=nginx tag=alpine source=pull
- community.docker.docker_container:
    name: my-container
    image: nginx:alpine
    ports: ["80:80"]
    state: started

# Kubernetes
- kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', 'deployment.yaml') | from_yaml }}"

# Cloud modules
- amazon.aws.ec2_instance: ...
- azure.azcollection.azure_rm_virtualmachine: ...
- google.cloud.gcp_compute_instance: ...
```

---

## Tips & Tricks

```bash
# Check syntax (without executing)
ansible-playbook playbooks/site.yml --syntax-check

# Linting (code quality)
ansible-lint playbooks/site.yml
pip install ansible-lint

# List tasks (without executing)
ansible-playbook playbooks/site.yml --list-tasks

# List hosts
ansible-playbook playbooks/site.yml --list-hosts

# List tags
ansible-playbook playbooks/site.yml --list-tags

# Cache Ansible facts (for performance)
# In ansible.cfg:
# [defaults]
# fact_caching = jsonfile
# fact_caching_connection = /tmp/ansible_facts
# fact_caching_timeout = 3600

# Parallel execution (forks)
ansible-playbook playbooks/site.yml -f 20

# Output callback (yaml is more readable)
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook playbooks/site.yml

# Save failed hosts in retry file
ansible-playbook playbooks/site.yml
# creates playbooks/site.retry on failure
ansible-playbook playbooks/site.yml --limit @playbooks/site.retry

# AWX / Ansible Automation Platform
# Web UI for Ansible: https://github.com/ansible/awx
# Enterprise: Red Hat Ansible Automation Platform (AAP)
```
