WAX_NODE_REPO = git@github.com:worldwide-asset-exchange/wax-blockchain.git
WAX_BRANCH ?= v4.0.4wax01
WAX_VERSION ?= v4.0.1wax01
WAX_CDT_REPO = git@github.com:worldwide-asset-exchange/cdt.git
CDT_BRANCH ?= v4.0.0
CDT_VERSION ?= v4.0.0
DEPS_DIR=./tmp

.PHONY: build-node-image build-node-image-dev push-node-image push-node-image-dev build-cdt-image build-cdt-image-dev push-cdt-image push-cdt-image-dev

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
    git submodule update --init --recursive
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
    git submodule update --init --recursive
	cd $(DEPS_DIR)/cdt && echo "$(CDT_VERSION):$(shell git rev-parse HEAD)" > wax-version

aws-login:
	aws ecr get-login --region us-east-1 | sed 's/-e none//g' | bash

build-node-image: get_wax_blockchain
	docker build -f Dockerfile.node\
         --build-arg deps_dir=$(DEPS_DIR) \
         -t waxteam/waxnode .

build-node-image-dev: get_wax_blockchain
	docker build -f Dockerfile.node.dev\
         --build-arg deps_dir=$(DEPS_DIR) \
         -t waxteam/waxnode-dev .

tag-node-image:
	docker tag waxteam/waxnode waxteam/waxnode:$(WAX_VERSION)
	docker tag waxteam/waxnode-dev waxteam/waxnode-dev:$(WAX_VERSION)

push-node-image:
	docker tag waxteam/waxnode waxteam/waxnode:$(WAX_VERSION)
	docker push waxteam/waxnode:$(WAX_VERSION)
	docker tag waxteam/waxnode:$(WAX_VERSION) waxteam/waxnode:latest
	docker push waxteam/waxnode:latest

push-node-image-dev:
	docker tag waxteam/waxnode-dev waxteam/waxnode-dev:$(WAX_VERSION)
	docker push waxteam/waxnode-dev:$(WAX_VERSION)
	docker tag waxteam/waxnode-dev:$(WAX_VERSION) waxteam/waxnode-dev:latest
	docker push waxteam/waxnode-dev:latest

build-cdt-image: get_cdt
	docker build -f Dockerfile.cdt \
        --build-arg deps_dir=$(DEPS_DIR) \
        --build-arg WAX_VERSION=$(WAX_VERSION)\
        -t waxteam/cdt .

build-cdt-image-dev: get_cdt
	docker build -f Dockerfile.cdt.dev \
        --build-arg deps_dir=$(DEPS_DIR) \
        --build-arg WAX_VERSION=$(WAX_VERSION)\
        -t waxteam/cdt-dev .

push-cdt-image:
	docker tag waxteam/cdt waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)
	docker push waxteam/cdt:$(WAX_VERSION)-$(CDT_VERSION)
	docker tag waxteam/cdt waxteam/cdt:latest
	docker push waxteam/cdt:latest

push-cdt-image-dev:
	docker tag waxteam/cdt-dev waxteam/waxdev:$(WAX_VERSION)-$(CDT_VERSION)
	docker push waxteam/waxdev:$(WAX_VERSION)-$(CDT_VERSION)
	docker tag waxteam/cdt-dev waxteam/waxdev:latest
	docker push waxteam/waxdev:latest

build-all: build-node-image build-node-image-dev tag-node-image build-cdt-image build-cdt-image-dev
push-all: push-node-image push-node-image-dev push-cdt-image push-cdt-image-dev
