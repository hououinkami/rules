#!/bin/bash

# 确保使用bash 4+版本，因为关联数组需要这个版本
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "需要 Bash 4.0 或更高版本才能使用关联数组"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取仓库根目录（脚本目录的上一级）
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# 声明关联数组
declare -A domainset=(
    [apple]="https://ruleset.skk.moe/List/domainset/apple_cdn.conf"
    [reject]="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/discretion/dns.txt https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-surge2.txt https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/tracking-protection-filter.txt"
)
declare -A ruleset=(
    [apple]="https://ruleset.skk.moe/List/non_ip/apple_services.conf"
)

# 创建目录（如果不存在）
mkdir -p "$REPO_ROOT/domainset"
mkdir -p "$REPO_ROOT/ruleset"

# 处理domainset数组
echo "处理 domainset 数组..."
for key in "${!domainset[@]}"; do
    urls="${domainset[$key]}"
    output_file="$REPO_ROOT/domainset/${key}.list"
    
    echo "处理键: $key"
    echo "输出到文件: $output_file"
    
    # 清空或创建输出文件
    > "$output_file"
    
    # 遍历该键对应的所有URL
    for url in $urls; do
        echo "获取 URL: $url"
        
        # 使用curl获取URL内容，然后用grep过滤掉以#开头的行，并追加到输出文件
        curl -s "$url" | grep -v "^#" >> "$output_file"
    done
    
    echo "已保存 $output_file"
    echo "------------------------"
done

# 处理ruleset数组
echo "处理 ruleset 数组..."
for key in "${!ruleset[@]}"; do
    urls="${ruleset[$key]}"
    output_file="$REPO_ROOT/ruleset/${key}.list"
    
    echo "处理键: $key"
    echo "输出到文件: $output_file"
    
    # 清空或创建输出文件
    > "$output_file"
    
    # 遍历该键对应的所有URL
    for url in $urls; do
        echo "获取 URL: $url"
        
        # 使用curl获取URL内容，然后用grep过滤掉以#开头的行，并追加到输出文件
        curl -s "$url" | grep -v "^#" >> "$output_file"
    done
    
    echo "已保存 $output_file"
    echo "------------------------"
done

echo "所有处理完成!"
