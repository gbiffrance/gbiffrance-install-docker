#! make

VERSION = $(TRAVIS_BUILD_ID)
ME = $(USER)
HOST = bioatlas.se
TS := $(shell date '+%Y_%m_%d_%H_%M')
PWD := $(shell pwd)
UID := $(shell id -u)
GID := $(shell id -g)

URL_JTS = https://repo1.maven.org/maven2/org/locationtech/jts/jts-core/1.15.1/jts-core-1.15.1.jar
URL_JTS_IO = https://repo1.maven.org/maven2/org/locationtech/jts/io/jts-io-common/1.15.1/jts-io-common-1.15.1.jar
URL_COLLECTORY = https://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/ala-collectory/1.6.2/ala-collectory-1.6.2.war
URL_BIOCACHE_SERVICE = https://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/biocache-service/2.1.20/biocache-service-2.1.20.war
URL_BIOCACHE_HUB = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/ala-hub/3.2.4/ala-hub-3.2.4.war
URL_BIOCACHE_CLI = https://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/biocache-store/2.4.5/biocache-store-2.4.5-distribution.zip
URL_BIEINDEX = https://github.com/bioatlas/bie-index/releases/download/bas-1.4.8/bie-index-1.4.8.war
URL_DYNTAXA = https://api.artdatabanken.se/taxonservice/v1/DarwinCore/DarwinCoreArchiveFile?Subscription-Key=4b068709e7f2427d9fc76bf42d8e2b57
URL_NAMESDIST = https://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/ala-name-matching/3.4/ala-name-matching-3.4-distribution.zip
URL_LOGGER_SERVICE = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/logger-service/2.3.5/logger-service-2.3.5.war

all: init build dotfiles
all-clean: init-clean dotfiles-clean all

init-clean:
	@echo "Removing cached files from the build"
	rm -f solr7/lib/jts-core-1.15.1.jar \
		solr7/lib/jts-io-common-1.15.1.jar \
		collectory/collectory.war \
		biocacheservice/biocache-service.war \
		biocachehub/ala-hub.war \
		biocachebackend/biocache.zip \
		bieindex/bie-index.war \
		dyntaxa-index/dyntaxa.dwca.zip \
		dyntaxa-index/nameindexer.zip \
		loggerservice/logger-service.war

init:
	@echo "Caching files required for the build..."

	@test -f solr7/lib/jts-core-1.15.1.jar || \
		wget -q --show-progress -O solr7/lib/jts-core-1.15.1.jar $(URL_JTS)
	@test -f solr7/lib/jts-io-common-1.15.1.jar || \
		wget -q --show-progress -O solr7/lib/jts-io-common-1.15.1.jar $(URL_JTS_IO)

	@test -f collectory/collectory.war || \
		wget -q --show-progress -O collectory/collectory.war $(URL_COLLECTORY)

	@test -f biocacheservice/biocache-service.war || \
		wget -q --show-progress -O biocacheservice/biocache-service.war $(URL_BIOCACHE_SERVICE)

	@test -f biocachehub/ala-hub.war || \
		wget -q --show-progress -O biocachehub/ala-hub.war $(URL_BIOCACHE_HUB)

	@test -f biocachebackend/biocache.zip || \
		wget -q --show-progress -O biocachebackend/biocache.zip $(URL_BIOCACHE_CLI)

	@test -f bieindex/bie-index.war || \
		wget -q --show-progress -O bieindex/bie-index.war $(URL_BIEINDEX)

	@test -f dyntaxa-index/dyntaxa.dwca.zip || \
		wget -q --show-progress -O dyntaxa-index/dyntaxa.dwca.zip $(URL_DYNTAXA)

	@test -f dyntaxa-index/nameindexer.zip || \
		wget -q --show-progress -O dyntaxa-index/nameindexer.zip $(URL_NAMESDIST)

	@test -f loggerservice/logger-service.war || \
		wget -q --show-progress -O loggerservice/logger-service.war $(URL_LOGGER_SERVICE)

secrets:
	docker run --rm -it -v $(PWD):/tmp -u $(UID):$(GID) httpd:alpine bash -c \
		'printf "export SECRET_MYSQL_ROOT_PASSWORD=%b\n" \
			$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) > /tmp/secrets && \
		printf "export SECRET_MYSQL_PASSWORD=%b\n" \
			$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> /tmp/secrets '

dotfiles: secrets
	docker run --rm -it httpd:alpine htpasswd -nb admin '' > env/.htpasswd
	docker run --rm -it \
		-v $(PWD)/secrets:/etc/profile.d/secrets.sh \
		-v $(PWD):/tmp \
		-u $(UID):$(GID) \
		-w /tmp \
		nginx:alpine sh -l -c \
			'envsubst < env/envcollectory.template > env/.envcollectory && \
             envsubst < env/envlogger.template > env/.envlogger'

dotfiles-clean:
	rm -f secrets && \
	    cd env && \
	    rm -f .envcollectory && \
	    rm -f .envlogger && \
		rm -f .htpasswd

build:
	@echo "Building images..."
	@docker build -t gbiffrance/ala-cassandra -t gbiffrance/ala-cassandra:1.0 cassandra3
	@docker build -t gbiffrance/ala-solr -t gbiffrance/ala-solr:1.0 solr7
	@docker build -t gbiffrance/ala-collectory -t gbiffrance/ala-collectory:1.0 collectory
	@docker build -t gbiffrance/ala-biocacheservice -t gbiffrance/ala-biocacheservice:1.0 biocacheservice
	@docker build -t gbiffrance/ala-biocachehub -t gbiffrance/ala-biocachehub:1.0 biocachehub
	@docker build -t gbiffrance/ala-biocachebackend -t gbiffrance/ala-biocachebackend:1.0 biocachebackend
	@docker build -t gbiffrance/ala-bieindex -t gbiffrance/ala-bieindex:1.0 bieindex
	@docker build -t gbiffrance/ala-dyntaxaindex -t gbiffrance/ala-dyntaxaindex:1.0 dyntaxa-index
	@docker build -t gbiffrance/ala-loggerservice -t gbiffrance/ala-loggerservice:1.0 loggerservice

push:
	@echo "Pushing images to Dockerhub..."
	@docker push gbiffrance/ala-cassandra:1.0
	@docker push gbiffrance/ala-solr:1.0
	@docker push gbiffrance/ala-collectory:1.0
	@docker push gbiffrance/ala-biocacheservice:1.0
	@docker push gbiffrance/ala-biocachehub:1.0
	@docker push gbiffrance/ala-biocachebackend:1.0
	@docker push gbiffrance/ala-bieindex:1.0
	@docker push gbiffrance/ala-dyntaxaindex:1.0
	@docker push gbiffrance/ala-loggerservice:1.0
