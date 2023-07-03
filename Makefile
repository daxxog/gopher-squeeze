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
