.PHONY: all conjur-ha build/clean build/push acceptance/clean acceptance/conjur acceptance/conjur-drop acceptance/prerequisites acceptance/run acceptance/results  

##### Run parameters
STUB_BUILD_NUMBER := $(USER)$(shell date +%s)
BUILD_NUMBER ?= $(STUB_BUILD_NUMBER)

##### Docker namespaces

#CONJUR_DOCKER_REGISTRY ?= registry.tld:80
BASE_IMAGE_NAME:=conjurinc/ldap-sync
TEST_IMAGE_NAME:=conjurinc/acceptance-ldap-sync
ARTIFACT_IMAGE_NAME:=conjurinc/acceptance-ldap-sync-results
CONJUR_PLATFORM ?= 4.4

# supplementary image, to launch Conjur servers for testing purposes
CONJUR_HA=conjurinc/conjur-ha:$(CONJUR_PLATFORM)

##### Build parameters
BUILDDIR:=build
BASE_DOCKER_CONTEXT :=$(BUILDDIR)/context/base
TEST_DOCKER_CONTEXT :=$(BUILDDIR)/context/test
BASE_TAG :=$(BASE_IMAGE_NAME):build_$(BUILD_NUMBER)
TEST_TAG ?=$(TEST_IMAGE_NAME):build_$(BUILD_NUMBER)

BASE_SOURCES:=bin lib Gemfile* *.gemspec
BASE_DEPS:=$(BASE_SOURCES) $(shell find bin/) $(shell find lib/) Dockerfile

TEST_SOURCES=features spec Rakefile dns_server
TEST_DEPS:=$(TEST_SOURCES) $(shell find features/) $(shell find spec/) Dockerfile.acceptance

##### Acceptance parameters
# non-deterministic dynamic evaluation should happen only with fixed variables (defined as := )
RANDOM_PASSWORD:=$(shell openssl rand -hex 8)
CONJUR_ADMIN_PASSWORD ?= $(RANDOM_PASSWORD)

CONJUR_ACCOUNT ?= conjur

CONJUR_STACK_NAME=acceptance-ldap-sync-$(BUILD_NUMBER)
ifdef AMI_ID
AMI_OPTS := --imageid $(AMI_ID)
endif

CONJURDIR:=test/conjur
HOSTFILE:=$(CONJURDIR)/conjur.host
PASSWORDFILE:=$(CONJURDIR)/conjur.password
STACKFILE:=$(CONJURDIR)/conjur.stackname

TESTDIR=test/test
CIDFILE:=$(TESTDIR)/acceptance.cid
EXITCODEFILE:=$(TESTDIR)/acceptance.exit.code

########## BUILD

$(BUILDDIR):
	mkdir -pv $(BUILDDIR)

build/clean:
	rm -rf $(BUILDDIR)

build/base: $(BASE_DEPS) $(BUILDDIR)
	rm -rf $(BASE_DOCKER_CONTEXT)
	mkdir -pv $(BASE_DOCKER_CONTEXT)
	rsync --delete -a $(BASE_SOURCES) Dockerfile $(BASE_DOCKER_CONTEXT)
	echo "BUILD_NUMBER=$(BUILD_NUMBER)" > $(BASE_DOCKER_CONTEXT)/build.base.info
	git show | head -n 2 >> $(BASE_DOCKER_CONTEXT)/build.base.info
	git status -s -b >> $(BASE_DOCKER_CONTEXT)/build.base.info
	docker build --rm -t $(BASE_TAG) $(BASE_DOCKER_CONTEXT)
	echo $(BASE_TAG) > $(BUILDDIR)/base
	docker tag -f $(BASE_TAG) $(BASE_IMAGE_NAME):latest
ifdef CONJUR_DOCKER_REGISTRY
	docker tag -f $(BASE_TAG) $(CONJUR_DOCKER_REGISTRY)/$(BASE_TAG)
	docker tag -f $(BASE_TAG) $(CONJUR_DOCKER_REGISTRY)/$(BASE_IMAGE_NAME):latest
endif

build/test: build/base $(TEST_DEPS) $(BUILDDIR)
	rm -rf $(TEST_DOCKER_CONTEXT)
	mkdir -pv $(TEST_DOCKER_CONTEXT)
	cp -r --preserve=all $(TEST_SOURCES) $(TEST_DOCKER_CONTEXT)
	sed -e 's/{BASEIMAGE}/$(subst /,\/,$(shell cat build/base))/' Dockerfile.acceptance > $(TEST_DOCKER_CONTEXT)/Dockerfile
	echo "BUILD_NUMBER=$(BUILD_NUMBER)" > $(TEST_DOCKER_CONTEXT)/build.test.info
	git show | head -n 2 >> $(TEST_DOCKER_CONTEXT)/build.test.info
	git status -s -b >> $(TEST_DOCKER_CONTEXT)/build.test.info
	docker build --rm -t $(TEST_TAG) $(TEST_DOCKER_CONTEXT)
	echo $(TEST_TAG) > $(BUILDDIR)/test
	docker tag -f $(TEST_TAG) $(TEST_IMAGE_NAME):latest
ifdef CONJUR_DOCKER_REGISTRY
	docker tag -f $(TEST_TAG) $(CONJUR_DOCKER_REGISTRY)/$(TEST_TAG)
	docker tag -f $(TEST_TAG) $(CONJUR_DOCKER_REGISTRY)/$(TEST_IMAGE_NAME):latest
endif

build/push:
ifdef CONJUR_DOCKER_REGISTRY
	docker push $(CONJUR_DOCKER_REGISTRY)/$(BASE_IMAGE_NAME)
	docker push $(CONJUR_DOCKER_REGISTRY)/$(TEST_IMAGE_NAME)
else
	$(error "Can not push images while CONJUR_DOCKER_REGISTRY is not defined")
endif


######### Acceptance

##### Acceptance: docker and FS boilerplate

$(TESTDIR):
	mkdir -pv $(TESTDIR)

$(CONJURDIR):
	mkdir -pv $(CONJURDIR)

# supplementary image to launch conjur
conjur-ha: 
ifdef CONJUR_DOCKER_REGISTRY
	docker pull $(CONJUR_DOCKER_REGISTRY)/$(CONJUR_HA)
	docker tag -f $(CONJUR_DOCKER_REGISTRY)/$(CONJUR_HA) $(CONJUR_HA)
else
	echo "No conjur docker registry defined, expecting $(CONJUR_HA) to be already in docker cache"
endif

acceptance/clean:
	rm -rf $(TESTDIR)

ifdef CONJUR_DOCKER_REGISTRY
acceptance/prerequisites: conjur-ha
	docker pull $(CONJUR_DOCKER_REGISTRY)/$(TEST_TAG)
	#docker tag -f $(CONJUR_DOCKER_REGISTRY)/$(TEST_IMAGE_NAME) $(TEST_IMAGE_NAME):latest
else
acceptance/prerequisites: build/test
endif


##### Acceptance: Conjur setup 

$(PASSWORDFILE): $(CONJURDIR)
	echo "$(CONJUR_ADMIN_PASSWORD)" > $(PASSWORDFILE)

# ensures we have available conjur appliance, either by picking it up from env, or by launching it
$(HOSTFILE): $(PASSWORDFILE) $(CONJURDIR)
ifdef CONJUR_APPLIANCE_HOSTNAME
	echo "$(CONJUR_APPLIANCE_HOSTNAME)" > $(HOSTFILE)
else
	make conjur-ha	
	docker run --rm -t                  \
		-e AWS_ACCESS_KEY	            \
		-e AWS_SECRET_KEY	            \
		$(CONJUR_HA) standalone	        \
			$(AMI_OPTS)				    \
			-k $(AWS_KEY_NAME)		    \
			-o $(CONJUR_ACCOUNT)	    \
			-p "$(shell cat $(PASSWORDFILE) )" \
            $(CONJUR_STACK_NAME)          	   \
		> $(CONJURDIR)/conjur.stack
	[ -f $(CONJURDIR)/conjur.stack ] || exit 1 
	grep -P 'Public(Ip|DnsName)' $(CONJURDIR)/conjur.stack  | cut -f2 | grep '[^[:space:]]' | head -n 1 > $(HOSTFILE)
	[ -s $(HOSTFILE) ] || exit 1
	echo "$(CONJUR_STACK_NAME)" > $(STACKFILE)
endif

# alias
acceptance/conjur: $(HOSTFILE)

acceptance/conjur-drop: conjur-ha
ifdef KEEP_INSTANCES
	$(error "KEEP_INSTANCES variable is set, refusing to delete stack $(CONJUR_STACK_NAME)")
endif
	[ -s $(STACKFILE) ] || exit 1
	docker run --rm --net=host -t       \
		-e AWS_ACCESS_KEY	            \
		-e AWS_SECRET_KEY	            \
		$(CONJUR_HA) stack delete       \
			$(shell cat $(STACKFILE))
	rm -rf $(CONJURDIR) 


##### Acceptance: main  

acceptance/run: $(TESTDIR) $(HOSTFILE) $(PASSWORDFILE) 
	[ ! -f $(CIDFILE) ] || exit 1
	docker run --cidfile $(CIDFILE)					                        \
		-t                  						                        \
		-e CONJUR_ACCOUNT="$(CONJUR_ACCOUNT)"                               \
		-e CONJUR_TEST_ENVIRONMENT=acceptance                               \
		-e CONJUR_APPLIANCE_HOSTNAME="$(shell cat $(HOSTFILE) )"			\
		-e CONJUR_ADMIN_PASSWORD_FILE=/tmp/conjur-admin-password	        \
		-v $(abspath $(PASSWORDFILE)):/tmp/conjur-admin-password			\
		$(TEST_TAG)                                                  \
			; echo $$? >> $(EXITCODEFILE)
	if [ ! -f $(CIDFILE) ]; then exit 1 ; fi

acceptance/results: acceptance/prerequisites acceptance/clean acceptance/run
	docker cp $(shell cat $(CIDFILE)):/opt/ldap-sync/features/report/ $(TESTDIR)/cukes_report
	docker cp $(shell cat $(CIDFILE)):/opt/ldap-sync/spec/reports/ $(TESTDIR)/spec_report
	docker logs $(shell cat $(CIDFILE)) > $(TESTDIR)/docker.logs
	docker commit $(shell cat $(CIDFILE)) $(ARTIFACT_IMAGE_NAME):$(BUILD_NUMBER)
ifdef CONJUR_DOCKER_REGISTRY 
	docker tag -f $(ARTIFACT_IMAGE_NAME):$(BUILD_NUMBER) $(CONJUR_DOCKER_REGISTRY)/$(ARTIFACT_IMAGE_NAME):$(BUILD_NUMBER)
	docker push $(CONJUR_DOCKER_REGISTRY)/$(ARTIFACT_IMAGE_NAME)
endif
	docker rm $(shell cat $(CIDFILE))
	rm -f $(CIDFILE)
	[ ! -f $(STACKFILE) ] || make acceptance/conjur-drop
	echo "Exit with original acceptance exit code $(shell cat $(EXITCODEFILE))"
	exit $(shell cat $(EXITCODEFILE))
