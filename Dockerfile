FROM node:22-bookworm-slim AS node

# 基础镜像：Ubuntu 22.04（兼容性最好）
FROM ubuntu:22.04

# 从 node 镜像复制 Node.js 运行环境
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装依赖（Qt5、ICU、glib、zlib 等）
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
    # tini 用于作为 PID 1 进程，处理僵尸进程
    tini && \
    # 清理缓存
    rm -rf /var/lib/apt/lists/* && \
    apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /tmp/*

ARG HBUILDERX_URL

# 下载 HBuilderX
WORKDIR /opt
RUN wget ${HBUILDERX_URL} -O hbuilderx.tar.gz && \
    mkdir /opt/hbuilderx && \
    tar -xzf hbuilderx.tar.gz -C /opt/hbuilderx --strip-components=1 && \
    rm hbuilderx.tar.gz

# 创建用户 node
RUN useradd -m -s /usr/bin/fish node

# 设置环境变量
ENV PATH="/opt/hbuilderx:/opt/hbuilderx/bin:${PATH}"

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

CMD []
