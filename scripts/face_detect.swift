// face_detect —— macOS 本地批量人脸计数（Vision 框架，零第三方依赖，纯本地不上传）
// 用法：face_detect <directory>
// 输出：文件名<TAB>人脸数（TSV，每行一张图；无法解码的图记 0）
// 编译：swiftc -O face_detect.swift -o /tmp/face_detect -framework Vision -framework AppKit
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
