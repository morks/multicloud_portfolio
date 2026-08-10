# Ansible Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install ansible

# Installation via pip
pip3 install ansible ansible-lint

# Version prüfen
ansible --version

# Ansible-Verzeichnis-Struktur (Best Practice)
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

# Shell-Completion
pip install argcomplete
activate-global-python-argcomplete
```

---

## Konfiguration (ansible.cfg)

```ini
# ansible.cfg (im Projektverzeichnis)
[defaults]
inventory          = inventory/
remote_user        = ansible
private_key_file   = ~/.ssh/ansible_key
host_key_checking  = False
retry_files_enabled = False
stdout_callback    = yaml
collections_path   = ./collections
roles_path         = ./roles

# Parallelisierung
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
# inventory/hosts.ini – statisches Inventory
[webserver]
web01.beispiel.de ansible_user=ubuntu
web02.beispiel.de ansible_user=ubuntu ansible_port=2222

[datenbank]
db01.beispiel.de ansible_user=ec2-user
db02.beispiel.de ansible_user=ec2-user

[loadbalancer]
lb01.beispiel.de

# Variablen für eine Gruppe
[webserver:vars]
http_port=80
https_port=443
app_version=1.5.0

# Gruppe aus Gruppen
[produktion:children]
webserver
datenbank
loadbalancer

# Host mit IP
192.168.1.100 ansible_user=root ansible_ssh_private_key_file=~/.ssh/key.pem
```

```yaml
# inventory/hosts.yml – YAML-Format (empfohlen)
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
# Dynamisches Inventory (z.B. AWS)
pip install boto3 botocore
ansible-inventory -i aws_ec2.yaml --list
ansible-inventory -i aws_ec2.yaml --graph

# Inventory aus mehreren Quellen
# inventory/
# ├── hosts.ini
# ├── aws_ec2.yaml
# └── group_vars/

# Inventory testen / anzeigen
ansible-inventory -i inventory/ --list
ansible-inventory -i inventory/ --graph

# Hosts einer Gruppe anzeigen
ansible webserver --list-hosts
```

---

## Ad-hoc-Befehle

```bash
# Ping (Verbindung testen)
ansible all -m ping
ansible webserver -m ping
ansible all -m ping -i inventory/hosts.ini

# Shell-Befehl ausführen
ansible all -m shell -a "uptime"
ansible webserver -m shell -a "df -h"

# Datei kopieren
ansible all -m copy \
  -a "src=./config.conf dest=/etc/app/config.conf mode=0644"

# Paket installieren
ansible all -m apt \
  -a "name=nginx state=present" \
  --become

# Service starten / stoppen
ansible webserver -m service \
  -a "name=nginx state=started enabled=yes" \
  --become

# Benutzer anlegen
ansible all -m user \
  -a "name=deploy state=present shell=/bin/bash groups=sudo" \
  --become

# Datei löschen
ansible all -m file \
  -a "path=/tmp/test.txt state=absent"

# Verzeichnis erstellen
ansible all -m file \
  -a "path=/opt/meine-app state=directory mode=0755 owner=deploy"

# Facts eines Hosts anzeigen
ansible web01.beispiel.de -m setup
ansible web01.beispiel.de -m setup -a "filter=ansible_distribution*"

# Mit bestimmtem User ausführen
ansible all -m shell -a "whoami" --become-user=deploy --become

# Parallele Ausführung begrenzen
ansible all -m ping -f 5           # max 5 parallel
```

---

## Playbooks

```yaml
# playbooks/webserver.yml
---
- name: Webserver einrichten
  hosts: webserver
  become: true
  vars:
    app_version: "1.5.0"
    app_port: 8080

  pre_tasks:
    - name: System aktualisieren
      apt:
        update_cache: yes
        cache_valid_time: 3600

  tasks:
    - name: Nginx installieren
      package:
        name: nginx
        state: present

    - name: Nginx-Konfiguration kopieren
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/meine-app
        mode: '0644'
      notify: Nginx neu starten

    - name: Site aktivieren
      file:
        src: /etc/nginx/sites-available/meine-app
        dest: /etc/nginx/sites-enabled/meine-app
        state: link

    - name: Nginx starten
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Nginx neu starten
      service:
        name: nginx
        state: reloaded

  post_tasks:
    - name: Deployment-Info ausgeben
      debug:
        msg: "App {{ app_version }} deployed auf {{ inventory_hostname }}"
```

```bash
# Playbook ausführen
ansible-playbook playbooks/webserver.yml

# Mit Inventory-Datei
ansible-playbook -i inventory/production/ playbooks/webserver.yml

# Dry-Run (Check Mode)
ansible-playbook playbooks/webserver.yml --check

# Verbose-Modus
ansible-playbook playbooks/webserver.yml -v    # einfach
ansible-playbook playbooks/webserver.yml -vvv  # sehr ausführlich

# Bestimmte Hosts / Gruppen
ansible-playbook playbooks/webserver.yml --limit web01.beispiel.de
ansible-playbook playbooks/webserver.yml --limit "webserver:!web02"

# Bestimmte Tags ausführen
ansible-playbook playbooks/webserver.yml --tags nginx,config
ansible-playbook playbooks/webserver.yml --skip-tags debug

# Extra-Variablen übergeben
ansible-playbook playbooks/webserver.yml \
  --extra-vars "app_version=1.6.0 env=production"

# Extra-Variablen aus Datei
ansible-playbook playbooks/webserver.yml \
  --extra-vars "@vars/prod.yml"

# Ab bestimmter Task starten
ansible-playbook playbooks/webserver.yml \
  --start-at-task="Nginx-Konfiguration kopieren"

# Step-by-Step (interaktiv bestätigen)
ansible-playbook playbooks/webserver.yml --step

# Passwort-Vault entschlüsseln
ansible-playbook playbooks/webserver.yml \
  --ask-vault-pass
# oder:
ansible-playbook playbooks/webserver.yml \
  --vault-password-file ~/.vault_pass
```

---

## Rollen (Roles)

```bash
# Rolle erstellen (Gerüst)
ansible-galaxy role init meine-rolle

# Rollenstruktur
# meine-rolle/
# ├── defaults/       # Standardvariablen (niedrigste Priorität)
# │   └── main.yml
# ├── vars/           # Rollenvariablen (hohe Priorität)
# │   └── main.yml
# ├── tasks/          # Hauptaufgaben
# │   └── main.yml
# ├── handlers/       # Handler
# │   └── main.yml
# ├── templates/      # Jinja2-Templates
# ├── files/          # Statische Dateien
# ├── meta/           # Rollenmeta (Abhängigkeiten)
# │   └── main.yml
# └── README.md

# Rolle in Playbook nutzen
cat << 'EOF' > playbooks/site.yml
---
- hosts: webserver
  roles:
    - common
    - nginx
    - { role: app-deploy, app_version: "1.5.0" }
EOF

# Rollen von Ansible Galaxy installieren
ansible-galaxy install geerlingguy.nginx
ansible-galaxy install geerlingguy.docker

# Aus requirements.yml installieren
ansible-galaxy install -r requirements.yml

# requirements.yml Beispiel
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

# Installierte Rollen auflisten
ansible-galaxy role list
```

---

## Variablen & Priorität

```yaml
# Prioritätsreihenfolge (höchste zuerst):
# 1. extra vars (--extra-vars)
# 2. task vars
# 3. block vars
# 4. role vars (vars/)
# 5. set_fact
# 6. registered vars
# 7. host_vars/ (pro Host)
# 8. group_vars/all
# 9. group_vars/<group>
# 10. inventory vars
# 11. role defaults (defaults/)

# group_vars/webserver.yml
app_port: 8080
app_workers: 4
log_level: info

# host_vars/web01.beispiel.de.yml
app_port: 8090     # überschreibt Group-Var für diesen Host
```

```yaml
# Variablen in Tasks registrieren und nutzen
- name: App-Version auslesen
  command: /opt/app/bin/app --version
  register: app_version_result

- name: Version ausgeben
  debug:
    msg: "Version: {{ app_version_result.stdout }}"

- name: Nur wenn bestimmte Version
  debug:
    msg: "Neue Version!"
  when: "'1.5' in app_version_result.stdout"
```

---

## Ansible Vault (Secrets verschlüsseln)

```bash
# Datei verschlüsseln
ansible-vault encrypt vars/secrets.yml

# Datei entschlüsseln
ansible-vault decrypt vars/secrets.yml

# Datei anzeigen (ohne zu entschlüsseln)
ansible-vault view vars/secrets.yml

# Datei erstellen (direkt verschlüsselt)
ansible-vault create vars/secrets.yml

# Datei bearbeiten
ansible-vault edit vars/secrets.yml

# Passwort ändern
ansible-vault rekey vars/secrets.yml

# Einzelnen Wert verschlüsseln (für Inline-Verwendung)
ansible-vault encrypt_string 'geheimesPasswort' --name 'db_password'

# Vault-Passwort-Datei (nicht ins Git!)
echo "meinVaultPasswort" > ~/.vault_pass
chmod 600 ~/.vault_pass
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Mehrere Vault-IDs (für unterschiedliche Passwörter)
ansible-vault encrypt_string 'secret' \
  --vault-id dev@~/.vault_pass_dev \
  --name 'db_password'
```

---

## Jinja2-Templates

```jinja2
{# templates/nginx.conf.j2 #}
server {
    listen {{ http_port | default(80) }};
    server_name {{ inventory_hostname }};

    location / {
        proxy_pass http://127.0.0.1:{{ app_port }};
    }
}

{# Bedingungen #}
{% if ssl_enabled | default(false) %}
    listen 443 ssl;
    ssl_certificate {{ ssl_cert_path }};
{% endif %}

{# Schleifen #}
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
# Collections installieren
ansible-galaxy collection install community.general
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install azure.azcollection
ansible-galaxy collection install google.cloud
ansible-galaxy collection install kubernetes.core

# Collection aus requirements.yml
ansible-galaxy collection install -r requirements.yml

# Installierte Collections anzeigen
ansible-galaxy collection list

# Collection-Info
ansible-galaxy collection info community.general

# Eigene Collection erstellen
ansible-galaxy collection init meine_org.meine_collection
```

---

## Nützliche Module

```yaml
# Datei-Management
- copy: src=datei.conf dest=/etc/datei.conf mode=0644 owner=root
- template: src=config.j2 dest=/etc/config.conf
- file: path=/opt/app state=directory mode=0755
- lineinfile: path=/etc/hosts line="10.0.0.1 db.lokal"
- replace: path=/etc/app.conf regexp='DEBUG=true' replace='DEBUG=false'

# Paketverwaltung
- apt: name=nginx state=present update_cache=yes         # Debian/Ubuntu
- yum: name=httpd state=latest                           # RHEL/CentOS
- dnf: name=podman state=present                         # Fedora/RHEL 8+
- package: name=curl state=present                       # OS-agnostisch

# Dienste
- service: name=nginx state=started enabled=yes
- systemd: name=myapp daemon_reload=yes state=restarted

# Benutzer & Gruppen
- user: name=deploy shell=/bin/bash groups=sudo state=present
- group: name=deploy state=present
- authorized_key: user=deploy key="{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

# Git
- git: repo=https://github.com/org/repo.git dest=/opt/app version=main

# Archiv
- unarchive: src=app.tar.gz dest=/opt/ remote_src=yes

# Docker
- community.docker.docker_image: name=nginx tag=alpine source=pull
- community.docker.docker_container:
    name: mein-container
    image: nginx:alpine
    ports: ["80:80"]
    state: started

# Kubernetes
- kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', 'deployment.yaml') | from_yaml }}"

# Cloud-Module
- amazon.aws.ec2_instance: ...
- azure.azcollection.azure_rm_virtualmachine: ...
- google.cloud.gcp_compute_instance: ...
```

---

## Tipps & Tricks

```bash
# Syntax prüfen (ohne Ausführen)
ansible-playbook playbooks/site.yml --syntax-check

# Linting (Code-Qualität)
ansible-lint playbooks/site.yml
pip install ansible-lint

# Tasks auflisten (ohne Ausführen)
ansible-playbook playbooks/site.yml --list-tasks

# Hosts auflisten
ansible-playbook playbooks/site.yml --list-hosts

# Tags auflisten
ansible-playbook playbooks/site.yml --list-tags

# Ansible-Facts cachen (für Performance)
# In ansible.cfg:
# [defaults]
# fact_caching = jsonfile
# fact_caching_connection = /tmp/ansible_facts
# fact_caching_timeout = 3600

# Parallele Ausführung (forks)
ansible-playbook playbooks/site.yml -f 20

# Ausgabe-Callback (yaml ist lesbarer)
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook playbooks/site.yml

# Fehlgeschlagene Hosts in retry-Datei speichern
ansible-playbook playbooks/site.yml
# erstellt playbooks/site.retry bei Fehler
ansible-playbook playbooks/site.yml --limit @playbooks/site.retry

# AWX / Ansible Automation Platform
# Web-UI für Ansible: https://github.com/ansible/awx
# Enterprise: Red Hat Ansible Automation Platform (AAP)
```
