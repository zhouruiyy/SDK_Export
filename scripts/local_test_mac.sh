#!/bin/bash

# Mac SDK 本地测试脚本
# 用途：在本地测试完整的 Mac SDK 处理流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 参数
SDK_URL=$1
SDK_VERSION=$2

if [ -z "${SDK_URL}" ] || [ -z "${SDK_VERSION}" ]; then
    echo -e "${RED}用法: $0 <SDK_URL> <SDK_VERSION>${NC}"
    echo "示例: $0 \"http://10.80.1.174:8090/.../Agora_Native_SDK_for_Mac_rel.v4.4.30_25321_FULL_20250820_1052_846534.zip\" \"4.4.30\""
    exit 1
fi

# 目录配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
WORK_DIR="${PROJECT_ROOT}/build_test_mac"
ORIGINAL_SDK_DIR="${WORK_DIR}/original_sdk"
EXTRA_RESOURCES_DIR="${PROJECT_ROOT}/extra_resources"
PYTHON_SCRIPT="${PROJECT_ROOT}/scripts/framework_to_dylib.py"

echo "=========================================="
echo "Mac SDK 本地测试"
echo "=========================================="
echo "SDK URL: ${SDK_URL}"
echo "SDK 版本: ${SDK_VERSION}"
echo "工作目录: ${WORK_DIR}"
echo "=========================================="

# ============================================
# 步骤 1: 清理并创建工作目录
# ============================================
echo ""
echo -e "${YELLOW}步骤 1: 准备工作目录...${NC}"

if [ -d "${WORK_DIR}" ]; then
    echo "清理旧的构建目录..."
    rm -rf "${WORK_DIR}"
fi

mkdir -p "${WORK_DIR}"
mkdir -p "${ORIGINAL_SDK_DIR}"

echo -e "${GREEN}✓ 工作目录准备完成${NC}"

# ============================================
# 步骤 2: 下载原始 SDK
# ============================================
echo ""
echo -e "${YELLOW}步骤 2: 下载原始 SDK...${NC}"

ORIGINAL_SDK_NAME=$(basename "${SDK_URL}")
ORIGINAL_SDK_ZIP="${WORK_DIR}/original_sdk.zip"

echo "下载 ${ORIGINAL_SDK_NAME}..."
curl -L -o "${ORIGINAL_SDK_ZIP}" "${SDK_URL}"

if [ ! -f "${ORIGINAL_SDK_ZIP}" ]; then
    echo -e "${RED}❌ 下载失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 下载完成: $(du -h "${ORIGINAL_SDK_ZIP}" | cut -f1)${NC}"

# ============================================
# 步骤 3: 解压原始 SDK
# ============================================
echo ""
echo -e "${YELLOW}步骤 3: 解压原始 SDK...${NC}"

unzip -q "${ORIGINAL_SDK_ZIP}" -d "${ORIGINAL_SDK_DIR}"

echo "解压后的目录结构:"
ls -lh "${ORIGINAL_SDK_DIR}"

echo -e "${GREEN}✓ 解压完成${NC}"

# ============================================
# 步骤 4: 检查 Python 脚本
# ============================================
echo ""
echo -e "${YELLOW}步骤 4: 检查 Python 脚本...${NC}"

if [ ! -f "${PYTHON_SCRIPT}" ]; then
    echo -e "${RED}❌ 错误: 找不到 Python 脚本: ${PYTHON_SCRIPT}${NC}"
    echo ""
    echo "请将 framework_to_dylib.py 放到 ${SCRIPT_DIR}/ 目录下"
    exit 1
fi

echo -e "${GREEN}✓ Python 脚本存在${NC}"

# 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到 python3${NC}"
    exit 1
fi

echo "Python 版本: $(python3 --version)"

# ============================================
# 步骤 5: 处理 SDK
# ============================================
echo ""
echo -e "${YELLOW}步骤 5: 处理 Mac SDK...${NC}"

bash "${SCRIPT_DIR}/process_sdk_mac.sh" \
    "${ORIGINAL_SDK_DIR}" \
    "${EXTRA_RESOURCES_DIR}" \
    "${PYTHON_SCRIPT}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ SDK 处理失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ SDK 处理完成${NC}"

# ============================================
# 步骤 6: 打包 SDK
# ============================================
echo ""
echo -e "${YELLOW}步骤 6: 打包 SDK...${NC}"

bash "${SCRIPT_DIR}/package_sdk_mac.sh" \
    "${ORIGINAL_SDK_DIR}" \
    "${ORIGINAL_SDK_NAME}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 打包失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 打包完成${NC}"

# ============================================
# 步骤 7: 移动最终文件到工作目录根目录
# ============================================
echo ""
echo -e "${YELLOW}步骤 7: 整理输出文件...${NC}"

mv ${ORIGINAL_SDK_DIR}/agora_sdk_mac_*.zip* ${WORK_DIR}/ 2>/dev/null || true

echo -e "${GREEN}✓ 文件整理完成${NC}"

# ============================================
# 步骤 8: 生成测试报告
# ============================================
echo ""
echo -e "${YELLOW}步骤 8: 生成测试报告...${NC}"

REPORT_FILE="${WORK_DIR}/test_report.txt"

cat > "${REPORT_FILE}" <<EOF
========================================
Mac SDK 处理测试报告
========================================

测试时间: $(date '+%Y-%m-%d %H:%M:%S')
原始 SDK: ${ORIGINAL_SDK_NAME}
SDK 版本: ${SDK_VERSION}

----------------------------------------
处理步骤
----------------------------------------
1. ✓ 下载原始 SDK
2. ✓ 解压 SDK
3. ✓ 将 xcframework 转换为 dylib
4. ✓ 添加 RTM SDK dylib 文件
   - libagora_rtm_sdk_c.dylib
   - libAgoraRtmKit.dylib
   - libuap_aed.dylib
5. ✓ 清理隐藏文件
6. ✓ 压缩 agora_sdk 目录
7. ✓ 生成新文件名

----------------------------------------
生成的文件
----------------------------------------
EOF

ls -lh "${WORK_DIR}"/agora_sdk_mac_*.zip* >> "${REPORT_FILE}" 2>/dev/null || echo "未找到生成的文件" >> "${REPORT_FILE}"

cat >> "${REPORT_FILE}" <<EOF

----------------------------------------
文件验证
----------------------------------------
EOF

# 检查生成的 zip 文件
NEW_ZIP_FILE=$(ls "${WORK_DIR}"/agora_sdk_mac_*.zip 2>/dev/null | head -1)

if [ -f "${NEW_ZIP_FILE}" ]; then
    echo "✓ 找到生成的 ZIP 文件: $(basename "${NEW_ZIP_FILE}")" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    echo "ZIP 文件内容预览:" >> "${REPORT_FILE}"
    unzip -l "${NEW_ZIP_FILE}" | head -30 >> "${REPORT_FILE}"
    
    echo "" >> "${REPORT_FILE}"
    echo "dylib 文件列表:" >> "${REPORT_FILE}"
    unzip -l "${NEW_ZIP_FILE}" | grep "\.dylib" >> "${REPORT_FILE}"
    
    echo "" >> "${REPORT_FILE}"
    echo "RTM 相关文件检查:" >> "${REPORT_FILE}"
    unzip -l "${NEW_ZIP_FILE}" | grep -E '(rtm|uap_aed)' >> "${REPORT_FILE}" || echo "⚠ 未找到 RTM 相关文件" >> "${REPORT_FILE}"
else
    echo "❌ 未找到生成的 ZIP 文件" >> "${REPORT_FILE}"
fi

cat >> "${REPORT_FILE}" <<EOF

========================================
测试完成
========================================
所有文件位于: ${WORK_DIR}
EOF

echo -e "${GREEN}✓ 报告生成完成${NC}"

# ============================================
# 显示最终结果
# ============================================
echo ""
echo "=========================================="
echo -e "${GREEN}✅ 测试完成！${NC}"
echo "=========================================="
cat "${REPORT_FILE}"
echo "=========================================="
echo ""
echo "生成的文件:"
ls -lh "${WORK_DIR}"/agora_sdk_mac_* 2>/dev/null || echo "  (未找到)"
echo ""
echo "详细报告: ${REPORT_FILE}"
echo "=========================================="

