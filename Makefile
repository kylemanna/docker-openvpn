container: lib
	docker build -t derekcrovo/openvpn .

lib:
	docker run -v $$PWD:/data alpine /data/yubikey/build-libs.sh
