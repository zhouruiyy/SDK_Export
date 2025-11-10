# SDK 增强打包 CI 系统

此项目用于在原始 Agora Linux SDK 的基础上，添加额外的库和头文件，生成增强版 SDK 并上传到 CDN。

## 📁 项目结构

```
.
├── Jenkinsfile                    # Jenkins Pipeline 配置
├── scripts/
│   ├── process_sdk.sh            # SDK 处理脚本
│   └── upload_to_cdn.sh          # CDN 上传脚本
├── extra_resources/
│   ├── libs/                     # 额外的库文件
│   ├── headers/                  # 额外的头文件
│   └── README.md
└── README.md                     # 本文件
```

## 🚀 快速开始

### 前置条件

1. **Jenkins 环境**
   - Jenkins 版本 2.x+
   - 已安装 Pipeline 插件

2. **必需工具**（Jenkins Agent 上需要安装）
   - `curl` - 下载文件
   - `unzip` - 解压 SDK
   - `zip` - 打包 SDK
   - CDN 上传工具（根据使用的 CDN 类型）：
     - AWS S3: `aws-cli`
     - 阿里云 OSS: `ossutil`
     - 腾讯云 COS: `coscmd`

### 步骤 1: 在 Jenkins 中创建 Pipeline 任务

1. 登录 Jenkins
2. 点击 "新建任务" (New Item)
3. 输入任务名称，如：`SDK-Enhanced-Build`
4. 选择 "Pipeline"
5. 点击确定

### 步骤 2: 配置 Pipeline

#### 方式 A：使用 SCM（推荐）

如果代码已经提交到 Git：

1. 在 Pipeline 配置中，选择 "Pipeline script from SCM"
2. SCM 选择 "Git"
3. 输入仓库 URL
4. 指定 Jenkinsfile 路径：`Jenkinsfile`

#### 方式 B：直接粘贴脚本

1. 在 Pipeline 配置中，选择 "Pipeline script"
2. 将 `Jenkinsfile` 的内容粘贴到脚本框中

### 步骤 3: 配置凭据和环境变量

在 Jenkins 中配置以下凭据（根据使用的 CDN 类型）：

#### Jenkins 全局凭据配置

进入 Jenkins → Manage Jenkins → Manage Credentials

**AWS S3:**
```
类型: Secret text
ID: aws-access-key-id
Secret: your-access-key

类型: Secret text
ID: aws-secret-access-key
Secret: your-secret-key
```

**阿里云 OSS:**
```
类型: Secret text
ID: aliyun-access-key-id
Secret: your-access-key

类型: Secret text
ID: aliyun-access-key-secret
Secret: your-secret-key
```

#### 在 Jenkinsfile 中引用凭据

修改 Jenkinsfile，添加凭据绑定：

```groovy
environment {
    // AWS 示例
    AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    
    // 或阿里云示例
    ALIYUN_ACCESS_KEY_ID = credentials('aliyun-access-key-id')
    ALIYUN_ACCESS_KEY_SECRET = credentials('aliyun-access-key-secret')
    ALIYUN_OSS_ENDPOINT = 'oss-cn-hangzhou.aliyuncs.com'
}
```

### 步骤 4: 准备额外资源

将需要添加的库和头文件放到 `extra_resources` 目录：

```bash
# 添加库文件
cp /path/to/your/lib.so extra_resources/libs/

# 添加头文件
cp /path/to/your/header.h extra_resources/headers/
```

### 步骤 5: 运行构建

1. 进入 Jenkins 任务页面
2. 点击 "Build with Parameters"
3. 填写参数：
   - **SDK_ZIP_URL**: 原始 SDK 的下载链接
   - **SDK_VERSION**: 版本号（如：4.2.0）
   - **PLATFORM**: 选择目标平台（Linux / Linux-x86）
4. 点击 "构建"

## 📋 参数说明

| 参数名 | 说明 | 示例 |
|--------|------|------|
| SDK_ZIP_URL | 原始 SDK 下载链接 | `https://download.agora.io/sdk/linux/Agora_SDK_4.2.0.zip` |
| SDK_VERSION | SDK 版本号 | `4.2.0` |
| PLATFORM | 目标平台 | `Linux` 或 `Linux-x86` |

## 🔧 自定义配置

### 修改 CDN 上传方式

编辑 `scripts/upload_to_cdn.sh`，在 Jenkinsfile 中设置 `CDN_TYPE` 环境变量：

```groovy
environment {
    CDN_TYPE = 'oss'  // 可选: s3, oss, cos, http, rsync
    CDN_BUCKET = 'your-bucket-name'
    CDN_PATH = 'sdk/enhanced'
}
```

### 自动触发构建

如果希望在上游 CI（原始 SDK 构建）完成后自动触发：

**方法 1: 使用 Jenkins 触发器**

在 Jenkinsfile 顶部添加：

```groovy
pipeline {
    agent any
    
    triggers {
        // 监听上游任务
        upstream(upstreamProjects: 'Original-SDK-Build-Job', threshold: hudson.model.Result.SUCCESS)
    }
    ...
}
```

**方法 2: 使用 Webhook**

在原始 SDK 构建完成后，调用 Jenkins API：

```bash
curl -X POST http://jenkins.yourcompany.com/job/SDK-Enhanced-Build/buildWithParameters \
  --user YOUR_USER:YOUR_TOKEN \
  --data-urlencode SDK_ZIP_URL="https://download.agora.io/sdk.zip" \
  --data-urlencode SDK_VERSION="4.2.0" \
  --data-urlencode PLATFORM="Linux"
```

### 添加通知

在 Jenkinsfile 的 `post` 部分添加通知：

```groovy
post {
    success {
        // 邮件通知
        emailext(
            subject: "✅ SDK 增强打包成功 - v${params.SDK_VERSION}",
            body: """
                SDK 增强版本构建成功！
                
                版本: ${params.SDK_VERSION}
                平台: ${params.PLATFORM}
                构建链接: ${env.BUILD_URL}
            """,
            to: 'team@yourcompany.com'
        )
        
        // 或钉钉通知
        sh """
            curl -X POST 'https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN' \
            -H 'Content-Type: application/json' \
            -d '{
                "msgtype": "text",
                "text": {
                    "content": "✅ SDK 增强打包成功\\n版本: ${params.SDK_VERSION}\\n平台: ${params.PLATFORM}"
                }
            }'
        """
    }
    failure {
        emailext(
            subject: "❌ SDK 增强打包失败 - v${params.SDK_VERSION}",
            body: "构建失败，请检查: ${env.BUILD_URL}console",
            to: 'team@yourcompany.com'
        )
    }
}
```

## 🔍 故障排查

### 1. 下载 SDK 失败

**问题**: `curl: (6) Could not resolve host`

**解决**: 
- 检查 Jenkins Agent 网络连接
- 检查 URL 是否正确
- 如果需要代理，在脚本中添加：
  ```bash
  export http_proxy=http://proxy.company.com:8080
  export https_proxy=http://proxy.company.com:8080
  ```

### 2. 上传 CDN 失败

**问题**: 上传超时或权限错误

**解决**:
- 检查凭据配置是否正确
- 检查 CDN bucket 权限
- 检查网络连接
- 查看 CDN 上传脚本日志

### 3. 脚本权限错误

**问题**: `Permission denied`

**解决**:
```bash
chmod +x scripts/*.sh
git add scripts/
git commit -m "添加执行权限"
```

## 📊 查看构建结果

构建完成后，可以在以下位置查看结果：

1. **Jenkins 任务页面**: 查看构建日志
2. **构建归档**: 下载生成的 zip 文件和 MD5
3. **CDN**: 访问 CDN URL 下载

构建报告示例：

```
===========================================
SDK 增强版本构建报告
===========================================
构建时间: 2025-11-10 14:30:00
SDK 版本: 4.2.0
目标平台: Linux
生成文件: Agora_SDK_Enhanced_Linux_v4.2.0.zip
文件大小: 45M
MD5: a1b2c3d4e5f6...
CDN 路径: https://cdn.yourcompany.com/sdk/enhanced/4.2.0/
===========================================
```

## 🔐 安全建议

1. **不要在代码中硬编码凭据**，使用 Jenkins 凭据管理
2. **限制 CDN bucket 权限**，只授予必要的上传权限
3. **使用 HTTPS** 进行文件传输
4. **定期更新凭据**
5. **限制 Jenkins 任务执行权限**

## 📞 联系方式

如有问题，请联系：
- DevOps 团队: devops@yourcompany.com
- SDK 团队: sdk-team@yourcompany.com

## 📝 变更日志

- **2025-11-10**: 初始版本创建
- 支持 Linux 平台 SDK 增强打包
- 支持多种 CDN 上传方式

