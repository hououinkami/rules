#!/bin/bash

# 定义转换函数
domain2rule() {
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
        # 如果没有指定输出文件，则修改源文件
        # 使用临时文件避免在读取时同时写入的问题
        local TEMP_FILE=$(mktemp)
        echo -e "$output" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$INPUT_FILE"
        echo "已更新源文件 '$INPUT_FILE'"
    fi
}

rule2domain() {
    local INPUT_FILE="$1"
    local OUTPUT_FILE="$2"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "错误: 输入文件 '$INPUT_FILE' 不存在" >&2
        return 1
    fi
    
    # 准备输出
    local output=""
    
    # 处理rule set格式
    while IFS= read -r line; do
        # 跳过空行
        if [[ -z "$line" ]]; then
            output+="\n"
            continue
        fi
        
        # 保留注释行
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            output+="$line\n"
            continue
        fi
        
        # 移除可能的前导和尾随空白
        clean_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # 处理DOMAIN开头的行
        if [[ "$clean_line" == DOMAIN,* ]]; then
            # 删除"DOMAIN,"前缀
            domain=$(echo "$clean_line" | sed 's/^DOMAIN,//')
            output+="$domain\n"
        # 处理DOMAIN-SUFFIX开头的行
        elif [[ "$clean_line" == DOMAIN-SUFFIX,* ]]; then
            # 将"DOMAIN-SUFFIX,"替换为"."
            domain=$(echo "$clean_line" | sed 's/^DOMAIN-SUFFIX,/\./')
            output+="$domain\n"
        # 只保留注释行（以#开头的行）
        elif [[ "$clean_line" =~ ^[[:space:]]*# ]]; then
            output+="$clean_line\n"
        fi
    done < "$INPUT_FILE"
    
    # 输出结果
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$output" > "$OUTPUT_FILE"
    else
        # 如果没有指定输出文件，则修改源文件
        # 使用临时文件避免在读取时同时写入的问题
        local TEMP_FILE=$(mktemp)
        echo -e "$output" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$INPUT_FILE"
        echo "已更新源文件 '$INPUT_FILE'"
    fi
}

removeDomains() {
    local INPUT_FILE="$1"
    local OUTPUT_FILE="$2"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "错误: 输入文件 '$INPUT_FILE' 不存在" >&2
        return 1
    fi
    
    # 准备输出
    local output=""
    
    # 处理文件，删除特定规则行
    while IFS= read -r line; do
        # 移除可能的前导和尾随空白用于判断
        clean_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # 如果行以DOMAIN,或DOMAIN-SUFFIX,开头，则跳过该行
        if [[ "$clean_line" == DOMAIN,* || "$clean_line" == DOMAIN-SUFFIX,* ]]; then
            continue
        fi
        
        # 保留其他所有行
        output+="$line\n"
    done < "$INPUT_FILE"
    
    # 输出结果
    if [ -n "$OUTPUT_FILE" ]; then
        # 如果指定了输出文件，写入到该文件
        echo -e "$output" > "$OUTPUT_FILE"
    else
        # 如果没有指定输出文件，则修改源文件
        # 使用临时文件避免在读取时同时写入的问题
        local TEMP_FILE=$(mktemp)
        echo -e "$output" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$INPUT_FILE"
        echo "已更新源文件 '$INPUT_FILE'"
    fi
}

processRules() {
    # 接收参数作为key值列表
    local keys=("$@")
    
    for key in "${keys[@]}"; do
        # 检查ruleset文件夹中是否存在key.list文件
        if [[ -f "ruleset/${key}.list" ]]; then
            echo "处理 ${key}.list 文件..."
            
            # 执行您指定的函数生成key.tmp和新的key.list
            # 替换下面这行为您实际需要执行的函数
            rule2domain "ruleset/${key}.list" "ruleset/${key}.tmp"
            removeDomains "ruleset/${key}.list"
            
            # 将key.tmp的内容追加到domainset文件夹中的key.list文件
            if [[ -f "ruleset/${key}.tmp" ]]; then
                # 如果domainset文件夹中不存在key.list，则创建它
                mkdir -p "domainset" # 确保目录存在
                if [[ ! -f "domainset/${key}.list" ]]; then
                    touch "domainset/${key}.list"
                fi
                
                # 追加内容到domainset中的文件
                cat "ruleset/${key}.tmp" >> "domainset/${key}.list"
                rm -rf "ruleset/${key}.tmp"
                echo "${key}.tmp 内容已追加到 domainset/${key}.list"
            else
                echo "警告: ruleset/${key}.tmp 文件不存在，跳过追加操作"
            fi
        else
            echo "警告: ruleset/${key}.list 文件不存在，跳过处理"
        fi
    done
}