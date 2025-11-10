#!/bin/bash

# 本地测试脚本 - Agora SDK 增强打包
# 用于在本地环境测试 SDK 处理流程（不上传到 CDN）

set -e

echo "=========================================="
echo "Agora SDK 增强打包 - 本地测试"
echo "=========================================="

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <SDK_ZIP_URL> [SDK_VERSION]"
    echo ""
    echo "示例:"
    echo "  $0 http://10.80.1.174:8090/agora_sdk/.../Agora_Native_SDK_xxx.zip 4.4.32.150"
    echo ""
    exit 1
fi

SDK_ZIP_URL=$1
SDK_VERSION=${2:-"test"}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 从 URL 中提取原始文件名
ORIGINAL_SDK_NAME=$(basename "${SDK_ZIP_URL}")

echo "项目根目录: ${PROJECT_ROOT}"
echo "SDK URL: ${SDK_ZIP_URL}"
echo "SDK 版本: ${SDK_VERSION}"
echo "原始文件名: ${ORIGINAL_SDK_NAME}"
echo "=========================================="

# 创建临时工作目录
WORK_DIR="${PROJECT_ROOT}/build_test"
ORIGINAL_SDK_DIR="${WORK_DIR}/original_sdk"

echo ""
echo "步骤 1/5: 清理并创建工作目录..."
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
mkdir -p ${ORIGINAL_SDK_DIR}

echo ""
echo "步骤 2/5: 下载原始 SDK..."
cd ${WORK_DIR}
echo "正在下载... (这可能需要一些时间)"
curl -L -o original_sdk.zip "${SDK_ZIP_URL}"

if [ ! -f original_sdk.zip ]; then
    echo "❌ 错误：SDK 下载失败"
    exit 1
fi

echo "✅ 下载完成，文件大小:"
ls -lh original_sdk.zip

echo ""
echo "步骤 3/5: 解压 SDK..."
unzip -q original_sdk.zip -d ${ORIGINAL_SDK_DIR}
echo "✅ 解压完成"
echo "解压后的目录结构:"
ls -lh ${ORIGINAL_SDK_DIR}

echo ""
echo "步骤 4/5: 处理 SDK（添加 RTM 库和头文件）..."
export BUILD_NUMBER=0
export BUILD_URL="本地测试"
${SCRIPT_DIR}/process_sdk.sh \
    "${ORIGINAL_SDK_DIR}" \
    "${PROJECT_ROOT}/extra_resources"

echo ""
echo "步骤 5/5: 打包 agora_sdk 为 zip..."
${SCRIPT_DIR}/package_sdk.sh \
    "${ORIGINAL_SDK_DIR}" \
    "${ORIGINAL_SDK_NAME}"

# 移动生成的文件到 WORK_DIR
# 新的 Linux SDK 文件名格式: agora_rtc_sdk_x86_64-linux-gnu-*
mv ${ORIGINAL_SDK_DIR}/agora_rtc_sdk_*.zip* ${WORK_DIR}/ 2>/dev/null || true

echo ""
echo "✅ 打包完成！"
echo "=========================================="
echo "生成的文件:"
ls -lh ${WORK_DIR}/*.zip ${WORK_DIR}/*.md5 2>/dev/null

# 获取生成的新文件名
NEW_ZIP_FILE=$(ls ${WORK_DIR}/agora_rtc_sdk_*.zip 2>/dev/null | head -1)
NEW_ZIP_NAME=$(basename "${NEW_ZIP_FILE}" 2>/dev/null || echo "未生成")

# 生成测试报告
cat > ${WORK_DIR}/test_report.txt <<EOF
========================================
Agora SDK 增强打包 - 本地测试报告
========================================
测试时间: $(date '+%Y-%m-%d %H:%M:%S')
SDK 版本: ${SDK_VERSION}
原始 SDK URL: ${SDK_ZIP_URL}
原始文件名: ${ORIGINAL_SDK_NAME}
新文件名: ${NEW_ZIP_NAME}
文件路径: ${NEW_ZIP_FILE}
文件大小: $(du -h ${NEW_ZIP_FILE} 2>/dev/null | cut -f1 || echo "N/A")

处理内容:
【删除的文件】
- libagora_mcc_ysd_extension.so
- libagora_stt_ag_extension.so
- libagora_stt_ms_extension.so

【添加的文件】
- RTM SDK 库文件到 sdk/ 目录:
  * libagora_rtm_sdk_c.so
  * libagora_rtm_sdk.so
  * libagora_uap_aed.so
- RTM SDK 头文件目录到 sdk/ 目录:
  * agora_rtm_sdk_c/
- VAD 头文件:
  * include/c/api2/vad.h

【其他处理】
- 目录重命名: sdk -> agora_sdk
- 清理隐藏文件: .DS_Store 等
- 文件名格式: agora_rtc_sdk_x86_64-linux-gnu-v{完整版本号}.zip (不含 _external/_internal 后缀)

验证:
$(unzip -t ${NEW_ZIP_FILE} > /dev/null 2>&1 && echo "✓ ZIP 文件完整性验证通过" || echo "✗ ZIP 文件可能存在问题")

MD5:
$(cat ${NEW_ZIP_FILE}.md5 2>/dev/null || echo "未生成")
========================================
EOF

cat ${WORK_DIR}/test_report.txt

echo ""
echo "=========================================="
echo "✅ 本地测试完成！"
echo "=========================================="
echo ""
echo "生成的文件位于: ${WORK_DIR}/"
echo "  - ${NEW_ZIP_NAME}"
echo "  - ${NEW_ZIP_NAME}.md5"
echo "  - test_report.txt"
echo ""
echo "可以解压验证:"
echo "  unzip -l ${NEW_ZIP_FILE} | grep -E '(agora_sdk|rtm|vad)'"
echo ""
echo "验证删除的文件:"
echo "  unzip -l ${NEW_ZIP_FILE} | grep -E '(mcc_ysd|stt_ag|stt_ms)' || echo '✓ 已成功删除'"
echo ""
echo "如需清理测试文件，运行："
echo "  rm -rf ${WORK_DIR}"
echo ""

