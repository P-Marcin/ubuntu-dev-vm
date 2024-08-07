ARG UBUNTU_VERSION=24.04
FROM dokken/ubuntu-${UBUNTU_VERSION}:main AS intellij-idea
ARG INTELLIJ_IDEA_VERSION
RUN apt-get update -y \
    && apt-get install -y \
		libfreetype6 \
		fontconfig fontconfig-config libfontconfig1 \
    && wget --progress=bar:force -O "intellij-idea.tar.gz" "https://download.jetbrains.com/idea/ideaIC-${INTELLIJ_IDEA_VERSION}.tar.gz" \
    && mkdir "/intellij-idea" \
    && tar --extract --gzip --directory "/intellij-idea" --strip-components=1 --file="intellij-idea.tar.gz" \
    # IntelliJ Idea plugins installation
    && /intellij-idea/bin/idea.sh installPlugins \
        # https://plugins.jetbrains.com/plugin/7724-docker
        "Docker" \
        # https://plugins.jetbrains.com/plugin/10650-json-parser
        "com.godwin.json.parser" \
        # https://plugins.jetbrains.com/plugin/6317-lombok
        "Lombook Plugin" \
        # https://plugins.jetbrains.com/plugin/7248-multirun
        "com.khmelyuk.multirun" \
        # https://plugins.jetbrains.com/plugin/7973-sonarlint
        "org.sonarlint.idea"

FROM alpine:latest AS kafka
ARG KAFKA_VERSION
ARG SCALA_VERSION
RUN wget -O "kafka.tar.gz" "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
    && mkdir "/kafka" \
    && tar --extract --gzip --exclude="windows" --directory "/kafka" --strip-components=1 --file="kafka.tar.gz" "kafka_${SCALA_VERSION}-${KAFKA_VERSION}/bin" \
        "kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config" \
        "kafka_${SCALA_VERSION}-${KAFKA_VERSION}/libs"

FROM dokken/ubuntu-${UBUNTU_VERSION}:main AS keystore-explorer
ARG KEYSTORE_EXPLORER_VERSION
RUN wget --progress=bar:force -O "/tmp/kse.deb" "https://github.com/kaikramer/keystore-explorer/releases/download/v${KEYSTORE_EXPLORER_VERSION}/kse_${KEYSTORE_EXPLORER_VERSION}_all.deb" \
    && apt-get update -y \
	&& apt-get install -y "/tmp/kse.deb"

FROM alpine:latest AS kitty
RUN mkdir "/kitty" \
    && wget --quiet -O - https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin dest="/kitty" launch=n

FROM alpine:latest AS postman
ARG POSTMAN_VERSION
RUN wget -O "postman.tar.gz" "https://dl.pstmn.io/download/${POSTMAN_VERSION}/linux64" \
    && mkdir "/postman" \
	&& tar --extract --gzip --directory="/postman" --strip-components=2 --file="postman.tar.gz" "Postman/app"

FROM dokken/ubuntu-${UBUNTU_VERSION}:main AS sdkman
ARG JAVA_VERSION
ARG MAVEN_VERSION
ARG SPRING_BOOT_VERSION
RUN apt-get update -y \
    && apt-get install -y unzip zip \
    && export SDKMAN_DIR="/opt/sdkman" \
    && wget --quiet -O - "https://get.sdkman.io" | bash \
    && sed --in-place "/sdkman_auto_answer=/c sdkman_auto_answer=true" "${SDKMAN_DIR}/etc/config" \
    && sed --in-place "/sdkman_auto_env=/c sdkman_auto_env=true" "${SDKMAN_DIR}/etc/config" \
    && sed --in-place "/sdkman_colour_enable=/c sdkman_colour_enable=false" "${SDKMAN_DIR}/etc/config" \
    && sed --in-place "/sdkman_selfupdate_feature=/c sdkman_selfupdate_feature=false" "${SDKMAN_DIR}/etc/config" \
    && /bin/bash -c ". \"${SDKMAN_DIR}/bin/sdkman-init.sh\" \
    && sdk install \"java\" \"${JAVA_VERSION}\" \
    && sdk install \"maven\" \"${MAVEN_VERSION}\" \
    && sdk install \"springboot\" \"${SPRING_BOOT_VERSION}\" \
    && sdk flush &>/dev/null"

FROM scratch AS dev-tools
COPY --from=intellij-idea /intellij-idea /dev-tools/intellij-idea/
COPY --from=kafka /kafka /dev-tools/kafka/
COPY --from=keystore-explorer /opt/kse /dev-tools/keystore-explorer/
COPY --from=kitty /kitty/kitty.app /dev-tools/kitty/
COPY --from=postman /postman /dev-tools/postman/
COPY --from=sdkman /opt/sdkman /dev-tools/sdkman/

FROM alpine:latest AS cloud-tools
ARG CTOP_VERSION
ARG KUBECTL_VERSION
ARG KUBECTL_KREW_VERSION
ARG K3D_VERSION
ARG HELM_VERSION
ARG K9S_VERSION
RUN apk update \
	&& apk add --no-cache git \
	&& mkdir /cloud-tools /etc/bash_completion.d \
    # Ctop
    && wget -O "/cloud-tools/ctop" "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64" \
    && chmod +x "/cloud-tools/ctop" \
    # Kubectl
    && wget -O "/cloud-tools/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x "/cloud-tools/kubectl" \
    && /cloud-tools/kubectl completion bash > "/etc/bash_completion.d/kubectl" \
	# Kubectl Krew
    && wget -O "/tmp/krew.tar.gz" "https://github.com/kubernetes-sigs/krew/releases/download/v${KUBECTL_KREW_VERSION}/krew-linux_amd64.tar.gz" \
    && tar --extract --gzip --directory "/tmp" --file="/tmp/krew.tar.gz" \
    && /tmp/krew-linux_amd64 install krew \
    # K3d
    && wget -O "/cloud-tools/k3d" "https://github.com/k3d-io/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64" \
    && chmod +x "/cloud-tools/k3d" \
    && /cloud-tools/k3d completion bash > "/etc/bash_completion.d/k3d" \
    # Helm
    && wget -O "helm.tar.gz" "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    && tar --extract --gzip --directory "/cloud-tools" --strip-components=1 --file="helm.tar.gz" "linux-amd64/helm" \
    && chmod +x "/cloud-tools/helm" \
    && /cloud-tools/helm completion bash > "/etc/bash_completion.d/helm" \
    # K9s
    && wget -O "k9s.tar.gz" "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
    && tar --extract --gzip --directory "/cloud-tools" --file="k9s.tar.gz" "k9s" \
    && chmod +x "/cloud-tools/k9s" \
    && /cloud-tools/k9s completion bash > "/etc/bash_completion.d/k9s"

FROM dokken/ubuntu-${UBUNTU_VERSION}:main
ARG UBUNTU_DEV_VM_VERSION
ARG UID=1001
ENV USER=${image.user} \
	DISPLAY=${image.display}

# System setup
RUN apt-get update -y \
    && apt-get install -y software-properties-common \
    # Custom repositories installation
    && add-apt-repository -y ppa:mozillateam/ppa \
    && add-apt-repository -y ppa:git-core/ppa \
    && wget --progress=bar:force -O "/etc/apt/trusted.gpg.d/git-lfs.asc" https://packagecloud.io/github/git-lfs/gpgkey \
        && printf "deb [arch=amd64] https://packagecloud.io/github/git-lfs/ubuntu $(sed --quiet 's/VERSION_CODENAME=//p' /etc/os-release) main\n" > /etc/apt/sources.list.d/git-lfs.list \
    && wget --progress=bar:force -O "/etc/apt/trusted.gpg.d/docker.asc" "https://download.docker.com/linux/ubuntu/gpg" \
        && printf "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(sed --quiet 's/VERSION_CODENAME=//p' /etc/os-release) stable\n" > /etc/apt/sources.list.d/docker.list \
    # Prioritize Firefox Apt Over Snap
    && printf "Package: *\n\
Pin: release o=LP-PPA-mozillateam\n\
Pin-Priority: 1001\n\
Package: firefox\n\
Pin: version 1:1snap*\n\
Pin-Priority: -1\n" > /etc/apt/preferences.d/mozilla-firefox \
    # Package installation from custom repositories
    && apt-get update -y \
    && apt-get install -y \
        # Utilities
        bash-completion \
        ca-certificates \
        dbus-x11 \
        gedit \
        jq \
        nano \
        neofetch \
        software-properties-common \
        yad \
        zip unzip \
        # Dev/Cloud Tools \
        firefox libpci3 \
        git git-lfs \
        docker-ce docker-ce-cli containerd.io \
        # Kitty Terminal dependency
        libxcb-xkb1 \
		# Postman dependency
		libnss3 \
        # Node Package Manager
        npm \
    # Yarn Package Manager installation
    && npm install -g "yarn" \
    # Cleanup
    && apt-get --purge autoremove -y \
    && apt-get clean -y \
    && npm cache clean --force \
    && yarn cache clean \
    && rm -rf /root/.launchpadlib \
        /root/.npm/* \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apt/* \
        /var/lib/apt/lists/* \
        /usr/local/share/.cache/* \
        /var/log/* \
    && find /etc/systemd/system \
        /lib/systemd/system \
        -path '*.wants/*' \
        \( -name '*getty*' \
        -or -name '*apt-daily*' \
        -or -name '*systemd-timesyncd*' \
        -or -name '*systemd-logind*' \
        -or -name '*systemd-vconsole-setup*' \
        -or -name '*systemd-readahead*' \
        -or -name '*udev*' \) \
        -exec rm -v {} \;

COPY --from=dev-tools /dev-tools /opt/
COPY --from=cloud-tools /cloud-tools /usr/local/bin/
COPY --from=cloud-tools /etc/bash_completion.d /etc/bash_completion.d/
COPY --from=cloud-tools /root/.krew /root/.krew/
COPY --from=intellij-idea /root/.local /tmp/.local/
COPY yad-panel/service /etc/systemd/system

# User setup
RUN useradd --uid ${UID} --user-group --create-home --comment "Developer" --shell /bin/bash "${USER}" \
    && printf "${USER} ALL=(ALL) NOPASSWD: ALL\n" > "/etc/sudoers.d/${USER}" \
    && usermod --home /nonexistent ubuntu \
    && rm -rf /home/ubuntu \
	# IntelliJ plugins configuration
	&& mv "/tmp/.local" "/home/${USER}/" \
	&& chown --recursive "${USER}":"${USER}" "/home/${USER}/.local" \
    # Maven configuration \
    && mkdir -p "/home/${USER}/.m2/repository" \
    && chown --recursive "${USER}":"${USER}" "/home/${USER}/.m2" \
	# Git configuration
    && git config --global "init.defaultBranch" "main" \
	&& mv "/root/.gitconfig" "/home/${USER}/" \
	&& chown "${USER}":"${USER}" "/home/${USER}/.gitconfig" \
    # Docker configuration
    && usermod --append --groups "docker" "${USER}" \
    && docker completion bash > "/etc/bash_completion.d/docker" \
    # Kubectl Krew configuration \
    && mv "/root/.krew" "/home/${USER}/" \
    && chown --recursive "${USER}":"${USER}" "/home/${USER}/.krew" \
    && ln --symbolic --force "/home/${USER}/.krew/store/krew/$(ls /home/${USER}/.krew/store/krew)/krew" "/home/${USER}/.krew/bin/kubectl-krew" \
	# Dev Tools configuration
    && ln --symbolic /opt/intellij-idea/bin/idea /usr/local/bin/idea \
    && ln --symbolic /opt/keystore-explorer/kse.sh /usr/local/bin/kse \
    && ln --symbolic /opt/kitty/bin/kitty /usr/local/bin/kitty \
    && ln --symbolic /opt/postman/Postman /usr/local/bin/postman \
	# Create .ubuntu-dev-vm.version file
    && printf "${UBUNTU_DEV_VM_VERSION}\n" > "/etc/.ubuntu-dev-vm.version" \
    # Create projects directory
    && mkdir "/home/${USER}/projects" \
    && chown "${USER}":"${USER}" "/home/${USER}/projects" \
    # Source .environment in .bashrc
    && printf "\nif [ -f ~/.environment ]; then\n\
    . ~/.environment\n\
fi\n" >> "/home/${USER}/.bashrc" \
    # XDG_RUNTIME_DIR setup
    && mkdir "/opt/xdg-runtime-dir-${UID}" \
    # Permissions for /opt setup
    && chown --recursive "${USER}":"${USER}" "/opt" \
    && chmod go+w "/opt" \
	# Enable YAD Panel
	&& systemctl enable yad-panel.service \
    # Cleanup
    && rm -rf /tmp/* \
		/var/tmp/* \
		/usr/local/share/.cache/* \
		/var/log/* \
    && find /etc/systemd/system \
        /lib/systemd/system \
        -path '*.wants/*' \
        \( -name '*getty*' \
        -or -name '*apt-daily*' \
        -or -name '*systemd-timesyncd*' \
        -or -name '*systemd-logind*' \
        -or -name '*systemd-vconsole-setup*' \
        -or -name '*systemd-readahead*' \
        -or -name '*udev*' \) \
        -exec rm -v {} \;

COPY --chown=${USER}:${USER} --chmod=644 home-config /home/${USER}/
COPY --chown=${USER}:${USER} --chmod=644 kitty-config /home/${USER}/.config/kitty/
COPY docker-config /etc/docker/
COPY scripts yad-panel/yad-panel /usr/local/bin/
COPY yad-panel/config /etc/yad-panel

WORKDIR /home/${USER}
