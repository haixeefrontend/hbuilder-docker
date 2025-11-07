FROM node:22-bookworm-slim AS node

FROM ubuntu:22.04 AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget tar curl \
    binutils

ARG HBUILDERX_PATH=./.cache/hbuilderx

ARG SLIM=false

# 复制 HBuilderX
WORKDIR /opt
COPY ${HBUILDERX_PATH} /opt/hbuilderx
RUN strip --strip-unneeded /opt/hbuilderx/cli /opt/hbuilderx/HBuilderX && \
    find /opt/hbuilderx -type f -name "*.so*" -exec strip --strip-unneeded {} || true \; && \
    # NOTE: HBuilderX 依赖 Qt5Network 库，但在 Ubuntu 22.04 中该库需求的 libssl1.1 在系统中不存在
    # 因此需要手动安装 libssl1.1
    # 我们先用 wget 下载到 builder 镜像，等会从 builder 镜像复制到最终镜像中
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# 精简 HBuilderX
# plugins 目录下只保留 about compile-dart-sass compile-less compile-node-sass uniapp-cli uniapp-cli-vite
RUN if [ ${SLIM} == "true" ]; then \
    # 先把文件夹名字改成临时的
    mv /opt/hbuilderx /opt/hbuilderx_full && \
    mkdir /opt/hbuilderx && \
    # 先复制基础文件
    cp -r /opt/hbuilderx_full/{HBuilderX,cli,platforms,*.so*} /opt/hbuilderx/ && \
    # 创建 plugins 目录
    mkdir -p /opt/hbuilderx/plugins && \
    # 复制需要保留的插件
    cp -r /opt/hbuilderx_full/plugins/{about,compile-dart-sass,compile-less,compile-node-sass,uniapp-cli,uniapp-cli-vite} /opt/hbuilderx/plugins/ ;\
    fi

# 基础镜像：Ubuntu 22.04（兼容性最好）
FROM ubuntu:22.04

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装依赖（Qt5、ICU、glib、zlib 等）
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libglib2.0-0 libx11-6 libgl1-mesa-glx \
    libharfbuzz0b libfreetype6 \
    libxrender1 libstdc++6 libgcc-s1 \
    libpcre2-16-0 libicu70 zlib1g \
    ca-certificates \
    # tini 用于作为 PID 1 进程，处理僵尸进程
    tini && \
    # 清理缓存
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /tmp/*

# 从 builder 镜像复制 HBuilderX
COPY --from=builder /opt/hbuilderx /opt/hbuilderx

# 从 builder 镜像复制 libssl1.1
COPY --from=builder /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/
# 创建软链接确保 Qt5 能找到 libssl 和 libcrypto
RUN ln -s /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libssl.so && \
    ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so

# 从 node 镜像复制 Node.js 运行环境
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /opt/yarn-* /opt/
COPY --from=node /usr/local/bin/node /usr/local/bin/
RUN ln -s /usr/local/lib/corepack/dist/corepack.js /usr/local/bin/corepack && \
    ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -s /opt/yarn-*/bin/yarn /usr/local/bin/yarn && \
    ln -s /opt/yarn-*/bin/yarnpkg /usr/local/bin/yarnpkg


# 设置环境变量
ENV PATH="/opt/hbuilderx:/opt/hbuilderx/bin:${PATH}"

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

# 创建用户 node
RUN useradd -m node
USER node

CMD []
