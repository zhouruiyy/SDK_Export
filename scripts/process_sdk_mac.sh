#!/bin/bash

# Mac SDK 处理脚本
# 用途：
# 1. 将 xcframework 转换为 dylib
# 2. 添加 RTM SDK 的 dylib 文件
# 3. 生成 agora_sdk 目录

set -e  # 遇到错误立即退出

# 参数
ORIGINAL_SDK_DIR=$1      # 解压后的原始 SDK 根目录
EXTRA_RESOURCES_DIR=$2   # 额外资源目录
PYTHON_SCRIPT=$3         # framework_to_dylib.py 脚本路径

echo "=========================================="
echo "开始处理 Mac SDK"
echo "=========================================="
echo "原始 SDK 目录: ${ORIGINAL_SDK_DIR}"
echo "额外资源目录: ${EXTRA_RESOURCES_DIR}"
echo "Python 脚本: ${PYTHON_SCRIPT}"
echo "=========================================="

# 查找 libs 目录（包含 xcframework 文件）
echo "正在查找 libs 目录..."
LIBS_DIR=$(find "${ORIGINAL_SDK_DIR}" -type d -name "libs" | head -1)

if [ -z "${LIBS_DIR}" ] || [ ! -d "${LIBS_DIR}" ]; then
    echo "❌ 错误: 找不到 libs 目录"
    exit 1
fi

echo "✓ 找到 libs 目录: ${LIBS_DIR}"

# 创建输出目录
AGORA_SDK_DIR="${ORIGINAL_SDK_DIR}/agora_sdk"
echo ""
echo "创建输出目录: ${AGORA_SDK_DIR}"
mkdir -p "${AGORA_SDK_DIR}"

# ============================================
# 步骤 1: 使用 Python 脚本转换 xcframework 为 dylib
# ============================================
echo ""
echo "步骤 1: 转换 xcframework 为 dylib..."

if [ ! -f "${PYTHON_SCRIPT}" ]; then
    echo "❌ 错误: Python 脚本不存在: ${PYTHON_SCRIPT}"
    exit 1
fi

# 修改 Python 脚本中的路径并运行
# 创建临时脚本
TEMP_SCRIPT="${ORIGINAL_SDK_DIR}/temp_convert.py"
cat > "${TEMP_SCRIPT}" <<EOF
import sys
sys.path.insert(0, '$(dirname "${PYTHON_SCRIPT}")')
from $(basename "${PYTHON_SCRIPT}" .py) import process_xcframeworks

# 处理 xcframework
xcframework_path = "${LIBS_DIR}"
output_path = "${AGORA_SDK_DIR}"

print(f"XCFramework 路径: {xcframework_path}")
print(f"输出路径: {output_path}")

process_xcframeworks(xcframework_path, output_path)
print("✓ 转换完成")
EOF

# 运行 Python 脚本
python3 "${TEMP_SCRIPT}"
rm -f "${TEMP_SCRIPT}"

echo "✓ xcframework 转换完成"
echo "生成的 dylib 文件:"
ls -lh "${AGORA_SDK_DIR}"/*.dylib 2>/dev/null | head -10 || echo "  (未找到 dylib 文件)"

# ============================================
# 步骤 2: 添加 RTM SDK 的 dylib 文件
# ============================================
echo ""
echo "步骤 2: 添加 RTM SDK dylib 文件..."

EXTRA_LIBS_DIR="${EXTRA_RESOURCES_DIR}/libs_mac"

if [ -d "${EXTRA_LIBS_DIR}" ]; then
    # 添加指定的 dylib 文件
    DYLIB_FILES=(
        "libagora_rtm_sdk_c.dylib"
        "libAgoraRtmKit.dylib"
        "libuap_aed.dylib"
    )
    
    for dylib_file in "${DYLIB_FILES[@]}"; do
        if [ -f "${EXTRA_LIBS_DIR}/${dylib_file}" ]; then
            echo "  ✓ 添加 ${dylib_file}"
            cp -p "${EXTRA_LIBS_DIR}/${dylib_file}" "${AGORA_SDK_DIR}/"
        else
            echo "  ⚠ 警告: 未找到 ${dylib_file}"
        fi
    done
    
    # 如果有其他 dylib 文件也一并复制
    find "${EXTRA_LIBS_DIR}" -name "*.dylib" -type f | while read dylib_file; do
        filename=$(basename "$dylib_file")
        if [[ ! " ${DYLIB_FILES[@]} " =~ " ${filename} " ]]; then
            echo "  ✓ 添加额外的库: ${filename}"
            cp -p "$dylib_file" "${AGORA_SDK_DIR}/"
        fi
    done
else
    echo "  ⚠ 警告: 额外库目录不存在: ${EXTRA_LIBS_DIR}"
fi

# ============================================
# 步骤 3: 显示最终的 agora_sdk 目录结构
# ============================================
echo ""
echo "步骤 3: 显示 agora_sdk 目录结构..."
echo "=========================================="
echo "agora_sdk 目录内容:"
ls -lh "${AGORA_SDK_DIR}" | head -20
echo ""
echo "dylib 文件数量: $(ls -1 "${AGORA_SDK_DIR}"/*.dylib 2>/dev/null | wc -l)"
echo ""
echo "添加的 RTM 库文件:"
ls -lh "${AGORA_SDK_DIR}"/libagora_rtm*.dylib "${AGORA_SDK_DIR}"/libuap_aed.dylib 2>/dev/null || echo "  (未找到)"
echo "=========================================="

echo ""
echo "✅ Mac SDK 处理完成！"
echo ""
echo "处理后的目录: ${AGORA_SDK_DIR}"

