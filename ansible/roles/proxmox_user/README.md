# proxmox_user role

Creates Proxmox users, groups, roles, and API tokens. Stores tokens in 1Password. Used in bootstrap for the `ansible` and `opentofu` service accounts, and from other roles (home_assistant) for their service users.

// TODO: Move these all to the proxmox nodes subdirectory I think

## Task files

// TODO: when do we need the root user (hence read_root_password); can't we just use the API token for Ansible?

- `admin_user` — creates a PAM admin user with the Administrator role (used for kate@pam in bootstrap)
- `service_user` — creates a PVE or PAM service user with group, roles, and ACL assignment
- `api_token` — creates an API token for a user and stores it in 1Password
- `read_root_password` — fetches the Proxmox root password from 1Password (required for community.proxmox modules)

## service_user: single role vs multiple roles

The task supports two calling conventions:

**Single role** (one role named after the user, the common case):

```yaml
proxmox_user_service_user_name: opentofu
proxmox_user_service_user_privs:
  - Datastore.Allocate
  - VM.Allocate
```

**Multiple roles** (for users that need purpose-specific roles, e.g. Home Assistant):

```yaml
proxmox_user_service_user_name: homeassistant
proxmox_user_service_user_roles:
  - name: HomeAssistant.Audit
    privs: [VM.Audit, Sys.Audit, Datastore.Audit]
  - name: HomeAssistant.VMPowerMgmt
    privs: [VM.PowerMgmt]
```

In both cases `privs` is a list — joined to a comma-separated string at the pvesh call site.

## Why all pvesh tasks delegate_to enterprise

// TODO: Again, why aren't we just calling these tasks on the enterprise host instead of delegating_to

pvesh is a Proxmox CLI tool that only exists on the Proxmox host. The `service_user` and `api_token` tasks were originally only called from bootstrap plays that run on enterprise directly. When roles started calling them from other VMs (home_assistant on codsworth), delegation became necessary. `delegate_to: enterprise` is safe from bootstrap too — enterprise→enterprise delegation is a no-op.

## Why privsep=0 on API tokens

// TODO do we actually have to verify that privsep shows 0? Why wouldn't it?

Proxmox creates API tokens with privilege separation enabled by default, giving the token an independent empty permission set regardless of the user's ACLs. Setting `privsep=0` (or unchecking "Privilege Separation" in the UI) makes the token inherit the user's permissions. Always verify `privsep` shows `0` after token creation for service users.

## Role update idempotency limitation

`pvesh` has no role-update command — only delete and recreate. If `proxmox_user_service_user_privs` or `proxmox_user_service_user_roles` changes for an existing role, re-running the playbook leaves the role stale. This is a known limitation. To update a role's privileges, delete it manually in Proxmox and re-run the play.

## Realms: pam vs pve

- `pam` — users that also exist as OS users on the Proxmox host (kate, ansible, opentofu). These can authenticate via PAM.
- `pve` — API-only users with no OS account (homeassistant). The default realm is `pam`; specify `proxmox_user_service_user_realm: pve` for API-only accounts.
