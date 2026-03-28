# onepassword role

Abstraction over the `op` CLI for reading, upserting, and deleting 1Password items from Ansible.

## Actions

- `read` — fetches an item by title, sets `onepassword_item_result` fact on all play hosts. Fails hard if the item does not exist.
- `upsert` — creates or updates an item; only writes if declared field values have changed (idempotent).
- `delete` — removes an item.

## Authentication

This role requires the 1Password desktop app (beta build) with integrations enabled. The `op` CLI runs on the controller — all commands are delegated to localhost where the service account token is available via `.envrc`.

**All secrets must come from 1Password via this role.** Never hardcode credentials, store them in plaintext vars, or prompt at runtime. If a credential does not exist in 1Password yet, add a task to create it first (see `proxmox_user/tasks/api_token.yml` for an example). See the main README for the exceptions - .envrc handles those.

## Interface reference

### `onepassword_item` fields

```yaml
onepassword_item:
  title: "..." # required; must match the item title in 1Password exactly
  category: LOGIN # required for upsert; 1Password-native (LOGIN, PASSWORD, API_CREDENTIAL, etc.)
  tags: [ansible-managed] # caller declares; role always adds "ansible" automatically
  fields:
    - id: username # stable identifier; used for change detection and result lookup
      type: STRING
      purpose: USERNAME # optional; 1Password-native (USERNAME, PASSWORD)
      label: username # display name in 1Password UI
      value: "{{ admin_email }}"
    - id: password
      type: CONCEALED
      purpose: PASSWORD
      label: password
      # omit value → auto-generated (see below)
```

### Role variables

| Variable                  | Required | Description                                                                       |
| ------------------------- | -------- | --------------------------------------------------------------------------------- |
| `onepassword_action`      | yes      | `read`, `upsert`, or `delete`                                                     |
| `onepassword_item`        | yes      | Item descriptor (see above)                                                       |
| `onepassword_item_result` | —        | Set as a fact after `read` or `upsert`; contains the full item including `fields` |

### Auto-generation

Any `CONCEALED` field with no `value` key is auto-generated:

- Item does not exist: generate a random string and store it.
- Item exists: use the stored value — no comparison, no write for that field.

Default generation parameters: `length: 32, special: true`. Override per field:

```yaml
- id: password
  type: CONCEALED
  label: password
  length: 16 # optional, default 32
  special: false # optional, default true — use for services that reject special characters
```

### Tags

The role stamps the `ansible` tag on every write. The caller also declares one of:

- `ansible-managed` — Ansible owns the full lifecycle; reconciles on every run.
- `ansible-bootstrap` — Ansible created this once; will not modify it after creation.

Manually managed items are never written by Ansible and are never tagged by it.

### Item title validation

A pre-commit hook (`ansible/scripts/check_1password_titles.py`) validates all item title strings referenced in the codebase against actual 1Password items at commit time. If you rename an item in 1Password, update every reference in the code before committing.

### `op` CLI quirks

- `op item create` and `op item edit` fail when stdin is a pipe — always append `</dev/null` to shell commands calling these.
- `op item create --category ssh` does not support `--template`. (SSH key lifecycle is handled by the `identity` role.)
- `ssh-keygen -y -f /dev/stdin` fails on macOS — write the key to a temp file via `mktemp` instead.

---

## Reading fields from results

After any `read` or `upsert`, fields are available on `onepassword_item_result`. Always select by `id`, never `label` — labels are display names visible in the 1Password UI and can be renamed by a human without Ansible knowing. The `id` is stable.

```yaml
- name: Read the item
  ansible.builtin.include_role:
    name: onepassword
  vars:
    onepassword_action: read
    onepassword_item:
      title: "My 1Password Item"
  no_log: true

- name: Extract a field value
  ansible.builtin.set_fact:
    _my_role_secret: >-
      {{
        onepassword_item_result.fields |
        selectattr('id', 'equalto', 'field_id_here') |
        map(attribute='value') | first
      }}
  no_log: true
```

To find which field `id` to use for an existing item: run `op item get "Item Title" --format json --reveal` and look at the `id` on each field object.

---

## Pattern catalogue

When adding a new credential, find the pattern that matches and copy it.

### Pattern A — Login (username + password)

_Use for: NPM, GitLab, OS admin user_

```yaml
onepassword_item:
  title: "NGINX Proxy Manager Admin"
  category: LOGIN
  tags: [ansible-managed]
  fields:
    - {
        id: username,
        type: STRING,
        purpose: USERNAME,
        label: username,
        value: "{{ admin_email }}",
      }
    - { id: password, type: CONCEALED, purpose: PASSWORD, label: password }
    # omit value → auto-generated (length: 32, special: true)
```

---

### Pattern B — Password only

_Use for: Pi-hole, any service with no username concept_

```yaml
onepassword_item:
  title: "Pi-hole Admin Password"
  category: PASSWORD
  tags: [ansible-managed]
  fields:
    - { id: password, type: CONCEALED, purpose: PASSWORD, label: password }
```

`PASSWORD` category (not `LOGIN`) is semantically correct here and displays more cleanly in the 1Password UI.

---

### Pattern C — API token

_Use for: Proxmox API tokens, bearer tokens with a separate ID and secret. Omit `token_id` if the token is a single opaque string._

```yaml
# With token ID and secret
onepassword_item:
  title: "Proxmox Ansible API Token"
  category: API_CREDENTIAL
  tags: [ansible-bootstrap]
  fields:
    - { id: token_id, type: STRING, label: "token id", value: "{{ token_id }}" }
    - { id: credential, type: CONCEALED, label: credential, value: "{{ token_secret }}" }

# Single-credential variant (no token_id)
onepassword_item:
  title: "Some API Key"
  category: API_CREDENTIAL
  tags: [ansible-bootstrap]
  fields:
    - { id: credential, type: CONCEALED, label: credential, value: "{{ token }}" }
```

---

### Pattern D — Manually managed (read only)

_Use for: any credential a human creates and maintains in 1Password_

```yaml
onepassword_action: read
onepassword_item:
  title: "Proxmox Root User"
# Missing item is a hard failure — item must exist before running the play
```

**Known manually managed items:**

| Item                             | Field id     | Notes                                |
| -------------------------------- | ------------ | ------------------------------------ |
| Proxmox Root User                | `password`   | Standard LOGIN item                  |
| Home Assistant Ansible API Token | `credential` | Field id confirmed via `op item get` |
