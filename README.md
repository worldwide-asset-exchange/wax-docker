# Build
```
$ make build-all
```
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