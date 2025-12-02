WAX_NODE_REPO = git@github.com:worldwide-asset-exchange/wax-blockchain.git
WAX_BRANCH ?= main
WAX_VERSION ?= ce-v1.0.3wax01
WAX_CDT_REPO = git@github.com:worldwide-asset-exchange/wax-cdt.git
CDT_BRANCH ?= main
CDT_VERSION ?= v4.1.1wax01
DEPS_DIR=./tmp

.PHONY: build-node-image build-node-base-image push-node-image push-node-base-image build-cdt-image build-cdt-image push-cdt-image push-cdt-image

make_deps_dir:
	@mkdir -p $(DEPS_DIR)

clean:
	-rm -rf $(DEPS_DIR)

# It has some optimization code because cloning/initing is really slow
get_wax_blockchain: make_deps_dir
	if [ ! -d $(DEPS_DIR)/wax-blockchain ]; then \
        cd $(DEPS_DIR) && \
        git clone -b $(WAX_BRANCH) $(WAX_NODE_REPO) wax-blockchain --recursive && \
        cd wax-blockchain; \
    else \
        cd $(DEPS_DIR)/wax-blockchain && \
        git fetch --all --tags && \
        git checkout $(WAX_BRANCH); \
    fi && \
    git checkout tags/$(WAX_VERSION) && git submodule update --init --recursive
	cd $(DEPS_DIR)/wax-blockchain && echo "$(WAX_VERSION):$(shell git rev-parse HEAD)" > wax-version

get_cdt: make_deps_dir
	if [ ! -d $(DEPS_DIR)/cdt ]; then \
        cd $(DEPS_DIR) && \
        git clone -b $(CDT_BRANCH) $(WAX_CDT_REPO) cdt --recursive && \
        cd cdt; \
    else \
        cd $(DEPS_DIR)/cdt && \
        git fetch --all --tags && \
        git checkout $(CDT_BRANCH); \
    fi && \
    git checkout tags/$(CDT_VERSION) &&git submodule update --init --recursive
	cd $(DEPS_DIR)/cdt && echo "$(CDT_VERSION):$(shell git rev-parse HEAD)" > wax-version

aws-login:
	aws ecr get-login --region us-east-1 | sed 's/-e none//g' | bash

build-node-image:
	docker build -f Dockerfile.node\
         --build-arg deps_dir=$(DEPS_DIR) \
				 --build-arg WAX_VERSION=$(WAX_VERSION)\
         -t waxteam/waxnode .

build-node-base-image: get_wax_blockchain
	docker build -f Dockerfile.node.base\
         --build-arg deps_dir=$(DEPS_DIR) \
         -t waxteam/waxnode-base .

tag-node-image:
	docker tag waxteam/waxnode waxteam/waxnode:$(WAX_VERSION)

tag-node-base-image:
	docker tag waxteam/waxnode-base waxteam/waxnode-base:$(WAX_VERSION)

push-node-image:
	docker tag waxteam/waxnode waxteam/waxnode:$(WAX_VERSION)
	docker push waxteam/waxnode:$(WAX_VERSION)
	docker tag waxteam/waxnode:$(WAX_VERSION) waxteam/waxnode:latest
	docker push waxteam/waxnode:latest

push-node-base-image:
	docker tag waxteam/waxnode-base waxteam/waxnode-base:$(WAX_VERSION)
	docker push waxteam/waxnode-base:$(WAX_VERSION)
	docker tag waxteam/waxnode-base:$(WAX_VERSION) waxteam/waxnode-base:latest
	docker push waxteam/waxnode-base:latest

build-cdt-node-image:
	docker build -f Dockerfile.cdt \
        --build-arg deps_dir=$(DEPS_DIR) \
        --build-arg WAX_VERSION=$(WAX_VERSION)\
				--build-arg CDT_VERSION=$(CDT_VERSION)\
        -t waxteam/cdt-node .

build-cdt-image: get_cdt
	docker build -f Dockerfile.cdt \
        --build-arg deps_dir=$(DEPS_DIR) \
        --build-arg WAX_VERSION=$(WAX_VERSION)\
        -t waxteam/cdt .

tag-cdt-node-image:
	docker tag waxteam/cdt-node waxteam/cdt-node:$(WAX_VERSION)-$(CDT_VERSION)

tag-cdt-image:
	docker tag waxteam/cdt waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)

push-cdt-node-image:
	docker tag waxteam/cdt-node waxteam/cdt-node:$(WAX_VERSION)-$(CDT_VERSION)
	docker push waxteam/cdt-node:$(WAX_VERSION)-$(CDT_VERSION)
	docker tag waxteam/cdt-node waxteam/cdt-node:latest
	docker push waxteam/cdt-node:latest

push-cdt-image:
	docker tag waxteam/cdt waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)
	docker push waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)
	docker tag waxteam/cdt waxteam/cdt:latest
	docker push waxteam/cdt:latest

build-all: build-node-base-image tag-node-base-image build-node-image tag-node-image build-cdt-image tag-cdt-image build-cdt-node-image tag-cdt-node-image
build-base: build-node-base-image tag-node-base-image build-cdt-image tag-cdt-image
push-all: push-node-base-image push-node-image push-cdt-image push-cdt-node-image