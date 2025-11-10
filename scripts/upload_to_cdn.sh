#!/bin/bash

# CDN 上传脚本
# 支持多种 CDN 服务，根据公司实际使用的 CDN 类型进行调整

set -e

FILE_PATH=$1
CDN_BUCKET=$2
CDN_PATH=$3

echo "=========================================="
echo "上传文件到 CDN"
echo "=========================================="
echo "本地文件: ${FILE_PATH}"
echo "CDN Bucket: ${CDN_BUCKET}"
echo "CDN 路径: ${CDN_PATH}"
echo "=========================================="

# 获取文件名
FILE_NAME=$(basename ${FILE_PATH})
FULL_CDN_PATH="${CDN_PATH}/${FILE_NAME}"

# ============================================
# 方案一：使用 AWS S3（如果使用阿里云 OSS/腾讯云 COS，语法类似）
# ============================================
upload_to_s3() {
    echo "使用 AWS S3 上传..."
    
    # 需要配置 AWS CLI 凭证
    # Jenkins 中配置: AWS_ACCESS_KEY_ID 和 AWS_SECRET_ACCESS_KEY
    
    aws s3 cp ${FILE_PATH} s3://${CDN_BUCKET}/${FULL_CDN_PATH} \
        --acl public-read \
        --storage-class STANDARD
    
    # 同时上传 MD5 文件
    if [ -f "${FILE_PATH}.md5" ]; then
        aws s3 cp ${FILE_PATH}.md5 s3://${CDN_BUCKET}/${FULL_CDN_PATH}.md5 \
            --acl public-read
    fi
    
    # 生成 CDN URL
    CDN_URL="https://${CDN_BUCKET}.s3.amazonaws.com/${FULL_CDN_PATH}"
    echo "上传成功！"
    echo "CDN URL: ${CDN_URL}"
}

# ============================================
# 方案二：使用阿里云 OSS
# ============================================
upload_to_aliyun_oss() {
    echo "使用阿里云 OSS 上传..."
    
    # 需要安装 ossutil: https://help.aliyun.com/document_detail/120075.html
    # Jenkins 中配置 OSS 凭证
    
    ossutil cp ${FILE_PATH} oss://${CDN_BUCKET}/${FULL_CDN_PATH} \
        --access-key-id=${ALIYUN_ACCESS_KEY_ID} \
        --access-key-secret=${ALIYUN_ACCESS_KEY_SECRET} \
        --endpoint=${ALIYUN_OSS_ENDPOINT}
    
    if [ -f "${FILE_PATH}.md5" ]; then
        ossutil cp ${FILE_PATH}.md5 oss://${CDN_BUCKET}/${FULL_CDN_PATH}.md5 \
            --access-key-id=${ALIYUN_ACCESS_KEY_ID} \
            --access-key-secret=${ALIYUN_ACCESS_KEY_SECRET} \
            --endpoint=${ALIYUN_OSS_ENDPOINT}
    fi
    
    CDN_URL="https://${CDN_BUCKET}.${ALIYUN_OSS_ENDPOINT}/${FULL_CDN_PATH}"
    echo "上传成功！"
    echo "CDN URL: ${CDN_URL}"
}

# ============================================
# 方案三：使用腾讯云 COS
# ============================================
upload_to_tencent_cos() {
    echo "使用腾讯云 COS 上传..."
    
    # 需要安装 coscmd: https://cloud.tencent.com/document/product/436/10976
    
    coscmd upload ${FILE_PATH} ${FULL_CDN_PATH}
    
    if [ -f "${FILE_PATH}.md5" ]; then
        coscmd upload ${FILE_PATH}.md5 ${FULL_CDN_PATH}.md5
    fi
    
    CDN_URL="https://${CDN_BUCKET}.cos.${TENCENT_COS_REGION}.myqcloud.com/${FULL_CDN_PATH}"
    echo "上传成功！"
    echo "CDN URL: ${CDN_URL}"
}

# ============================================
# 方案四：使用 HTTP/HTTPS 直接上传（通用方案）
# ============================================
upload_via_http() {
    echo "使用 HTTP API 上传..."
    
    # 如果公司有自己的上传 API
    UPLOAD_URL="${CDN_UPLOAD_API_URL}/${FULL_CDN_PATH}"
    
    curl -X PUT \
        -H "Authorization: Bearer ${CDN_API_TOKEN}" \
        -H "Content-Type: application/zip" \
        --data-binary @${FILE_PATH} \
        ${UPLOAD_URL}
    
    if [ $? -eq 0 ]; then
        echo "上传成功！"
        echo "CDN URL: ${CDN_BASE_URL}/${FULL_CDN_PATH}"
    else
        echo "上传失败！"
        exit 1
    fi
}

# ============================================
# 方案五：使用 rsync/scp 到内部服务器
# ============================================
upload_via_rsync() {
    echo "使用 rsync 上传到内部服务器..."
    
    # 需要在 Jenkins 中配置 SSH 密钥
    rsync -avz --progress \
        ${FILE_PATH} \
        ${CDN_SERVER_USER}@${CDN_SERVER_HOST}:${CDN_SERVER_PATH}/${FULL_CDN_PATH}
    
    if [ -f "${FILE_PATH}.md5" ]; then
        rsync -avz --progress \
            ${FILE_PATH}.md5 \
            ${CDN_SERVER_USER}@${CDN_SERVER_HOST}:${CDN_SERVER_PATH}/${FULL_CDN_PATH}.md5
    fi
    
    echo "上传成功！"
    echo "服务器路径: ${CDN_SERVER_HOST}:${CDN_SERVER_PATH}/${FULL_CDN_PATH}"
}

# ============================================
# 主逻辑：根据环境变量选择上传方式
# ============================================

case "${CDN_TYPE:-s3}" in
    s3|aws)
        upload_to_s3
        ;;
    oss|aliyun)
        upload_to_aliyun_oss
        ;;
    cos|tencent)
        upload_to_tencent_cos
        ;;
    http|api)
        upload_via_http
        ;;
    rsync|server)
        upload_via_rsync
        ;;
    *)
        echo "错误：未知的 CDN 类型: ${CDN_TYPE}"
        echo "支持的类型: s3, oss, cos, http, rsync"
        exit 1
        ;;
esac

echo "=========================================="
echo "✅ 上传完成！"
echo "=========================================="

