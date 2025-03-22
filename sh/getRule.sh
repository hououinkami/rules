#!/bin/bash

# 导入
source ./setConvert.sh

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取仓库根目录（脚本目录的上一级）
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# 声明关联数组
declare -A domainset=(
    [Apple]="https://ruleset.skk.moe/List/domainset/apple_cdn.conf"
    [Reject]="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/discretion/dns.txt
        https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-surge2.txt
        https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/tracking-protection-filter.txt"
    [Speedtest]="https://ruleset.skk.moe/List/domainset/speedtest.conf"
    [Proxy]="https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/proxy.txt"
    [Direct]="https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/direct.txt"
)
declare -A ruleset=(
    [Apple]="https://ruleset.skk.moe/List/non_ip/apple_services.conf"
    [Japan]="https://raw.githubusercontent.com/dler-io/Rules/refs/heads/main/Surge/Surge%203/Provider/Media/Spotify.list
        https://raw.githubusercontent.com/dler-io/Rules/refs/heads/main/Surge/Surge%203/Provider/PayPal.list"
    [Reject]="https://raw.githubusercontent.com/limbopro/Adblock4limbo/main/Adblock4limbo_surge.list"
    [AI]="https://raw.githubusercontent.com/dler-io/Rules/refs/heads/main/Surge/Surge%203/Provider/AI%20Suite.list"
    [Telegram]="https://ruleset.skk.moe/List/ip/telegram.conf"
    [Direct]="https://ruleset.skk.moe/List/ip/china_ip.conf"
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
    echo -n > "$output_file"
    
    # 遍历该键对应的所有URL
    for url in $(echo $urls); do
        echo "获取 URL: $url"
        
        # 使用curl获取URL内容，清除多余空行，并追加到输出文件
        curl -s "$url" | grep -v "^[[:space:]]*$" >> "$output_file"
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
    echo -n > "$output_file"
    
    # 遍历该键对应的所有URL
    for url in $(echo $urls); do
        echo "获取 URL: $url"
        
        # 使用curl获取URL内容，清除多余空行，并追加到输出文件
        # curl -s "$url" | grep -v "^[[:space:]]*$" >> "$output_file"
        curl -s "$url" | grep -v "^[[:space:]]*$" | awk '{
            if ($0 ~ /^IP-CIDR/ && $0 !~ /no-resolve$/) {
                print $0 ",no-resolve";
            } else {
                print $0;
            }
        }' >> "$output_file"

    done
    
    echo "已保存 $output_file"
    echo "------------------------"
done

echo "所有处理完成!"
