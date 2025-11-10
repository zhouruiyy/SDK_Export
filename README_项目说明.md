# Agora SDK 增强处理工具

## 项目概述

这是一个用于自动化处理和增强 Agora SDK 的工具集，支持 **Linux** 和 **Mac** 两个平台。

### 主要功能

1. **下载原始 SDK** - 从 CI 系统下载原始 SDK 包
2. **添加额外库文件** - 集成 RTM SDK 和其他必需的库
3. **添加头文件** (仅 Linux) - 添加 RTM SDK 头文件和 VAD 头文件
4. **删除特定文件** (仅 Linux) - 移除不需要的扩展库
5. **转换库格式** (仅 Mac) - 将 xcframework 转换为 dylib
6. **重命名和打包** - 标准化文件名并重新打包
7. **生成校验文件** - 创建 MD5 校验和
8. **上传到 CDN** - 自动上传到指定的 CDN

---

## 支持的平台

### Linux (x86_64)

**原始 SDK 格式：**
- 文件类型：`.zip`
- 库文件格式：`.so`
- 包含：SDK 库、头文件、示例代码

**处理内容：**
- ✅ 添加 RTM SDK `.so` 库文件
- ✅ 添加 RTM SDK 头文件目录
- ✅ 添加 VAD 头文件
- ✅ 删除 3 个特定的 `.so` 文件
- ✅ 重命名 SDK 目录
- ✅ 重命名包文件

**文件名格式：**
```
输入：Agora_Native_SDK_for_Linux_x64_rel.v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678_external.zip
输出：agora_rtc_sdk_x86_64-linux-gnu-v4.4.32.150_26715_SERVER_20251030_1807_953678.zip
```

### Mac (arm64 + x86_64)

**原始 SDK 格式：**
- 文件类型：`.zip`
- 库文件格式：`.xcframework`
- 包含：XCFramework 格式的库

**处理内容：**
- ✅ 转换 xcframework 为 dylib
- ✅ 添加 RTM SDK `.dylib` 库文件
- ❌ 不需要头文件
- ❌ 不删除文件
- ✅ 重命名包文件

**文件名格式：**
```
输入：Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip
输出：agora_sdk_mac_v4.4.30_25321_FULL_20250820_1052_846534.zip
```

---

## 项目结构

```
/Volumes/ZR/Agora/Jenkins/
├── scripts/                           # 脚本目录
│   ├── process_sdk.sh                # Linux SDK 处理脚本
│   ├── package_sdk.sh                # Linux SDK 打包脚本
│   ├── local_test.sh                 # Linux 本地测试脚本
│   ├── process_sdk_mac.sh            # Mac SDK 处理脚本
│   ├── package_sdk_mac.sh            # Mac SDK 打包脚本
│   ├── local_test_mac.sh             # Mac 本地测试脚本
│   ├── framework_to_dylib.py         # xcframework 转 dylib 工具
│   └── upload_to_cdn.sh              # CDN 上传脚本
├── extra_resources/                   # 额外资源目录
│   ├── libs/                         # Linux .so 库文件
│   │   ├── libagora_rtm_sdk_c.so
│   │   ├── libagora_rtm_sdk.so
│   │   └── libagora_uap_aed.so
│   ├── libs_mac/                     # Mac .dylib 库文件
│   │   ├── libagora_rtm_sdk_c.dylib
│   │   ├── libAgoraRtmKit.dylib
│   │   └── libuap_aed.dylib
│   ├── agora_rtm_sdk_c/              # RTM SDK 头文件目录
│   │   └── *.h
│   ├── headers/                      # 其他额外头文件
│   │   └── vad.h
│   └── README.md                     # 资源说明文档
├── Jenkinsfile                        # Jenkins Pipeline 配置
├── test_filename.sh                   # Linux 文件名测试
├── test_filename_mac.sh               # Mac 文件名测试
├── 测试命令.txt                        # Linux 测试命令速查
├── 测试命令_Mac.txt                    # Mac 测试命令速查
├── 修改说明.md                         # Linux 修改说明
├── 修改说明_Mac.md                     # Mac 修改说明
├── README_项目说明.md                  # 本文档
└── QUICKSTART.md                      # 快速开始指南
```

---

## 快速开始

### 准备工作

#### 1. 准备 Linux RTM 库和头文件

```bash
cd extra_resources

# 复制 Linux .so 库文件
cp /path/to/libagora_rtm_sdk_c.so libs/
cp /path/to/libagora_rtm_sdk.so libs/
cp /path/to/libagora_uap_aed.so libs/

# 复制 RTM SDK 头文件目录
cp -r /path/to/agora_rtm_sdk_c ./

# 复制 VAD 头文件
cp /path/to/vad.h headers/
```

#### 2. 准备 Mac RTM 库文件

```bash
cd extra_resources

# 创建并复制 Mac .dylib 文件
mkdir -p libs_mac
cp /path/to/libagora_rtm_sdk_c.dylib libs_mac/
cp /path/to/libAgoraRtmKit.dylib libs_mac/
cp /path/to/libuap_aed.dylib libs_mac/
```

### Linux SDK 测试

```bash
cd /Volumes/ZR/Agora/Jenkins

# 完整测试
./scripts/local_test.sh \
  "http://10.80.1.174:8090/agora_sdk/4.4.32.150/official_build/2025-10-30/linux/server/Agora_Native_SDK_for_Linux_x64_rel.v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678_external.zip" \
  "4.4.32.150"
```

**详细说明：** 见 `测试命令.txt`

### Mac SDK 测试

```bash
cd /Volumes/ZR/Agora/Jenkins

# 完整测试
./scripts/local_test_mac.sh \
  "http://10.80.1.174:8090/agora_sdk/4.4.30/nightly_build/2025-08-20/mac/full/Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip" \
  "4.4.30"
```

**详细说明：** 见 `测试命令_Mac.txt`

---

## 脚本说明

### Linux 脚本

#### `scripts/process_sdk.sh`

**功能：** 处理 Linux SDK

**处理步骤：**
1. 自动查找 `sdk` 目录
2. 删除 3 个指定的 `.so` 文件
3. 添加 RTM SDK `.so` 库文件
4. 添加 RTM SDK 头文件目录
5. 添加 VAD 头文件到 `include/c/api2/`
6. 重命名 `sdk` → `agora_sdk`

#### `scripts/package_sdk.sh`

**功能：** 打包 Linux SDK

**处理步骤：**
1. 清理隐藏文件
2. 生成新文件名（去掉 `ubuntu` 版本号和 `_external/_internal` 后缀）
3. 压缩 `agora_sdk` 目录
4. 生成 MD5 校验文件

#### `scripts/local_test.sh`

**功能：** Linux 本地完整测试

**包含：** 下载、解压、处理、打包、验证、报告生成

### Mac 脚本

#### `scripts/process_sdk_mac.sh`

**功能：** 处理 Mac SDK

**处理步骤：**
1. 查找 `libs` 目录（包含 xcframework）
2. 调用 Python 脚本转换 xcframework → dylib
3. 添加 RTM SDK `.dylib` 库文件
4. 创建 `agora_sdk` 目录

#### `scripts/package_sdk_mac.sh`

**功能：** 打包 Mac SDK

**处理步骤：**
1. 清理隐藏文件
2. 生成新文件名（提取 `v` 后面的所有字符）
3. 压缩 `agora_sdk` 目录
4. 生成 MD5 校验文件

#### `scripts/local_test_mac.sh`

**功能：** Mac 本地完整测试

**包含：** 下载、解压、转换、处理、打包、验证、报告生成

#### `scripts/framework_to_dylib.py`

**功能：** xcframework 到 dylib 转换工具

**特点：**
- 支持 `macos-arm64_x86_64` 架构
- 自动更新 `@rpath` 依赖
- 批量处理多个 xcframework

---

## 文件名规则

### Linux

**提取规则：**
1. 提取 `v` 后面到 `_external` 或 `_internal` 之间的内容
2. 移除 `_ubuntu[0-9]+_[0-9]+_[0-9]+` 版本号
3. 添加前缀 `agora_rtc_sdk_x86_64-linux-gnu-`

**示例：**
```
输入：Agora_Native_SDK_for_Linux_x64_rel.v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678_external.zip

提取：v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678
移除：ubuntu14_04_5
结果：v4.4.32.150_26715_SERVER_20251030_1807_953678

输出：agora_rtc_sdk_x86_64-linux-gnu-v4.4.32.150_26715_SERVER_20251030_1807_953678.zip
```

### Mac

**提取规则：**
1. 提取 `v` 后面到 `.zip` 之间的所有字符
2. 添加前缀 `agora_sdk_mac_`

**示例：**
```
输入：Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip

提取：v4.4.30_25321_FULL_20250820_1052_846534

输出：agora_sdk_mac_v4.4.30_25321_FULL_20250820_1052_846534.zip
```

---

## 测试工具

### 文件名测试

**Linux:**
```bash
bash test_filename.sh
```

**Mac:**
```bash
bash test_filename_mac.sh
```

### 完整流程测试

**Linux:**
```bash
bash scripts/local_test.sh "<SDK_URL>" "<VERSION>"
```

**Mac:**
```bash
bash scripts/local_test_mac.sh "<SDK_URL>" "<VERSION>"
```

---

## Jenkins 集成

### Pipeline 配置

编辑 `Jenkinsfile` 配置 Jenkins Pipeline：

```groovy
parameters {
    string(name: 'SDK_URL', description: 'SDK 下载链接')
    string(name: 'SDK_VERSION', description: 'SDK 版本号')
    choice(name: 'PLATFORM', choices: ['linux', 'mac'], description: '平台')
}
```

### 使用步骤

1. 在 Jenkins 中创建新的 Pipeline 项目
2. 配置 SCM 指向此仓库
3. 指定 `Jenkinsfile` 路径
4. 配置参数化构建
5. 运行构建

---

## 平台对比

| 特性 | Linux | Mac |
|------|-------|-----|
| **库文件格式** | `.so` | `.dylib` |
| **原始格式** | `.so` | `.xcframework` |
| **需要转换** | ❌ 否 | ✅ 是 (xcframework→dylib) |
| **需要头文件** | ✅ 是 (RTM + VAD) | ❌ 否 |
| **删除文件** | ✅ 3个 .so | ❌ 否 |
| **文件名处理** | 复杂（去除 ubuntu 和后缀） | 简单（提取 v 后面） |
| **工具依赖** | bash, zip, curl, sed | bash, zip, curl, sed, python3 |

---

## 常见问题

### Q: 如何验证生成的 SDK？

**Linux:**
```bash
# 查看文件名
ls -lh build_test/agora_rtc_sdk_*.zip

# 检查内容
unzip -l build_test/agora_rtc_sdk_*.zip | grep -E '(rtm|vad|agora_sdk)'

# 验证已删除的文件
unzip -l build_test/agora_rtc_sdk_*.zip | grep -E '(mcc_ysd|stt_ag|stt_ms)' || echo "✓ 已删除"
```

**Mac:**
```bash
# 查看文件名
ls -lh build_test_mac/agora_sdk_mac_*.zip

# 检查内容
unzip -l build_test_mac/agora_sdk_mac_*.zip | grep "\.dylib"

# 验证 RTM 库
unzip -l build_test_mac/agora_sdk_mac_*.zip | grep -E '(rtm|uap_aed)'
```

### Q: 脚本执行失败怎么办？

1. **检查日志输出** - 脚本会打印详细的执行步骤
2. **检查文件权限** - 确保脚本有执行权限：`chmod +x scripts/*.sh`
3. **验证依赖** - 确保 `curl`, `unzip`, `zip`, `python3` 已安装
4. **清理重试** - 删除 `build_test` 或 `build_test_mac` 目录后重试

### Q: 文件名格式不对？

运行文件名测试脚本：
- Linux: `bash test_filename.sh`
- Mac: `bash test_filename_mac.sh`

如果测试失败，查看对应的修改说明文档。

### Q: 如何添加新的平台支持？

1. 创建新的处理脚本 `scripts/process_sdk_<平台>.sh`
2. 创建新的打包脚本 `scripts/package_sdk_<平台>.sh`
3. 创建测试脚本 `scripts/local_test_<平台>.sh`
4. 在 `extra_resources/` 添加平台专用目录
5. 更新 `Jenkinsfile` 添加新平台选项

---

## 相关文档

- **[QUICKSTART.md](QUICKSTART.md)** - 快速开始指南
- **[修改说明.md](修改说明.md)** - Linux 版本的详细修改说明
- **[修改说明_Mac.md](修改说明_Mac.md)** - Mac 版本的详细修改说明
- **[extra_resources/README.md](extra_resources/README.md)** - 额外资源说明
- **[测试命令.txt](测试命令.txt)** - Linux 测试命令速查
- **[测试命令_Mac.txt](测试命令_Mac.txt)** - Mac 测试命令速查

---

## 版本历史

### 2025-11-10 v1.0
- ✅ Linux SDK 处理完成
- ✅ Mac SDK 处理完成
- ✅ 文件名规范化
- ✅ 自动化测试
- ✅ Jenkins Pipeline 集成
- ✅ 完整文档

---

## 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/new-feature`)
3. 提交更改 (`git commit -am 'Add new feature'`)
4. 推送到分支 (`git push origin feature/new-feature`)
5. 创建 Pull Request

---

## 许可证

Copyright © 2025 Agora

---

**作者：** Agora DevOps Team  
**最后更新：** 2025-11-10  
**文档版本：** 1.0

