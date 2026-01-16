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

#### 結構圖

* **Region (東京)**
  * **VPC (你的總公司)**
    * **IGW (大門)**
    * **AZ (A 棟)**
      * **Subnet 1 (業務部)**  配有 Route Table (指路牌)
    * **AZ (C 棟)**
      * **Subnet 2 (研發部)**  配有 Route Table (指路牌)
    * **NAT Gateway (總機小姐)**  雖然住在 A 棟的業務部，但專門幫 C 棟的研發部買東西。

<br>

---

<br>

## 【實作題】

### 1. 在東京 region，嘗試創建一個 VPC，其 CIDR 為 10.0.0.0/18，為其創建兩個 subnet 並且其遮罩長度為 20，並且位於不同的 zone，且提供該兩個 subnet 的 CIDR。


這題的目標是規劃出一個私有的網路空間，並將其切割成兩個不同用途的區塊。

#### 第一步：創建 VPC (大蛋糕)**

1. 確認右上角區域選在 **Tokyo (ap-northeast-1)**。
2. 進入 **VPC** 控制台，點擊 **Create VPC**。
3. 選擇 **VPC only** (手動建，學習效果最好)。
4. **Name tag**: `MyVPC`。
5. **IPv4 CIDR**: 輸入 `10.0.0.0/18`。
* *解釋：`/18` 代表這個 VPC 總共有 16,384 個 IP 可用。*
6. 點擊 **Create VPC**。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/a4107a81-f55c-4263-98b0-cd8ec6abc6ff" />

#### 第二步：創建兩個 Subnet (切小塊)**

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

#### 📝 對照表

| 路由表名稱 | 關聯的 Subnet | 有無 `0.0.0.0/0` 指向 IGW? | 用途 |
| --- | --- | --- | --- |
| **Public-RT** | `Public-Subnet-1a` | **有** | 讓機器可以直接擁有公網 IP 上網。 |
| **Private-RT** | `Private-Subnet-1c` | **無** (只有 local) | 機器藏在內網，外面連不進來。 |


* 結果圖示
  * <img width="1920" height="699" alt="image" src="https://github.com/user-attachments/assets/6aa190f3-d8ca-431c-8ce2-d3524bbb6c4d" />
 
<br>

---

<br>

### 3. 承第二題，在兩個 subnet 上分別創建一台 ec2，並且使用 ssh 從自己的 laptop 連上此兩台 ec2，提供你的做法。

<br>

---

<br>

### 4. 在 public ec2 上安裝 nginx，並且使用瀏覽器輸入 public ip，取得 nginx 的網頁頁面後截圖。

<br>

---

<br>

### 5. 嘗試在 private 的那台 ec2 上使用 curl google.com 指令，取得回傳的 html 頁面（有回傳就是成功）
