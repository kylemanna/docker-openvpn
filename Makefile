.PHONY: test

build:
	docker build -t eilidhmae/openvpn .
test:
	test/run.sh eilidhmae/openvpn

clean:
	docker volume rm basic-data basic-data-otp dual-data ovpn-revoke-test-data
