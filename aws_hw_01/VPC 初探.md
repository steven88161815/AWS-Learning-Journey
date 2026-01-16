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


