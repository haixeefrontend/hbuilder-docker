FROM node:22-bookworm-slim AS node

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    binutils && \
    strip --strip-unneeded /usr/local/bin/node && \
    for f in LICENSE README.md docs man; do \
        rm -rf /usr/local/lib/node_modules/npm/$f; \
    done && \
    find /usr/local/lib/node_modules/npm -type f \( -name "*.so*" -o -name "*.node" \) -exec strip --strip-unneeded {} \;

FROM debian:bookworm-slim AS builder

ARG HBUILDERX_PATH=./.cache/hbuilderx

ARG SLIM=false

WORKDIR /opt
# 复制 HBuilderX
COPY ${HBUILDERX_PATH} /opt/hbuilderx

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget tar curl \
    binutils && \
    # 精简二进制文件和共享库
    strip --strip-unneeded /opt/hbuilderx/cli /opt/hbuilderx/HBuilderX && \
    find /opt/hbuilderx -type f -name "*.so*" -exec strip --strip-unneeded {} || true \; && \
    find /opt/hbuilderx -type f -name "*.node" -exec strip --strip-unneeded {} || true \; && \
    # NOTE: HBuilderX 依赖 Qt5Network 库，但在 Ubuntu 22.04 中该库需求的 libssl1.1 在系统中不存在
    # 因此需要手动安装 libssl1.1
    # 我们先用 wget 下载到 builder 镜像，等会从 builder 镜像复制到最终镜像中
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    strip --strip-unneeded /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 && \
    # 精简 HBuilderX
    # plugins 目录下只保留:
    #   about - 整个插件目录的 manifest
    #   uniapp-uts-v1 - UniApp UTS 编译器
    #   compile-less - less 编译器
    #   compile-node-sass - sass 编译器
    #   uniapp-cli - UniApp Vue 2 编译器
    #   uniapp-cli-vite - UniApp Vue 3 (Vite) 编译器
    if [ "${SLIM}" = "true" ]; then \
    # 先把文件夹名字改成临时的
    mv /opt/hbuilderx /opt/hbuilderx_full && \
    mkdir /opt/hbuilderx && \
    # 先复制基础文件
    for f in HBuilderX cli platforms package.json; \
        do cp -r /opt/hbuilderx_full/$f /opt/hbuilderx/; done && \
    cp -r /opt/hbuilderx_full/*.so* /opt/hbuilderx/ && \
    # 创建 plugins 目录
    mkdir -p /opt/hbuilderx/plugins && \
    # 复制需要保留的插件
    for f in about uniapp-uts-v1 compile-less compile-node-sass uniapp-cli uniapp-cli-vite; \
        do cp -r /opt/hbuilderx_full/plugins/$f /opt/hbuilderx/plugins/; done \
    fi;

# 基础镜像：Debian Bookworm Slim
FROM debian:bookworm-slim

# 设置时区为上海
ENV TZ=Asia/Shanghai
# 安装 su-exec 用于切换用户运行命令
ADD https://github.com/ncopa/su-exec/releases/download/v0.3/su-exec-static-v0.3-x86_64 /usr/local/bin/su-exec

# 从 builder 镜像复制 HBuilderX
COPY --from=builder /opt/hbuilderx /opt/hbuilderx

# 从 builder 镜像复制 libssl1.1
COPY --from=builder /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/

# 从 node 镜像复制 Node.js 运行环境
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
COPY --from=node /usr/local/bin/node /usr/local/bin/

# 设置环境变量
ENV PATH="/opt/hbuilderx:/opt/hbuilderx/bin:${PATH}"

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # 安装依赖（Qt5、ICU、glib、zlib 等）
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    libglib2.0-0 libgl1 \
    libharfbuzz0b libfreetype6 \
    libxrender1 libstdc++6 libgcc-s1 \
    libpcre2-16-0 zlib1g \
    libx11-6 libx11-xcb1 libxcb1 \
    libfontconfig1 \
    ca-certificates tini procps xz-utils && \
    # tini 用于作为 PID 1 进程，处理僵尸进程
    # 清理缓存
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/locale/* /usr/lib/locale/* /usr/share/i18n/* && \
    rm -rf /usr/share/fonts/* /etc/fonts/* && \
    rm -rf /tmp/* && \
    # 设置 su-exec 可执行权限
    chmod +x /usr/local/bin/su-exec && \
    # 创建软链接确保 Qt5 能找到 libssl 和 libcrypto
    ln -s /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libssl.so && \
    ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so && \
    ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    # 设置 docker-entrypoint.sh 可执行权限
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    # 创建用户 node
    useradd -m node

CMD []
