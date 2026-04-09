URL:     https://linuxfr.org/users/killruana/journaux/docker-swarm-et-ci-les-contextes-a-la-rescousse
Title:   Docker swarm et CI, les contextes à la rescousse
Authors: jtremesay
Date:    2026-03-03T23:05:14+01:00
License: CC By-SA
Tags:    docker, docker_swarm, intégration_continue et cicd
Score:   16


Plop,

Solution simple à un problème qui m'a souvent cassé les gonades et dont je suis resté longtemps sans réponse : comment redéployer une stack docker swarm ?

## Contexte

[Docker](https://fr.wikipedia.org/wiki/Docker_(logiciel)) est un truc muche permettant de faire tourner des applications dans des [containers](https://fr.wikipedia.org/wiki/Conteneur_(virtualisation)).

Docker Swarm permet de faire des groupes afin de facilement répartir les containers sur plusieurs serveurs. 

Une stack est un groupe cohérent de containers destinés à travailler ensemble.

## Exemple

Exemple de stack :

```yaml
services:
  webapp:
    image: "webapp"
    networks:
      - traefik_public
      - redis
      - pg
    
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.monservice.rule=Host(`monservice.exemple.org`)"
        - "traefik.http.routers.monservice.tls.certresolver=leresolver"
        - "traefik.http.services.monservice.loadbalancer.server.port=80"

  pg:
    image: "postgres:18"
    networks:
      - pg
    volumes:
      - pg_data:/var/lib/postgresql

  redis:
    image: "valkey:latest"
    networks:
      - redis

networks:
  traefik_public:
    external: true. Et là c'est le drame.  
  pg:
  redis:

volumes:
  pg_data:
```

puis un petit coup de 

```shell
$ docker stack deploy -c compose.yml
```

pis pouf, vous avez 3 containers qui tournent dans votre grappe : une web app, une base de données [postgres](https://fr.wikipedia.org/wiki/PostgreSQL) et un serveur de clé valeur valkey (fork de [redis](https://fr.wikipedia.org/wiki/Redis)). Y'a des sous réseaux afin d'isoléer tout ce petit monde (valkey ne peut parler qu'à la webapp. pareil pour postgres. valkey et postgres ne peuvent pas se parler entre eux). la db a un volume afin que ses données soient persistantes. La web app est automatiquement géré par le frontal web [traefik](https://doc.traefik.io/traefik/) (avec certificat tls lets encrypt)

Tout est géré automatiquement, y'a rien a faire c'est simple, c'est beau, c'est propre. j'aime. ça a le Jojo seal of approval®, une récompense rare.

Apparté, comment déployer un cluster docker swarm ?

Sur un des serveurs : `docker swarm init`
Sur les autres : `docker swarm join <params donnés par docker swarm init>`

Tout est géré automatiquement, y'a rien a faire c'est simple, c'est beau, c'est propre. j'aime. ça a le Jojo seal of approval®, une récompense rare.

Pour les petites infras, docker swarm c'est la vie, mangez en.

## Le drame de la CI/CD

Maintenant, imaginez que vous êtes le développeur de webapp.

Vous développez une nouvelle fonctionnalité, vous la pushé, l'[intégration continue](https://fr.wikipedia.org/wiki/Int%C3%A9gration_continue) exécute les tests, construit l'image docker et la publie sur votre registre.

Jusque là pas de problème.

Maintenant, vous voulez redéployer votre stack docker swarm afin de relancer les containers avec des images à jour. Et là c'est le drame.  

Parce que voyez-vous, la doc est formelle. le seul moyen de (re-)déployer une stack, c'est via la commande `docker stack deploy [-c compose_file]`. Commande à exécuter sur un des serveurs de la grappe swarm. C'est à dire pas votre serveur actuel parce que là vous êtes sur celui de la CI.

Arf.

J'vais quand même pas demander à ma CI de se connecter en ssh à ma grappe, télécharger le compose.yaml depuis le dépot et exécuter le `docker stack deploy`. C'est ignoble et ça a l'air un peu relou à implémenter pour que ça soit suffisamment robuste.

Pendant longtemps ma solution a été d'utiliser un [webhook](https://fr.wikipedia.org/wiki/Webhook) [portainer](https://www.portainer.io/) : la CI faisait une requête [HTTP](https://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol) sur une URL secrète, et pouf portainer redeploy la stack.

C'était insatisfaisant parce fallait d'abord déclarer la stack dans portainer pour obtenir l'url du webhook à enregister dans la CI. Moi je suis une sale feignasse, je veux que tout marche seul automagiquement:(

## Les contextes à la rescousse 

Les [contextes](https://docs.docker.com/engine/manage-resources/contexts/) sont un moyen de gérer plusieurs démons docker depuis un client docker.

Par défault, votre client docker ne connait qu'un seul contexte, `default` (votre docker local).

```shell
jtremesay@nemo ~> docker context ls
NAME        DESCRIPTION                               DOCKER ENDPOINT               ERROR
default *   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
```

Toutes les commandes docker que vous tapez sont envoyées à ce contexte, comme `docker run`, `docker ls`, ou cas qui nous intéresse, `docker stack deploy`.

Et oh joie, vous pouvez déclarer des contextes distants :

```shell
$ docker context create --docker "host=ssh://alpha.exemple.org" alpha
```

Exemple d'utilisation :

```shell
# Commande exécuté localement :
$ docker ps

# Changement de contexte :
$ docker context use alpha

# Commande exécuté sur alpha :
$ docker ps

# Restaurer le contexte par défaut :
$ docker context use default

# Utiliser un contexte pour un one-shot:
$ docker --context alpha ps
$ DOCKER_CONTEXT=alpha docker ps
```

## Contextes et CI

Préparation à effectuer sur le nœud docker :

```shell
# Création d'un utilisateun dédié à la CI
$ sudo useradd -m -G docker ci

# Se connecte en tant que CI,
# crée une clé SSH, et configure SSH afin d'accepter la 
# clé et de n'autoriser que la command
# `docker system dial-stdio`
sudo -u ci -s
ssh-keygen
echo 'command="docker system dial-stdio"' $(cat $HOME/.ssh/id_ed25519.pub) >> $HOME/.ssh/authorized_keys
```

Exemple avec Github Actions :

```shell
jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: build-prod
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Création de la clé privée SSH depuis les secrets
        shell: bash
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.ssh_private_key }}" > ~/.ssh/private.key
          chmod 600 ~/.ssh/private.key
          cat > ~/.ssh/config <<EOF
          Host docker
            HostName alpha.exemple.org
            IdentityFile ~/.ssh/private.key
            StrictHostKeyChecking no
          EOF

      - name: Creation du contexte Docker
        shell: bash
        run: |
          docker context create docker --docker "host=ssh://docker"
          docker context use docker

      - name: Connection à Docker hub (nécessaire si votre image est dans un dépot privé)
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.docker_username }}
          password: ${{ secrets.docker_password }}

      - name: Redéployement
        shell: bash
        run: |
          docker stack deploy \
            --detach=false \
            --with-registry-auth \
            --prune \
            my_stack
```

Pour les gens intéressés, j'en ai fait une [action dédié](https://github.com/jtremesay/docker-swarm-deploy). En terme de support, y'a pas de support, donc je vous enjoins à forker joyeusement ou copier directement le code dans votre workflow :)

En travail préliminaire, y'a juste à renseigner la clé SSH dans les secrets de la CI. À vous de voir si vous préférez le faire qu'une fois au niveau global et accessible par tous vos dépots afin de ne plus jamais avoir à y toucher et que ça juste marche ou carrément créer un nouvel user (ou juste clé) par repo pour sécuriser et cloisonner.

Ça n'a pas le jojo seal of approval® parce que j'aime pas trop balader comme ça des clés ssh, mais ça reste simple et efficace, la CI va automatiquement crée la stack au premier push et la redeploy automatiquement lors des pushs suivant, y'a pas d'autres dépendances que docker et ssh.
