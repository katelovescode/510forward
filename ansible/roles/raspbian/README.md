# raspbian role

## What it does

- Configures the wf-panel-pi clock format for the labwc desktop
- Optionally creates a dedicated kiosk user that autologs in and launches Chromium in kiosk mode

## Desktop config

andromeda runs labwc (Wayland compositor) with wf-panel-pi. The clock format is configured via `clock_time_format` in `~/.config/wf-panel-pi/wf-panel-pi.ini`. The 12-hour format `%-l:%M %p` uses `%-l` to avoid the leading space on single-digit hours. Changes take effect on next panel restart (logout/login).

The config key was found in `/usr/share/wf-panel-pi/metadata/clock.xml` from the `wfplug-clock` package — the ini key names are not otherwise documented.

## Kiosk mode

When `raspbian_kiosk_enabled: true` on a host, the role:

1. Creates a locked OS user (`raspbian_kiosk_user`, default `kiosk`) with no password and no sudo.
2. Installs `chromium-browser`.
3. Drops `/etc/lightdm/lightdm.conf.d/50-kiosk-autologin.conf` to autologin as the kiosk user on boot.
4. Writes `~/.config/labwc/autostart` for the kiosk user to launch Chromium in kiosk mode at `raspbian_kiosk_url`.

The kiosk user's desktop session is completely separate from kate's — no creds, no terminal access, just Chromium.

**Screen blanking:** not currently managed. If the display goes to sleep, configure the compositor's idle settings manually or extend this role.

## Network

andromeda is on WiFi. The NM connection name includes the SSID (`netplan-wlan0-<SSID>`), making it fragile to target directly in Ansible. DNS configuration (systemd-resolved drop-in) is managed by the `pihole` role using an interface-agnostic approach that avoids this problem.

## first_run_user

`first_run_user` overrides the default `ansible` connection user for the base configuration play:

- **andromeda** — `first_run_user: kate`. Kate is the only privileged user available before the ansible user is created (no cloud-init on Raspberry Pi).
- **lxc_containers group** — `first_run_user: root` via `group_vars/lxc_containers/vars.yml`. LXC containers inject SSH keys to root; the ansible user doesn't exist until after the first `make host-bootstrap` run.

All other hosts default to the `ansible` user, which cloud-init provisions at first boot.
