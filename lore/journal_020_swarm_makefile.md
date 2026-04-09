URL:     https://linuxfr.org/users/killruana/journaux/docker-swarm-et-makefiles-pour-sa-prod-perso
Title:   Docker swarm et Makefiles pour sa prod perso
Authors: jtremesay
Date:    2026-03-05T20:13:32+01:00
License: CC By-SA
Tags:    docker, docker_swarm, make et makefile
Score:   14


Épisode 2 du feuilleton où je baragouine sur ma prod.
Dans le [journal précédent](https://linuxfr.org/users/killruana/journaux/docker-swarm-et-ci-les-contextes-a-la-rescousse), on parlait de Docker Swarm et de CI/CD.

J'aime bien [Arch](https://fr.wikipedia.org/wiki/Arch_Linux), y compris sur des serveurs. On a des paquets très récents; et grâce au rolling release, on s'évite de trop gros changement d'un coup (pensez juste à vous abonnez à la [mailing list](https://lists.archlinux.org/mailman3/lists/arch-announce.lists.archlinux.org) pour être prévenu des trucs qui cassent). Arch Linux is one of the best distro for home servers, change my mind.

Malheureusement, lors d'un changement de serveur, j'ai pu constater que OVH ne proposait plus d'images Arch Linux. Et mon serveur n'avait pas de [IPMI](https://fr.wikipedia.org/wiki/Intelligent_Platform_Management_Interface)/[KVM](https://fr.wikipedia.org/wiki/Commutateur_%C3%A9cran-clavier-souris)/autres pour faire une installation manuelle. J'aurais pu tenter des [trucs](https://wiki.archlinux.org/title/Install_Arch_Linux_from_existing_Linux), mais flemme. Tant pis, on va partir sur Ubuntu LTS.

Oh joie, la LTS est sortie il y a 20 mois. Ça veut dire que tous les paquets sont ultra-périmés et que dans quelques mois faudra se taper une upgrade vers la nouvelle LTS. Génial.

C'est la que j'ai décidé de prendre une décision importante dans ma vie. Avant, je n'utilisais Docker Swarm que pour les projets liés à une CI/CD. Pour les autres services, je les installais directement sur le système, avec des paquets. C'était chiant à maintenir, mais au moins ça marchait. Mais maintenant, je serais "cloud-natif" et je containeriserai tout. Plus de dépendance à une distribution, plus de problèmes de paquets périmés, plus de problèmes de compatibilité. Juste des conteneurs Docker qui tournent sur n'importe quelle machine. Et des docker-compose pour tout gérer de manière déclarative et versionnée.

Ce fut un peu relou, mais avec le temps j'ai réussi à docker swarmisé tous mes services (freshrss, mattermost, nextcloud, vaultwarden, miroir archlinux…).

Avantages :

- contrôle fin des versions: je ne suis plus soumis à la politique de mise à jour de la distribution
- isolation des services: chacun tourne dans son petit sous réseau, à sa propre base de données, …
- déclarativité et reproductibilité: tout est dans git, je peux redéployer toutes les stacks en quelques minutes sur n'importe quelle machine (faut quand même se taper quelques heures de migration manuelle des données :D me suis pas encore posé la question de comment partager les volumes docker entre les machines du cluster swarm)

Inconvénients :

- parfois le truc que tu veux n'a pas encore d'image officielle
- parfois l'image est cloud-hostile. Je pense à vous machins qui me demande d'éditer un fichier de config. Tu crois que c'est facile de modifier un fichier de config dans un environnement CaaS sans SSH ? Tu crois que j'ai que ça a faire que de build une image custom juste un fichier de config ? Les gens, soyez cloud-friendly et permettez de configurer votre app par des variables d'environnement et des arguments de ligne de commande.
- maintenant que vous avez une db par service, faut se taper vachement plus de migrations de postgres :D
- c'est plus relou à backuper proprement. je suis un sauvage et j'ai directement ajouté /var/lib/docker/volumes à borgmatic. J'ai pas eu à restaurer, je ne sais pas à quel point c'est une mauvaise idée

Et surtout, c'était relou de redeploy tout ce petit monde pour prendre les mises à jours.

À l'époque, quand j'avais regardé, le seul projet qui gérait ça était [Watchtower](https://github.com/containrrr/watchtower), mais qui était déjà non maintenu. (Le camarade flagos< vient de me faire découvrir [gantry](https://github.com/shizunge/gantry), pas encore testé).

Du coup je gérais ça via la GUI de [Portainer](https://www.portainer.io/).

Pis j'ai découvert les contextes Docker. Et là, c'est la révélation. C'est exactement ce qu'il me fallait pour gérer mes stacks Docker Swarm à distance depuis ma CI/CD. Et c'était l'occasion de martyriser encore un peu plus Make, mon outil préféré pour l'automatisation.


## Automatiser le déploiement de stacks Docker Swarm avec Make et les contextes Docker

Voici un petit exemple avec deux stacks :

```
.
├── Makefile
├── stack1/
│   ├── compose.yml
│   └── Makefile
└── stack2/
    ├── compose.yml
    └── Makefile
```

Exemple d'utilisation :

```shell
# Déployer la stack1 :
$ cd stack1
$ make deploy

# Déployer la stack2 :
$ cd ../stack2
$ make undeploy

# tout déployer d'un coup :
$ cd ..
$ make -j2 deploy-all
```

Makefile d'une stack :

```makefile
deploy:
    DOCKER_CONTEXT=mon_cluster docker stack deploy --compose-file compose.yml --prune stack1

undeploy:
    DOCKER_CONTEXT=mon_cluster docker stack rm stack1
```

Makefile racine :

```makefile
deploy-all: deploy-stack1 deploy-stack2

deploy-stack1:
    $(MAKE) -C stack1 deploy

deploy-stack2:
    $(MAKE) -C stack2 deploy
```

C'est facile d'ajouter de nouvelles stacks, c'est facile de redéploy une stack spécifique après avoir touché le compose.yml, c'est facile de tout redéployer d'un coup afin de s'assurer d'avoir les dernières images de tous les services (docker swarm ne redéployant que ce qui a effectivement changé). Et tout ça sans jamais quitter la ligne de commande, sans jamais se connecter en ssh à un serveur, sans jamais ouvrir une interface web. Juste du Make et des contextes Docker. C'est beau, c'est propre, c'est efficace. J'ai même hésité à ajouter une CI pour encore plus d'automatisation.

Pour les curieux, le dépot de mon ancienne infra où j'implémente cette approche : https://github.com/jtremesay/infra

À l'épisode 3 du feuilleton où je baragouine sur ma prod, on verra [nixos](https://fr.wikipedia.org/wiki/NixOS) et les containers [systemd-nspawn](https://wiki.archlinux.org/title/Systemd-nspawn) pour une prod toujours plus containerisé, déclarative, reproductible tout en restant facile à maintenir
