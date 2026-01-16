```
嘗試寫一個 shell script 腳本，用來印出 EC2 相關資訊。

提供您的腳本（github repo）。

使用方式及輸出格式如下：
$ sh ./ec2_info.sh i-0123456789abcdef0

=== EC2 Information ===
Instance ID : i-0123456789abcdef0
Instance Type : t3.micro
State : running
Launch Time : 2025-01-01T10:00:00Z
VPC ID : vpc-12345678
Subnet ID : subnet-98765432
Private IP : 10.0.1.25
Public IP : 3.115.22.53
```

使用 **Git Bash** 是在 Windows 上跑 Shell Script 最標準、最少雷的做法。

### 步驟一：開啟 Git Bash
1. 點擊 Windows 左下角的 **「開始」** 選單。
2. 搜尋 **"Git Bash"**。
3. 點擊開啟（會看到一個類似 CMD 的視窗，但字體顏色通常比較豐富）。

### 步驟二：前往檔案所在的資料夾

* 在 Git Bash 中，路徑寫法會稍微不一樣（`C:` 會變成 `/c/`）。
* 請輸入以下指令切換目錄：
```bash
cd /c/Users/Steven/Desktop
```
* <img width="577" height="367" alt="image" src="https://github.com/user-attachments/assets/ac3456e5-08a5-40f3-846f-8b179930302d" />

### 步驟三：確認檔案是否存在

* 我們先檢查一下檔案是不是真的在那裡，且檔名正確（沒有多出 `.txt`）。
```bash
ls -l ec2_info.sh
```
* <img width="577" height="367" alt="image" src="https://github.com/user-attachments/assets/ae59ef3e-28cf-431c-a814-df270aac6c46" />

### 步驟四：賦予執行權限 (chmod)

```bash
chmod +x ec2_info.sh
```
*(執行後通常不會有回傳訊息，沒有消息就是好消息)*

### 步驟五：執行腳本

* 現在可以用標準的 Linux 方式執行腳本了。把後面的 `i-xxxxx` 換成您實際的 EC2 Instance ID。
```bash
./ec2_info.sh i-04ebcdef44a5e5745
```
* <img width="577" height="367" alt="image" src="https://github.com/user-attachments/assets/8564caa2-9fb5-4e4c-8edd-8121178b350b" />

### 腳本內容

```bash
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
```
