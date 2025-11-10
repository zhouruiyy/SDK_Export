# GitHub Actions 使用指南

## 🚀 3 步开始使用

### 步骤 1：提交代码到 GitHub

```bash
cd /Volumes/ZR/Agora/Jenkins

# 添加所有文件
git add .

# 提交
git commit -m "添加 GitHub Actions workflow"

# 推送
git push origin main
```

### 步骤 2：在 GitHub 上触发构建

1. 打开你的 GitHub 仓库：https://github.com/zhouruiyy/SDK_Export
2. 点击顶部的 **"Actions"** 标签
3. 左侧找到 **"Build Enhanced SDK"** workflow
4. 点击右侧的 **"Run workflow"** 按钮
5. 填写参数：

**Linux 示例：**
```
sdk_url: 
http://10.80.1.174:8090/agora_sdk/4.4.32.150/official_build/2025-10-30/linux/server/Agora_Native_SDK_for_Linux_x64_rel.v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678_external.zip

sdk_version: 
4.4.32.150

platform: 
linux
```

**Mac 示例：**
```
sdk_url:
http://10.80.1.174:8090/agora_sdk/4.4.30/nightly_build/2025-08-20/mac/full/Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip

sdk_version:
4.4.30

platform:
mac
```

6. 点击 **"Run workflow"** 开始构建

### 步骤 3：下载构建产物

1. 构建完成后，点击具体的 workflow run
2. 滚动到页面底部，找到 **"Artifacts"** 部分
3. 下载 `sdk-linux-4.4.32.150` 或 `sdk-mac-4.4.30`
4. 解压后包含：
   - `*.zip` - 增强后的 SDK
   - `*.md5` - MD5 校验文件
   - `build_report.txt` - 构建报告

---

## 📊 如何查看构建进度

1. 在 Actions 页面，点击正在运行的 workflow
2. 点击 "build" job
3. 实时查看每个步骤的日志输出
4. 如果失败，可以看到详细的错误信息

---

## 👥 团队协作

### 其他人如何使用？

只需要：
1. **有 GitHub 账号**
2. **对仓库有 Write 权限**（你需要添加他们为 Collaborator）
3. 进入仓库 → Actions → Run workflow

### 添加协作者：

1. GitHub 仓库页面 → **Settings**
2. 左侧 → **Collaborators**
3. 点击 **"Add people"**
4. 输入他们的 GitHub 用户名或邮箱
5. 发送邀请

---

## ⚙️ GitHub Actions vs Jenkins 对比

| 特性 | GitHub Actions | Jenkins |
|------|---------------|---------|
| **服务器** | GitHub 提供 | 需要自己维护 |
| **成本** | 免费（公开仓库） | 需要服务器成本 |
| **权限管理** | 基于 GitHub 仓库权限 | 独立的用户系统 |
| **配置复杂度** | ⭐⭐ 简单 | ⭐⭐⭐⭐ 复杂 |
| **运行环境** | Linux/Mac/Windows | 取决于节点配置 |
| **构建历史** | 90天（免费版） | 永久保存 |
| **并发构建** | 有限制 | 取决于节点 |
| **集成性** | GitHub 原生 | 需要配置 |

---

## 🎯 功能特点

### ✅ 支持的功能

- ✅ 手动触发构建（workflow_dispatch）
- ✅ Linux 和 Mac 平台
- ✅ 参数化构建（SDK URL、版本、平台）
- ✅ 自动下载和解压 SDK
- ✅ 处理和打包 SDK
- ✅ 生成 MD5 校验
- ✅ 构建报告
- ✅ 自动上传构建产物（保留 30 天）
- ✅ 完整的日志输出
- ✅ 失败通知（GitHub 邮件）

### ⚠️ 限制

- Linux 构建使用 `ubuntu-latest`
- Mac 构建使用 `macos-latest`
- 构建产物保留 30 天（可调整）
- 需要能访问内网 SDK 下载地址（`10.80.1.174`）

---

## 🔍 查看构建历史

所有的构建记录都在：
```
仓库 → Actions → All workflows
```

可以查看：
- ✅ 构建时间
- ✅ 触发者
- ✅ 参数
- ✅ 构建结果
- ✅ 日志
- ✅ 构建产物

---

## 💡 高级技巧

### 1. 添加自动触发（Push 时自动构建）

如果想在代码 push 时自动测试，修改 `.github/workflows/build-sdk.yml`：

```yaml
on:
  workflow_dispatch:  # 保留手动触发
  push:              # 添加 push 触发
    branches:
      - main
```

### 2. 添加定时构建

每天自动构建：

```yaml
on:
  workflow_dispatch:
  schedule:
    - cron: '0 2 * * *'  # 每天 UTC 2:00（北京时间 10:00）
```

### 3. 添加 Slack/钉钉通知

在 workflow 最后添加通知步骤（需要配置 webhook）

### 4. 并发控制

防止同时运行多个构建：

```yaml
concurrency:
  group: build-sdk-${{ github.event.inputs.platform }}
  cancel-in-progress: true
```

---

## 🐛 故障排查

### 问题 1：无法下载 SDK（网络问题）

如果 GitHub Actions 无法访问内网地址 `10.80.1.174`，需要：
1. 使用 GitHub self-hosted runner（自托管运行器）
2. 或者先上传 SDK 到公网可访问的位置

### 问题 2：构建失败 "Permission denied"

脚本没有执行权限：
```bash
chmod +x scripts/*.sh
git add scripts/
git commit -m "Fix permissions"
git push
```

### 问题 3：找不到构建产物

检查 workflow 是否成功完成，只有成功的构建才会上传产物。

### 问题 4：Mac 构建失败 "Python not found"

GitHub Actions 的 `macos-latest` 应该自带 Python3，如果失败检查日志。

---

## 📞 需要帮助？

- 查看 GitHub Actions 文档：https://docs.github.com/actions
- 查看构建日志找到具体错误
- 检查 `测试命令.txt` 和 `测试命令_Mac.txt` 进行本地测试

---

## 🎉 完成！

现在你可以：
- ✅ 在 GitHub 上轻松触发构建
- ✅ 团队成员都可以使用（只需要 GitHub 账号）
- ✅ 无需维护 Jenkins 服务器
- ✅ 自动保存构建历史和产物
- ✅ 随时随地访问（只要能上 GitHub）

**开始使用吧！** 🚀

