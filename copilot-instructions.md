# Copilot Instructions: NixOS Colmena Infrastructure

## Project Overview

This is a **NixOS infrastructure** managed with **Colmena**, a distributed NixOS deployment orchestrator. The project provides declarative, reproducible configuration for multiple personal machines with automated secrets management, containerized services, backup automation, and centralized security policies.

- **Language**: Nix (functional configuration language for NixOS)
- **Deployment**: Colmena v0.4.x + Home Manager + sops-nix (secrets encryption)
- **Target**: x86_64-linux (NixOS 25.11)

## Machine Architecture

### `hiraeth` (Server)
- **Role**: Multi-service production server
- **Services**: DNS, Traefik reverse proxy, containerized web apps (Freshrss, Nextcloud, Mattermost, Vaultwarden, RSSBridge), Headscale VPN, Borgmatic backups, GitHub CI runner
- **Hardware**: Uses hardware-configuration.nix for EFI/BIOS, secure boot (Lanzaboote)
- **Networking**: nftables firewall, NAT for containers (192.168.100.0/24), external interface `eno1`

### `music` (Desktop)
- **Role**: Personal desktop/workstation
- **Services**: Sway window manager, DNS, Tailscale VPN, local development tools
- **Desktop Environment**: Sway (Wayland compositor) with Fish shell

### Shared Configuration
- **Base module** ([modules/base.nix](modules/base.nix)): SSH hardening, systemd-boot, console/locale settings, common programs
- **Home Manager**: User environments (jtremesay, root)
- **Secrets**: Age-encrypted via sops-nix, stored in [secrets/default.yaml](secrets/default.yaml)

## Module Organization

```
modules/
├── base.nix                 # Shared config: SSH, locale, nix defaults
├── arion.nix               # Docker Compose integration (arion)
├── secureboot.nix          # Lanzaboote integration
├── dns/
│   ├── dns.nix            # Container DNS setup
│   └── resolved.nix       # systemd-resolved configuration
├── network/
│   ├── firewall.nix       # nftables rules
│   ├── headscale.nix      # Headscale VPN
│   └── tailscale.nix      # Tailscale VPN
├── mirrors/               # Nix package mirror config
├── services/
│   ├── borgmatic.nix      # Backup automation
│   ├── docker.nix         # Docker daemon + Arion
│   └── github_ci.nix      # GitHub Actions runner
└── web/
    ├── traefik.nix        # Reverse proxy + routing
    ├── traefik_dashboard.nix  # Traefik UI
    ├── caddy.nix          # Alternative web server
    ├── freshrss.nix       # RSS reader
    ├── mattermost.nix     # Team chat
    ├── nextcloud.nix      # Cloud storage
    ├── rssbridge.nix      # RSS bridge plugin
    ├── vaultwarden.nix    # Password manager
    └── public_html.nix    # Static site serving
```

### Module Naming Convention
- Custom NixOS options are prefixed with `config.slaanesh.*` (custom namespace)
- Example: `config.slaanesh.freshrss.localAddress` defines container IP for FreshRSS
- Each service declares its own options via `lib.mkOption` with types and defaults

## Key Patterns & Conventions

### 1. **Custom NixOS Options**

Every service module (e.g., `modules/web/freshrss.nix`) follows this structure:

```nix
{ config, lib, ... }:
let
  cfg = config.slaanesh.SERVICE_NAME;
in
{
  options.slaanesh.SERVICE_NAME = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Container IP in 192.168.100.0/24 subnet";
    };
    host = lib.mkOption {
      type = lib.types.str;
      description = "Public hostname";
      default = "service.jtremesay.org";
    };
  };
  
  config = {
    # Secrets, containers, services defined here
  };
}
```

**Key Points**:
- Use `lib.mkOption` for every configurable parameter
- Reference via `cfg.fieldName` throughout the module
- Provide sensible defaults where appropriate
- Document each option's purpose and type

### 2. **Container Networking (Isolate & Connect)**

Every web service runs in a **NixOS container** with a private network:

```nix
containers.SERVICE_NAME = {
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.100.1";      # Host-side veth address
  localAddress = cfg.localAddress;    # Container-side address (must be in 192.168.100.0/24)
  
  config = { pkgs, lib, ... }: {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    # Service definitions inside container
    system.stateVersion = "25.05";
  };
};
```

**Container Networking**:
- Host forwards traffic via NAT (`config.networking.nat`)
- nftables masquerade rule handles external connectivity
- Containers communicate with host services via `192.168.100.1`
- Traefik (on host) routes external traffic to container IPs

### 3. **Secrets Management (sops-nix)**

Secrets are **age-encrypted** and injected at runtime:

```nix
config = {
  sops.secrets = {
    "SERVICE_NAME/secret_name" = { };  # Will be decrypted at runtime
  };
  
  containers.SERVICE_NAME = {
    bindMounts = {
      secret_mount = {
        hostPath = config.sops.secrets."SERVICE_NAME/secret_name".path;
        mountPoint = "/run/secrets/secret_name";
        isReadOnly = true;
      };
    };
  };
};
```

**Workflow**:
1. Add secret name to module: `sops.secrets."path/to/secret" = { }`
2. Edit encrypted file: `sops edit secrets/default.yaml`
3. Add/update secret value under the matching key
4. Traefik/services read from `/run/secrets/...` paths
5. To add new servers, get their public key: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
6. Update keys: `sops updatekeys secrets/default.yaml`

### 4. **Service Routing via Traefik**

Traefik (running in `containers.traefik`) dynamically routes all HTTP(S) traffic:

```nix
services.traefik.dynamicConfigOptions = {
  http = {
    routers."SERVICE_NAME" = {
      rule = "Host(`${cfg.host}`)";
      service = "SERVICE_NAME";
      entryPoints = [ "https" ];  # Use "http" for unencrypted
    };
    services."SERVICE_NAME" = {
      loadBalancer.servers = [
        { url = "http://${cfg.localAddress}:80"; }
      ];
    };
  };
};
```

**Key Points**:
- Service names must be unique across all modules
- Container IP must match `cfg.localAddress`
- Port inside container (usually 80) routed to external hostname
- TLS certificates auto-provisioned via Let's Encrypt

### 5. **Database Setup (PostgreSQL in Containers)**

Services needing databases delegate initialization to container's PostgreSQL:

```nix
containers.SERVICE_NAME.config = { pkgs, lib, ... }: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ config.services.SERVICE.database.name ];
    ensureUsers = [
      {
        name = config.services.SERVICE.database.name;
        ensureDBOwnership = true;
      }
    ];
  };
  
  services.SERVICE = {
    enable = true;
    database.type = "pgsql";
    # Other service config...
  };
};
```

**Persistence**:
- Containers maintain state in `/var/lib` (bind-mounted to host on hiraeth)
- PostgreSQL data persists across nixos-rebuild

### 6. **Systemd Services Inside Containers**

Custom timers/services run inside containers alongside main services:

```nix
/containers.SERVICE.config = { pkgs, lib, ... }: {
  systemd = {
    timers.SERVICE-task = {
      description = "Task Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "minutely";  # Run every minute
        Unit = "SERVICE-task.service";
      };
    };
    services.SERVICE-task = {
      description = "Task Service";
      ExecStart = "${pkgs.myapp}/bin/task-runner";
      Environment = "DATADIR=${config.services.SERVICE.dataDir}";
    };
  };
};
```

## Development Workflow

### Enter Development Environment

```bash
nix develop
```

This loads the devShell with:
- `colmena` – deployment tool
- `sops` – secrets editing
- `ssh-to-age` – convert SSH keys to age format
- `age` – encryption tool
- `nixfmt-rfc-style` – code formatter
- `nil`, `nixd` – LSPs for Nix
- `fish` – shell

### Common Tasks

**Format Code**:
```bash
nixfmt modules/web/freshrss.nix
# Or all files:
find . -name "*.nix" -exec nixfmt {} \;
```

**Update Flake Inputs**:
```bash
nix flake update
# Check what changed:
git diff flake.lock
```

**Test Configuration (Dry Run)**:
```bash
colmena apply --on hiraeth --dry-activate
```

**Deploy to Specific Machine**:
```bash
colmena apply --on hiraeth
# Deploy only the music machine:
colmena apply --on music
```

**Full Deployment**:
```bash
colmena apply
```

**Manual SSH Access**:
```bash
# SSH to hiraeth (uncomment deployment.targetHost in flake.nix)
ssh root@hiraeth.jtremesay.org

# Inside hiraeth, access container:
nixos-container root-login freshrss
```

## Adding a New Containerized Service

### Step 1: Create Module File

Create `modules/web/newservice.nix`:

```nix
{ config, lib, ... }:
let
  cfg = config.slaanesh.newservice;
in
{
  options.slaanesh.newservice = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Container IP (must be in 192.168.100.0/24)";
    };
    host = lib.mkOption {
      type = lib.types.str;
      description = "Public hostname";
      default = "newservice.jtremesay.org";
    };
  };

  config = {
    # Step 2: Define secrets needed
    sops.secrets."newservice/api_key" = { };
    
    # Step 3: Configure container
    containers.newservice = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;
      
      bindMounts = {
        api_key = {
          hostPath = config.sops.secrets."newservice/api_key".path;
          mountPoint = "/run/secrets/api_key";
          isReadOnly = true;
        };
      };

      config = { pkgs, lib, ... }: {
        imports = [ ../dns/dns.nix ];  # For DNS inside container
        
        services.newservice = {
          enable = true;
          apiKeyFile = "/run/secrets/api_key";
        };
        
        networking.firewall.allowedTCPPorts = [ 80 ];
        system.stateVersion = "25.05";
      };
    };

    # Step 4: Route via Traefik
    services.traefik.dynamicConfigOptions = {
      http = {
        routers."newservice" = {
          rule = "Host(`${cfg.host}`)";
          service = "newservice";
          entryPoints = [ "https" ];
        };
        services."newservice" = {
          loadBalancer.servers = [
            { url = "http://${cfg.localAddress}:80"; }
          ];
        };
      };
    };
  };
}
```

### Step 2: Add to Machine Configuration

Edit `machines/hiraeth/configuration.nix`:

```nix
imports = [
  # ... existing imports ...
  ../../modules/web/newservice.nix
];

slaanesh = {
  # ... existing services ...
  newservice.localAddress = "192.168.100.20";  # Pick next available IP
};
```

### Step 3: Add Secrets

Edit secrets file:

```bash
sops edit secrets/default.yaml
```

Add YAML entry:
```yaml
newservice:
  api_key: "your-secret-value-here"
```

### Step 4: Deploy

```bash
nixos-rebuild switch --flake .#hiraeth
# Or via Colmena:
colmena apply --on hiraeth
```

## Security Considerations

### Secrets Handling
- **Never commit unencrypted secrets** to git
- Age encryption keys (`.sops.yaml`) define who can decrypt
- Always use `isReadOnly = true` for secret bind mounts
- Store keys in `/run/secrets` (ephemeral, not persisted)

### Firewall & Network Isolation
- Containers use private networks (192.168.100.0/24)
- Host firewall (nftables) controls external access
- SSH limited to key-based auth only (no passwords)
- Tailscale for off-network access

### Secure Boot
- Lanzaboote manages EFI SecureBoot
- Keys stored on disk during deployment
- Threat model: assumes boot media security

## Quick Reference

### Flake Inputs
- `colmena` – Distributed NixOS deployment
- `home-manager` – User-specific configurations
- `nixpkgs` – NixOS 25.11 package repository
- `sops-nix` – Age-encrypted secrets integration
- `lanzaboote` – Secure Boot support

### Important Paths
- `flake.nix` – Project entry point, machine definitions
- `machines/*/configuration.nix` – Machine-specific config
- `modules/` – Reusable NixOS modules
- `secrets/default.yaml` – Encrypted secret store
- `users/*/default.nix` – Home Manager configurations
- `.sops.yaml` – Secrets encryption key management

### Debugging Commands

**Check NixOS options**:
```bash
man configuration.nix  # View available options
nixos-option services.traefik  # Search specific option
```

**Inspect running container**:
```bash
nixos-container root-login freshrss
systemctl status freshrss  # Inside container
journalctl -xe              # Container's journal
```

**Rebuild with debug output**:
```bash
colmena apply -- --show-trace --verbose  # Extra logging
```

**Check secrets availability**:
```bash
ls -la /run/secrets/  # Check if secrets mounted
cat /run/secrets/SERVICE/secret_name  # View value
```

### Common Issues

**Container fails to start**:
1. Check journalctl on host: `journalctl -xe`
2. Check container syntax: `nixfmt modules/web/service.nix`
3. Verify IP not duplicated: `grep localAddress machines/hiraeth/configuration.nix`

**Secrets not loading**:
1. Verify age key in `.sops.yaml`
2. Rebuild sops keys: `sops updatekeys secrets/default.yaml`
3. Check file permissions: `ls -la /run/secrets/`

**Traefik not routing**:
1. Verify container IP: `ip addr` inside container
2. Check dynamic config: `curl http://localhost:8080/api/http/routers` (Traefik API)
3. Test DNS: `dig service.jtremesay.org`

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [Home Manager Manual](https://nix-community.github.io/home-manager/options.xhtml)
- [Colmena Documentation](https://colmena.cli.rs/unstable/)
- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [Lanzaboote (SecureBoot)](https://github.com/nix-community/lanzaboote)

## Style Guide

1. **Code Format**: Use `nixfmt-rfc-style` for all Nix files
2. **Option Names**: Use snake_case for custom options (`config.slaanesh.service_name`)
3. **Comments**: Explain *why* (not *what*) — code is usually self-explanatory
4. **Container IPs**: Allocate from 192.168.100.0/24, starting from .10
5. **Secrets**: Keep them organized by service in `secrets/default.yaml`
6. **Module Imports**: Keep imports in alphabetical order where possible
