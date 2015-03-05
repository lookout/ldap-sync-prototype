.PHONY: build pull push clean check conjur conjur/drop acceptance

CONJUR_DOCKER_REGISTRY ?= registry.tld:80
IMAGE_NAME := conjurinc/ldap-sync
CONJUR_PLATFORM ?= 4.4

STUB_BUILD_NUMBER := $(USER)$(shell date +%s)
BUILD_NUMBER ?= $(STUB_BUILD_NUMBER)
IMAGE_ID=$(IMAGE_NAME):$(BUILD_NUMBER)

CONJUR_HA=$(CONJUR_DOCKER_REGISTRY)/conjurinc/conjur-ha:$(CONJUR_PLATFORM)

# non-deterministic dynamic evaluation should happen only with fixed variables (defined as := )
STUB_ADMIN_PASSWORD:=$(shell uuid | cut -f1 -d '-')
CONJUR_ADMIN_PASSWORD ?= $(STUB_ADMIN_PASSWORD)

CONJUR_ACCOUNT ?= conjur
TESTDIR=test


CONJUR_STACK_NAME=a-conjur-ldap-sync-$(BUILD_NUMBER)
ifdef AMI_ID
AMI_OPTS := --imageid $(AMI_ID)
endif

CIDFILE=$(TESTDIR)/acceptance.cid
HOSTFILE=$(TESTDIR)/conjur.host
STACKFILE=$(TESTDIR)/conjur.stackname
EXITCODEFILE:=$(TESTDIR)/acceptance.exit.code

all: build conjur acceptance conjur/drop

build: 
	docker build -t $(IMAGE_ID) .
	docker tag -f $(IMAGE_ID) $(IMAGE_NAME):latest
	docker tag -f $(IMAGE_ID) $(CONJUR_DOCKER_REGISTRY)/$(IMAGE_ID) 
	docker tag -f $(IMAGE_NAME):latest $(CONJUR_DOCKER_REGISTRY)/$(IMAGE_NAME):latest 

pull:
	docker pull $(CONJUR_DOCKER_REGISTRY)/$(IMAGE_NAME):latest
	docker tag -f $(CONJUR_DOCKER_REGISTRY)/$(IMAGE_NAME):latest $(IMAGE_NAME):latest

push:
	docker push $(CONJUR_DOCKER_REGISTRY)/$(IMAGE_NAME)

clean:
	rm -rf $(TESTDIR)

$(TESTDIR):
	mkdir -pv $(TESTDIR)

check:
ifndef AWS_KEY_FILE
	$(error AWS_KEY_FILE must be defined)
endif
ifeq ("$(wildcard $(AWS_KEY_FILE))","")
	$(error "File defined by AWS_KEY_FILE ($(AWS_KEY_FILE)) does not exist ")
endif

conjur: $(TESTDIR) check
	docker run --rm -t    			           \
		-e AWS_ACCESS_KEY_ID	            	   \
		-e AWS_SECRET_ACCESS_KEY                   \
		$(CONJUR_HA) standalone	                   \
			$(AMI_OPTS)		           \
			-k $(AWS_KEY_NAME)		   \
			-o $(CONJUR_ACCOUNT)	           \
			-p $(CONJUR_ADMIN_PASSWORD)      \
            	$(CONJUR_STACK_NAME)                       \
			| tee  $(TESTDIR)/conjur.stack
	[ -f $(TESTDIR)/conjur.stack ] || exit 1 
	grep -P 'Public(Ip|DnsName)' $(TESTDIR)/conjur.stack  | cut -f2 | grep '[^[:space:]]' | head -n 1 > $(TESTDIR)/conjur.host
	echo "$(CONJUR_STACK_NAME)" > $(TESTDIR)/conjur.stackname
	echo "$(CONJUR_ADMIN_PASSWORD)" > $(TESTDIR)/conjur.password

conjur/drop: $(TESTDIR)/conjur.stackname
ifdef KEEP_INSTANCES
	$(error "KEEP_INSTANCES variable is set, refusing to delete stack $(CONJUR_STACK_NAME)")
endif
	docker run --rm --net=host -t       \
		-e AWS_ACCESS_KEY	    \
		-e AWS_SECRET_KEY	    \
		$(CONJUR_HA) stack delete   \
		$(shell cat $(TESTDIR)/conjur.stackname)

$(TESTDIR)/conjur.host: $(TESTDIR)
ifdef CONJUR_APPLIANCE_HOSTNAME
	if [ ! -f $(TESTDIR)/conjur.host] ; then echo "$(CONJUR_APPLIANCE_HOSTNAME)" > $(TESTDIR)/conjur.host ; fi
else
	if [ ! -f $(TESTDIR)/conjur.host] ; then echo "Try to run `make conjur`"; exit 1; fi
endif

$(TESTDIR)/conjur.password: $(TESTDIR)
ifdef CONJUR_ADMIN_PASSWORD
	if [ ! -f $(TESTDIR)/conjur.password] ; then echo "$(CONJUR_ADMIN_PASSWORD)" > $(TESTDIR)/conjur.password ; fi
else
	if [ ! -f $(TESTDIR)/conjur.password] ; then echo "Try to run `make conjur`"; exit 1; fi
endif

prep: $(TESTDIR)/conjur.password $(TESTDIR)/conjur.host check

$(CIDFILE): prep
	docker run --cidfile $(CIDFILE)					                        \
		-t                  						                        \
		-e CONJUR_ACCOUNT="$(CONJUR_ACCOUNT)"                               \
		-e CONJUR_TEST_ENVIRONMENT=acceptance                               \
		-e CONJUR_APPLIANCE_HOSTNAME="$(shell cat $(TESTDIR)/conjur.host)"	\
		-e CONJUR_ADMIN_PASSWORD_FILE=/tmp/conjur-admin-password	        \
		-v $(abspath $(TESTDIR)/conjur.password):/tmp/conjur-admin-password	\
		$(IMAGE_NAME)                                                       \
			; echo $$? >> $(EXITCODEFILE)
	if [ ! -f $(CIDFILE) ]; then exit 1 ; fi

acceptance: $(CIDFILE)
	docker cp $(shell cat $(CIDFILE)):/opt/ldap-sync/features/report/ $(TESTDIR)/
	docker logs $(shell cat $(CIDFILE)) > $(TESTDIR)/docker.logs
	docker rm $(shell cat $(CIDFILE))
	rm -f $(CIDFILE)
	echo "Exit with original acceptance exit code $(shell cat $(EXITCODEFILE))"
	exit $(shell cat $(EXITCODEFILE))
	

