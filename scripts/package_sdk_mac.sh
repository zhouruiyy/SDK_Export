#!/bin/bash

# Mac SDK 打包脚本
# 用途：
# 1. 清理隐藏文件
# 2. 打包 agora_sdk 目录
# 3. 重命名为规范的文件名

set -e  # 遇到错误立即退出

# 参数
ORIGINAL_SDK_DIR=$1      # 处理后的 SDK 根目录
ORIGINAL_SDK_NAME=$2     # 原始 SDK 文件名（例如：Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip）

echo "=========================================="
echo "开始打包 Mac SDK"
echo "=========================================="
echo "SDK 目录: ${ORIGINAL_SDK_DIR}"
echo "原始文件名: ${ORIGINAL_SDK_NAME}"
echo "=========================================="

AGORA_SDK_DIR="${ORIGINAL_SDK_DIR}/agora_sdk"

if [ ! -d "${AGORA_SDK_DIR}" ]; then
    echo "❌ 错误: agora_sdk 目录不存在: ${AGORA_SDK_DIR}"
    exit 1
fi

cd "${ORIGINAL_SDK_DIR}"

# ============================================
# 步骤 1: 清理隐藏文件和系统文件
# ============================================
echo ""
echo "步骤 1: 清理隐藏文件..."

# 清理常见的隐藏文件
find agora_sdk -name ".DS_Store" -type f -delete 2>/dev/null || true
find agora_sdk -name "._*" -type f -delete 2>/dev/null || true
find agora_sdk -name ".AppleDouble" -type d -exec rm -rf {} + 2>/dev/null || true
find agora_sdk -name "__MACOSX" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✓ 清理完成"

# ============================================
# 步骤 2: 生成新的文件名
# ============================================
echo ""
echo "步骤 2: 生成新文件名..."

# 从原始文件名中提取 v 后面的所有字符
# 例如：Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip
# 提取：v4.4.30_25321_FULL_20250820_1052_846534
generate_mac_sdk_name() {
    local original_name=$1
    
    # 提取 v 后面到 .zip 前的所有字符
    local version_part=$(echo "${original_name}" | sed 's/.*\.v/v/' | sed 's/\.zip$//')
    
    if [ -z "${version_part}" ] || [ "${version_part}" = "${original_name}" ]; then
        echo "⚠ 警告: 无法解析原始文件名，使用原名" >&2
        echo "${original_name}"
        return 1
    fi
    
    # 生成新文件名：agora_sdk_mac_{version_part}-3a.zip
    local new_name="agora_sdk_mac_${version_part}-3a.zip"
    
    # 将调试信息输出到 stderr，这样不会影响返回值
    echo "原始文件名: ${original_name}" >&2
    echo "提取版本部分: ${version_part}" >&2
    echo "新文件名: ${new_name}" >&2
    
    # 只将文件名输出到 stdout
    echo "${new_name}"
    return 0
}

NEW_SDK_NAME=$(generate_mac_sdk_name "${ORIGINAL_SDK_NAME}")

if [ $? -ne 0 ]; then
    echo "⚠ 警告: 使用原始文件名"
    NEW_SDK_NAME="${ORIGINAL_SDK_NAME}"
fi

echo "✓ 新文件名: ${NEW_SDK_NAME}"

# ============================================
# 步骤 3: 压缩 agora_sdk 目录
# ============================================
echo ""
echo "步骤 3: 压缩 agora_sdk 目录..."

# 删除旧的压缩文件（如果存在）
rm -f "${NEW_SDK_NAME}" 2>/dev/null || true

# 使用 zip 命令压缩
# -r: 递归压缩
# -X: 不保存额外的文件属性
# -q: 安静模式
# -9: 最高压缩率
echo "正在压缩..."
zip -r -X -9 "${NEW_SDK_NAME}" agora_sdk

if [ ! -f "${NEW_SDK_NAME}" ]; then
    echo "❌ 错误: 压缩失败"
    exit 1
fi

echo "✓ 压缩完成"

# ============================================
# 步骤 4: 生成 MD5 校验文件
# ============================================
echo ""
echo "步骤 4: 生成 MD5 校验..."

MD5_FILE="${NEW_SDK_NAME}.md5"

# 检测操作系统并使用相应的 md5 命令
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    MD5_HASH=$(md5 -q "${NEW_SDK_NAME}")
    echo "${MD5_HASH}  ${NEW_SDK_NAME}" > "${MD5_FILE}"
else
    # Linux
    md5sum "${NEW_SDK_NAME}" > "${MD5_FILE}"
fi

echo "✓ MD5: $(cat ${MD5_FILE})"

# ============================================
# 步骤 5: 显示最终结果
# ============================================
echo ""
echo "=========================================="
echo "✅ 打包完成！"
echo "=========================================="
echo "生成的文件:"
ls -lh "${NEW_SDK_NAME}"*
echo ""
echo "文件大小: $(du -h "${NEW_SDK_NAME}" | cut -f1)"
echo "MD5: $(cat ${MD5_FILE})"
echo "=========================================="

