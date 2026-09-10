---
name: face-detect
description: "macOS 本地批量人脸检测工具。基于系统 Vision 框架，对目录下所有图片检测人脸数量，输出『文件名<TAB>人脸数』。用于照片整理时快速区分有人脸/无人脸、单人/多人合照。零依赖、纯本地、不上传图片。"
compatibility: "仅在 macOS(Darwin) 实测可用；Windows/Linux 未适配。执行前先判平台(uname -s 返回 Darwin)，非 macOS 停止并告知需另行适配、不硬跑；将来补齐 Windows 后仍按平台分流并分别标注验证状态。本机依赖：macOS + Swift(swiftc) + Vision 框架，无需第三方库。"
---

# Face Detect（本地批量人脸检测）

## 平台适用（执行前先读）
- 本技能当前**仅在 macOS（Darwin）实测可用**，命令、路径、代理端口与系统原生能力均按 Mac。
- 动手前先判平台：`uname -s` 返回 `Darwin` 才走本技能流程；**Windows/Linux 未适配，遇到就停下告知用户“需先做该平台适配”，不要用想当然的等价命令硬跑**。
- 以后补齐 Windows 后也必须保留“先判平台 → 按平台分流”的结构：mac/Windows 的命令与路径分开写、各自标注是否已验证。

用 macOS 原生 Vision 框架对一个目录下的所有图片批量检测人脸数量，输出 TSV 格式（文件名<TAB>人脸数）。

## 适用场景

- 照片整理时快速区分：有人脸 vs 无人脸（风景/文档/截图）
- 区分单人照 vs 多人合照（人脸数=1 vs >=2）
- 为联系表分类提供预筛选，减少逐张人工判断的量

## 能力边界

- **只能检测人脸数量**，不能识别人物身份（是谁）
- 侧脸、背影、戴口罩、远距离人脸可能漏检（无人脸≠真的没人）
- 支持格式：jpg/jpeg/png/heic/gif/bmp/tiff
- 纯本地运行，图片不上传任何外部服务

## 安装（编译一次即可）

```bash
# 编译到 /tmp/face_detect（也可放到 ~/bin/）
cat > /tmp/face_detect.swift << 'SWIFTEOF'
import Foundation
import Vision
import AppKit

if CommandLine.arguments.count < 2 {
    fputs("Usage: face_detect <directory>\n", stderr)
    exit(1)
}
let dir = CommandLine.arguments[1]
let fm = FileManager.default
guard let files = try? fm.contentsOfDirectory(atPath: dir) else {
    fputs("Cannot read directory\n", stderr)
    exit(1)
}
let exts: Set<String> = ["jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff"]
for f in files.sorted() {
    let ext = (f as NSString).pathExtension.lowercased()
    guard exts.contains(ext) else { continue }
    let path = (dir as NSString).appendingPathComponent(f)
    guard let img = NSImage(contentsOfFile: path),
          let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("\(f)\t0")
        continue
    }
    let req = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: cg, options: [:])
    try? handler.perform([req])
    let count = req.results?.count ?? 0
    print("\(f)\t\(count)")
}
SWIFTEOF
swiftc -O /tmp/face_detect.swift -o /tmp/face_detect -framework Vision -framework AppKit
```

编译成功后 `/tmp/face_detect` 可执行文件可重复使用（重启后 /tmp 可能被清理，需重新编译）。

## 使用方法

### 基本用法

```bash
# 检测单个目录，输出到文件
/tmp/face_detect /path/to/photos > /tmp/face_result.txt 2>/dev/null

# 输出格式：文件名<TAB>人脸数
# IMG_001.JPG	3
# IMG_002.JPG	0
# IMG_003.JPG	1
```

### 统计人脸数分布

```bash
awk -F'\t' '{print $2}' /tmp/face_result.txt | sort -n | uniq -c | sort -rn
```

### 筛选分类

```bash
# 无人脸（风景/文档/截图候选）
awk -F'\t' '$2==0 {print $1}' /tmp/face_result.txt > /tmp/noface.txt

# 单人照（需进一步判断是谁）
awk -F'\t' '$2==1 {print $1}' /tmp/face_result.txt > /tmp/single.txt

# 多人合照（>=2人，可直接归合照）
awk -F'\t' '$2>=2 {print $1}' /tmp/face_result.txt > /tmp/group.txt
```

### 批量处理多个目录

```bash
for d in /path/to/photos/*/; do
  name=$(basename "$d")
  /tmp/face_detect "$d" > "/tmp/face_${name}.txt" 2>/dev/null
  echo "$name: $(wc -l < /tmp/face_${name}.txt) 张, 有人脸 $(awk -F'\t' '$2>0' /tmp/face_${name}.txt | wc -l | tr -d ' ')"
done
```

## 性能参考

- 约 1000 张图片 / 分钟（取决于图片分辨率和 CPU）
- 1500 张约需 2-3 分钟，建议后台运行

## 与联系表配合的工作流

1. 人脸检测 → 按人脸数分组（0/1/>=2）
2. 无人脸组 → 生成联系表，人工区分风景/画作/文档/背影
3. 单人组 → 生成联系表，人工判断人物身份（爸爸/妈妈/孩子/老人）
4. 多人组 → 通常直接归"合照"，抽样联系表确认
5. 按分类结果移动文件到目标目录

## 注意事项

- `/tmp/face_detect` 重启后可能丢失，需重新编译（编译很快，约 5 秒）
- HEIC 格式需要 macOS 10.13+ 支持
- 人脸检测结果是辅助筛选，最终分类仍需人工通过联系表确认
- 大目录（>5000张）建议分批处理
