#!/bin/bash

# SDK 处理脚本 - Agora SDK 增强版
# 用途：
# 1. 添加 RTM SDK 的 .so 库文件到 sdk 目录
# 2. 添加 agora_rtm_sdk_c 头文件目录到 sdk 目录
# 3. 添加 vad.h 到 include/c/api2/ 目录
# 4. 将 sdk 目录重命名为 agora_sdk

set -e  # 遇到错误立即退出

# 参数
ORIGINAL_SDK_DIR=$1      # 解压后的原始 SDK 根目录
EXTRA_RESOURCES_DIR=$2   # 额外资源目录

echo "=========================================="
echo "开始处理 Agora SDK"
echo "=========================================="
echo "原始 SDK 目录: ${ORIGINAL_SDK_DIR}"
echo "额外资源目录: ${EXTRA_RESOURCES_DIR}"
echo "=========================================="

# 自动查找 sdk 目录
echo "正在查找 sdk 目录..."
SDK_DIR=$(find "${ORIGINAL_SDK_DIR}" -name "sdk" -type d | head -1)

if [ -z "${SDK_DIR}" ] || [ ! -d "${SDK_DIR}" ]; then
    echo "❌ 错误: 找不到 sdk 目录"
    echo "尝试查找的路径: ${ORIGINAL_SDK_DIR}"
    find "${ORIGINAL_SDK_DIR}" -maxdepth 3 -type d
    exit 1
fi

echo "✓ 找到 SDK 目录: ${SDK_DIR}"

# 确定根目录（用于查找 include 目录）
SDK_ROOT_DIR=$(dirname "${SDK_DIR}")
echo "SDK 根目录: ${SDK_ROOT_DIR}"

# ============================================
# 步骤 1: 删除原 SDK 中的特定 .so 文件
# ============================================
echo ""
echo "步骤 1: 删除原 SDK 中不需要的库文件..."

FILES_TO_DELETE=(
    "libagora_mcc_ysd_extension.so"
    "libagora_stt_ag_extension.so"
    "libagora_stt_ms_extension.so"
)

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "${SDK_DIR}/${file}" ]; then
        echo "  ✓ 删除 ${file}"
        rm -f "${SDK_DIR}/${file}"
    else
        echo "  ℹ ${file} 不存在，跳过"
    fi
done

# ============================================
# 步骤 2: 添加 RTM SDK 的 .so 文件到 sdk 目录
# ============================================
echo ""
echo "步骤 2: 添加 RTM SDK 库文件到 sdk 目录..."

EXTRA_LIBS_DIR="${EXTRA_RESOURCES_DIR}/libs"

if [ -d "${EXTRA_LIBS_DIR}" ]; then
    # 添加指定的 .so 文件
    SO_FILES=(
        "libagora_rtm_sdk_c.so"
        "libagora_rtm_sdk.so"
        "libagora_uap_aed.so"
    )
    
    for so_file in "${SO_FILES[@]}"; do
        if [ -f "${EXTRA_LIBS_DIR}/${so_file}" ]; then
            echo "  ✓ 添加 ${so_file}"
            cp "${EXTRA_LIBS_DIR}/${so_file}" "${SDK_DIR}/"
        else
            echo "  ⚠ 警告: 未找到 ${so_file}"
        fi
    done
    
    # 如果有其他 .so 文件也一并复制
    find "${EXTRA_LIBS_DIR}" -name "*.so" -type f | while read so_file; do
        filename=$(basename "$so_file")
        if [[ ! " ${SO_FILES[@]} " =~ " ${filename} " ]]; then
            echo "  ✓ 添加额外的库: ${filename}"
            cp "$so_file" "${SDK_DIR}/"
        fi
    done
else
    echo "  ⚠ 警告: 额外库目录不存在: ${EXTRA_LIBS_DIR}"
fi

# ============================================
# 步骤 3: 添加 agora_rtm_sdk_c 头文件目录到 sdk 目录
# ============================================
echo ""
echo "步骤 3: 添加 agora_rtm_sdk_c 头文件目录到 sdk 目录..."

RTM_HEADERS_DIR="${EXTRA_RESOURCES_DIR}/agora_rtm_sdk_c"

if [ -d "${RTM_HEADERS_DIR}" ]; then
    echo "  ✓ 复制 agora_rtm_sdk_c 目录"
    cp -r "${RTM_HEADERS_DIR}" "${SDK_DIR}/"
    echo "  已添加的头文件:"
    find "${SDK_DIR}/agora_rtm_sdk_c" -name "*.h" -o -name "*.hpp" | sed 's/^/    - /'
else
    echo "  ⚠ 警告: 未找到 agora_rtm_sdk_c 目录: ${RTM_HEADERS_DIR}"
fi

# ============================================
# 步骤 4: 添加 vad.h 到 include/c/api2/ 目录
# ============================================
echo ""
echo "步骤 4: 添加 vad.h 到 include/c/api2/ 目录..."

# 检查 include/c/api2 目录（在 sdk 目录下）
INCLUDE_API2_DIR="${SDK_DIR}/include/c/api2"

if [ ! -d "${INCLUDE_API2_DIR}" ]; then
    echo "  ⚠ 警告: include/c/api2 目录不存在，尝试创建..."
    mkdir -p "${INCLUDE_API2_DIR}"
fi

VAD_HEADER="${EXTRA_RESOURCES_DIR}/headers/vad.h"

if [ -f "${VAD_HEADER}" ]; then
    echo "  ✓ 添加 vad.h 到 include/c/api2/"
    cp "${VAD_HEADER}" "${INCLUDE_API2_DIR}/"
elif [ -f "${EXTRA_RESOURCES_DIR}/vad.h" ]; then
    echo "  ✓ 添加 vad.h 到 include/c/api2/"
    cp "${EXTRA_RESOURCES_DIR}/vad.h" "${INCLUDE_API2_DIR}/"
else
    echo "  ⚠ 警告: 未找到 vad.h 文件"
fi

# ============================================
# 步骤 5: 添加其他额外的头文件（可选）
# ============================================
echo ""
echo "步骤 5: 检查是否有其他额外头文件..."

EXTRA_HEADERS_DIR="${EXTRA_RESOURCES_DIR}/headers"

if [ -d "${EXTRA_HEADERS_DIR}" ]; then
    # 查找除 vad.h 外的其他头文件
    OTHER_HEADERS=$(find "${EXTRA_HEADERS_DIR}" -type f \( -name "*.h" -o -name "*.hpp" \) ! -name "vad.h")
    
    if [ -n "$OTHER_HEADERS" ]; then
        echo "  发现其他头文件，添加到 sdk 目录:"
        echo "$OTHER_HEADERS" | while read header_file; do
            filename=$(basename "$header_file")
            echo "    ✓ 添加 ${filename}"
            cp "$header_file" "${SDK_DIR}/"
        done
    else
        echo "  ℹ 无其他额外头文件"
    fi
fi

# ============================================
# 步骤 6: 重命名 sdk 为 agora_sdk
# ============================================
echo ""
echo "步骤 6: 重命名 sdk 目录为 agora_sdk..."

AGORA_SDK_DIR="${ORIGINAL_SDK_DIR}/agora_sdk"

if [ -d "${AGORA_SDK_DIR}" ]; then
    echo "  ⚠ agora_sdk 目录已存在，先删除..."
    rm -rf "${AGORA_SDK_DIR}"
fi

mv "${SDK_DIR}" "${AGORA_SDK_DIR}"
echo "  ✓ 已重命名: sdk -> agora_sdk"

# ============================================
# 步骤 7: 显示最终的 agora_sdk 目录结构
# ============================================
echo ""
echo "步骤 7: 显示 agora_sdk 目录结构..."
echo "=========================================="
echo "agora_sdk 目录内容:"
ls -lh "${AGORA_SDK_DIR}" | head -20
echo ""
echo "添加的 RTM 库文件:"
ls -lh "${AGORA_SDK_DIR}"/libagora_rtm*.so "${AGORA_SDK_DIR}"/libagora_uap_aed.so 2>/dev/null || echo "  (未找到)"
echo ""
echo "agora_rtm_sdk_c 目录:"
if [ -d "${AGORA_SDK_DIR}/agora_rtm_sdk_c" ]; then
    ls -lh "${AGORA_SDK_DIR}/agora_rtm_sdk_c" | head -10
else
    echo "  (未找到)"
fi
echo ""
echo "include/c/api2/vad.h:"
ls -lh "${INCLUDE_API2_DIR}/vad.h" 2>/dev/null || echo "  (未找到)"
echo "=========================================="

echo ""
echo "✅ SDK 处理完成！"
echo ""
echo "处理后的目录: ${AGORA_SDK_DIR}"

