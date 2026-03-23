# ansible role

Configures the `ansible` OS user and hardens SSH across the lab.

## What it does

- Creates the `ansible` OS user with the automation SSH key from 1Password
- Hardens SSH (`PermitRootLogin no`, `PasswordAuthentication no`, etc.) on hosts where it applies

## Why SSH hardening is conditional

SSH hardening is skipped for `proxmox_nodes` and `raspbian_nodes`. Proxmox manages its own sshd config and hardening it via Ansible risks breaking Proxmox's own SSH access. Raspbian uses `kate` as the privileged user (not `root` due to Raspbian OS restrictions) and runs with a different SSH trust model — see the `raspbian` role.
