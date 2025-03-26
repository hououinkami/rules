#!/bin/bash

# 导入
source "$(dirname "$0")/ruleConvert.sh"

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
        
        # 在获取URL内容时处理指定部分
        if [[ "$url" == *"ruleset.skk.moe"* ]]; then
            # 如果URL包含ruleset.skk.moe，过滤掉包含"#"或"ruleset.skk.moe"的行
            content=$(curl -s "$url" | grep -v "#" | grep -v "ruleset.skk.moe")
            # 在content变量前添加注释
            content="# Sukka's Ruleset"$'\n'"$content"
        else
            # 正常获取内容
            content=$(curl -s "$url")
        fi

        # 使用curl获取URL内容，清除多余空行，并追加到输出文件
        echo "$content" | grep -v "^[[:space:]]*$" >> "$output_file"
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
        
        # 在获取URL内容时处理指定部分
        if [[ "$url" == *"ruleset.skk.moe"* ]]; then
            # 如果URL包含ruleset.skk.moe，过滤掉包含"#"或"ruleset.skk.moe"的行
            content=$(curl -s "$url" | grep -v "#" | grep -v "ruleset.skk.moe")
            # 在content变量前添加注释
            content="# Sukka's Ruleset"$'\n'"$content"
        else
            # 正常获取内容
            content=$(curl -s "$url")
        fi

        # 使用curl获取URL内容，清除多余空行，并追加到输出文件
        echo "$content" | grep -v "^[[:space:]]*$" | awk '{
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

# 合并指定的set文件
processRules "Apple"

# 处理自定义规则
echo "开始处理 Kami.list 文件..."

# Kami.list 文件路径
KAMI_FILE="$REPO_ROOT/sh/Kami.list"

# 检查文件是否存在
if [[ ! -f "$KAMI_FILE" ]]; then
    echo "错误: Kami.list 文件不存在于 $KAMI_FILE"
    exit 1
fi

# 初始化变量
CURRENT_SECTION=""
declare -A DOMAIN_CONTENT
declare -A RULE_CONTENT

# 读取 Kami.list 并处理内容
echo "解析 Kami.list 文件..."
while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行和注释行
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # 检查是否是节标题行 [Section]
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        # 提取节名称
        CURRENT_SECTION="${BASH_REMATCH[1]}"
        echo "发现节: $CURRENT_SECTION"
        # 初始化该节的内容变量（如果不存在）
        DOMAIN_CONTENT["$CURRENT_SECTION"]=""
        RULE_CONTENT["$CURRENT_SECTION"]=""
    elif [[ -n "$CURRENT_SECTION" && -n "$line" ]]; then
        # 根据内容格式决定添加到哪个变量
        if [[ "$line" == *","* ]]; then
            # 包含逗号的行添加到ruleset变量
            RULE_CONTENT["$CURRENT_SECTION"]+="${line}"$'\n'
        else
            # 不包含逗号的行（纯URL）添加到domainset变量
            DOMAIN_CONTENT["$CURRENT_SECTION"]+="${line}"$'\n'
        fi
    fi
done < "$KAMI_FILE"

# 处理每个节，将内容添加到相应的列表文件前面
echo "将 Kami.list 内容添加到相应的列表文件..."

# 获取所有节名称
SECTIONS=()
for section in "${!DOMAIN_CONTENT[@]}"; do
    SECTIONS+=("$section")
done

# 处理每个节
for section in "${SECTIONS[@]}"; do
    # 处理domainset部分
    if [[ -n "${DOMAIN_CONTENT[$section]}" ]]; then
        target_file="$REPO_ROOT/domainset/$section.list"
        
        # 检查目标文件是否存在
        if [[ ! -f "$target_file" ]]; then
            echo "警告: 找不到domainset目录下的 $section.list 文件，创建新文件"
            touch "$target_file"
        fi
        
        echo "处理domainset节 $section -> $target_file"
        
        # 读取原始文件内容
        original_content=$(cat "$target_file")
        
        # 将新内容和原始内容合并写入文件
        echo -n "# 自定义规则"$'\n'"${DOMAIN_CONTENT[$section]}$original_content" > "$target_file"
        
        echo "已将 $section 节的URL内容添加到 $target_file 的开头"
    else
        echo "节 $section 没有URL内容，跳过domainset处理"
    fi
    
    # 处理ruleset部分
    if [[ -n "${RULE_CONTENT[$section]}" ]]; then
        target_file="$REPO_ROOT/ruleset/$section.list"
        
        # 检查目标文件是否存在
        if [[ ! -f "$target_file" ]]; then
            echo "警告: 找不到ruleset目录下的 $section.list 文件，创建新文件"
            touch "$target_file"
        fi
        
        echo "处理ruleset节 $section -> $target_file"
        
        # 读取原始文件内容
        original_content=$(cat "$target_file")
        
        # 将新内容和原始内容合并写入文件
        echo -n "# 自定义规则"$'\n'"${RULE_CONTENT[$section]}$original_content" > "$target_file"
        
        echo "已将 $section 节的规则内容添加到 $target_file 的开头"
    else
        echo "节 $section 没有规则内容，跳过ruleset处理"
    fi
done

echo "Kami.list 处理完成!"

echo "所有处理完成!"
