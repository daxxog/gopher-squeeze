SHELL := /bin/bash


.PHONY: build
build: build-local build-container


.PHONY: build-local
build-local: client/gopher-squeeze server/gopher-squeeze


.PHONY: build-container
build-container: container-built.txt


.PHONY: help
help:
	@printf "available targets -->\n\n"
	@cat Makefile | grep ".PHONY" | grep -v ".PHONY: _" | sed 's/.PHONY: //g'


client/gopher-squeeze: client/client.go
	cd client && go build .


server/gopher-squeeze: server/server.go
	cd server && go build .


LICENSE:
	curl -s https://www.apache.org/licenses/LICENSE-2.0.txt > LICENSE


container-built.txt: Dockerfile client/client.go server/server.go client/go.mod server/go.mod server/go.sum
	podman build . \
		-t localhost/$$(git remote get-url origin | awk '{split($$0,a,"/");print a[2]}' | sed 's/\.git//g') \
	;
	echo "$$(date) :: localhost/$$(git remote get-url origin | awk '{split($$0,a,"/");print a[2]}' | sed 's/\.git//g')" \
		| tee -a container-built.txt \
	;


.PHONY: debug
debug: build-container
	podman run \
		-i \
		-t \
		--entrypoint /bin/sh \
		localhost/$$(git remote get-url origin | awk '{split($$0,a,"/");print a[2]}' | sed 's/\.git//g') \
	;


webhook-secret.txt:
	cat /dev/random \
		| head -c 4096 \
		| shasum -a 512 \
		| head -c 64 \
		> webhook-secret.txt \
	;


.PHONY: run-server
run-server: build-container webhook-secret.txt
	podman run \
		-p 8000:8000 \
		-i \
		-t \
		-e WEBHOOK_SECRET=$$(cat webhook-secret.txt) \
		localhost/$$(git remote get-url origin | awk '{split($$0,a,"/");print a[2]}' | sed 's/\.git//g') \
	;


.PHONY: test-client
test-client: webhook-secret.txt client/gopher-squeeze
	WEBHOOK_ENDPOINT=http://localhost:8000/log/$$(cat webhook-secret.txt) \
		cat README.md \
		| ./client/gopher-squeeze \
	;


env:
	python3 -m venv env
	if [ -f requirements.txt ]; then \
		bash -c 'source env/bin/activate && set -x && python3 -m pip install -r requirements.txt'; \
	fi


requirements.in:
	echo "pip-tools" > requirements.in
	echo "zest.releaser" >> requirements.in
	if git status requirements.in | grep -q requirements.in; then \
		git add requirements.in; \
		git commit -m 'new file:   requirements.in'; \
	fi


requirements.txt: requirements.in env
	bash -c 'source env/bin/activate && set -x && python3 -m pip install -r requirements.in && pip-compile --generate-hashes --resolver=backtracking'
	if git status requirements.txt | grep -q requirements.txt; then \
		git add requirements.txt; \
		git commit -m 'generated:   requirements.txt'; \
	fi


CHANGES.md:
	if [ ! -f CHANGES.md ]; then \
		touch CHANGES.md; \
		git add CHANGES.md; \
		git commit -m 'new file:   CHANGES.md'; \
	fi


VERSION:
	if [ ! -f VERSION ]; then \
		echo "0.0.1" > VERSION; \
		git add VERSION; \
		git commit -m 'new file:   VERSION'; \
	fi


.PHONY: release
release: env CHANGES.md VERSION requirements.txt .github/workflows/docker-push.yml
	bash -c 'source env/bin/activate && set -x && fullrelease'


.github/workflows:
	mkdir -p .github/workflows


.github/workflows/docker-push.yml: .github/workflows
	curl \
		-sL \
		https://raw.githubusercontent.com/daxxog/trufflehog-testing/master/.github/workflows/docker-push.yml \
		> .github/workflows/docker-push.yml \
	;
	if git status .github/workflows/docker-push.yml | grep -q .github/workflows/docker-push.yml; then \
		git add .github/workflows/docker-push.yml; \
		git commit -m 'downloaded:   .github/workflows/docker-push.yml'; \
	fi
