# docker build -t accetto/ubuntu-vnc-xfce .
# docker build --build-arg BASETAG=rolling -t accetto/ubuntu-vnc-xfce:rolling .
# docker build --build-arg ARG_VNC_RESOLUTION=1360x768 -t accetto/ubuntu-vnc-xfce .

ARG BASETAG=latest

FROM ubuntu:${BASETAG} as stage-ubuntu

LABEL \
    maintainer="https://github.com/accetto" \
    vendor="accetto"

### 'apt-get clean' runs automatically
RUN apt-get update && apt-get install -y \
        lsb-release \
        net-tools \
        vim \
    && rm -rf /var/lib/apt/lists/*

### supports testing, should be overriden
#ENTRYPOINT ["tail", "-f", "/dev/null"]

FROM stage-ubuntu as stage-xfce

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

### 'apt-get clean' runs automatically
RUN apt-get update && apt-get install -y \
        mousepad \
        locales \
        supervisor \
        xfce4 \
        xfce4-terminal \
    && locale-gen en_US.UTF-8 \
    && apt-get purge -y \
        pm-utils \
        xscreensaver* \
    && rm -rf /var/lib/apt/lists/*

FROM stage-xfce as stage-vnc

### 'apt-get clean' runs automatically
### installed into '/usr/share/usr/local/share/vnc'
RUN apt-get update && apt-get install -y \
        wget \
    && wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.9.0.x86_64.tar.gz | tar xz --strip 1 -C / \
    && rm -rf /var/lib/apt/lists/*

FROM stage-vnc as stage-novnc

### same parent path as VNC
ENV NO_VNC_HOME=/usr/share/usr/local/share/noVNCdim

### 'apt-get clean' runs automatically
### 'python-numpy' used for websockify/novnc
### ## Use the older version of websockify to prevent hanging connections on offline containers, 
### see https://github.com/ConSol/docker-headless-vnc-container/issues/50
### installed into '/usr/share/usr/local/share/noVNCdim'
RUN apt-get update && apt-get install -y \
        python-numpy \
    && mkdir -p ${NO_VNC_HOME}/utils/websockify \
    && wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C ${NO_VNC_HOME} \
    && wget -qO- https://github.com/novnc/websockify/archive/v0.8.0.tar.gz | tar xz --strip 1 -C ${NO_VNC_HOME}/utils/websockify \
    && chmod +x -v ${NO_VNC_HOME}/utils/*.sh \
    && rm -rf /var/lib/apt/lists/*

### add 'index.html' for choosing noVNC client
RUN echo \
"<!DOCTYPE html>\n" \
"<html>\n" \
"    <head>\n" \
"        <title>noVNC</title>\n" \
"        <meta charset=\"utf-8\"/>\n" \
"    </head>\n" \
"    <body>\n" \
"        <p><a href=\"vnc_lite.html\">noVNC Lite Client</a></p>\n" \
"        <p><a href=\"vnc.html\">noVNC Full Client</a></p>\n" \
"    </body>\n" \
"</html>" \
> ${NO_VNC_HOME}/index.html

FROM stage-novnc as stage-final

LABEL \
    any.accetto.description="Headless Ubuntu VNC/noVNC container with Xfce desktop" \
    any.accetto.display-name="Headless Ubuntu/Xfce VNC/noVNC container" \
    any.accetto.expose-services="6901:http,5901:xvnc" \
    any.accetto.tags="ubuntu, xfce, vnc, novnc"

### Arguments can be provided during build
ARG ARG_HOME
ARG ARG_VNC_BLACKLIST_THRESHOLD
ARG ARG_VNC_BLACKLIST_TIMEOUT
ARG ARG_VNC_PW
ARG ARG_VNC_RESOLUTION

ENV \
    DISPLAY=:1 \
    HOME=${ARG_HOME:-/home/headless} \
    NO_VNC_PORT="6901" \
    STARTUPDIR=/boot/startup \
    VNC_BLACKLIST_THRESHOLD=${ARG_VNC_BLACKLIST_THRESHOLD:-20} \
    VNC_BLACKLIST_TIMEOUT=${ARG_VNC_BLACKLIST_TIMEOUT:-0} \
    VNC_COL_DEPTH=24 \
    VNC_PORT="5901" \
    VNC_PW=${ARG_VNC_PW:-headless} \
    VNC_RESOLUTION=${ARG_VNC_RESOLUTION:-1366x768} \
    VNC_VIEW_ONLY=false

### Creates home folder
WORKDIR ${HOME}

COPY [ "./src/", "${STARTUPDIR}/" ]

### 'apt-get clean' runs automatically
### Install nss-wrapper to be able to execute image as non-root user
### 'generate_container_user' has to be sourced to hold all env vars correctly
RUN apt-get update && apt-get install -y \
        gettext \
        libnss-wrapper \
    && echo 'source $STARTUPDIR/generate_container_user' >> ${HOME}/.bashrc \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x ${STARTUPDIR}/*.sh

### Preconfigure Xfce panels
COPY [ "./src/xfce4/panel", "./.config/xfce4/panel/" ]
COPY [ "./src/xfce4/xfce4-panel.xml", "./.config/xfce4/xfconf/xfce-perchannel-xml/" ]
RUN chmod 700 ./.config/xfce4/xfconf/xfce-perchannel-xml \
    && chmod 644 ./.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    && chmod 700 ./.config/xfce4/panel/launcher* \
    && chmod 644 ./.config/xfce4/panel/launcher*/*

EXPOSE ${VNC_PORT} ${NO_VNC_PORT}


ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_HOME       /usr/lib/jvm/java-8-oracle
ENV LANG            en_US.UTF-8
ENV LC_ALL          en_US.UTF-8

RUN apt-get update && \
  apt-get install -y --no-install-recommends locales && \
  locale-gen en_US.UTF-8 && \
  apt-get dist-upgrade -y && \
  apt-get --purge remove openjdk* && \
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
  apt-get update && \
  apt-get install -y --no-install-recommends oracle-java8-installer oracle-java8-set-default && \
  apt-get install -y x11-apps libxext-dev libxrender-dev libxtst-dev libgtk2.0-0 libcanberra-gtk-module && \
  apt-get clean all

WORKDIR ${HOME}

ENV GEPHI_VERSION=0.9.2\
	SCI2_VERSION=1.3.0_20180202
RUN wget --no-check-certificate https://github.com/gephi/gephi/releases/download/v$GEPHI_VERSION/gephi-$GEPHI_VERSION-linux.tar.gz &&\
	tar xzf gephi-$GEPHI_VERSION-linux.tar.gz &&\
	rm gephi-$GEPHI_VERSION-linux.tar.gz
COPY [ "./gephi-$GEPHI_VERSION/gephi.png", "./gephi-$GEPHI_VERSION/" ]
RUN wget http://nwb.cns.iu.edu/nightly/sci2/$SCI2_VERSION/sci2-$SCI2_VERSION-linux.gtk.x86_64.tgz &&\
	tar xzf sci2-$SCI2_VERSION-linux.gtk.x86_64.tgz &&\
	rm sci2-$SCI2_VERSION-linux.gtk.x86_64.tgz
ENV PATH=$PATH:gephi-$GEPHI_VERSION/bin:sci2

COPY [ "./sci2.desktop", "./Desktop/" ]
COPY [ "./gephi-$GEPHI_VERSION/gephi.desktop", "./Desktop/" ]

RUN chmod +x ./Desktop/sci2.desktop
RUN chmod +x ./Desktop/gephi.desktop

WORKDIR ${STARTUPDIR}
ENTRYPOINT ["./vnc_startup.sh"]
CMD [ "--wait" ]
