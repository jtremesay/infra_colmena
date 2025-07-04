# 

## Usage

Enter in the development environment:

```shell
$ nix develop
```

Update the inputs:

```shell
$ nix flake update
```

Deploy the config

```shell
$ colmena apply
```

## Generate server public key

Get the public key:

```shell
$ ssh root@hiraeth.jtremesay.org cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

Add it to `.sops.yaml` then recrypt `secrets/default.yaml`:

```shell
$ sops updatekeys secrets/default.yaml
```

## Update secrets file:

```shell
$ sops edit secrets/default.yaml
```