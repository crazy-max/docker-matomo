## Swarm

Install and use this Matomo Docker image within a Docker Swarm cluster.

### Prerequisites

Create a running Swarm cluster environment and use a storage volume driver of your choice. Here I use a simple NFS
server with binded volumes.

Then edit all `*.env` files with your preferences.

```shell
mkdir -p ${ROOT_DIR}
cp .env ${ROOT_DIR}/
cp matomo.env ${ROOT_DIR}/
touch ${ROOT_DIR}/acme.json
chmod 600 ${ROOT_DIR}/acme.json
```

> `ROOT_DIR` is defined in [.env](.env)

### Deploy

And deploy [the stack](docker-compose.yml) with this command:

```shell
docker stack deploy matomo -c docker-compose.yml
```
