# raspbian role

Configures Raspberry Pi OS-specific settings on andromeda.

## What it does

- Configures the wf-panel-pi clock format for the labwc desktop

## Why this role exists separately

andromeda runs Raspberry Pi OS (trixie), not Debian/Ubuntu. It has a different desktop environment (labwc + wf-panel-pi), a different network management setup, and SSH hardening is skipped for the `raspbian_nodes` group — there is no `root` user on Raspbian; `kate` is the privileged user. A separate role keeps these Raspbian-specific concerns isolated.

## Desktop config

andromeda runs labwc (Wayland compositor) with wf-panel-pi. The clock format is configured via `clock_time_format` in `~/.config/wf-panel-pi/wf-panel-pi.ini`. The 12-hour format `%-l:%M %p` uses `%-l` to avoid the leading space on single-digit hours. Changes take effect on next panel restart (logout/login).

The config key was found in `/usr/share/wf-panel-pi/metadata/clock.xml` from the `wfplug-clock` package — the ini key names are not otherwise documented.

## Network

andromeda is on WiFi. The NM connection name includes the SSID (`netplan-wlan0-<SSID>`), making it fragile to target directly in Ansible. DNS configuration (systemd-resolved drop-in) is managed by the `pihole` role using an interface-agnostic approach that avoids this problem.

Note: systemd-resolved is not installed by default on Raspbian trixie. The pihole role installs it before configuring it.

## first_run_user

andromeda uses `first_run_user: kate` in `playbook.yml` (the only host that does). On all other hosts the first-run user is `ansible`, provisioned by cloud-init. On andromeda, `kate` is the only privileged user available before the ansible user is created.
