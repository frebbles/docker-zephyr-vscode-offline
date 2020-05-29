FROM ubuntu:18.04

ARG ZSDK_VERSION=0.11.2
ARG GCC_ARM_NAME=gcc-arm-none-eabi-9-2019-q4-major
ARG CMAKE_VERSION=3.16.2
ARG RENODE_VERSION=1.8.2
ARG DTS_VERSION=1.4.7
ARG VSCODESERVER_VERSION=3.3.1

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
	gnupg \
	ca-certificates && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
	apt-get -y update && \
	apt-get install --no-install-recommends -y \
	autoconf \
	automake \
	bash \
	build-essential \
	ccache \
	device-tree-compiler \
	dfu-util \
	dos2unix \
	doxygen \
	file \
	g++ \
	gcc \
	gcc-multilib \
	gcovr \
	git \
	git-core \
	gperf \
	gtk-sharp2 \
	iproute2 \
	lcov \
	libglib2.0-dev \
	libgtk2.0-0 \
	libpcap-dev \
	libsdl2-dev:i386 \
	libtool \
	locales \
	make \
	menu \
	minicom \
	mono-complete \
	netcat \
	net-tools \
	ninja-build \
	openbox \
	pkg-config \
	python3-dev \
	python3-pip \
	python3-ply \
	python3-setuptools \
	python-xdg \
	qemu \
	socat \
	sudo \
	texinfo \
	valgrind \
	vim \
	wget \
	x11vnc \
	xvfb \
	xz-utils && \
	wget -O dtc.deb http://security.ubuntu.com/ubuntu/pool/main/d/device-tree-compiler/device-tree-compiler_${DTS_VERSION}-3ubuntu2_amd64.deb && \
	dpkg -i dtc.deb && \
	wget -O renode.deb https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb && \
	apt install -y ./renode.deb && \
	rm dtc.deb renode.deb && \
	rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


RUN wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements-base.txt && \
	wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements-build-test.txt && \
	wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements-doc.txt && \
	wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements-run-test.txt && \
	wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements-extras.txt && \
	pip3 install wheel &&\
	pip3 install -r requirements.txt && \
	pip3 install west &&\
	pip3 install sh

RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
	rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

RUN west init /zephyrproject && \
        cd /zephyrproject && \
        west update && \
        west zephyr-export && \
        pip3 install -r /zephyrproject/zephyr/scripts/requirements.txt

RUN wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-setup.run" && \
	sh "zephyr-sdk-${ZSDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
	rm "zephyr-sdk-${ZSDK_VERSION}-setup.run"

RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/${GCC_ARM_NAME}-x86_64-linux.tar.bz2  && \
	tar xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 && \
	rm -f ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 && \
	mv ${GCC_ARM_NAME} /opt/toolchains/${GCC_ARM_NAME}

# download the coder binary, untar it, and allow it to be executed
RUN wget https://github.com/cdr/code-server/releases/download/v${VSCODESERVER_VERSION}/code-server-${VSCODESERVER_VERSION}-linux-x86_64.tar.gz \
    && tar -xzvf code-server-${VSCODESERVER_VERSION}-linux-x86_64.tar.gz && chmod +x code-server-${VSCODESERVER_VERSION}-linux-x86_64/code-server

RUN groupadd -g $GID -o user

RUN useradd -u $UID -m -g user -G plugdev,dialout user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user

USER user

RUN code-server-${VSCODESERVER_VERSION}-linux-x86_64/code-server \
        --user-data-dir=/home/user/.vscode/ \
        --extensions-dir=/home/user/.vscode-oss/extensions/ \
        --install-extension ms-vscode.cpptools

RUN code-server-${VSCODESERVER_VERSION}-linux-x86_64/code-server \
        --user-data-dir=/home/user/.vscode/ \
        --extensions-dir=/home/user/.vscode-oss/extensions/ \
        --install-extension marus25.cortex-debug

RUN code-server-${VSCODESERVER_VERSION}-linux-x86_64/code-server \
        --user-data-dir=/home/user/.vscode/ \
        --extensions-dir=/home/user/.vscode-oss/extensions/ \
        --install-extension lextudio.restructuredtext

# Copy required configs into their dirs for vscode extensions
RUN mkdir /home/user/SVD
RUN mkdir /home/user/vscode_default
RUN mkdir -p /home/user/.vscode/User/state/
ADD ./svd/STM32F746.svd /home/user/SVD/STM32F746.svd
ADD ./vscode_defaults/* /home/user/vscode_default/
ADD ./vscode_defaults/global.json /home/user/.vscode/User/state/

# Setup some symlinks for vscode to find and run debugger
RUN ln -s \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/arm-zephyr-eabi/bin/arm-none-eabi-gdb
RUN ln -s \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/arm-zephyr-eabi/bin/arm-zephyr-eabi-objdump \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/arm-zephyr-eabi/bin/arm-none-eabi-objdump
RUN sudo ln -s \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/sysroots/x86_64-pokysdk-linux/usr/bin/openocd \
	/usr/local/bin/openocd

# Set the locale for zephyr
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
ENV ZEPHYR_BASE=/zephyrproject
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DISPLAY=:0
ENV SHELL=/bin/bash

ADD ./entrypoint.sh /home/user/entrypoint.sh

RUN sudo chown -R user:user /home/user
RUN sudo chown -R user:user /zephyrproject

RUN dos2unix /home/user/entrypoint.sh

RUN sed -i "s/VSCODESERVER_VERSION/${VSCODESERVER_VERSION}/g" /home/user/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD ["/bin/bash"]
USER user
WORKDIR /workdir
VOLUME ["/workdir"]

