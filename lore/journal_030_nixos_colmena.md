URL:     https://linuxfr.org/users/killruana/journaux/nixos-et-colmena-la-prod-declarative-du-pauvre
Title:   NixOS et Colmena, la prod déclarative du pauvre
Authors: jtremesay
Date:    2026-04-09T21:30:17+02:00
License: CC By-SA
Tags:    nixos, colmena, sops, systemd-nspawn et infrstructure_as_code
Score:   0


Épisode 3 du feuilleton où je baragouine sur ma prod.
Dans les journaux précédents, on a parlé de [Docker Swarm](https://docs.docker.com/engine/swarm/), de [contextes Docker](https://docs.docker.com/engine/manage-resources/contexts/) et de [Makefiles](https://fr.wikipedia.org/wiki/Make) pour gérer tout ce petit monde.

L'approche marchait. Enfin, marchait dans le sens où ça tournait et que les services étaient accessibles. Mais il y avait des trucs qui me grattaient.

## Ce qui grattait

Premier problème : les secrets. Comment vous passez le mot de passe de la base de données à votre container Docker ? Variable d'environnement dans le compose.yml ? Fichier `.env` ? Docker secrets ? Peu importe la méthode choisie, il fallait gérer ça en dehors de git, manuellement, à la main, comme un animal. Résultat : la config n'était pas entièrement reproductible. Un beau jour j'allume une nouvelle machine, je clone le dépôt, je lance `make deploy-all`, et là c'est le drame. Il manque des secrets partout.

Deuxième problème : l'OS lui-même. J'avais tout dockerisé, certes, mais la configuration de l'hôte, les utilisateurs, les clés SSH, les paramètres réseau, vivait dans ma tête (ou dans un README pas à jour). Pas versionné, pas reproductible. Juste du folklore.

Troisième problème, plus philosophique : j'avais des stacks séparées à gérer séparément. Le hack Makefile était malin, mais c'était quand même un hack. Ce que je voulais, c'est une vue unifiée de toute l'infra.

## NixOS à la rescousse

[NixOS](https://fr.wikipedia.org/wiki/NixOS) est une distribution Linux un peu folle où toute la configuration du système est déclarative et gérée via le [gestionnaire de paquets Nix](https://fr.wikipedia.org/wiki/Nix_(gestionnaire_de_paquets)). Tout  (les paquets installés, les services activés, les utilisateurs, la configuration réseau) est décrit dans des fichiers `.nix` versionnés dans git. Et quand vous changez quelque chose, Nix construit le nouveau système et vous bascule dessus atomiquement. Si ça casse, vous rebootez sur la génération précédente.

C'est déclaratif, reproductible, et ça aurait presque le Jojo seal of approval® si le langage nix n'était pas aussi, hum, particulier.

Aparté : si j'avais était cloud-natif, j'aurais géré tout ça avec [Terraform](https://fr.wikipedia.org/wiki/Terraform_(logiciel)), [Pulumi](https://www.pulumi.com/) ou un autre outil d'infrastructure as code. Mais je suis un sale radin qui préfère les bon vieux kimsufi d'OVH.

## La gestion modulaire de la configuration

NixOS est livré avec un système de modules qui permet de décomposer la configuration en morceaux cohérents, avec un mécanisme d'options propre.

Par exemple, voici le module pour [FreshRSS](https://freshrss.github.io/FreshRSS/) (lecteur RSS) :

```nix
{ config, lib, ... }:
let
  cfg = config.slaanesh.freshrss;
in
{
  options.slaanesh.freshrss = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the freshrss container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "rss.jtremesay.org";
    };
  };

  config = {
    containers.freshrss = {
      # ... le container systemd-nspawn, voir plus bas
    };

    slaanesh.caddy.reverseProxies = {
      "${cfg.host}" = "http://${cfg.localAddress}";
    };
  };
}
```

Et dans la configuration de la machine :

```nix
{
  imports = [
    ../../modules/web/freshrss.nix
    ../../modules/web/nextcloud.nix
    ../../modules/web/vaultwarden.nix
    ../../modules/web/mattermost.nix
    # etc.
  ];

  slaanesh = {
    freshrss.localAddress    = "192.168.100.10";
    nextcloud.localAddress   = "192.168.100.13";
    vaultwarden.localAddress = "192.168.100.12";
    mattermost.localAddress  = "192.168.100.14";
  };
}
```

Vous incluez le module, vous définissez éventuellement quelques options, et pouf, chocapic. Le service tourne, Caddy est configuré pour le reverse proxy, borgmatic sait quoi sauvegarder. Tout ça sans rien toucher manuellement.

Je veux déployer FreshRSS sur une autre machine ? J'ajoute l'import et je définis l'adresse IP. Terminé.

## Les containers systemd-nspawn

NixOS supporte nativement les [containers systemd-nspawn](https://wiki.archlinux.org/title/Systemd-nspawn) via `containers.<nom>`. Ce sont des containers légers, sans overhead de Docker, qui partagent le kernel de l'hôte mais ont leur propre système de fichiers, leurs propres processus et leur propre réseau.

L'avantage par rapport à Docker ici c'est l'intégration parfaite avec NixOS : la config du container est du Nix comme le reste. Pas d'image à construire, pas de Dockerfile, pas de registre. Le container est défini inline dans le module, avec les mêmes primitives que le reste du système.

```nix
containers.freshrss = {
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.100.1";
  localAddress = cfg.localAddress;

  bindMounts = {
    # On monte le secret depuis l'hôte en lecture seule
    freshrss_jtremesay_password = {
      hostPath   = config.sops.secrets."freshrss/jtremesay/password".path;
      mountPoint = "/run/secrets/freshrss_jtremesay_password";
      isReadOnly = true;
    };
  };

  config = { pkgs, ... }: {
    services.freshrss = {
      enable       = true;
      baseUrl      = "https://${cfg.host}";
      defaultUser  = "jtremesay";
      passwordFile = "/run/secrets/freshrss_jtremesay_password";
      database.type = "pgsql";
    };

    services.postgresql = {
      enable  = true;
      package = pkgs.postgresql_17;
    };
  };
};
```

Isolation réseau, base de données dédiée, tout ça sans quitter le confort du Nix. Ça a le Jojo seal of approval®.

## La gestion des secrets avec sops-nix

Vous avez remarqué le `config.sops.secrets."freshrss/jtremesay/password".path` dans l'exemple précédent. C'est là qu'on règle le problème des secrets.

[sops](https://github.com/getsops/sops) est un outil de chiffrement de fichiers de secrets. Il chiffre les valeurs dans un fichier YAML (pas les clés, juste les valeurs) avec [age](https://github.com/FiloSottile/age). Le fichier `secrets/default.yaml` dans le dépôt ressemble à ça une fois déchiffré :

```yaml
borgmatic: monmotdepassedebackup
freshrss:
  jtremesay:
    password: monsupermotdepasse
nextcloud:
  jtremesay:
    password: encoreunmotdepasse
```

Chiffré, c'est du charabia illisible. Le fichier est commitable dans git sans crainte.

Le déchiffrement est géré par [sops-nix](https://github.com/Mic92/sops-nix) : au boot de la machine, les secrets sont déchiffrés et déposés dans `/run/secrets/` avec les bonnes permissions. Le module NixOS d'un service peut alors pointer vers ce chemin.

Pour que ça marche, il faut que la clé privée age soit présente sur la machine. Je la génère depuis la clé SSH de la machine via `ssh-to-age`, comme ça pas besoin de gérer une clé supplémentaire. Ça n'a pas vraiment le jojo seal of approval® parce que j'aime pas trop mélanger les usages d'une clé cryptographique, mais c'est pratique.

La config `.sops.yaml` au niveau du dépôt déclare qui peut déchiffrer quoi :

```yaml
keys:
  - &admin   age1ma7y9pzj5dk04j3jvjde3esfm6led6duludqk375k7hz93jc5a2scmw3v1
  - &hiraeth age1n2q78sfsycx533vq5umcntpe3049c0gp92d38a4307zndylppv4qfdqsh2
  - &music   age1gmpvctgh6axqpegek3h7c5kn0a5eumeksn5mscdha2w88ghenemsfg0cz3
creation_rules:
  - path_regex: secrets/.*
    key_groups:
      - age:
          - *admin
          - *hiraeth
          - *music
```

Moi (admin), ainsi que les machines `hiraeth` et `music` peuvent lire les secrets. Simple, efficace.

## La gestion du parc avec Colmena

J'ai deux machines : `hiraeth` (le serveur) et `music` (un laptop d'expérimentation). [Colmena](https://github.com/zhaofengli/colmena) est l'outil que j'utilise pour déployer la configuration NixOS sur ces machines à distance.

```nix
colmenaHive = colmena.lib.makeHive {
  meta = {
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };
  };

  hiraeth = {
    deployment.targetHost = "hiraeth.jtremesay.org";
    imports = commonModules ++ [ ./machines/hiraeth/configuration.nix ];
  };

  music = {
    deployment.targetHost = "192.168.1.79";
    imports = commonModules ++ [ ./machines/music/configuration.nix ];
  };
};
```

Pour déployer :

```shell
# Déployer sur toutes les machines :
$ colmena apply

# Déployer sur une machine spécifique :
$ colmena apply --on hiraeth
```

Colmena construit la configuration localement (ou sur la machine cible, configurable), la pousse via SSH et active la nouvelle génération. Approche gitops : le dépôt est la source de vérité, on déploie depuis la CI ou depuis son poste.

Une évolution future possible : migrer vers [deploy-rs](https://github.com/serokell/deploy-rs). Le système de profils a l'air plus flexible et l'intégration avec les flakes Nix semble plus naturelle. Mais j'ai pas encore testé.

## Ce qui reste dans Docker Swarm

Les services "statiques" (freshrss, nextcloud, vaultwarden, mattermost...) sont maintenant des containers systemd-nspawn gérés par NixOS.

En revanche, mes projets persos ont leurs propres CI/CD. Ils buildent leur image Docker, la publient sur un registre, et redéploient leur stack Docker Swarm sur `hiraeth` via les contextes Docker (cf. [journal 1](https://linuxfr.org/users/killruana/journaux/docker-swarm-et-ci-les-contextes-a-la-rescousse)). Cette partie reste inchangée. NixOS configure le démon Docker sur `hiraeth` et expose un utilisateur `github-ci` dédié avec juste ce qu'il faut comme permissions pour faire tourner ses stacks.

Le frontal web reste [Traefik](https://doc.traefik.io/traefik/) dans une stack Docker Swarm pour les services dynamiques, et [Caddy](https://caddyserver.com/) (géré par NixOS) pour les services statiques. Caddy reverse-proxy vers Traefik pour les domaines qui pointent vers du Docker Swarm. C'est un poil spaghetti, mais ça marche et les responsabilités sont claires.

## Da infrastructure

[![infra](https://raw.githubusercontent.com/jtremesay/infra_colmena/20e849258682cdc38c7b7a295dd253f647bd9af5/infra.mermaid.svg)](https://raw.githubusercontent.com/jtremesay/infra_colmena/20e849258682cdc38c7b7a295dd253f647bd9af5/infra.mermaid.svg)

## Bilan

Avantages :

- tout est dans git, tout est reproductible : depuis n'importe où dans le monde, si j'ai internet et ma clé ssh, je peux reconstruire toute mon infra avec `git clone ... && cd infra && nix develop && colmena apply`
- les secrets sont versionnés et chiffrés : fini de les gérer à la main hors dépôt
- les modules NixOS sont composables et réutilisables : ajouter un service c'est trois lignes
- les containers systemd-nspawn sont légers et natifs, sans la complexité de Docker pour les services qui n'ont pas besoin de CI/CD

Inconvénients :

- [le langage Nix](https://nix.dev/tutorials/nix-language) est bizarre. C'est un langage fonctionnel paresseux avec une syntaxe atypique. Ça prend du temps à apprivoiser et les messages d'erreur sont parfois cryptiques
- le temps de build peut être long, surtout sur une petite machine
- la documentation NixOS est fragmentée entre le manuel, [NixOS Search](https://search.nixos.org/options), les forums et le code source de nixpkgs. Souvent c'est le code source qui gagne

Le dépôt : https://github.com/jtremesay/infra_colmena

À l'épisode 4 du feuilleton, peut-être : la camarade [solene](https://www.lambda-solene.eu/) m'a parlé d'[IncusOS](https://linuxcontainers.org/incus-os/docs/main/), une distro minimaliste qui ne fait qu'une chose : tourner des containers et des VMs [Incus](https://linuxcontainers.org/incus/). L'idée c'est d'oublier complètement l'OS, de le traiter comme un détail d'implémentation, et de gérer toute l'infra via [Terraform](https://search.opentofu.org/provider/lxc/incus/latest) comme si on était dans le cloud. Même sur du cheap bare metal. Ça a l'air tentant. Mais je viens à peine de finir ma migration vers NixOS, j'ai pas encore envie de repartir pour une nouvelle aventure. 
