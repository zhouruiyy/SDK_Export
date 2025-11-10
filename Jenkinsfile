pipeline {
    agent any
    
    parameters {
        string(name: 'SDK_ZIP_URL', defaultValue: '', description: '原始 SDK 的下载链接')
        string(name: 'SDK_VERSION', defaultValue: '', description: 'SDK 版本号，如：4.2.0')
        choice(name: 'PLATFORM', choices: ['Linux', 'Linux-x86'], description: '目标平台')
    }
    
    environment {
        // CDN 上传相关配置（根据您公司的 CDN 调整）
        CDN_BUCKET = 'your-cdn-bucket'
        CDN_PATH = 'sdk/enhanced'
        
        // 工作目录
        WORK_DIR = "${WORKSPACE}/build"
        ORIGINAL_SDK_DIR = "${WORK_DIR}/original_sdk"
    }
    
    stages {
        stage('准备环境') {
            steps {
                script {
                    echo "开始处理 SDK 增强打包..."
                    echo "SDK URL: ${params.SDK_ZIP_URL}"
                    echo "SDK Version: ${params.SDK_VERSION}"
                    echo "Platform: ${params.PLATFORM}"
                    
                    // 清理并创建工作目录
                    sh '''
                        rm -rf ${WORK_DIR}
                        mkdir -p ${WORK_DIR}
                        mkdir -p ${ORIGINAL_SDK_DIR}
                        
                        echo "工作目录已创建:"
                        ls -la ${WORK_DIR}
                        
                        echo ""
                        echo "额外资源目录:"
                        ls -la ${WORKSPACE}/extra_resources/
                    '''
                }
            }
        }
        
        stage('下载原始 SDK') {
            steps {
                script {
                    echo "正在下载原始 SDK..."
                    sh '''
                        cd ${WORK_DIR}
                        curl -L -o original_sdk.zip "${SDK_ZIP_URL}"
                        
                        # 验证下载是否成功
                        if [ ! -f original_sdk.zip ]; then
                            echo "错误：SDK 下载失败"
                            exit 1
                        fi
                        
                        # 显示文件大小
                        ls -lh original_sdk.zip
                    '''
                }
            }
        }
        
        stage('解压原始 SDK') {
            steps {
                script {
                    echo "解压原始 SDK..."
                    sh '''
                        cd ${WORK_DIR}
                        
                        # 解压原始 SDK 到 original_sdk 目录
                        unzip -q original_sdk.zip -d ${ORIGINAL_SDK_DIR}
                        
                        echo "解压完成，目录结构:"
                        ls -lh ${ORIGINAL_SDK_DIR}
                    '''
                }
            }
        }
        
        stage('处理 SDK - 添加额外文件') {
            steps {
                script {
                    echo "添加 RTM SDK 库和头文件..."
                    sh '''
                        # 调用处理脚本
                        # 参数1: 原始 SDK 根目录
                        # 参数2: 额外资源目录
                        ${WORKSPACE}/scripts/process_sdk.sh \
                            "${ORIGINAL_SDK_DIR}" \
                            "${WORKSPACE}/extra_resources"
                    '''
                }
            }
        }
        
        stage('打包 SDK') {
            steps {
                script {
                    echo "打包 agora_sdk 并重命名..."
                    sh '''
                        # 从 URL 中提取原始 SDK 文件名
                        ORIGINAL_SDK_NAME=$(basename "${params.SDK_ZIP_URL}")
                        echo "原始 SDK 名称: ${ORIGINAL_SDK_NAME}"
                        
                        # 调用打包脚本
                        # 参数1: SDK 根目录
                        # 参数2: 原始 SDK 文件名
                        ${WORKSPACE}/scripts/package_sdk.sh \
                            "${ORIGINAL_SDK_DIR}" \
                            "${ORIGINAL_SDK_NAME}"
                        
                        # 移动生成的文件到 WORK_DIR
                        mv ${ORIGINAL_SDK_DIR}/${ORIGINAL_SDK_NAME}* ${WORK_DIR}/
                        
                        echo "最终生成的文件:"
                        ls -lh ${WORK_DIR}/${ORIGINAL_SDK_NAME}*
                    '''
                }
            }
        }
        
        stage('上传到 CDN') {
            steps {
                script {
                    echo "上传到 CDN..."
                    sh '''
                        cd ${WORK_DIR}
                        
                        # 获取原始 SDK 文件名
                        ORIGINAL_SDK_NAME=$(basename "${params.SDK_ZIP_URL}")
                        
                        # 调用上传脚本（根据您公司的 CDN 类型调整）
                        ${WORKSPACE}/scripts/upload_to_cdn.sh \
                            "${ORIGINAL_SDK_NAME}" \
                            "${CDN_BUCKET}" \
                            "${CDN_PATH}/${params.SDK_VERSION}"
                    '''
                }
            }
        }
        
        stage('生成报告') {
            steps {
                script {
                    sh '''
                        cd ${WORK_DIR}
                        
                        # 获取原始 SDK 文件名
                        ORIGINAL_SDK_NAME=$(basename "${params.SDK_ZIP_URL}")
                        
                        # 生成构建报告
                        cat > build_report.txt <<EOF
===========================================
Agora SDK 增强版本构建报告
===========================================
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
SDK 版本: ${params.SDK_VERSION}
目标平台: ${params.PLATFORM}
原始 SDK: ${params.SDK_ZIP_URL}
原始文件名: ${ORIGINAL_SDK_NAME}
生成文件: ${ORIGINAL_SDK_NAME}
文件大小: $(du -h ${ORIGINAL_SDK_NAME} | cut -f1)
MD5: $(cat ${ORIGINAL_SDK_NAME}.md5 | cut -d' ' -f1 2>/dev/null || echo "未生成")
CDN 路径: ${CDN_BUCKET}/${CDN_PATH}/${params.SDK_VERSION}/${ORIGINAL_SDK_NAME}

增强内容:
- 添加 RTM SDK 库文件:
  * libagora_rtm_sdk_c.so
  * libagora_rtm_sdk.so
  * libagora_uap_aed.so
- 添加 RTM SDK 头文件目录: agora_rtm_sdk_c/
- 添加 VAD 头文件: include/c/api2/vad.h
- 目录重命名: sdk -> agora_sdk
===========================================
EOF
                        cat build_report.txt
                    '''
                    
                    // 归档构建产物
                    archiveArtifacts artifacts: 'build/*.zip, build/*.md5, build/build_report.txt', 
                                     fingerprint: true
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ SDK 增强打包成功！"
            // 可以添加邮件通知或钉钉/企业微信通知
        }
        failure {
            echo "❌ SDK 增强打包失败！"
            // 发送失败通知
        }
        always {
            // 清理工作空间（可选）
            // cleanWs()
        }
    }
}

