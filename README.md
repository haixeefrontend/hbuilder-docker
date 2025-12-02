# HBuilderX Linux Docker Image

这个仓库包含了用于构建 HBuilderX 的 Linux 版本 Docker 镜像的配置文件和脚本。

此外这个仓库包含了 GitHub Actions 工作流配置文件，用于在云端构建 Docker 镜像并发布到 GitHub Release。

## 使用说明

使用以下命令构建 Docker 镜像：

```bash
docker build . -t hbuilderx:latest
```

构建 slim 版本的镜像，这个版本仅保留基础的编译到 app 包所需的工具：

```bash
docker build --build-arg SLIM=true . -t hbuilderx:slim
```

构建完成后，可以使用 docker run 命令运行容器，并将项目目录挂载到容器中：

```bash
docker run --rm -it \
    -v /path/to/your/project:/project \
    -w /project \
    hbuilderx:latest
```

当容器输出 `✅ HBuilderX started.`，表明 HBuilderX 在后台启动。
此时可以运行 HBuilderX 编译命令，如导出 app 发布资源（需要登录）

```bash
cli user login --username "<email>" --password "<password>"
cli project open --path "$(pwd)"
cli publish --platform APP --type appResource --project project
```

更多命令请参考 [HBuilderX CLI 文档](https://hx.dcloud.net.cn/cli/README)。

## License

本项目采用 AGPL-3.0 许可证，详情请参阅 [LICENSE](./LICENSE) 文件。
