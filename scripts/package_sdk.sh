#!/bin/bash

# SDK 打包脚本
# 用途：
# 1. 清理 agora_sdk 目录中的隐藏文件（.DS_Store 等）
# 2. 压缩 agora_sdk 目录为 zip
# 3. 生成新的文件名（Linux包专用）

set -e  # 遇到错误立即退出

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 参数
SDK_ROOT_DIR=$1          # SDK 根目录（包含 agora_sdk 的目录）
ORIGINAL_SDK_NAME=$2     # 原始 SDK 的 zip 文件名

echo "=========================================="
echo "开始打包 agora_sdk"
echo "=========================================="
echo "SDK 根目录: ${SDK_ROOT_DIR}"
echo "原始 SDK 名称: ${ORIGINAL_SDK_NAME}"
echo "=========================================="

# ============================================
# 生成新的 Linux SDK 文件名
# 格式: agora_rtc_sdk_x86_64-linux-gnu-v{版本号}.zip
# 从原始文件名提取 v4.4.32.150_... 到 _external/_internal 前的部分
# 去掉 ubuntu14_04_5 版本号，但保留完整的版本信息
# 不包含 _external 或 _internal 后缀
# ============================================
generate_linux_sdk_name() {
    local original_name=$1
    
    # 判断是 external 还是 internal
    local suffix="external"
    if [[ "$original_name" == *"_internal"* ]]; then
        suffix="internal"
    fi
    
    # 提取版本号部分（从 v 开始到 _external/_internal 之前）
    # 例如: Agora_Native_SDK_for_Linux_x64_rel.v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678_external.zip
    # 需要提取: v4.4.32.150_26715_SERVER_20251030_1807_ubuntu14_04_5_953678
    
    # 方法：先找到 .v，然后提取到文件名末尾，再去掉 _external.zip 或 _internal.zip
    local version_part=$(echo "$original_name" | sed 's/.*\.v/v/' | sed 's/_'"${suffix}"'\.zip$//')
    
    if [ -z "$version_part" ] || [ "$version_part" = "$original_name" ]; then
        echo "  ⚠ 警告: 无法解析原始文件名，使用原名" >&2
        echo "$original_name"
        return
    fi
    
    # 去掉 ubuntu 版本号 (ubuntu14_04_5 或类似)
    # 格式通常是 ubuntu + 数字 + _ + 数字 + _ + 数字
    version_part=$(echo "$version_part" | sed -E 's/_ubuntu[0-9]+_[0-9]+_[0-9]+//g')
    
    # 获取 rtm_c 库的时间戳（从配置文件读取）
    local rtm_version_file="${SCRIPT_DIR}/../extra_resources/rtm_version.txt"
    local rtm_timestamp=""
    
    if [ -f "${rtm_version_file}" ]; then
        # 从配置文件读取时间戳
        rtm_timestamp=$(grep "^RTM_TIMESTAMP=" "${rtm_version_file}" | cut -d'=' -f2)
        if [ -n "${rtm_timestamp}" ]; then
            echo "  ℹ RTM 库时间戳 (从配置文件): ${rtm_timestamp}" >&2
        else
            echo "  ⚠ 警告: 配置文件中未找到时间戳，使用当前时间" >&2
            rtm_timestamp=$(date +"%Y%m%d_%H%M")
        fi
    else
        # 降级：尝试从文件修改时间获取
        local rtm_c_file="${SCRIPT_DIR}/../extra_resources/libs/libagora_rtm_sdk_c.so"
        if [ -f "${rtm_c_file}" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                rtm_timestamp=$(stat -f "%Sm" -t "%Y%m%d_%H%M" "${rtm_c_file}")
            else
                rtm_timestamp=$(date -r "${rtm_c_file}" +"%Y%m%d_%H%M")
            fi
            echo "  ℹ RTM 库时间戳 (从文件): ${rtm_timestamp}" >&2
        else
            echo "  ⚠ 警告: 未找到配置文件和库文件，使用当前时间" >&2
            rtm_timestamp=$(date +"%Y%m%d_%H%M")
        fi
    fi
    
    # 生成新文件名（添加 rtm_c 时间戳和 -3a 后缀）
    local new_name="agora_rtc_sdk_x86_64-linux-gnu-${version_part}_${rtm_timestamp}-3a.zip"
    
    echo "  ℹ 原始文件名: ${original_name}" >&2
    echo "  ℹ 提取的版本部分: ${version_part}" >&2
    echo "  ℹ 新文件名: ${new_name}" >&2
    
    echo "$new_name"
}

NEW_SDK_NAME=$(generate_linux_sdk_name "${ORIGINAL_SDK_NAME}")
echo ""
echo "生成的新文件名: ${NEW_SDK_NAME}"
echo "=========================================="

# 检查 agora_sdk 目录是否存在
AGORA_SDK_DIR="${SDK_ROOT_DIR}/agora_sdk"

if [ ! -d "${AGORA_SDK_DIR}" ]; then
    echo "❌ 错误: 找不到 agora_sdk 目录: ${AGORA_SDK_DIR}"
    exit 1
fi

# ============================================
# 步骤 1: 清理隐藏文件和临时文件
# ============================================
echo ""
echo "步骤 1: 清理隐藏文件和临时文件..."

# 要删除的文件模式
PATTERNS_TO_DELETE=(
    ".DS_Store"
    "._.DS_Store"
    "._*"
    ".Spotlight-V100"
    ".Trashes"
    "Thumbs.db"
    "desktop.ini"
    "*~"
    ".*.swp"
)

for pattern in "${PATTERNS_TO_DELETE[@]}"; do
    COUNT=$(find "${AGORA_SDK_DIR}" -name "${pattern}" 2>/dev/null | wc -l)
    if [ $COUNT -gt 0 ]; then
        echo "  ✓ 删除 ${pattern} 文件 (${COUNT} 个)"
        find "${AGORA_SDK_DIR}" -name "${pattern}" -delete
    fi
done

echo "  ✓ 清理完成"

# ============================================
# 步骤 2: 显示将要打包的内容
# ============================================
echo ""
echo "步骤 2: 显示 agora_sdk 目录大小和文件数量..."

TOTAL_SIZE=$(du -sh "${AGORA_SDK_DIR}" | cut -f1)
FILE_COUNT=$(find "${AGORA_SDK_DIR}" -type f | wc -l)

echo "  总大小: ${TOTAL_SIZE}"
echo "  文件数: ${FILE_COUNT}"
echo ""
echo "  顶层目录结构:"
ls -lh "${AGORA_SDK_DIR}" | head -15

# ============================================
# 步骤 3: 压缩 agora_sdk 目录
# ============================================
echo ""
echo "步骤 3: 压缩 agora_sdk 目录..."

# 进入 SDK 根目录
cd "${SDK_ROOT_DIR}"

# 临时 zip 文件名
TEMP_ZIP="agora_sdk.zip"

# 删除已存在的临时 zip
if [ -f "${TEMP_ZIP}" ]; then
    rm -f "${TEMP_ZIP}"
fi

echo "  正在压缩... (这可能需要一些时间)"

# 使用 zip 命令压缩，排除隐藏文件
# -r: 递归
# -q: 安静模式
# -X: 排除额外的文件属性
zip -r -q -X "${TEMP_ZIP}" agora_sdk

if [ ! -f "${TEMP_ZIP}" ]; then
    echo "❌ 错误: 压缩失败"
    exit 1
fi

ZIP_SIZE=$(du -sh "${TEMP_ZIP}" | cut -f1)
echo "  ✓ 压缩完成"
echo "  压缩后大小: ${ZIP_SIZE}"

# ============================================
# 步骤 4: 重命名为新的 Linux SDK 名字
# ============================================
echo ""
echo "步骤 4: 重命名为新的 SDK 名字..."

# 如果新名字已存在，先删除
if [ -f "${NEW_SDK_NAME}" ]; then
    echo "  删除已存在的文件: ${NEW_SDK_NAME}"
    rm -f "${NEW_SDK_NAME}"
fi

# 重命名
mv "${TEMP_ZIP}" "${NEW_SDK_NAME}"

echo "  ✓ 已重命名: agora_sdk.zip -> ${NEW_SDK_NAME}"

# ============================================
# 步骤 5: 生成 MD5 校验
# ============================================
echo ""
echo "步骤 5: 生成 MD5 校验..."

MD5_FILE="${NEW_SDK_NAME}.md5"

if command -v md5sum &> /dev/null; then
    md5sum "${NEW_SDK_NAME}" > "${MD5_FILE}"
elif command -v md5 &> /dev/null; then
    # macOS 的 md5 命令，需要重新格式化输出
    MD5_HASH=$(md5 -q "${NEW_SDK_NAME}")
    echo "${MD5_HASH}  ${NEW_SDK_NAME}" > "${MD5_FILE}"
else
    echo "  ⚠ 警告: 未找到 md5sum 或 md5 命令"
fi

if [ -f "${MD5_FILE}" ]; then
    echo "  ✓ MD5 校验文件已生成"
    cat "${MD5_FILE}"
fi

# ============================================
# 步骤 6: 显示最终结果
# ============================================
echo ""
echo "步骤 6: 最终结果"
echo "=========================================="
ls -lh "${NEW_SDK_NAME}" "${MD5_FILE}" 2>/dev/null
echo "=========================================="

# 验证 zip 文件
echo ""
echo "步骤 7: 验证 zip 文件完整性..."
if unzip -t "${NEW_SDK_NAME}" > /dev/null 2>&1; then
    echo "  ✓ ZIP 文件完整性验证通过"
else
    echo "  ⚠ 警告: ZIP 文件可能存在问题"
fi

echo ""
echo "✅ 打包完成！"
echo ""
echo "生成的文件:"
echo "  原始文件名: ${ORIGINAL_SDK_NAME}"
echo "  新文件名: ${NEW_SDK_NAME}"
echo "  MD5 文件: ${MD5_FILE}"
echo ""
echo "文件位置: ${SDK_ROOT_DIR}"

