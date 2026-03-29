SHELL := /bin/bash

help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  install                  Install dependencies and set up pre-commit hooks"
	@echo "  uninstall                Remove installed dependencies"
	@echo "  lab-bootstrap            One-time Proxmox host bootstrap (enterprise only — disaster recovery)"
	@echo "  play                     Run the main Ansible playbook against all hosts (idempotent): make play [LIMIT=host_or_group]"
	@echo "  verify                   Run the verify playbook against live infrastructure: make verify [LIMIT=host_or_group] [SKIP_TAGS=tag1,tag2]"
	@echo "  lint                     Run ansible-lint and tflint"
	@echo "  tofu-proxmox             Run OpenTofu for Proxmox: make tofu-proxmox ARGS='plan'"
	@echo "  tofu-recreate            Recreate VMs by name: make tofu-recreate HOSTS=centaurus,norville"
	@echo "  sync-pihole              Manually trigger nebula-sync on centaurus"
	@echo "  generate-proxmox-answer  Generate proxmox_installer/answer.toml from template + 1Password"
	@echo "  build-proxmox-iso        Build auto-install ISO — runs generate-proxmox-answer automatically (PVE_ISO_VERSION=9.1-1)"
	@echo "  help                     Show this help message"
	@echo ""

# Install all dependencies and set up pre-commit hooks
# Any injected packages need --include-apps to expose the binaries to path immediately without a new shell
# core.hooksPath needs to be unset, pre-commit refuses to install with it set
install:
ifdef VIRTUAL_ENV
	pip install --upgrade pip
	pip install --upgrade ansible-core ansible-lint pre-commit passlib proxmoxer requests detect-secrets pyahocorasick
else
	pipx install ansible-core || pipx upgrade ansible-core
	pipx inject ansible-core ansible-lint --include-apps
	pipx inject ansible-core pre-commit --include-apps
	pipx inject ansible-core passlib
	pipx inject ansible-core proxmoxer requests detect-secrets pyahocorasick
endif
	git config --local --unset-all core.hooksPath || true
	pre-commit install
	ansible-galaxy collection install -r ansible/requirements.yml

uninstall:
ifdef VIRTUAL_ENV
	pip uninstall -y ansible-core ansible-lint pre-commit passlib proxmoxer requests
else
	pipx uninstall ansible-core
endif

lab-bootstrap:
	cd ansible && ansible-playbook lab_bootstrap.yml

play:
	cd ansible && ansible-playbook playbook.yml $(if $(LIMIT),--limit $(LIMIT),)

verify:
	cd ansible && ansible-playbook verify.yml $(if $(LIMIT),--limit $(LIMIT),) $(if $(SKIP_TAGS),--skip-tags $(SKIP_TAGS),)

lint:
	cd ansible && ansible-lint
	cd tofu/proxmox && tflint --recursive --config "$(PWD)/tofu/proxmox/.tflint.hcl"

lint-fix:
	cd ansible && ansible-lint --fix
	cd tofu/proxmox && tflint --recursive --config "$(PWD)/tofu/proxmox/.tflint.hcl" --fix

tofu-proxmox:
	cd tofu/proxmox && ../tofu.sh $(ARGS)

COMMA := ,
tofu-recreate:
	cd tofu/proxmox && ../tofu.sh apply $(addprefix -replace=proxmox_virtual_environment_vm.,$(subst $(COMMA), ,$(HOSTS)))

sync-pihole:
	cd ansible && ansible -m ansible.builtin.systemd -b -a "name=nebula-sync state=started" centaurus

PVE_ISO_VERSION ?= 9.1-1

generate-proxmox-answer:
	$(eval ROOT_PASS := $(shell op item get "Proxmox Root User" --fields password --reveal))
	$(eval ROOT_PASS_HASHED := $(shell python3 -c "from passlib.hash import sha512_crypt; print(sha512_crypt.hash('$(ROOT_PASS)'))"))
	$(eval SYSADMIN_KEY := $(shell op item get "SysAdmin SSH Key" --fields "public key"))
	@sed \
	  -e 's|%%ROOT_PASSWORD_HASHED%%|$(ROOT_PASS_HASHED)|' \
	  -e 's|%%SYSADMIN_PUBLIC_KEY%%|$(SYSADMIN_KEY)|' \
	  proxmox_installer/answer.toml.template > proxmox_installer/answer.toml
	@echo "Generated proxmox_installer/answer.toml"

build-proxmox-iso: generate-proxmox-answer
	docker run --rm \
	  -v "$(PWD)/proxmox_installer:/work" \
	  debian:trixie \
	  bash -c "set -e && \
	    apt-get update -qq && \
	    apt-get install -y -qq wget gnupg2 && \
	    wget -qO /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg && \
	    echo 'deb http://download.proxmox.com/debian/pve trixie pve-no-subscription' > /etc/apt/sources.list.d/pve.list && \
	    apt-get update -qq && \
	    apt-get install -y -qq proxmox-auto-install-assistant && \
	    wget -q --show-progress -O /tmp/proxmox-ve.iso https://enterprise.proxmox.com/iso/proxmox-ve_$(PVE_ISO_VERSION).iso && \
	    proxmox-auto-install-assistant prepare-iso /tmp/proxmox-ve.iso \
	      --fetch-from iso \
	      --answer-file /work/answer.toml \
	      --output /work/proxmox-ve_$(PVE_ISO_VERSION)-auto.iso"
	@echo "Built proxmox_installer/proxmox-ve_$(PVE_ISO_VERSION)-auto.iso"
