# 基础镜像：Ubuntu 22.04（兼容性最好）
FROM ubuntu:22.04

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
    fish wget tar && \
    rm -rf /var/lib/apt/lists/*

# 下载 HBuilderX
WORKDIR /opt
RUN wget https://download1.dcloud.net.cn/download/HBuilderX.4.84.2025110307.linux_x64.full.tar.gz -O hbuilderx.tar.gz && \
    mkdir /opt/hbuilderx && \
    tar -xzf hbuilderx.tar.gz -C /opt/hbuilderx --strip-components=1 && \
    rm hbuilderx.tar.gz

# 设置环境变量
ENV PATH="/opt/hbuilderx:/opt/hbuilderx/bin:${PATH}"

# 默认启动 shell
CMD ["fish"]
