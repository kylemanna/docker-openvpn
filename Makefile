.PHONY: test

build:
	docker build -t eilidhmae/openvpn .
test:
	test/run.sh eilidhmae/openvpn
