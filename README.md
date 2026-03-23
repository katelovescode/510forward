# 510 Forward

![images/guinanpicard.jpg](images/guinanpicard.jpg)
_"The idea of fitting in just repels me."_ - Guinan

## Homelab Portal

Setting up a homelab. Why am I doing this to myself?

- Layer 2 Switching & Layer 3 Routing
  - managed switch
  - router/firewall
  - VLANs to isolate traffic between Docker, Proxmox and other services
  - How to secure traffic
- DNS
  - maps friendly names to IP addresses
  - helps to automate certs w/ let's encrypt
  - can use the dns resolver in your router, but if you want more control you can use Pi-Hole and AdGuard home
  - Technitium
- DHCP
  - Every client can automatically get an IP address
  - You can create reservations that tie a specific IP address to a specific MAC address
  - PfSense, OpenSense, most of them have DHCP
- Reverse Proxy
  - Runs in a container - Docker host should be online at this point - single entry point for your services
  - NGINX Proxy Manager is beginner-friendly
  - Traefik is this guy's favorite, good for docker swarm and kubernetes, auto-detect containers
  - Caddy - middle ground, auto-certificate
- Monitoring
- Security

Steps for a new device:

- Bring new node online
- Point to DNS & DHCP service
- Node under Lab system
- Set up DNS entries/Set up DHCP reservations
- Friendly name & predictable IP
- Reverse Proxy setup
- HTTPS url
- Add dockerized services behind Proxy

### Disaster Recovery

#### MiniPC

- Boot from the USB stick that is formatted with the custom-built ISO for Proxmox
- Run the automatic installer
- Reboot and remove the USB stick

TODO: all things should be VMs, not LXCs - or run by docker inside a VM or whatever
Maybe running my own DHCP will make it so I can assign fixed IPs?

## Lab Bootstrap

### Prerequisites

- Proxmox installed and accessible at enterprise IP
- 1Password CLI installed and authenticated on controller
- Vault password file present at ./secrets/vault_password

## Why `become` is scoped per-task

Global `become: true` is prohibited by ansible-lint. Every task that needs privilege escalation declares it explicitly. This is a hard requirement across the entire codebase.
