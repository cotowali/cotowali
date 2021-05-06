.PHONY: all build verify-system

all: build

build: verify-system
	z build

verify-system:
	@sh ./scripts/verify-system.sh
