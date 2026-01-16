## VPC 初探

### 嘗試了解 VPC 最基本元件。

`VPC`、`region`、`avaliable zones(az)`、`subnet`、`route table`、`internet gateway`、`nat gateway`。

這幾個名詞是 AWS 網路架構的「七大金剛」。為了好讀又好懂，我們把它們分成 **「物理層級」**、**「邏輯層級」** 和 **「連接層級」** 三類來解釋，並搭配生活化的比喻。

<img width="2878" height="1586" alt="image" src="https://github.com/user-attachments/assets/19944aa3-e68d-4258-a270-5aaced158089" />

#### 1. 物理層級 (實體基礎設施)

這兩個決定了你的機房蓋在哪裡、穩不穩固。

* **Region (區域)**
  * **定義**：AWS 在全球設立資料中心的**地理位置**。例如：東京 (ap-northeast-1)、維吉尼亞北部 (us-east-1)。
  * **比喻**：你想在哪個 **「城市」** 蓋房子。
  * **重點**：Region 之間是完全獨立的，選東京是為了讓台灣使用者的連線速度快（延遲低）。


* **Availability Zone (AZ, 可用區域)**
  * **定義**：同一個 Region 內，**物理上隔離**（獨立電力、冷氣、網路）的資料中心聚落。
  * **比喻**：同一個城市裡的 **「不同大樓」** (A 棟、C 棟)。
  * **重點**：為了 **「高可用性 (High Availability)」**。如果 A 棟大樓停電 (AZ 故障)，C 棟大樓 (另一個 AZ) 通常不會受影響。所以題目才要求你的兩個 Subnet 要放在不同的 Zone。

#### 2. 邏輯層級 (你的虛擬地盤)

這三個決定了你的網路怎麼切分、封包怎麼走。

* **VPC (Virtual Private Cloud)**
  * **定義**：你在 AWS 雲端上劃出來的一個 **「邏輯隔離網路空間」**。這是你的專屬機房，別人的帳號進不來。
  * **比喻**：你是一間跨國公司，在東京這個城市（Region）裡，同時租下了 A 大樓與 C 大樓（AZs）的特定樓層來辦公。雖然物理上分屬不同大樓，但透過專屬的**虛擬內網**連結，對內部員工來說，就像是在同一個大辦公室裡一樣。
  * **範圍**：VPC 是屬於 Region 層級的（跨 AZ，但不跨 Region）。

* **Subnet (子網域)**
  * **定義**：將 VPC 的大 IP 範圍切分成更小的區塊。EC2 機器必須放在 Subnet 裡。
  * **比喻**：辦公室裡的 **「部門隔間」**。例如「對外業務部 (Public Subnet)」和「內部研發部 (Private Subnet)」。
  * **重點**：Subnet 是屬於 AZ 層級的（**一個 Subnet 只能在一個 AZ 裡**，不能跨兩棟樓）。

* **Route Table (路由表)**
  * **定義**：決定封包流向的規則表。每個 Subnet 都必須關聯一張 Route Table。
  * **比喻**：辦公室走廊上的 **「路標指示牌」**。它告訴封包：「想去 Internet？請往左轉找 IGW」、「想找隔壁部門？請直走」。

#### 3. 連接層級 (大門與通道)

這兩個決定了你的機器能不能上網。

* **Internet Gateway (IGW)**
  * **定義**：VPC 連接網際網路的 **「大門」**。
  * **比喻**：辦公室的 **「正門」**。
  * **功能**：支援 **雙向通行**。外面的客人可以進來（如果有開權限），裡面的人也可以出去。
  * **應用**：Public Subnet 的 Route Table 必須指向它，EC2 才能變成 Public EC2。

* **NAT Gateway**
  * **定義**：讓 Private Subnet 的機器可以「單向」連線到網際網路的裝置。
  * **比喻**：辦公室的 **「總機小姐」** 或 **「代購人員」**。
  * **功能**：**單向通行 (Outbound only)**。內部的機器想去 Google 下載更新，把請求交給 NAT Gateway 幫忙抓回來；但外面的駭客無法主動穿過 NAT Gateway 連進來。
  * **應用**：放在 **Public Subnet** 裡，專門服務 Private Subnet 的機器。

<br>

---

<br>

## 【實作題】

### 1. 在東京 region，嘗試創建一個 VPC，其 CIDR 為 10.0.0.0/18，為其創建兩個 subnet 並且其遮罩長度為 20，並且位於不同的 zone，且提供該兩個 subnet 的 CIDR。


這題的目標是規劃出一個私有的網路空間，並將其切割成兩個不同用途的區塊。

#### 第一步：創建 VPC (大蛋糕)

1. 確認右上角區域選在 **Tokyo (ap-northeast-1)**。
2. 進入 **VPC** 控制台，點擊 **Create VPC**。
3. 選擇 **VPC only** (手動建，學習效果最好)。
4. **Name tag**: `MyVPC`。
5. **IPv4 CIDR**: 輸入 `10.0.0.0/18`。
* *解釋：`/18` 代表這個 VPC 總共有 16,384 個 IP 可用。*
6. 點擊 **Create VPC**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/a4107a81-f55c-4263-98b0-cd8ec6abc6ff" />

#### 第二步：創建兩個 Subnet (切小塊)

我們要切出兩個 `/20` 大小的隔間，並且故意放在不同的 AZ 以分散風險。

1. 點擊左側 **Subnets**  **Create subnet**。
2. **VPC ID**: 選擇剛剛建立的 `MyVPC`。
3. **建立第一個 Subnet (未來當 Public 用)**:
* **Subnet name**: `Public-Subnet-1a` (建議名稱帶上 AZ)。
* **Availability Zone**: 選 `ap-northeast-1a`。
* **IPv4 CIDR block**: 輸入 `10.0.0.0/20`。
4. 點擊 **Add new subnet** 按鈕（繼續建第二個）。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/6020c7ca-946e-4ef9-95e3-1d31eef73866" /> 
5. **建立第二個 Subnet (未來當 Private 用)**:
* **Subnet name**: `Private-Subnet-1c`。
* **Availability Zone**: 選 `ap-northeast-1c` (**重點：要跟上面選不同的**)。
* **IPv4 CIDR block**: 輸入 `10.0.16.0/20`。
* 解釋
  * 一個 `/20` 的 Subnet 擁有 **4,096 個 IP**。
    * **Subnet 1 開始**：`10.0.0.0`
    * ... (中間經過了 10.0.1.x, 10.0.2.x ... 一直到 10.0.15.x) ...
    * **Subnet 1 結束**：`10.0.15.255`
  * 因為 **0 ~ 15** 這段區間（共 16 個數）都已經被第一個 Subnet 用光了。
  * 所以，**第二個 Subnet** 必須從下一個數字開始，也就是 **16**。
6. 點擊 **Create subnet**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/fd5a0e56-c0aa-49ef-8224-f63ff5a07932" />

<br>

---

<br>

### 2. 承第一題，為該兩個 subnet 分別創建一個 route table，使其成為 public 跟 private subnet。

這題的關鍵在於理解一個 AWS 的核心定義：

> **什麼叫做 Public Subnet？**
> 答案：只要一個 Subnet 的 Route Table 有一條路指向 **Internet Gateway (IGW)**，它就自動變身為 Public Subnet。

反之，如果沒有指向 IGW，它就是 Private Subnet。

#### 實作步驟流程

我們需要做三件事：

1. **建大門**：創建 Internet Gateway (IGW) 並裝到 VPC 上。
2. **設定 Public 路由**：建立一張表，指引去大門的路，並綁定給 Subnet 1。
3. **設定 Private 路由**：建立一張表，不指引去大門（只在內部互通），綁定給 Subnet 2。

#### 第一步：創建並附加 Internet Gateway (IGW)

沒有大門，路由表指去哪裡都沒用。

1. 在左側選單點擊 **Internet gateways** → **Create internet gateway**。
2. **Name tag**: `MyIGW`。
3. 點擊 **Create internet gateway**。
* <img width="1920" height="454" alt="image" src="https://github.com/user-attachments/assets/2dae35e2-8dde-4966-810a-14391e291b4d" />
4. **附加到 VPC**：
* 剛建好時狀態是 `Detached` (未附加)。
* 點擊右上角的 **Actions**  **Attach to VPC**。
* 選擇 `MyVPC`，點擊 **Attach internet gateway**。
* <img width="1920" height="372" alt="image" src="https://github.com/user-attachments/assets/ba306eb9-25b5-4e42-a647-d25b2f799f8b" />

#### 第二步：創建 Public Route Table

1. 在左側選單點擊 **Route tables** → **Create route table**。
2. **設定基本資料**：
* **Name**: `Public-RT`。
* **VPC**: 選擇 `MyVPC`。
* 點擊 **Create route table**。
* <img width="1920" height="517" alt="image" src="https://github.com/user-attachments/assets/d040cdfd-cc64-4490-98d0-a4f56f77ace5" />

3. **編輯路由 (加路標)**：
* 進入剛剛建好的 `Public-RT`，切換到 **Routes** 分頁  **Edit routes**。
* 點擊 **Add route**。
* **Destination**: 輸入 `0.0.0.0/0` (代表全世界所有 IP)。
* **Target**: 選擇 `Internet Gateway`  選剛剛建的 `MyIGW`。
* 點擊 **Save changes**。
* <img width="1920" height="385" alt="image" src="https://github.com/user-attachments/assets/69c9088d-0546-4cb7-a52a-86ac6dca2bf0" />

4. **關聯 Subnet (指定生效範圍)**：
* 切換到 **Subnet associations** 分頁  **Edit subnet associations**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/141932ad-b722-4c39-bb2a-09eafcc9eeea" />
* 勾選 `Public-Subnet-1a` (我們說好這個要當 Public 的)。
* 點擊 **Save associations**。
* <img width="1920" height="438" alt="image" src="https://github.com/user-attachments/assets/dcbf6fb4-673b-464c-a30d-e36a28e72d4e" />

#### 第三步：創建 Private Route Table

1. 再次點擊 **Create route table**。
2. **設定基本資料**：
* **Name**: `Private-RT`。
* **VPC**: 選擇 `MyVPC`。
* 點擊 **Create route table**。
* <img width="1920" height="517" alt="image" src="https://github.com/user-attachments/assets/c9a4bd63-786c-4aac-95ff-4de77ea332a1" />
3. **編輯路由**：
* **不需要加 IGW**。預設只有一條 `10.0.0.0/18 local`，這代表「VPC 內部互通」，這樣就夠了。
4. **關聯 Subnet**：
* 切換到 **Subnet associations** 分頁  **Edit subnet associations**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/2d3a7f28-c8a2-446d-9bb4-5cf0df236b8a" />
* 勾選 `Private-Subnet-1c`。
* 點擊 **Save associations**。
* <img width="1920" height="438" alt="image" src="https://github.com/user-attachments/assets/96b7a3f2-9b91-44e2-ae93-39baa7a1be1b" />

#### 補充

* Q: 創建 VPC 時不是會自動送一張 Route Table 嗎？ 
* A: 是的，那張叫 Main Route Table。 但為了安全起見，AWS 最佳實踐建議我們不要修改主路由表來當作 Public 用途。我們應該保持主路由表為 Private (僅限內部溝通)，並另外手動建立專用的 Public Route Table。這樣可以防止未來新建立的 Subnet 不小心意外暴露在網際網路上。

#### 📝 對照表

| 路由表名稱 | 關聯的 Subnet | 有無 `0.0.0.0/0` 指向 IGW? | 用途 |
| :----: | :----: | :----: | :----: |
| **Public-RT** | `Public-Subnet-1a` | **有** | 讓機器可以直接擁有公網 IP 上網。 |
| **Private-RT** | `Private-Subnet-1c` | **無** (只有 local) | 機器藏在內網，外面連不進來。 |


* 結果圖示
  * <img width="1920" height="699" alt="image" src="https://github.com/user-attachments/assets/6aa190f3-d8ca-431c-8ce2-d3524bbb6c4d" />
 
<br>

---

<br>

### 3. 承第二題，在兩個 subnet 上分別創建一台 ec2，並且使用 ssh 從自己的 laptop 連上此兩台 ec2，提供你的做法。

這題的目標是：

1. 在 Public Subnet 開一台機器  用自己電腦連進去（證明它是 Public）。
2. 在 Private Subnet 開一台機器  用自己電腦連連看（證明它連不進去）。
3. **進階挑戰**：那我要怎麼連進那台 Private 機器？（透過 Public 機器當跳板）。

#### 第一步：準備 SSH Key Pair (如果你還沒建)

為了方便實驗，我們這次統一用一個 Key 就好。

1. EC2 控制台  **Key Pairs** → **Create key pair**。
2. Name: `VPC-Lab-Key`。
3. Format: `.pem` (Windows CMD/PowerShell 用 `.pem` 也可以，或是用 `.ppk` 給 PuTTY)。
4. 下載並保管好這個檔案。
* <img width="882" height="24" alt="image" src="https://github.com/user-attachments/assets/4b79eef1-4638-4e00-9fd3-ba3df89cdc64" />

#### 第二步：啟動 Public EC2

1. **Launch instances**。
2. **Name**: `Public-EC2`。
3. **OS**: Amazon Linux 2023。
4. **Key pair**: 選 `VPC-Lab-Key`。
5. **Network settings** (這是重點！點擊 Edit)：
* **VPC**: 選擇 `MyVPC`。
* **Subnet**: 選擇 `Public-Subnet-1a`。
* **Auto-assign public IP**: **Enable** (一定要開，不然它就沒有門牌號碼，你也連不進去)。
* **Security group**: 建立新的，名稱 `Allow-SSH`，規則設為 Allow SSH (port 22) from Anywhere (0.0.0.0/0)。
6. 點擊 **Launch instance**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/76840f2f-e6c1-47d5-bfa0-966b004ce83a" />

#### 第三步：啟動 Private EC2

1. 再次 **Launch instances**。
2. **Name**: `Private-EC2`。
3. **OS**: Amazon Linux 2023。
4. **Key pair**: 選 `VPC-Lab-Key`。
5. **Network settings** (點擊 Edit)：
* **VPC**: 選擇 `MyVPC`。
* **Subnet**: 選擇 `Private-Subnet-1c`。
* **Auto-assign public IP**: **Disable** (既然是私有，就不需要公網 IP)。
* **Security group**: 選擇剛剛建的 `Allow-SSH` (讓我們先允許 SSH)。
6. 點擊 **Launch instance**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/9839fe73-418c-4741-b1c9-a426265b95a3" />

#### 第四步：驗證連線 (提供你的做法)

**1. 連線 Public EC2 (應該成功)**

* 取得 Public EC2 的 Public IP (例如 `54.x.x.x`)。
* 在你的終端機執行：
```cmd
ssh -i "path/to/VPC-Lab-Key.pem" ec2-user@54.x.x.x
```
* 結果圖示
  * <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/622582e9-addb-471a-88c1-4e73adabef76" />

**2. 連線 Private EC2 (失敗)**

* 取得 Private EC2 的 Private IP (例如 `10.0.16.x`)。
* 嘗試連線：
  * 你會發現它**沒有 Public IP**，所以你根本不知道要連去哪裡。
  * 就算你有它的 Private IP，直接 ssh 也會 timeout，因為你的電腦在網際網路，連不到它內網的 IP。

**3. 進階：透過 Public EC2 當跳板 (Bastion Host) 連進去**

這是連線 Private 機器最標準且安全的做法。

* **原理**：我們不把私鑰複製到 Public EC2 上（避免遺失風險），而是使用 **SSH Agent Forwarding** 技術，讓 Public EC2 充當「轉接頭」，直接借用你筆電裡的鑰匙來開啟 Private EC2 的門。

* **前置作業：以「系統管理員身分」開啟 CMD**
  * (因為啟動服務需要較高權限，一般視窗會失敗)

* **啟動 SSH Agent 服務 (在你的電腦)**
先設定服務啟動類型，再將其開啟。
```cmd
sc config ssh-agent start= demand
net start ssh-agent
```

* **將金鑰加入代理 (在你的電腦)**
把下載的 `.pem` 鑰匙交給 Agent 保管。
```cmd
ssh-add "C:\Users\Steven\Downloads\VPC-Lab-Key.pem"
```

* **帶著鑰匙連線至 Public EC2 (跳板)**
關鍵參數是 `-A` (Agent Forwarding)，告訴 SSH Client 允許轉發代理資訊。
```cmd
ssh -A ec2-user@<Public-EC2-IP>
```

* **從 Public EC2 跳轉至 Private EC2**
登入 Public EC2 後，直接輸入 SSH 指令連線到 Private IP。**注意：此時不需要再指定 `-i key.pem`**，因為它會自動回頭問你筆電裡的 Agent 要鑰匙。
```bash
ssh ec2-user@<Private-EC2-IP>
```

* 結果圖示
 * <img width="975" height="743" alt="image" src="https://github.com/user-attachments/assets/66831a8d-12fb-474b-b0d7-32788b3835c5" />

#### 補充知識：為什麼需要 SSH Agent？

在透過跳板機 (Public EC2) 連線到內網機器 (Private EC2) 時，我們必須嚴格遵守 **「私鑰不落地 (Private Key never leaves your laptop)」** 的資安原則。

1. **核心概念比較**

| 操作方式 | 做法 | 安全性 | 風險分析 |
| :----: | :----: | :----: | :----: |
| **❌ 錯誤做法** | 將 `.pem` 私鑰檔案**複製**一份上傳到 Public EC2，再從裡面執行 SSH。 | **危險** | Public EC2 暴露在網際網路，一旦被駭客攻破，你的私鑰檔案就會被竊取，駭客將擁有通往內網所有機器的萬能鑰匙。 |
| **✅ 正確做法 (SSH Agent)** | 私鑰檔案**只保留在自己的筆電**。透過 `SSH Agent Forwarding` 技術，讓 Public EC2 充當「驗證轉發站」。 | **安全** | 即使 Public EC2 被攻破，駭客也找不到任何私鑰檔案。因為鑰匙根本不在那裡。 |

2. **SSH Agent 運作流程**

這個機制分為兩個階段：先 **「建立通道」**，再 **「使用通道」**。

* **第一階段：建立通道 (帶著 Agent 出門)**
  * **指令**：在筆電執行 `ssh -A ec2-user@Public-IP`
  * **動作**：你成功登入 Public EC2（跳板機）。
  * **關鍵意義**：
  * 參數 `-A` (Agent Forwarding) 的作用是在這條連線中，暗中建立一條 **「指回你筆電的 Unix Domain Socket 通道」**。
  * 此時，Public EC2 已經準備好隨時把未來的驗證請求轉發回來，但還沒開始轉發。

* **第二階段：使用通道 (實際驗證)**
  * **指令**：在 Public EC2 裡面執行 `ssh ec2-user@Private-IP`
  * **流程觸發**：
    * **請求**：Private EC2 收到連線請求，要求出示私鑰證明。
    * **轉發**：Public EC2 發現自己沒私鑰，但記得有建立通道，於是透過通道說：「筆電筆電，Private EC2 要驗證，快幫我簽名！」
    * **簽署**：你的 **SSH Agent** (在筆電端) 收到請求，使用記憶體裡的私鑰進行「數位簽名」，再傳回給 Public EC2。
    * **回傳**：Public EC2 拿到簽名後轉交給 Private EC2。
    * **成功**：Private EC2 驗證通過，允許登入。

3. **為什麼 Windows 需要打那些指令？**

在 Windows 系統中，OpenSSH Agent 被設計為一個 **系統服務 (Service)**，預設狀態通常是「停用」或「未執行」。

* `sc config ssh-agent start= demand`
  * 解鎖服務設定。將其啟動類型改為「手動」，允許它被呼叫。

* `net start ssh-agent`
  * 叫醒服務。讓 Agent 開始在背景執行（上班）。

* `ssh-add "路徑/key.pem"`
  * 把私鑰交給 Agent 代管。讓 Agent 把鑰匙載入記憶體，準備隨時應付簽名請求。

<br>

---

<br>

### 4. 在 public ec2 上安裝 nginx，並且使用瀏覽器輸入 public ip，取得 nginx 的網頁頁面後截圖。

#### 步驟一：登入 Public EC2

* 使用你的終端機（CMD 或 PowerShell），登入那台有公網 IP 的 Public EC2。
* (這題不需要 `-A`，因為我們不用跳板，只是要裝軟體)
```cmd
ssh -i "路徑\key.pem" ec2-user@<你的-Public-IP>
```

#### 步驟二：安裝並啟動 Nginx

因為你選的是 **Amazon Linux 2023**，指令如下（一行一行複製執行）：

1. **更新系統套件**：
```bash
sudo dnf update -y
```
2. **安裝 Nginx**：
```bash
sudo dnf install nginx -y
```
3. **啟動 Nginx 服務**：
```bash
sudo systemctl start nginx
```
4. **設定開機自動啟動**（選做，好習慣）：
```bash
sudo systemctl enable nginx
```
5. **檢查狀態**（看到綠色的 active running 代表成功）：
```bash
sudo systemctl status nginx
```
* <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/9bb02cf3-ecb5-4203-be83-a429db5c6312" />

#### 步驟三：修改 Security Group (⚠️ 這是陷阱題！)

現在 Nginx 已經跑起來了，但如果你直接用瀏覽器開 IP，你會發現圈圈轉很久然後連不上。
* <img width="1920" height="990" alt="image" src="https://github.com/user-attachments/assets/b34bf67e-7d47-4a5c-a03c-a847f981de5f" />
> **Q: 為什麼 Nginx 裝好了，瀏覽器卻連不上？**
> **A:** 因為 EC2 的防火牆 (Security Group) 預設是拒絕所有連線的。在第 3 題建立的 Security Group (`Allow-SSH`) **只有開 Port 22**，沒開 Port 80 (HTTP)。我們必須手動在 Inbound Rules 新增 **HTTP (Port 80)** 的規則，外面的瀏覽器才進得來。

回到 AWS Console 操作：
1. 進入 **EC2 控制台**  左側 **Security Groups**。
2. 找到你綁定給 Public EC2 的那個群組（名字應該叫 `Allow-SSH`）。
3. 點擊下方的 **Inbound rules** → **Edit inbound rules**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/6c9cc11c-490a-49d4-a4c4-71e2b6baa369" />
4. 點擊 **Add rule**：
* **Type**: 選擇 `HTTP` (它會自動帶入 Port 80)。
* **Source**: 選擇 `Anywhere-IPv4` (`0.0.0.0/0`)。
5. 點擊 **Save rules**。
* <img width="1920" height="438" alt="image" src="https://github.com/user-attachments/assets/66ad9078-42ee-4048-825e-5597f45631b6" />

#### 步驟四：瀏覽器驗證與截圖

1. 打開 Chrome 或 Edge。
2. 在網址列輸入：`http://<你的-Public-IP>` (注意是 http 不是 https)。
* <img width="1920" height="990" alt="image" src="https://github.com/user-attachments/assets/aeeaaa43-645a-4a1f-b304-8026ee4d0680" />

<br>

---

<br>

### 5. 嘗試在 private 的那台 ec2 上使用 curl google.com 指令，取得回傳的 html 頁面（有回傳就是成功）

你的筆記整理得**非常完整且專業**！
尤其是關於 SSH Agent 那一段，不僅有指令操作，還包含了「為什麼要這樣做」的資安原理解析，這是非常有深度的學習筆記。

針對第五題，我們現在要讓 **Private EC2 (內網機器)** 也能上網。

---

### 【實作題】5. 透過 NAT Gateway 讓 Private EC2 上網

目前的狀況：
* Private EC2 被關在內網（Route Table 沒有 IGW），所以它出不去。
* 我們不能直接給它接 IGW，否則它就變成 Public Subnet 了（違反安全原則）。

解法：我們需要一個「代理人」，它住在 Public Subnet，專門幫內網機器跑腿去抓資料。這個代理人就叫 **NAT Gateway**。

#### 步驟一：驗證目前無法上網 (對照組)

1. 使用跳板機 (Bastion Host) 的方式登入 **Private EC2**。
2. 輸入以下指令嘗試連線 Google：
```bash
curl -I https://www.google.com
```
*(參數 `-I` 代表只抓檔頭，畫面比較乾淨)*
3. **預期結果**：卡住不動 (Timeout)，因為封包出不去。
*(按 `Ctrl + C` 強制中斷)*
* <img width="974" height="508" alt="image" src="https://github.com/user-attachments/assets/c497f14d-80c9-4bb1-aa02-1c057cb12bbe" />


#### 步驟二：創建 NAT Gateway (請代理人)

1. 進入 **VPC 控制台** → 左側 **NAT gateways** → **Create NAT gateway**。
2. **Name**: `MyNAT`。
3. **Subnet**: ⚠️ **重點中的重點！** 這裡必須選擇 **Public Subnet** (`Public-Subnet-1a`)。
* *解釋：NAT Gateway 必須住在能上網的地方，才能幫別人上網。*
4. **Connectivity type**: `Public`。
5. **Elastic IP allocation ID**: 點擊 **Allocate Elastic IP** 按鈕。
* *解釋：NAT Gateway 需要一個固定的公網 IP 才能跟外面的網路溝通。*
6. 點擊 **Create NAT gateway**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/fae1f766-ae80-4db5-b633-adf146132750" />
* *狀態會顯示 `Pending`，等個 1-2 分鐘變成 `Available` 再繼續。*

#### 步驟三：修改 Private Route Table (指路)

現在代理人請好了，我們要告訴內網機器這條路。

1. 進入 **Route tables**。
2. 找到你建立的 **`Private-RT`** (綁定 Private Subnet 的那張)。
3. 切換到 **Routes** 分頁  **Edit routes**。
4. 點擊 **Add route**。
5. **Destination**: `0.0.0.0/0` (代表要去網際網路)。
6. **Target**: 選擇 `NAT Gateway`  選剛剛建的 `MyNAT`。
* *注意：不要選成 IGW 喔！*
7. 點擊 **Save changes**。
* <img width="1920" height="370" alt="image" src="https://github.com/user-attachments/assets/b05f0eba-4fd2-4f94-8339-41bdd9a3e20d" />

#### 步驟四：驗證成功 (實驗組)

1. 回到你的終端機 (你應該還在 Private EC2 裡面)。
2. 再次執行：
```bash
curl -I https://www.google.com
```
3. **預期結果**：瞬間回傳 `HTTP/2 200` 或 `301 Moved Permanently` 等訊息。
* <img width="974" height="508" alt="image" src="https://github.com/user-attachments/assets/873f41f3-11d9-46b5-80e0-e24462445fc0" />

#### ⚠️ 特別警告：做完記得刪除！ (省荷包動作)

NAT Gateway 是 AWS **收費較高** 的元件（不管有沒有流量，只要開著就在計費，每小時約 0.045 USD，一天約 1 美金）。**作業截圖完成後，請務必執行刪除動作：**

1. **刪除 NAT Gateway**:
* NAT Gateways  選中 `MyNAT`  Actions  **Delete NAT gateway**。
* 輸入 `delete` 確認。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/45b49740-e0f6-4010-bf79-d8486d903a81" />
* *狀態會變成 `Deleting`。*

2. **釋放 Elastic IP (EIP)**:
* *等 NAT Gateway 完全刪除後 (狀態變 Deleted)*。
* 左側 **Elastic IPs**  選中剛剛申請的 IP  Actions  **Release Elastic IP addresses**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/f3334059-697a-4a86-a560-c02f5f63c1a8" />
* *如果不釋放 EIP，AWS 會因為你「佔著茅坑不拉屎 (沒綁定資源)」而跟你收費。*


