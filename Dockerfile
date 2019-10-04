# Original credit: https://github.com/kylemanna/docker-openvpn, https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:latest

LABEL maintainer="TheMardy" \
  org.label-schema.name="openvpn" \
  org.label-schema.description="OpenVPN" \
  org.label-schema.url="https://github.com/themardy/docker-openvpn" \
  org.label-schema.vcs-url="https://github.com/themardy/docker-openvpn" \
  org.label-schema.vendor="TheMardy" \
  org.label-schema.schema-version="1.0"

# Allow Multi Platform
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
