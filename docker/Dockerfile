FROM quay.io/pterodactyl/core:source
LABEL author="Ricool" maintainer="ricoolohsix@hotmail.com"
USER root
RUN echo steam steam/question select "I AGREE" | debconf-set-selections && \
echo steam steam/license note '' | debconf-set-selections
RUN dpkg --add-architecture i386 && apt-get update && \
apt-get install -y software-properties-common basez jq gnupg && \
add-apt-repository multiverse && \
apt-get update && \
apt-get install -y steamcmd && rm -rf /var/lib/apt/lists/*
USER container
