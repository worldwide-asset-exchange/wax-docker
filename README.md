# Build
## waxteam/waxnode
```
$ make build-node-image
```
## waxteam/cdt
```
$ make build-cdt-image
```

## waxteam/waxdev
```
$ make build-cdt-image-dev
```

# Docker images
- wax-cdt
- wax-blockchain

## nodeos image
```
$ docker container run -it waxteam/waxnode /bin/bash
# nodeos -h
```

## cdt image
```
$ docker container run -it waxteam/cdt /bin/bash
# cdt-cpp -h
```

## Dev image
- wax-cdt: /tmp/wax-cdt
- wax-blockchain: /tmp/wax-blockchain
```
$ docker container run -it waxteam/waxdev /bin/bash
$ cd /tmp && ls -la
drwxr-xr-x 1 root root 4096 May 22 06:38 wax-cdt
drwxr-xr-x 1 root root 4096 Apr  3 15:33 wax-blockchain
```

# Usage
## Run a wax node with waxteam/waxnode docker

## Compile a contract with waxteam/cdt
```
# cd to build project
$ cd <path>/eosio.token

# start a wax-cdt container and mount current directory as a volume in folder /opt/contracts in docker
$ docker run -it -v `pwd`:/opt/contracts --name waxteam-dev -w /opt/contracts waxteam/cdt:latest bash

# use wax-cdt inside docker to compile your project
$ cdt-cpp -I ./include -w --abigen ./src/eosio.token.cpp -o ./build/eosio.token.wasm

# you now can access the build binaries file with and without docker
$ ls -la
-rw-r--r-- 1 root root  4452 May 18 16:40 eosio.token.abi
-rwxr-xr-x 1 root root 15672 May 18 16:40 eosio.token.wasm
drwxr-xr-x 3 root root    96 Jun 28  2022 include
drwxr-xr-x 3 root root    96 Jun  7  2022 ricardian
drwxr-xr-x 3 root root    96 Jul  9  2022 src

# destroy a container
$ docker container rm waxteam-dev
```