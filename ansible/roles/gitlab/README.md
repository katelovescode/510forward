# gitlab role

Installs and configures [GitLab CE](https://about.gitlab.com/) on memory-alpha. Runs behind NPM (norville) which handles TLS termination. Initial root password is managed via 1Password.

## What it does

- Adds the official GitLab apt repository and installs GitLab CE at a pinned version
- Configures `gitlab.rb` for operation behind a reverse proxy: external HTTPS URL, nginx listening on HTTP port 80, Let's Encrypt disabled
- Upserts the initial root password into 1Password ("GitLab Root Password") and sets it in `gitlab.rb` before first reconfigure
- Runs `gitlab-ctl reconfigure` when any configuration changes

## Reverse proxy configuration

NPM (norville) handles TLS termination for `https://memory-alpha.510forward.space` and forwards plain HTTP to memory-alpha:80. GitLab's bundled nginx is configured to:

- Listen on port 80 (HTTP only)
- Not attempt HTTPS or certificate management
- Report `https://memory-alpha.510forward.space` as its `external_url` so generated links and OAuth redirects use the correct public URL

## Version pinning

The installed version is controlled by `gitlab_version` in `host_vars/memory-alpha/vars.yml`. The install task checks the currently installed version via `dpkg-query` and skips installation if it matches. To upgrade, bump the version variable and re-run the play.

GitLab backup/restore requires matching major.minor versions. Pin the new instance to the same version as the old instance before restoring a backup, then upgrade afterward.

## Secret management

The root password is upserted into 1Password as "GitLab Root Password" on first run. If the item already exists the existing password is reused — the `initial_root_password` setting in `gitlab.rb` is ignored by GitLab after the first `gitlab-ctl reconfigure`, so subsequent runs are safe.
