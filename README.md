# Build
```
$ make build-all
```

## Versions

The images currently target:

| Build arg     | Default          | What it is |
|---------------|------------------|------------|
| `WAX_VERSION` | `ce-v1.0.3wax01` | WAX blockchain / nodeos — Antelope Spring Community Edition (nodeos `v1.3.0wax01`), successor to the Leap 5.0 (`v5.0.x`) line |
| `CDT_VERSION` | `v4.1.1wax01`    | Contract Development Toolkit |

These defaults are set in the `Makefile` and are checked out as the matching git tags from `wax-blockchain` / `wax-cdt`. `make` clones those repos into `./tmp` automatically — you do not need to clone them by hand.

### Build a specific version

Override the version on the `make` command line (no need to edit the Dockerfiles — they take `WAX_VERSION` / `CDT_VERSION` as build args):

```
$ make WAX_VERSION=ce-v1.0.3wax01 CDT_VERSION=v4.1.1wax01 build-all
```

`make build-all` tags the resulting images with the version (e.g. `waxteam/waxnode:ce-v1.0.3wax01`, `waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)`). Pick versions from the upstream release pages ([wax-blockchain](https://github.com/worldwide-asset-exchange/wax-blockchain/releases), [wax-cdt](https://github.com/worldwide-asset-exchange/wax-cdt/releases)) and the published [Docker Hub tags](https://hub.docker.com/r/waxteam/waxnode/tags).
# Docker images
## waxteam/waxnode
- This Docker image is used for the WAX blockchain and includes the following tools: cleos, nodeos, and keosd. It provides a complete environment for running and managing a WAX blockchain node. 
- This one image was optimized for the production.
```
$ docker container run -it waxteam/waxnode /bin/bash
# nodeos -h
```
## waxteam/cdt
- The waxteam/cdt Docker image provides the environment for developing smart contracts on the WAX blockchain. It includes the Smart Contract Development Toolkit (CDT), which is a collection of tools and libraries that aid in the development of WAX smart contracts.
```
$ docker container run -it waxteam/cdt /bin/bash
# cdt-cpp -h
```
## waxteam/cdt-node
- This Docker image combines the features of the waxteam/waxnode and waxteam/cdt images. It includes the WAX blockchain tools as well as the Smart Contract Development Toolkit. 
- Inside /tmp/wax-blockchain and /tmp/wax-cdt directories, you'll find the compiled folders for the WAX blockchain and CDT. These folders contain the compiled artifacts and resources needed for running and testing your local blockchain network and WAX smart contracts. 
```
$ docker container run -it waxteam/cdt-node /bin/bash
$ cd /tmp && ls -la
drwxr-xr-x 1 root root 4096 May 22 06:38 wax-cdt
drwxr-xr-x 1 root root 4096 Apr  3 15:33 wax-blockchain
```
# Usage
## Run a wax node with waxteam/waxnode docker
To run wax-node follow [this document](https://github.com/worldwide-asset-exchange/wax-node)
## Compile a contract with waxteam/cdt
```
# cd to build project
$ cd <path>/eosio.token

# start a wax-cdt container and mount current directory as a volume in folder /opt/contracts in docker
$ docker run -it -v `pwd`:/opt/contracts --name waxteam-dev -w /opt/contracts waxteam/cdt:latest bash

# use wax-cdt inside docker to compile your project
$ cdt-cpp -I ../include -abigen eosio.token.cpp -o ../build/eosio.token.wasm

# you now can access the build binaries file with and without docker
$ ls -la ../build
drwxr-xr-x 2 root root  4096 Dec  3 02:03 .
drwxrwxr-x 6 1000 1000  4096 Dec  3 01:59 ..
-rw-r--r-- 1 root root  4452 Dec  3 02:03 eosio.token.abi
-rwxr-xr-x 1 root root 15322 Dec  3 02:03 eosio.token.wasm

# destroy a container
$ docker container rm waxteam-dev
```