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

