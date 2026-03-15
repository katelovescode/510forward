# Install all dependencies and set up pre-commit hooks
# Any injected packages need --include-apps to expose the binaries to path immediately without a new shell
# core.hooksPath needs to be unset, pre-commit refuses to install with it set
install:
ifdef VIRTUAL_ENV
	pip install ansible-core ansible-lint pre-commit passlib
else
	pipx install ansible-core
	pipx inject ansible-core ansible-lint --include-apps
	pipx inject ansible-core pre-commit --include-apps
	pipx inject ansible-core passlib
endif
	git config --local --unset-all core.hooksPath || true
	pre-commit install
	ansible-galaxy collection install -r ansible/requirements.yml

uninstall:
ifdef VIRTUAL_ENV
	pip uninstall -y ansible-core ansible-lint pre-commit passlib
else
	pipx uninstall ansible-core
endif