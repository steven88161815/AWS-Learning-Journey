#!/bin/bash

# 檢查是否提供 Instance ID 參數
if [ -z "$1" ]; then
    echo "Usage: $0 <instance-id>"
    exit 1
fi

INSTANCE_ID=$1

# 檢查系統是否安裝 AWS CLI
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it and run 'aws configure'."
    exit 1
fi

# 使用 AWS CLI 查詢資訊
# --query: 使用 JMESPath 語法只提取需要的欄位，保證順序
# --output text: 將結果輸出為純文字（Tab 分隔），方便 shell 讀取變數
# 2>/dev/null: 隱藏標準錯誤輸出（例如 ID 不存在時的報錯，改由下方判斷）
INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].[InstanceId, InstanceType, State.Name, LaunchTime, VpcId, SubnetId, PrivateIpAddress, PublicIpAddress]' \
    --output text 2>/dev/null)

# 檢查指令執行結果 (如果 ID 錯誤或沒有權限，INFO 會是空的或指令回傳非 0)
if [ $? -ne 0 ] || [ -z "$INFO" ]; then
    echo "Error: Instance '$INSTANCE_ID' not found or AWS CLI error."
    exit 1
fi

# 將輸出的字串讀入變數
# 這裡利用 read 將 Tab 分隔的字串依序塞入對應變數
read -r id type state time vpc subnet priv_ip pub_ip <<< "$INFO"

# 處理 Public IP 可能為 None 的情況 (例如 Private Subnet 的機器)
if [ "$pub_ip" == "None" ] || [ -z "$pub_ip" ]; then
    pub_ip="N/A"
fi

# 輸出格式化結果
echo "=== EC2 Information ==="
printf "Instance ID   : %s\n" "$id"
printf "Instance Type : %s\n" "$type"
printf "State         : %s\n" "$state"
printf "Launch Time   : %s\n" "$time"
printf "VPC ID        : %s\n" "$vpc"
printf "Subnet ID     : %s\n" "$subnet"
printf "Private IP    : %s\n" "$priv_ip"
printf "Public IP     : %s\n" "$pub_ip"