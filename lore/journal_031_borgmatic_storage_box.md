URL:     https://linuxfr.org/users/killruana/journaux/borgmatic-et-hetzner-storage-box-les-sauvegardes-pas-cheres
Title:   Borgmatic et Hetzner Storage Box, les sauvegardes pas chères
Authors: jtremesay
Date:    2026-04-09T22:27:34+02:00
License: CC By-SA
Tags:    borgmatic, borgbackup, sauvegarde_système, hetzner et storage_box
Score:   0


Annexe au journal [précédent](https://linuxfr.org/users/killruana/journaux/nixos-et-colmena-la-prod-declarative-du-pauvre). Ça avait pas vraiment sa place dans le journal principal, mais j'avais pas de lien à bookmarker. Du coup je jette ça là.

## À propos de Borgmatic et des Storage Box

### Borgmatic, c'est quoi

[Borgmatic](https://torsion.org/borgmatic/) est un wrapper autour de [BorgBackup](https://www.borgbackup.org/). Vous configurez un fichier YAML, vous mettez en cron, et ça lance les sauvegardes automatiquement.

Borgmatic gère la déduplication (les données identiques ne sont sauvegardées qu'une fois), la compression, les snapshots à différents points dans le temps, et le pruning automatique des vieux archives. Une fois configuré, c'est autonome.

### Hetzner Storage Box, c'est quoi

Hetzner, c'est une boîte allemande qui vend du bare metal, du cloud et des stockages à distance. Les Storage Box sont accessibles via FTP, SFTP, SMB, Rsync, Borg, WebDAV, [et d'autres protocoles](https://docs.hetzner.com/storage/storage-box/general#supported-protocols). 4€/mois pour 1To, jusqu'à 40To selon les besoins.

## Exemple de configuration

```yaml
source_directories:
  - /home
  - /var/lib/postgresql
  - /var/lib/docker/volumes
  - /etc

repositories:
  - label: hetzner_storage_box
    path: ssh://u123456@u123456.your-storagebox.de:23/borg/hiraeth

retention:
  keep_daily: 7
  keep_weekly: 4
  keep_monthly: 6

consistency:
  checks:
    - name: repository
      frequency: 2 weeks
    - name: extract
      frequency: 1 month
```

Mis en cron une fois par jour, ça crée des snapshots sur le storage box de Hetzner. Les données sont dédupliquées, compressées et chiffrées (borg chiffre par défaut).

- RTFM pour la config de borgmatic : https://torsion.org/borgmatic/reference/configuration/
- RTFM pour que votre machine parle à la storage box en SSH : https://docs.hetzner.com/storage/storage-box/backup-space-ssh-keys
- RTFM pour faire un timer systemd https://wiki.archlinux.org/title/Systemd/Timers

Résultat en chiffres : lors d'une sauvegarde typique, j'avais 403 GB de données brutes, 388 GB compressés, qui se réduisent à 777 MB après déduplication.

```
Archive name: hiraeth-2026-04-09T21:12:32.186702
Archive fingerprint: 2c166a71d9956352be075e6811464aff58b4d745aeba665cebaecb6b1973b91d
Hostname: hiraeth
Username: root
Time (start): Thu, 2026-04-09 21:12:33
Time (end): Thu, 2026-04-09 21:13:48
Duration: 1 minutes 15.87 seconds
Number of files: 147797

                       Original size      Compressed size    Deduplicated size
This archive:              403.55 GB            388.38 GB            777.78 MB
All archives:               15.81 TB             15.21 TB            319.07 GB

                       Unique chunks         Total chunks
Chunk index:                  266260             11240755
```

Au total, 15.81 TB d'archives originales qui deviennent 319 GB une fois dédupliquées.

## Le tarif

4€ par mois pour 16 TB de stockage (après déduplication et compression). Accessible en SSH pour combiner facilement avec borgmatic. Hetzner propose aussi 10 jours de snapshots versionnés, utiles en cas d'incident.

## Intégration dans NixOS

Pour les utilisateurs de NixOS, borgmatic a un module natif. Vous déclarez simplement :

```nix
{ config, ... }:
{
  sops.secrets.borgmatic = { };

  services.borgmatic = {
    enable = true;
    settings = {
      constants = {
        hostname = config.networking.hostName;
      };
      source_directories = [
        "/etc"
        "/home"
        "/var/lib/postgresql"
        "/var/lib/docker/volumes"
      ];
      repositories = [
        {
          label = "storage_box";
          path = "ssh://storage_box/./borg/${config.networking.hostName}";
        }
      ];
      exclude_patterns = [
        "/home/*/.cache/"
      ];
      encryption_passcommand = "cat ${config.sops.secrets.borgmatic.path}";
      retries = 3;
      retry_wait = 10;
      keep_hourly = 24;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 12;
    };
  };

  home-manager.users.root.programs.ssh.matchBlocks = {
    storage_box = {
      hostname = "u123456.your-storagebox.de";
      user = "u123456";
      port = 23;
    };
  };
}
```

Et pouf, NixOS se charge de tout : la config, l'installation de borgmatic, la cron job qui lance ça tous les jours. Déclaratif, versionné, reproductible. Tout ce qu'on aime.

- RTFM pour la config borgmatic dans NixOS https://nixos.org/manual/nixos/stable/options#opt-services.borgmatic.enable
- RTFM pour la gestion des secrets avec sops https://github.com/Mic92/sops-nix
- RTFM pour la config de ssh dans home-manager https://nix-community.github.io/home-manager/

(je ne suis pas payé par Hetzner pour faire leur pub, je suis juste client satisfait)
