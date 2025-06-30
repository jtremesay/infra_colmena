# 

## Deploy

```shell
$ nix develop
$ colmena apply
``

## Generate server public key

```shell
$ ssh root@hiraeth.jtremesay.org cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```