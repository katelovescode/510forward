#!/bin/sh
op read "op://$(op vault get homelab --format json | jq -r '.id')/Ansible Vault Password/password"
