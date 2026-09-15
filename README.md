# Build
```
$ make build-all
```

## Versions

The images currently target:

| Build arg     | Default          | What it is |
|---------------|------------------|------------|
| `WAX_VERSION` | `ce-v1.3.1wax01` | WAX blockchain / nodeos — Antelope Spring Community Edition (nodeos `v1.3.1wax01`), successor to the Leap 5.0 (`v5.0.x`) line |
| `CDT_VERSION` | `v4.1.1wax01`    | Contract Development Toolkit |

These defaults are set in the `Makefile` and are checked out as the matching git tags from `wax-blockchain` / `wax-cdt`. `make` clones those repos into `./tmp` automatically — you do not need to clone them by hand.

### Limiting build parallelism

The C++ builds run `make -j $(nproc)` by default and need roughly **2-3GB of RAM per job** — on a
16-core machine that is ~32GB, which will swap-thrash a shared box. Cap it with `JOBS`:

```
$ make JOBS=6 build-all
```

Leave `JOBS` unset for the historical `$(nproc)` behaviour.

### Build a specific version

Override the version on the `make` command line (no need to edit the Dockerfiles — they take `WAX_VERSION` / `CDT_VERSION` as build args):

```
$ make WAX_VERSION=ce-v1.3.1wax01 CDT_VERSION=v4.1.1wax01 build-all
```

`make build-all` tags the resulting images with the version (e.g. `waxteam/waxnode:ce-v1.3.1wax01`, `waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)`). Pick versions from the upstream release pages ([wax-blockchain](https://github.com/worldwide-asset-exchange/wax-blockchain/releases), [wax-cdt](https://github.com/worldwide-asset-exchange/wax-cdt/releases)) and the published [Docker Hub tags](https://hub.docker.com/r/waxteam/waxnode/tags).
## Verifying a build

```
$ make verify                      # or: make verify WAX_VERSION=... CDT_VERSION=...
```

Runs [`scripts/verify-images.sh`](scripts/verify-images.sh): checks that `nodeos`/`cleos`/`cdt-cpp` report the versions their tags claim, that no binary in any image is missing a shared library, that both CDT images compile [`test/hello.cpp`](test/hello.cpp) to `.wasm` + `.abi`, and that the `wax-version` provenance file records the right commit.

`SKIP_HEAVY=1` drops the checks needing the ~21GB `waxteam/cdt` builder image.

**Always run this before `push-all`.** `waxteam/cdt-node` shipped from 2025-12 to 2026-09 with neither `libz3-4` (needed by `clang-9`) nor `libxml2` (needed by `lld`/`wasm-ld`) installed, so its compiler and linker were both broken — the image could not do the one thing it exists for. Nothing caught it because nothing ever compiled a contract with a published image.

## CI

| Workflow | Trigger | What it does |
|---|---|---|
| [`verify images`](.github/workflows/verify.yml) | PR touching a Dockerfile/Makefile/script, weekly cron, manual | Pulls the published `waxnode` + `cdt-node` and runs the verification above. Minutes, fits a GitHub-hosted runner. Skips with a notice if the pinned version is not published yet. |
| [`build images`](.github/workflows/build.yml) | Manual only | Full from-source `build-all`, then verification, then an optional push. |

`build images` **will not run on `ubuntu-latest`** — the base image is ~11GB and the CDT image ~21GB against ~14GB of free disk. Point its `runner` input at a self-hosted or larger runner; the job fails fast with a clear message if there is under 60GB free.

Pushing from CI needs repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`, and `push`/`move_latest` are separate inputs so moving `:latest` is always a deliberate choice.

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