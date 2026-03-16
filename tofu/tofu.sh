#!/usr/bin/env bash
set -euo pipefail

TF_VAR_proxmox_api_token="$(op item get "Proxmox OpenTofu API Token" --vault "$OP_VAULT_ID" --fields label=username --format json | jq -r .value)=$(op item get "Proxmox OpenTofu API Token" --vault "$OP_VAULT_ID" --fields label=password --format json | jq -r .value)"
export TF_VAR_proxmox_api_token

TF_VAR_opentofu_ssh_private_key=$(op read "op://$OP_VAULT_ID/OpenTofu SSH Key/private key?ssh-format=openssh")
export TF_VAR_opentofu_ssh_private_key

TF_VAR_sysadmin_public_key="$SYSADMIN_PUBLIC_KEY"
export TF_VAR_sysadmin_public_key

tofu "$@"