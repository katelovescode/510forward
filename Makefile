help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  install            Install dependencies and set up pre-commit hooks"
	@echo "  uninstall          Remove installed dependencies"
	@echo "  bootstrap          Run the one-time lab bootstrap playbook"
	@echo "  play               Run the main Ansible playbook"
	@echo "  upgrade            Interactively upgrade apt packages (excludes haos_nodes, memory-alpha): make upgrade [LIMIT=host_or_group]"
	@echo "  verify             Run the verify playbook against live infrastructure"
	@echo "  lint               Run ansible-lint and tflint"
	@echo "  edit-secret        Edit a vault-encrypted file: make edit-secret FILE=path"
	@echo "  tofu-proxmox       Run OpenTofu for Proxmox: make tofu-proxmox ARGS='plan'"
	@echo "  tofu-recreate      Recreate VMs by name: make tofu-recreate HOSTS=centaurus,norville"
	@echo "  reboot-vms         Reboot all QEMU VMs (centaurus, norville, dorothy)"
	@echo "  sync-pihole        Manually trigger nebula-sync on centaurus"
	@echo "  generate-proxmox-answer  Generate proxmox_installer/answer.toml from template + 1Password"
	@echo "  build-proxmox-iso        Build auto-install ISO — runs generate-proxmox-answer automatically (PVE_ISO_VERSION=9.1-1)"
	@echo "  help               Show this help message"
	@echo ""

# Install all dependencies and set up pre-commit hooks
# Any injected packages need --include-apps to expose the binaries to path immediately without a new shell
# core.hooksPath needs to be unset, pre-commit refuses to install with it set
install:
ifdef VIRTUAL_ENV
	pip install --upgrade pip
	pip install --upgrade ansible-core ansible-lint pre-commit passlib proxmoxer requests
else
	pipx install ansible-core || pipx upgrade ansible-core
	pipx inject ansible-core ansible-lint --include-apps
	pipx inject ansible-core pre-commit --include-apps
	pipx inject ansible-core passlib
	pipx inject ansible-core proxmoxer requests
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

bootstrap:
	cd ansible && ansible-playbook lab_bootstrap.yml

bootstrap-log:
	cd ansible && ansible-playbook lab_bootstrap.yml 2>&1 | tee bootstrap_output.log

play:
	cd ansible && ansible-playbook playbook.yml

upgrade:
	cd ansible && ansible-playbook upgrade.yml $(if $(LIMIT),--limit $(LIMIT),)

verify:
	cd ansible && ansible-playbook verify.yml

play-log:
	cd ansible && ansible-playbook playbook.yml 2>&1 | tee play_output.log

lint:
	cd ansible && ansible-lint
	cd tofu/proxmox && tflint --recursive --config "$(PWD)/tofu/proxmox/.tflint.hcl"

lint-fix:
	cd ansible && ansible-lint --fix
	cd tofu/proxmox && tflint --recursive --config "$(PWD)/tofu/proxmox/.tflint.hcl" --fix

edit-secret:
	cd ansible && ansible-vault edit $(FILE)

tofu-proxmox:
	cd tofu/proxmox && ../tofu.sh $(ARGS)

COMMA := ,
tofu-recreate:
	cd tofu/proxmox && ../tofu.sh apply $(addprefix -replace=proxmox_virtual_environment_vm.,$(subst $(COMMA), ,$(HOSTS)))

reboot-vms:
	ssh -i ~/.ssh/id_ed25519_ansible_510forward ansible@enterprise "sudo qm reboot 100 && sudo qm reboot 101 && sudo qm reboot 102"

sync-pihole:
	cd ansible && ansible -b -m systemd -a "name=nebula-sync state=started" centaurus

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