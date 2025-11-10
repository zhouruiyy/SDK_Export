# 额外资源目录

此目录用于存放需要添加到 Agora SDK 中的 RTM SDK 库文件、头文件和其他额外资源。

支持 **Linux** 和 **Mac** 两个平台。

## 目录结构

```
extra_resources/
├── libs/                          # Linux 平台：RTM SDK 的 .so 库文件
│   ├── libagora_rtm_sdk_c.so     # RTM C SDK 库
│   ├── libagora_rtm_sdk.so       # RTM SDK 库
│   └── libagora_uap_aed.so       # UAP AED 库
├── libs_mac/                      # Mac 平台：RTM SDK 的 .dylib 库文件
│   ├── libagora_rtm_sdk_c.dylib  # RTM C SDK 库
│   ├── libAgoraRtmKit.dylib      # RTM SDK 库
│   └── libuap_aed.dylib          # UAP AED 库
├── agora_rtm_sdk_c/              # Linux 平台：RTM SDK 的 C 头文件目录
│   ├── *.h                       # RTM 相关的头文件
│   └── ...
├── headers/                      # Linux 平台：其他额外头文件
│   └── vad.h                     # VAD 头文件
└── README.md                     # 本文件
```

## 文件放置规则

### 1. RTM SDK 库文件 → `libs/` 目录

将以下三个 .so 文件放到 `libs/` 目录：

```bash
extra_resources/libs/
├── libagora_rtm_sdk_c.so    # 必需
├── libagora_rtm_sdk.so      # 必需
└── libagora_uap_aed.so      # 必需
```

这些文件会被添加到 SDK 的 `sdk/` 目录（最终为 `agora_sdk/`）。

### 2. RTM SDK 头文件目录 → `agora_rtm_sdk_c/` 目录

将整个 RTM C SDK 头文件目录放在这里：

```bash
extra_resources/agora_rtm_sdk_c/
├── rtm_common.h
├── rtm_client.h
├── rtm_stream.h
└── ... (其他 RTM 头文件)
```

这个完整的目录会被复制到 SDK 的 `sdk/` 目录（最终为 `agora_sdk/agora_rtm_sdk_c/`）。

### 3. VAD 头文件 → `headers/` 目录

将 `vad.h` 放到 `headers/` 目录：

```bash
extra_resources/headers/
└── vad.h
```

这个文件会被添加到 SDK 的 `include/c/api2/` 目录。

### 4. 其他额外头文件（可选）→ `headers/` 目录

如果有其他头文件需要添加到 SDK 根目录，也放在 `headers/` 目录。

## 处理流程

脚本会按照以下顺序处理：

1. **添加库文件** → `sdk/` 目录
   - `libagora_rtm_sdk_c.so`
   - `libagora_rtm_sdk.so`
   - `libagora_uap_aed.so`

2. **添加 RTM 头文件目录** → `sdk/` 目录
   - 整个 `agora_rtm_sdk_c/` 目录

3. **添加 VAD 头文件** → `include/c/api2/` 目录
   - `vad.h`

4. **重命名目录** 
   - `sdk/` → `agora_sdk/`

5. **打包压缩**
   - 清理隐藏文件（.DS_Store 等）
   - 压缩 `agora_sdk/` 目录
   - 重命名为原 SDK 文件名

## 快速开始

### 准备文件

```bash
cd extra_resources

# 1. 复制 RTM SDK 的 .so 库文件
cp /path/to/libagora_rtm_sdk_c.so libs/
cp /path/to/libagora_rtm_sdk.so libs/
cp /path/to/libagora_uap_aed.so libs/

# 2. 复制 RTM SDK 头文件目录（整个目录）
cp -r /path/to/agora_rtm_sdk_c ./

# 3. 复制 vad.h 头文件
cp /path/to/vad.h headers/

# 4. 验证目录结构
ls -R .
```

### 验证文件

```bash
# 检查库文件
ls -lh libs/*.so

# 检查 RTM 头文件目录
ls -lh agora_rtm_sdk_c/

# 检查 VAD 头文件
ls -lh headers/vad.h
```

### 本地测试

```bash
cd ..
./scripts/local_test.sh "http://10.80.1.174:8090/.../SDK.zip" "4.4.32"
```

## 最终 SDK 结构

处理后的 SDK 目录结构：

```
agora_sdk/                              # 重命名后的 sdk 目录
├── libagora_rtm_sdk_c.so              # ✅ 新增
├── libagora_rtm_sdk.so                # ✅ 新增
├── libagora_uap_aed.so                # ✅ 新增
├── agora_rtm_sdk_c/                   # ✅ 新增目录
│   ├── rtm_common.h
│   ├── rtm_client.h
│   └── ...
├── (其他原始 SDK 文件)
└── ...

include/c/api2/
└── vad.h                              # ✅ 新增
```

## 注意事项

1. **文件完整性**
   - 确保所有 3 个 .so 文件都存在
   - 确保 `agora_rtm_sdk_c` 目录完整
   - 确保 `vad.h` 文件存在

2. **版本兼容性**
   - RTM SDK 版本需要与原始 SDK 版本兼容
   - 确认 .so 文件的架构匹配（x64/x86）

3. **文件权限**
   - .so 文件应该有可执行权限
   - 可以使用 `chmod +x libs/*.so`

4. **Git 提交**
   ```bash
   git add extra_resources/
   git commit -m "添加 RTM SDK 库和头文件"
   git push
   ```

## 故障排查

### 问题：脚本找不到文件

**检查文件是否存在：**
```bash
ls -lh libs/libagora_rtm_sdk_c.so
ls -lh agora_rtm_sdk_c/
ls -lh headers/vad.h
```

### 问题：.so 文件无法加载

**检查文件格式：**
```bash
file libs/libagora_rtm_sdk_c.so
# 应该显示: ELF 64-bit LSO shared object, x86-64
```

### 问题：头文件缺失

**检查头文件完整性：**
```bash
find agora_rtm_sdk_c -name "*.h" | wc -l
# 应该有多个头文件
```

## 示例：完整的设置流程

```bash
# 假设你有以下文件：
# - /tmp/rtm/libagora_rtm_sdk_c.so
# - /tmp/rtm/libagora_rtm_sdk.so
# - /tmp/rtm/libagora_uap_aed.so
# - /tmp/rtm/agora_rtm_sdk_c/ (目录)
# - /tmp/vad/vad.h

cd /Volumes/ZR/Agora/Jenkins/extra_resources

# 1. 复制库文件
cp /tmp/rtm/libagora_rtm_sdk_c.so libs/
cp /tmp/rtm/libagora_rtm_sdk.so libs/
cp /tmp/rtm/libagora_uap_aed.so libs/

# 2. 复制 RTM 头文件目录
cp -r /tmp/rtm/agora_rtm_sdk_c ./

# 3. 复制 VAD 头文件
cp /tmp/vad/vad.h headers/

# 4. 验证
echo "✓ 库文件:"
ls -lh libs/

echo "✓ RTM 头文件:"
ls -lh agora_rtm_sdk_c/

echo "✓ VAD 头文件:"
ls -lh headers/vad.h

# 5. 本地测试
cd ..
./scripts/local_test.sh \
  "http://10.80.1.174:8090/agora_sdk/4.4.32.150/.../SDK.zip" \
  "4.4.32.150"

# 6. 提交到 Git
git add extra_resources/
git commit -m "添加 RTM SDK v4.4.32 和 VAD 头文件"
git push

# 7. 在 Jenkins 中触发构建
```

---

## Mac 平台说明

### Mac SDK 处理流程

Mac SDK 的处理相对简单，**只需要 dylib 库文件，不需要头文件**。

### Mac 目录结构

```bash
extra_resources/
└── libs_mac/                      # Mac 平台库文件
    ├── libagora_rtm_sdk_c.dylib  # 必需
    ├── libAgoraRtmKit.dylib      # 必需
    └── libuap_aed.dylib          # 必需
```

### Mac 处理步骤

1. **转换 xcframework 为 dylib**
   - 使用 `scripts/framework_to_dylib.py` 脚本
   - 自动处理 SDK 中所有的 xcframework

2. **添加 RTM SDK dylib**
   - 从 `libs_mac/` 复制 3 个 dylib 文件
   - 全部放入 `agora_sdk/` 目录

3. **打包**
   - 清理隐藏文件
   - 压缩 `agora_sdk/` 目录
   - 重命名为：`agora_sdk_mac_{version}.zip`

### Mac 文件准备

```bash
cd extra_resources

# 创建 Mac 库目录
mkdir -p libs_mac

# 复制 Mac 的 dylib 文件
cp /path/to/libagora_rtm_sdk_c.dylib libs_mac/
cp /path/to/libAgoraRtmKit.dylib libs_mac/
cp /path/to/libuap_aed.dylib libs_mac/

# 验证文件
ls -lh libs_mac/
```

### Mac 本地测试

```bash
cd /Volumes/ZR/Agora/Jenkins

./scripts/local_test_mac.sh \
  "http://10.80.1.174:8090/agora_sdk/4.4.30/nightly_build/2025-08-20/mac/full/Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip" \
  "4.4.30"
```

### Mac 最终结构

```
agora_sdk/
├── libAgorafdkaac.dylib           # 原始 SDK（从 xcframework 转换）
├── libAgoraRtcKit.dylib           # 原始 SDK（从 xcframework 转换）
├── libAgoraSoundTouch.dylib       # 原始 SDK（从 xcframework 转换）
├── ... (其他转换的 dylib)
├── libagora_rtm_sdk_c.dylib       # ✅ 新增
├── libAgoraRtmKit.dylib           # ✅ 新增
└── libuap_aed.dylib               # ✅ 新增
```

### Mac 文件名格式

**原始文件名：**
```
Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip
```

**新文件名：**
```
agora_sdk_mac_v4.4.30_25321_FULL_20250820_1052_846534.zip
```

规则：
- 前缀：`agora_sdk_mac_`
- 版本：从原文件名中提取 `v` 后面的所有字符（去掉 `.zip`）

---

## 平台对比

| 特性 | Linux | Mac |
|------|-------|-----|
| 库文件格式 | `.so` | `.dylib` |
| 需要头文件 | ✅ 是 | ❌ 否 |
| RTM 头文件目录 | ✅ 需要 | ❌ 不需要 |
| VAD 头文件 | ✅ 需要 | ❌ 不需要 |
| xcframework 转换 | ❌ 不需要 | ✅ 需要 |
| 删除 .so/.dylib | ✅ 3个 | ❌ 不需要 |
| 文件名前缀 | `agora_rtc_sdk_x86_64-linux-gnu-` | `agora_sdk_mac_` |

