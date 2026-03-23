# ansible role

Configures the `ansible` OS user and hardens SSH across the lab.

## What it does

- Creates the `ansible` service user (via `os_user/service_user`) with the automation SSH key from 1Password
- Hardens SSH (`PermitRootLogin no`, `PasswordAuthentication no`, etc.) on hosts where it applies

`qemu-guest-agent` installation and service management live in the `proxmox` role (`tasks/vms/`) — not here.

## Why SSH hardening is conditional

SSH hardening is skipped for `proxmox_nodes` and `raspbian_nodes`. Proxmox manages its own sshd config and hardening it via Ansible risks breaking Proxmox's own SSH access. Raspbian uses `kate` as the privileged user (not `root`) and runs with a different SSH trust model — see the `raspbian` role.

## Why `become` is scoped per-task

Global `become: true` is prohibited by ansible-lint. Every task that needs privilege escalation declares it explicitly. This is a hard requirement across the entire codebase.
