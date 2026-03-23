# nginx_proxy_manager role

Deploys Nginx Proxy Manager (NPM) via Docker Compose on norville, issues a wildcard TLS certificate via Cloudflare DNS-01, and manages proxy hosts via the NPM API.

## What it does

- Deploys NPM (`jc21/nginx-proxy-manager:latest`) via Docker Compose
- Issues a `*.510forward.space` wildcard cert via Let's Encrypt DNS-01 (Cloudflare)
- Creates and updates proxy hosts via the NPM REST API
- Associates the wildcard cert with all proxy hosts

## Why Docker Compose, not native install

NPM distributes exclusively via Docker. Native installs require extracting the rootfs from the Docker image, which is fragile and unsupported. Docker is the correct deployment method.

## TLS certificate via API

The wildcard cert is issued via `POST /api/nginx/certificates`. NPM's schema for this endpoint is strict (`additionalProperties: false`). Valid `meta` fields for Cloudflare DNS-01:

- `dns_challenge: true`
- `dns_provider: cloudflare`
- `dns_provider_credentials: "dns_cloudflare_api_token = <token>"`
- `propagation_seconds` (integer, optional)

Fields that are **not** in the schema and will cause a 400: `letsencrypt_agree`, `letsencrypt_email`. These were removed in NPM 2.14.0.

The Cloudflare token is read from 1Password ("Cloudflare DNS API Token") using `selectattr('label', 'equalto', 'credential')` — field `label`, not `id`.

Cert creation has `timeout: 120` because DNS propagation takes 30–60 seconds. Idempotency: GET `/api/nginx/certificates`, check if a cert matching the wildcard domain already exists, skip creation if found. NPM handles renewal automatically.

## Proxy host management

Proxy hosts are defined in `nginx_proxy_manager_proxy_hosts` in norville's `host_vars`. Each entry specifies subdomain, backend host, port, scheme, and optionally `allow_websocket_upgrade`.

**WebSocket** must be enabled per-host for services that use it:
- Proxmox (`enterprise`) — required for noVNC console
- Home Assistant (`codsworth`) — required for the HA frontend

## Initial admin credentials

NPM reads `INITIAL_ADMIN_EMAIL` and `INITIAL_ADMIN_PASSWORD` from the Docker Compose environment on first boot only (ignored if the admin already exists). These are set from 1Password in the Compose template so no manual rotation step is needed.

## Why `bcrypt`, not `bcryptjs`

NPM uses the native Node `bcrypt` module. `bcryptjs` (pure JS) is a separate package that produces compatible hashes but is not what NPM ships. This matters if you ever try to pre-hash passwords — use the same library NPM uses.
