---
type: capability
name: face-detect
description: macOS 本地批量人脸检测/数人脸工具。基于系统 Vision 框架（Swift，零第三方依赖、纯本地、图片不上传），对目录下所有图片检测人脸数量，输出『文件名<TAB>人脸数』TSV。当用户要统计/检测照片里有几张人脸、按人脸数给照片分组、区分有人脸与无人脸（风景/文档/截图）、单人照与多人合照，或为照片整理(photo-organize)做预筛选时使用。只数人脸数量，不识别人物身份。
compatibility: 仅在 macOS(Darwin) 实测可用；Windows/Linux 未适配。执行前先判平台(uname -s 返回 Darwin)，非 macOS 停止并告知需另行适配、不硬跑；本机依赖 macOS + Swift(swiftc) + Vision 框架，无需第三方库
---

# Face Detect（本地批量人脸检测）

用 macOS 原生 Vision 框架对一个目录下的所有图片批量检测人脸数量，输出 TSV 格式（文件名<TAB>人脸数）。纯本地运行，图片不上传。

## 平台适用（执行前先读）
- 本技能当前**仅在 macOS（Darwin）实测可用**，命令、路径与系统原生能力均按 Mac。
- 动手前先判平台：`uname -s` 返回 `Darwin` 才走本技能流程；**Windows/Linux 未适配，遇到就停下告知用户"需先做该平台适配"，不要用想当然的等价命令硬跑**。
- 以后补齐 Windows 后也必须保留"先判平台 → 按平台分流"的结构：mac/Windows 的命令与路径分开写、各自标注是否已验证。

## 适用场景

- 照片整理时快速区分：有人脸 vs 无人脸（风景/文档/截图）
- 区分单人照 vs 多人合照（人脸数=1 vs >=2）
- 为联系表分类提供预筛选，减少逐张人工判断的量

## 能力边界

- **只能检测人脸数量**，不能识别人物身份（是谁）
- 侧脸、背影、戴口罩、远距离人脸可能漏检（无人脸≠真的没人）
- 支持格式：jpg/jpeg/png/heic/gif/bmp/tiff
- 纯本地运行，图片不上传任何外部服务

## 按需加载索引

| 你要做什么 | 读这篇 |
|---|---|
| 编译 swift、跑检测、awk 分布/筛选/批量、与联系表配合工作流、性能与注意 | [references/usage.md](references/usage.md) |
