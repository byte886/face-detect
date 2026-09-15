# Face Detect 用法（编译 / 跑数 / 筛选 / 与联系表配合）

## 安装（编译一次即可）

源码在技能脚本 `scripts/face_detect.swift`，编译到 `/tmp/face_detect` 复用（也可改输出到 `~/bin/`）：

```bash
# $SKILL_DIR 为本技能目录（双机家目录名不同，一律用 $HOME 派生、不写死用户名）
SKILL_DIR="$HOME/Doubao/skills/face-detect"
swiftc -O "$SKILL_DIR/scripts/face_detect.swift" -o /tmp/face_detect -framework Vision -framework AppKit
```

编译成功后 `/tmp/face_detect` 可重复使用（重启后 /tmp 可能被清理，重跑上面一行即可，约 5 秒）。

## 基本用法

```bash
# 检测单个目录，输出到文件
/tmp/face_detect /path/to/photos > /tmp/face_result.txt 2>/dev/null

# 输出格式：文件名<TAB>人脸数
# IMG_001.JPG	3
# IMG_002.JPG	0
# IMG_003.JPG	1
```

## 统计人脸数分布

```bash
awk -F'\t' '{print $2}' /tmp/face_result.txt | sort -n | uniq -c | sort -rn
```

## 筛选分类

```bash
# 无人脸（风景/文档/截图候选）
awk -F'\t' '$2==0 {print $1}' /tmp/face_result.txt > /tmp/noface.txt

# 单人照（需进一步判断是谁）
awk -F'\t' '$2==1 {print $1}' /tmp/face_result.txt > /tmp/single.txt

# 多人合照（>=2人，可直接归合照）
awk -F'\t' '$2>=2 {print $1}' /tmp/face_result.txt > /tmp/group.txt
```

## 批量处理多个目录

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
