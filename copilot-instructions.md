# Copilot Instructions: NixOS Colmena Infrastructure

## Project Overview

This is a **hybrid infrastructure** combining declarative NixOS configuration (via **Colmena**) with dynamic containerized services deployed via **Docker Swarm**:

- **Static Layer** (this repo): NixOS configuration for machines, third-party services (Freshrss, Nextcloud, Mattermost, Vaultwarden, RSSBridge), DNS, firewalls, backups, and base system configuration. Managed declaratively via Nix.
- **Dynamic Layer** (external repos + CI/CD): Custom applications and microservices orchestrated by Docker Swarm. Autodiscovered and routed by Traefik. Managed independently via separate Git repositories and deployment pipelines.
- **Networking**: Caddy (host) terminates TLS for all traffic → Traefik (container) routes to Swarm services. Traefik also routes legacy static services still running in NixOS containers.

**Technology Stack**:
- **Language**: Nix (static layer) + Docker Compose/Swarm (dynamic layer)
- **Deployment**: Colmena v0.4.x (static), Docker Swarm (dynamic)
- **Orchestration**: Home Manager, sops-nix (static secrets), Docker Swarm secrets (dynamic)
- **Targets**: x86_64-linux, NixOS 25.11

## Machine Architecture

### `hiraeth` (Server)
- **Role**: Central infrastructure hub — runs static services and Docker Swarm orchestrator
- **Static Services** (NixOS containers): DNS, third-party web apps (Freshrss, Nextcloud, Mattermost, Vaultwarden, RSSBridge), Headscale VPN, Borgmatic backups, GitHub CI runner
- **Dynamic Layer**: Docker Swarm orchestrator + Traefik service mesh (autodiscovers Swarm services)
- **Frontals**: 
  - **Caddy**: Host-level reverse proxy, TLS termination for all external traffic
  - **Traefik**: Container-level routing for both NixOS containers (192.168.100.0/24) and Docker Swarm services
- **Hardware**: Uses hardware-configuration.nix for EFI/BIOS, secure boot (Lanzaboote)
- **Networking**: nftables firewall, Docker Swarm overlay networks, NAT for legacy NixOS containers (192.168.100.0/24), external interface `eno1`

### `music` (Desktop)
- **Role**: Personal desktop/workstation
- **Services**: Sway window manager, DNS, Tailscale VPN, local development tools
- **Desktop Environment**: Sway (Wayland compositor) with Fish shell

### Shared Configuration
- **Base module** ([modules/base.nix](modules/base.nix)): SSH hardening, systemd-boot, console/locale settings, common programs, Docker daemon setup
- **Home Manager**: User environments (jtremesay, root)
- **Secrets (Static Layer)**: Age-encrypted via sops-nix, stored in [secrets/default.yaml](secrets/default.yaml)
- **Secrets (Dynamic Layer)**: Managed via Docker Swarm secrets or injected by external CI/CD pipelines (outside scope of this repo)

## Infrastructure Architecture: Static vs Dynamic

Understanding the separation of concerns is critical:

### Static Layer (This Repository)
**What**: Declarative NixOS configuration for machines, third-party services, system-level settings.  
**Managed By**: Colmena deployments, sops-nix for secrets.  
**Scope**: Machines, base OS, DNS, firewalls, certified third-party services (Freshrss, Nextcloud, etc.), backups.  
**Key Principle**: Everything is declared in Nix — can be fully reproduced by running `colmena apply`.

**Services in Static Layer** (all run in NixOS containers):
- DNS (systemd-resolved, coredns)
- Reversing Proxy chain: Caddy (host) → Traefik (container) → services
- Third-party software: Freshrss, Nextcloud, Mattermost, Vaultwarden, RSSBridge
- Backup system: Borgmatic
- CI/CD runner: GitHub Actions runner
- VPN: Headscale

### Dynamic Layer (External Repositories)
**What**: Custom applications and microservices, orchestrated by Docker Swarm, managed via external Git repos and CI/CD pipelines.  
**Managed By**: Docker Swarm + service CI/CD pipelines (outside this repo).  
**Scope**: Custom applications, business logic, frequently-deployed services.  
**Key Principle**: Deploy independently without touching this repo. Traefik autodiscovers and routes via Swarm labels.

**Why Separate?**
- Static layer (Nix) is immutable, reproducible, version-controlled, and slow-to-rebuild:
  - Pulling third-party Docker images in Nix is non-declarative
  - NixOS containers have overhead for simple services
  - Rebuilding static layer for each app change is inefficient
- Dynamic layer (Swarm) is mutable, fast, and tight-loop friendly:
  - Deploy, scale, update services without full NixOS rebuild
  - Each service owns its deploy pipeline
  - Better for rapid iteration on personal projects

### Traffic Flow
```
External request
    ↓
Internet → eno1:443 (Caddy on host)
    ↓
Caddy terminates TLS, routes to backend
    ↓
┌─────────────────────────────────────┐
│         Traefik (container)         │ (routes based on Host header)
├─────────────────┬───────────────────┤
│  NixOS Services │  Docker Services  │
│  (192.168.100.x)│  (Swarm overlay)  │
│                 │                   │
│ • Freshrss      │ • App1            │
│ • Nextcloud     │ • App2            │
│ • Mattermost    │ • microservice-x  │
│ • ...           │ • ...             │
└─────────────────┴───────────────────┘
```

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

### 4. **Service Routing via Caddy & Traefik**

**Caddy** (running on host) handles TLS termination:
```bash
# docker/traefik/compose.yaml - Caddy listens on :443
services:
  caddy:
    ports:
      - "443:443"      # External TLS
    environment:
      - BACKEND=http://traefik:80  # Forward to Traefik
```

**Traefik** (running in `containers.traefik`) routes traffic to both NixOS and Swarm services:

**For NixOS containers** (legacy pattern in static layer):
```nix
services.traefik.dynamicConfigOptions = {
  http = {
    routers."SERVICE_NAME" = {
      rule = "Host(`${cfg.host}`)";
      service = "SERVICE_NAME";
      entryPoints = [ "https" ];  # Already decrypted by Caddy
    };
    services."SERVICE_NAME" = {
      loadBalancer.servers = [
        { url = "http://${cfg.localAddress}:80"; }  # 192.168.100.x
      ];
    };
  };
};
```

**For Docker Swarm services** (dynamic layer, autodiscovered):
Traefik discovers services via Docker Swarm labels at deployment time. Example from external app repo:
```yaml
services:
  myapp:
    image: myapp:latest
    deploy:
      labels:
        - traefik.enable=true
        - traefik.http.routers.myapp.rule=Host(\"myapp.jtremesay.org\")
        - traefik.http.services.myapp.loadbalancer.server.port=8080
```

**Key Points**:
- Caddy is the single entry point (TLS termination)
- Traefik routes all backend traffic (both static NixOS and dynamic Swarm)
- NixOS services: declarative in Nix, static IP addresses
- Swarm services: autodiscovered via labels, deployed externally

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

## Adding a New Service

### Adding a Static Service (NixOS Container)

For third-party or infrastructure services that should be managed declaratively in Nix.

#### Step 1: Create Module File

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

#### Step 2: Add to Machine Configuration

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

#### Step 3: Add Secrets

Edit secrets file:

```bash
sops edit secrets/default.yaml
```

Add YAML entry:
```yaml
newservice:
  api_key: "your-secret-value-here"
```

#### Step 4: Deploy

```bash
nixos-rebuild switch --flake .#hiraeth
# Or via Colmena:
colmena apply --on hiraeth
```

### Adding a Dynamic Service (Docker Swarm)

For custom applications that should be deployed independently via Swarm.

**This approach**:
1. Create a separate Git repository for the service
2. Include `docker-compose.yml` or `docker-stack.yml` with Traefik labels
3. Use CI/CD pipeline (e.g., GitHub Actions) to deploy to Swarm
4. Traefik automatically discovers and routes the service
5. **No changes needed in this repo**

Example:
```yaml
# In external app repo: docker-stack.yml
version: '3.8'
services:
  myapp:
    image: registry.example.com/myapp:latest
    deploy:
      replicas: 2
      labels:
        traefik.enable: "true"
        traefik.http.routers.myapp.rule: "Host(\"myapp.jtremesay.org\")"
        traefik.http.services.myapp.loadbalancer.server.port: "8080"
    environment:
      - LOG_LEVEL=info
      # Secrets injected by Docker Swarm or CI/CD
      - DB_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    external: true  # Created by CI/CD pipeline
```

Deploy via CI/CD:
```bash
docker stack deploy -c docker-stack.yml myapp
```

**Benefit**: Update frequency, scale, and secrets are independent. This repo doesn't need to rebuild.

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

### Flake Inputs (Static Layer)
- `colmena` – Distributed NixOS deployment
- `home-manager` – User-specific configurations
- `nixpkgs` – NixOS 25.11 package repository
- `sops-nix` – Age-encrypted secrets integration
- `lanzaboote` – Secure Boot support

### Important Paths (Static Layer)
- `flake.nix` – Project entry point, machine definitions
- `machines/*/configuration.nix` – Machine-specific config
- `modules/` – Reusable NixOS modules for static services
- `secrets/default.yaml` – Age-encrypted secret store (NixOS services)
- `users/*/default.nix` – Home Manager configurations
- `.sops.yaml` – Secrets encryption key management
- `docker/traefik/` – Caddy + Traefik configuration for routing

### Dynamic Layer (External)
- Separate Git repositories per service/project
- Docker Swarm stack files (`docker-stack.yml`)
- CI/CD pipelines (GitHub Actions, etc.) for deployment
- Docker Swarm secrets (managed externally)
- See Traefik labels in service stacks for routing rules

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
1. Verify container IP: `ip addr` inside container (NixOS services)
2. Check Swarm services: `docker service ls` (dynamic services)
3. Inspect Traefik config: `curl http://localhost:8080/api/http/routers` (Traefik API)
4. Test DNS: `dig service.jtremesay.org`
5. Check Caddy logs: `docker logs caddy` or `journalctl -xe` on host

**Docker Swarm service not discovered**:
1. Verify Traefik labels are correct in docker-compose
2. Check Traefik logs: `docker service logs -f traefik_traefik`
3. Confirm service is running: `docker service ps SERVICE_NAME`
4. Test connectivity: `docker exec CONTAINER_ID curl http://localhost:8080`

## References

### Static Layer (NixOS / Nix)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [Home Manager Manual](https://nix-community.github.io/home-manager/options.xhtml)
- [Colmena Documentation](https://colmena.cli.rs/unstable/)
- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [Lanzaboote (SecureBoot)](https://github.com/nix-community/lanzaboote)

### Dynamic Layer (Docker / Swarm)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Compose Specification](https://github.com/compose-spec/compose-spec)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Labels for Traefik](https://doc.traefik.io/traefik/providers/docker/)
- [Caddy Documentation](https://caddyserver.com/docs/)

### Hybrid Architecture
- [NixOS Containers](https://nixos.wiki/wiki/NixOS_Containers)
- [Docker Integration with NixOS](https://nixos.wiki/wiki/Docker)

## Style Guide

1. **Code Format**: Use `nixfmt-rfc-style` for all Nix files
2. **Option Names**: Use snake_case for custom options (`config.slaanesh.service_name`)
3. **Comments**: Explain *why* (not *what*) — code is usually self-explanatory
4. **Container IPs**: Allocate from 192.168.100.0/24, starting from .10
5. **Secrets**: Keep them organized by service in `secrets/default.yaml`
6. **Module Imports**: Keep imports in alphabetical order where possible
