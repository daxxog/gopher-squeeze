SHELL := /bin/bash


.PHONY: build
build: client/gopher-squeeze server/gopher-squeeze


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
