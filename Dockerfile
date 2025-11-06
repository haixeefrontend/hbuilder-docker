# 基础镜像：Ubuntu 22.04（兼容性最好）
FROM ubuntu:22.04

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装依赖（Qt5、ICU、glib、zlib 等）
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libglib2.0-0 libglib2.0-bin libx11-6 libx11-xcb1 libgl1-mesa-glx \
    libharfbuzz0b libfreetype6 fontconfig \
    libxrender1 libxi6 libxext6 libxfixes3 libxcb1 \
    libxcb-keysyms1 libxcb-render0 libxcb-shape0 libxcb-shm0 \
    libxcb-xfixes0 libxcb-icccm4 libxcb-image0 libxcb-sync1 \
    libxcb-randr0 libxcb-render-util0 \
    libpcre2-16-0 libdouble-conversion3 libicu70 \
    zlib1g libstdc++6 libgcc-s1 libzstd1 libcairo2 \
    libxkbcommon0 libxkbcommon-x11-0 libasound2 \
    libmtdev1 libinput10 libquazip5-1 \
    fish wget tar curl \
    # n 需要这些依赖
    git make \
    # tini 用于作为 PID 1 进程，处理僵尸进程
    tini && \
    rm -rf /var/lib/apt/lists/*

ARG HBUILDERX_URL

# 下载 HBuilderX
WORKDIR /opt
RUN wget ${HBUILDERX_URL} -O hbuilderx.tar.gz && \
    mkdir /opt/hbuilderx && \
    tar -xzf hbuilderx.tar.gz -C /opt/hbuilderx --strip-components=1 && \
    rm hbuilderx.tar.gz

# 创建用户 node
RUN useradd -m -s /usr/bin/fish node
ENV N_PREFIX=/home/node/.n

# 以用户 node 安装 nodejs 22
USER node
RUN curl -L https://bit.ly/n-install | bash -s -- -y 22 && \
    mkdir -p $HOME/.n && \
    ${N_PREFIX}/bin/n 22

# 设置环境变量
ENV PATH="${N_PREFIX}/bin:/opt/hbuilderx:/opt/hbuilderx/bin:${PATH}"

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

CMD []
