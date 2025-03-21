#!/bin/bash

# 定义转换函数
setConvert() {
    local INPUT_FILE="$1"
    local OUTPUT_FILE="$2"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "错误: 输入文件 '$INPUT_FILE' 不存在" >&2
        return 1
    fi
    
    # 准备输出
    local output=""
    
    # 处理domain set格式
    while IFS= read -r line; do
        # 跳过空行和注释行
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            output+="$line\n"  # 保留原始注释
            continue
        fi
        
        # 移除可能的前导和尾随空白
        domain=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # 检查是否以点开头
        if [[ "$domain" == .* ]]; then
            # 去掉前导点并转换为DOMAIN-SUFFIX
            domain_without_dot=$(echo "$domain" | sed 's/^\.//')
            output+="DOMAIN-SUFFIX,$domain_without_dot\n"
        else
            # 直接转换为DOMAIN
            output+="DOMAIN,$domain\n"
        fi
    done < "$INPUT_FILE"
    
    output+="\n# 转换完成\n"
    
    # 输出结果
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$output" > "$OUTPUT_FILE"
    else
        echo -e "$output"
    fi
}
