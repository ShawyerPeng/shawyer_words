# 压缩包导入 Apple 元数据过滤设计

## 目标

修复词典压缩包导入时误报“包含多个 MDX 文件”的问题。

## 根因

当前扫描器会把所有以 `.mdx` 结尾的文件都当成主词典候选。macOS 生成的隐藏元数据文件，例如 `__MACOSX/.../._main.mdx` 或 `._main.mdx`，也会被计入，导致本来只有一个主词典的 zip 被误判为多个 `mdx`。

## 方案

- 在 `DictionaryPackageScanner` 中忽略 Apple metadata 文件和目录：
  - `__MACOSX/`
  - 任意路径段里的 `._*`
  - `.DS_Store`
- 保持真正多 `mdx` 压缩包的现有报错逻辑不变。
- 增加 importer 测试，覆盖 zip 内含 `__MACOSX/._main.mdx` 的场景。

## 改动范围

- `lib/features/dictionary/data/dictionary_package_scanner.dart`
- `test/features/dictionary/data/dictionary_package_importer_test.dart`

## 验证

- 带 Apple metadata 的 zip 能正常导入。
- 不影响现有单 `mdx`、单文件和无 `mdx` 的测试行为。
