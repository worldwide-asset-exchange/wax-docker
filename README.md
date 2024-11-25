# Build
```
$ make build-all
```
# Docker images
## waxteam/waxnode-dev
- This Docker image includes required packages and compiled code of WAX blockchain. It provides a complete development environment for building, running and managing a WAX blockchain.
- Inside /tmp/wax-blockchain, you'll find the compiled folders for the WAX blockchain. These folders contain the compiled artifacts and resources needed for running and interacting with your blockchain node. 
```
$ docker container run -it waxteam/waxnode-dev /bin/bash
$ cd /tmp/
$ ls -la
total 20
drwxrwxrwt 1 root root 4096 Nov 23 16:06 .
drwxr-xr-x 1 root root 4096 Nov 25 05:40 ..
drwxr-xr-x 1 root root 4096 Nov 23 15:26 wax-blockchain
$ nodeos -h
Application Options:

Config Options for eosio::chain_plugin:
  --blocks-dir arg (="blocks")          the location of the blocks directory
                                        (absolute path or relative to
                                        application data dir)
```

## waxteam/waxnode
- This Docker image is used for the WAX blockchain and includes the following tools: cleos, nodeos, and keosd. It provides a complete environment for running and managing a WAX blockchain node. 
- This one image was optimized for the production.
```
$ docker container run -it waxteam/waxnode /bin/bash
# nodeos -h
```

## waxteam/cdt
- The waxteam/cdt Docker image provides the environment for developing smart contracts on the WAX blockchain. It includes the Smart Contract Development Toolkit (CDT) and WAX blockchain tools: cleos, nodeos, and keosd. It provides a complete environment for building smart contract, running and managing a WAX blockchain node. 
```

$ docker container run -it waxteam/cdt /bin/bash
$ cdt-cpp -h
```

## waxteam/waxdev
- This Docker image includes complied code of the WAX blockchain tools as well as the Smart Contract Development Toolkit. 
- Inside /tmp/wax-blockchain and /tmp/wax-cdt directories, you'll find the compiled folders for the WAX blockchain and CDT. These folders contain the compiled artifacts and resources needed for running and testing your local blockchain network and WAX smart contracts. 
```
$ docker container run -it waxteam/waxdev /bin/bash
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