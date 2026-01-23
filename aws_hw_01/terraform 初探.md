## 【簡答題】

### 1. 何為 IaC? 除了 terraform 以外，還有哪些工具呢？

#### 1. 什麼是 IaC (基礎設施即程式碼)？

**核心概念**：
IaC 就是把我們原本要「手動」去 AWS Console 點滑鼠建立伺服器、網路、資料庫的過程，改成用「寫程式碼（設定檔）」的方式來描述。

**比喻：**

* **傳統方式 (手動)**：就像是在玩《Minecraft》蓋房子。你一塊磚、一塊磚地疊上去。如果要再蓋一棟一模一樣的，你憑記憶可能蓋不出來完全一樣的，而且很花時間。
* **IaC 方式**：就像是寫了一張 **「建築藍圖」**。只要把這張藍圖交給機器（Terraform），它就能自動幫你瞬間蓋出一棟房子。如果需要蓋 100 棟一模一樣的房子，只要執行 100 次藍圖就好。

**為什麼需要 IaC？ (好處)**

1. **版本控制 (Git)**：因為是程式碼，你可以把它存到 Git 裡。誰在什麼時候把 `t2.micro` 改成了 `t2.large`，全部都有紀錄，出錯了也可以隨時還原 (Rollback)。
2. **一致性 (不再有「我的電腦可以跑啊」)**：開發環境、測試環境、正式環境，全部都用同一份程式碼產生，保證環境長得一模一樣。
3. **自動化與速度**：幾千台機器可以在幾分鐘內建好，不需要人手動點到手酸。

#### 2. 除了 Terraform，還有哪些常見工具？

* `Ansible`：由 Red Hat 維護。主要強項在於「組態管理 (Configuration Management)」，即機器開好後，進去安裝軟體、設定檔。它是無代理 (Agentless) 的。
* `AWS CloudFormation`：AWS 原生的 IaC 工具。優點是與 AWS 整合最深，缺點是寫法繁瑣（JSON/YAML）且只能用在 AWS。
* `Pulumi`：新興工具。允許使用真正的程式語言（Python, TypeScript, Go）來寫架構，而不是 Terraform 的 HCL 語言。
* `Chef / Puppet`：較早期的組態管理工具，通常需要在機器上安裝 Agent。

### 2. 執行 terraform 時，會有一個檔案 .tfstate，功能是什麼？

#### 1. 什麼是 `.tfstate`？

當你執行 Terraform 指令（如 `terraform apply`）後，你會發現目錄下多了一個叫做 `terraform.tfstate` 的檔案（如果是用遠端後端，則會存在遠端）。

這個檔案就是 Terraform 的 **「記帳本」** 或 **「大腦記憶」**。它用來記錄 Terraform **認為** 目前雲端上的基礎設施長什麼樣子。

#### 2. 它的主要功能有哪些？

這個檔案主要負責做三件大事：

1. **映射真實資源 (Mapping Real World Resources)**
* **問題**：你的程式碼只寫了 `resource "aws_instance" "web" {}`，但它不知道這段程式碼對應到 AWS 上到底是哪一台機器（例如 `i-0123456789`）。
* **功能**：State 檔裡面會記錄：「程式碼裡的 `aws_instance.web` = 真實世界的 `i-0123456789`」。這樣下次你改程式碼時，它才知道要去找哪一台機器開刀。
2. **追蹤中繼資料 (Tracking Metadata)**
* **功能**：它會記錄資源之間的依賴關係（誰先誰後），以及某些資源的屬性。這樣就算你改了程式碼的順序，Terraform 還是知道原本的結構，不會亂掉。
3. **效能快取 (Performance / Caching)**
* **問題**：如果你有 1000 台機器，每次跑指令都要去 AWS API 問一遍「這 1000 台現在長怎樣？」，會跑得非常慢。
* **功能**：Terraform 會先把資源的屬性存在 State 檔裡。執行 `terraform plan` 時，它會優先參考這個檔案，加快檢查速度。

#### ⚠️ 關於 State 的重要觀念

1. **絕對不要手動修改它**：
這個檔案是 JSON 格式，看起來像文字檔，但**千萬不要**用記事本打開來手動改內容。一旦格式錯了或 ID 對不上，Terraform 就會「失憶」或報錯，導致你跟雲端上的資源斷了聯繫。
2. **敏感資料風險**：
State 檔是**純文字**存儲的。如果你在 Terraform 裡設定了資料庫密碼 (`password = "123456"`)，這個密碼會**直接以明碼**顯示在 `.tfstate` 檔案裡。
* 解決方案：這也是為什麼我們通常建議使用 Remote Backend (如 S3) 並開啟加密，而不是直接把這個檔案存在 GitHub 上（會被看光光）。

### 3. 多人協作時，如何確保 terraform 的狀態一致性？

#### 1. 問題的根源：如果大家各自為政會怎樣？

想像一下，如果我們把 `.tfstate` 檔案存在自己的筆電裡：

* **情境**：工程師 A 在他的電腦跑完 Terraform，建立了一台 EC2。工程師 B 的電腦裡沒有這個紀錄。
* **災難**：工程師 B 執行 Terraform 時，系統以為「還沒有任何機器」，於是又建立了一台新的 EC2，或者試圖刪除 A 剛建好的東西。
* **結果**：狀態衝突、資源重複建立、資料遺失。

#### 2. 解決方案：Remote Backend (遠端後端) + State Locking (狀態鎖定)

為了讓大家看到的「世界」是一樣的，我們必須做兩件事：

**第一招：Remote State (單一真理來源)**

* **概念**：不要把記帳本（.tfstate）放在個人的電腦或 Git 裡。而是把它放在一個**中央共享的雲端儲存空間**。
* **實作**：在 AWS 環境中，我們通常使用 **S3 Bucket** 來存放這個檔案。
* **好處**：無論是誰（或 CI/CD 機器人）要執行 Terraform，第一件事都是去 S3 下載最新的狀態檔，確保大家看到的基礎設施狀態是同步的。

**第二招：State Locking (狀態鎖定)**

* **概念**：就像飛機上的廁所，一次只能一個人進去。當有人正在修改基礎設施時，要把門鎖起來，避免別人同時修改。
* **實作**：
  * 當工程師 A 執行 `terraform apply` 時，Terraform 會自動在鎖定表上寫入「鎖定中」。
  * 此時工程師 B 如果也想執行，系統會偵測到鎖定狀態，直接報錯拒絕執行，直到 A 完成並解鎖。
  * **AWS 工具**：通常搭配 **DynamoDB** 來實作這個鎖定表（Lock Table）。

#### 重點整理

在多人協作 Terraform 專案時，必須設定 **Remote Backend**。

1. **儲存 (Storage)**：使用 **AWS S3** 集中存放 `.tfstate` 檔案，確保所有成員存取同一份狀態。
2. **鎖定 (Locking)**：使用 **AWS DynamoDB** 來管理鎖定狀態 (State Lock)，防止兩個人同時執行寫入操作造成資料損毀。

### 4. 何為冪等性？他在 IaC 工具中帶來怎樣的好處？

#### 1. 什麼是冪等性 (Idempotency)？

**定義**：
一個操作無論執行一次還是執行無限多次，其**結果都是一樣的**，不會因為重複執行而產生副作用。
*(數學表示：`f(x) = f(f(x)) = f(f(f(x)))...`)*

**生活中的比喻**：

* **電梯按鈕 (冪等)**：你要去 5 樓，按了一次「5樓」按鈕。就算你因為無聊連按了 100 次，電梯還是只會把你載到 5 樓，而不會把你載到 500 樓。
* **網購下單 (非冪等)**：你要買一本書，按了一次「結帳」。如果你手抖連按了 10 次，結果你家送來了 10 本書還扣了 10 次款。這就是**沒有**冪等性。

#### 2. 在 Terraform (IaC) 中的運作方式

在 Terraform 的世界裡，冪等性意味著：**「無論你跑幾次 `terraform apply`，基礎設施的狀態都會停留在你程式碼描述的那樣。」**

* **情境**：你的程式碼寫 `resource "aws_instance" "web" { count = 1 }`。
* **第一次執行**：Terraform 發現雲端沒這台機器，於是**建立**一台。
* **第二次執行**：Terraform 發現雲端已經有一台了，且設定都沒變，於是**什麼都不做** (No changes)。
* **第三次執行**：結果一樣，**什麼都不做**。
*(如果是傳統的 Shell Script，你寫一行 `aws ec2 run-instances`，每跑一次就會多開一台機器，跑十次就開十台，這就是不具備冪等性。)*

#### 3. 帶來的好處

這個特性對維運來說至關重要，主要好處有兩點：

1. **安全性與可重複執行 (Repeatability & Safety)**
* 你可以放心地把 Terraform 指令放進自動化排程 (CI/CD) 裡，設定「每次有人改 code 就跑一次 apply」。
* 你不必擔心「重複跑會不會把舊機器刪掉？」或「會不會多開一倍的機器？」。因為冪等性保證了結果永遠鎖定在「你寫的樣子」。

2. **自動修復 (Drift Correction / Self-healing)**
* **情境**：假設今天有個同事手殘，手動去 AWS Console 把那台 EC2 的防火牆規則刪掉了（這叫 Configuration Drift，組態偏移）。
* **修復**：當你再次執行 `terraform apply` 時，Terraform 雖然已經建過機器了，但它會發現：「咦？雲端上的防火牆規則跟程式碼寫的不一樣（被刪了）」。
* **結果**：Terraform 會自動把那個被刪掉的規則**補回去**，讓狀態恢復成程式碼描述的樣子。

> **冪等性** 指的是「操作執行多次，結果與執行一次相同」。
> 在 IaC 中，它讓工程師可以**無懼地重複部署**，並具備**自動修正 (Self-healing)** 雲端資源狀態的能力，確保實際環境永遠符合程式碼的描述。

### 5. 何為 terraform module，它解決了什麼問題？

#### 1. 什麼是 Terraform Module？

**定義：**
在 Terraform 中，**任何一個包含設定檔 (`.tf`) 的資料夾**，都可以被稱為一個 Module。
你可以把它想像成程式語言中的 **「函式 (Function)」** 或 **「類別 (Class)」**。

* **Root Module**：你執行 `terraform apply` 指令所在的那個目錄，就是當下的 Root Module。
* **Child Module**：你在程式碼裡呼叫引用的其他 Module。

**比喻：**

* **沒有 Module**：就像你要組裝 10 台一樣的樂高車子，你每次都要從散亂的積木堆裡，一塊一塊重新找、重新拼湊。
* **使用 Module**：就像你買了 10 盒 **「樂高車子套件包」**。每一盒裡面的零件都已經配好了，甚至底盤已經組好了。你只需要把它拿出來，決定要貼什麼顏色的貼紙（輸入參數），就可以快速組好一台車。

#### 2. 它解決了什麼問題？ (核心價值)

Module 主要解決了以下三個「大型專案」一定會遇到的問題：

**1. 避免重複造輪子 (DRY - Don't Repeat Yourself)**

* **問題**：假設你要在 Dev、Test、Prod 三個環境各建一套 VPC。如果不用 Module，你得把那一長串建立 VPC、Subnet、Route Table 的程式碼 **複製貼上三次**。一旦要修改（例如加一個 Subnet），你得改三個地方，很容易漏改。
* **解決**：寫好一個標準的 `vpc_module`。然後在三個環境裡，分別呼叫這個 Module 三次（只是傳入的參數不同，例如 CIDR 不同）。

**2. 標準化與封裝 (Standardization & Encapsulation)**

* **問題**：公司規定所有的 S3 Bucket 都必須「開啟加密」且「關閉公開存取」。但新來的 Junior 工程師不懂，自己寫 Resource 時漏了這些設定，導致資安漏洞。
* **解決**：資深架構師寫好一個 `secure_s3_module`，把加密和防火牆都在裡面寫死。之後所有人要開 Bucket，只能呼叫這個 Module，不用擔心沒經驗的人設錯。

**3. 提升可讀性 (Readability)**

* **問題**：當你的架構變大，單一檔案裡可能有幾千行程式碼，混雜著 EC2, VPC, IAM, S3... 光是用滑鼠滾輪找東西就瘋了。
* **解決**：使用 Module 後，你的主程式碼會變得很乾淨，只看得到「大架構」：
```hcl
module "network" { source = "./modules/vpc" }
module "database" { source = "./modules/db" }
module "app"      { source = "./modules/ec2" }
```

一眼就能看懂這份架構在做什麼。

#### 3. 簡單的結構範例

一個標準的 Module 通常會有這三個檔案：

* `main.tf`：主要的資源定義（邏輯核心）。
* `variables.tf`：定義輸入參數（像是函式的引數 arguments）。
* `outputs.tf`：定義輸出值（像是函式的 return value）。

#### 重點整理

> **Terraform Module** 是將一組相關資源打包的容器，類似程式設計的 Function。
> 它的好處包含：**重用代碼 (DRY)**、**強制標準化 (Security)**、以及**簡化主程式碼 (Readability)**，是管理大型架構的必備工具。

### 6. terraform 的資源創建順序為何？如何去控制相依性？

#### 1. 預設順序：平行處理與相依性圖 (Parallelism & Dependency Graph)

Terraform 最大的特色之一，就是它**不是**依照你寫程式碼的「上下順序」一行一行執行的。

* **預設行為**：Terraform 會先分析所有資源，畫出一張 **「相依性圖 (Dependency Graph)」**。
* **平行執行**：在這張圖中，只要兩個資源之間**沒有關聯**（誰也不依靠誰），Terraform 為了加速，預設會 **「同時 (Parallel)」** 去建立它們。
* *例如：你同時寫了一個 VPC 和一個 S3 Bucket。這兩者互不相干，Terraform 就會同時向 AWS 發送 API 請求。*

#### 2. 如何控制順序？ (兩種相依性)

如果資源之間有先後關係（例如：一定要先有 VPC，才能在裡面開 EC2），Terraform 提供了兩種方式來處理：

**方法一：隱式相依性 (Implicit Dependency) [最推薦/最常用]**

這是 Terraform 最聰明的地方。你不需要刻意去告訴它順序，只要你在程式碼中 **「引用」** 了另一個資源的屬性，Terraform 就會自動知道先後順序。

* **範例**：
```hcl
# 1. 建立 VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# 2. 建立 Subnet (引用了上面的 VPC ID)
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id  # <--- 關鍵在這行
  cidr_block = "10.0.1.0/24"
}
```
* **解讀**：因為 `aws_subnet` 裡面的 `vpc_id` 引用了 `aws_vpc.my_vpc.id`，Terraform 會自動判斷：「我必須先等 VPC 建好、拿到 ID 之後，才能開始建 Subnet」。這就是隱式相依。

**方法二：顯式相依性 (Explicit Dependency)**

有時候，資源之間沒有直接的參數引用關係，但邏輯上你還是希望有先後順序。這時就要用 **`depends_on`** 這個參數來強制指定。

* **情境**：你的 EC2 應用程式啟動時，需要去讀取 S3 Bucket 裡面的設定檔。雖然 EC2 的參數裡沒有寫到 S3，但如果 Bucket 還沒好，EC2 起來就會報錯。
* **範例**：
```hcl
resource "aws_s3_bucket" "config_bucket" {
  bucket = "my-app-config"
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  # 強制告訴 Terraform：先去把 Bucket 建好，再來建我！
  depends_on = [
    aws_s3_bucket.config_bucket
  ]
}
```
#### 📝 重點整理

1. **預設行為**：Terraform 會建立相依性圖 (Graph)，互不相關的資源會 **平行 (Parallel)** 建立以節省時間。
2. **隱式相依 (Implicit)**：透過引用其他資源的屬性 (如 `vpc_id = aws_vpc.example.id`)，Terraform 會自動偵測並安排順序。這是最推薦的做法。
3. **顯式相依 (Explicit)**：使用 **`depends_on`** 參數，強制指定資源必須在另一個資源建立完成後才能開始建立。通常用於解決隱藏的邏輯依賴。

### 7. 何為 datasource?

#### 1. 什麼是 Datasource？

**定義：**
Datasource 是 Terraform 用來 **「查詢雲端上已經存在的資源」** 的一種唯讀介面。
它**不會**建立、修改或刪除任何東西，它只是負責去 AWS 把這項資源的資訊（ID, ARN, IP 等）抓回來，讓你可以在程式碼中引用。

**簡單的比喻：**

* **Resource (資源)**：像是**「建築工」**。你告訴他：「去幫我蓋一棟房子（建立 EC2）。」
* **Datasource (資料來源)**：像是**「查號台」**或**「偵探」**。你告訴他：「去幫我查一下那棟已經蓋好的房子地址在哪裡（查詢 VPC ID）。」

#### 2. 為什麼需要 Datasource？ (使用情境)

通常有兩種主要情境會用到它：

**情境一：與「非 Terraform 管理」的資源介接**

* **狀況**：你的 VPC 是網路部門早就建好的（可能是手動建的，或用別的工具建的）。你的 Terraform 專案只需要負責在裡面開 EC2。
* **問題**：你的程式碼怎麼知道那個 VPC 的 ID 是多少？寫死 `vpc-123456` 嗎？這樣換個環境就掛了。
* **解法**：使用 `data "aws_vpc"` 去查詢「名稱叫 `Main-VPC`」的那個 VPC，動態取得它的 ID。

**情境二：取得動態變動的資訊 (如 AMI)**

* **狀況**：你想開一台 Amazon Linux 2023 的機器。但 AWS 常常更新映像檔，AMI ID (例如 `ami-0abc...`) 每隔一段時間就會變。
* **問題**：如果你把 ID 寫死，過幾個月這個 ID 可能就過期失效了。
* **解法**：使用 `data "aws_ami"` 設定過濾條件（我要最新的、Amazon Linux 2023），每次執行 `apply` 時，Terraform 就會自動去問 AWS：「現在最新的是哪一個？」並抓回來用。

#### 3. 程式碼範例

這是一個最經典的例子：**「自動查詢最新的 Amazon Linux AMI」**。

```hcl
# 定義一個 Datasource (偵探)
data "aws_ami" "latest_amazon_linux" {
  most_recent = true      # 我要最新的
  owners      = ["amazon"] # 發行者是 Amazon

  # 設定搜尋條件 (就像 SQL 的 Where)
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"] # 檔名要符合這個規則
  }
}

# 建立資源 (建築工)
resource "aws_instance" "web" {
  # 這裡不寫死 ID，而是引用上面的 Datasource 查到的結果
  ami           = data.aws_ami.latest_amazon_linux.id 
  instance_type = "t2.micro"
}
```

#### 重點整理

1. **定義**：Datasource 是 Terraform 的 **唯讀 (Read-Only)** 元件，用來查詢雲端上 **已存在** 的資源資訊。
2. **關鍵字**：使用 `data` 開頭 (區別於 `resource`)。
3. **用途**：
* 查詢 **外部資源** (非此專案建立的，如共用的 VPC)。
* 查詢 **動態資訊** (如最新的 AMI ID、AWS 帳號 ID、當前 Region)。
4. **好處**：避免在程式碼中將 ID 寫死 (Hardcode)，讓程式碼更具彈性與可攜性。

### 8. 若使用 terraform 創建一台 ec2，希望對該 ec2 進行初始化操作，有哪些方式做到這件事，盡可能地列舉。

#### 1. 使用 User Data (使用者資料) [最推薦/最常用]

這是 AWS EC2 原生提供的功能。你可以在 Terraform 程式碼中直接塞入一段 Shell Script 或 Cloud-Init 設定檔。

* **作法**：在 `aws_instance` 資源中使用 `user_data` 參數。
```hcl
resource "aws_instance" "web" {
  # ... 其他設定 ...
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              EOF
}
```

* **優點**：簡單、原生支援、完全自動化。
* **缺點**：如果腳本太複雜（例如幾百行），會很難除錯與維護。

#### 2. 使用 Custom AMI (黃金映像檔) [高效能/不可變基礎設施]

與其開機後才慢慢裝軟體，不如先把軟體都裝好，打包成一個映像檔 (AMI)。

* **作法**：
1. 使用工具（如 **Packer**）先在本地建立一台機器，安裝好所有需要的環境（Java, Tomcat, Log agent...）。
2. 將其打包成 AMI。
3. Terraform 直接指定這個 AMI ID 來開機。

* **優點**：**開機即用**（不用等安裝時間），啟動速度最快，且保證環境絕對一致。
* **缺點**：每次軟體更新（例如修一個 Bug）都要重新打包 AMI，流程較繁瑣。

#### 3. 結合組態管理工具 (Terraform + Ansible) [適合複雜設定]

讓 Terraform 專注於「生出機器」，讓專業的工具（Ansible）專注於「設定機器」。

* **作法**：
* Terraform 建立 EC2。
* 使用 `local-exec` 呼叫 Ansible Playbook，針對剛建好的 IP 進行軟體安裝。

* **優點**：Ansible 的劇本 (Playbook) 比 Shell Script 好讀、好維護，且適合管理大量複雜的設定檔。
* **缺點**：需要學習兩套工具，且架構較複雜。

#### 4. 使用 Terraform Provisioners (`remote-exec` / `file`) [官方不推薦]

這是 Terraform 早期提供的功能，允許 Terraform 在執行過程中透過 SSH 連進機器跑指令。

* **作法**：
```hcl
resource "aws_instance" "web" {
  # ...
  provisioner "remote-exec" {
    inline = [
      "yum install -y nginx",
    ]
  }
}
```

* **為什麼不推薦？**
* **破壞狀態追蹤**：Terraform 無法完美追蹤這些指令到底有沒有成功，如果網路斷線導致指令跑一半，Terraform 可能會誤判為成功，造成「髒狀態」。
* HashiCorp 官方建議將此作為**最後手段 (Last Resort)**，盡量用 User Data 取代。

#### 重點整理

| 方式 | 核心概念 | 適用場景 |
| :---: | :---: | :---: |
| **1. User Data** | 傳入 Shell Script，開機時由 AWS 自動執行一次。 | **最通用**。安裝簡單軟體、Docker、下載程式碼。 |
| **2. Custom AMI** | 先把軟體裝好打包成映像檔 (Pre-baked)。 | **要求快速擴展**。如 Auto Scaling Group，需要秒級啟動。 |
| **3. Ansible** | 機器建好後，由外部工具連進去設定。 | **複雜組態**。需要長期維護、大量設定檔管理。 |
| **4. Provisioners** | Terraform 透過 SSH 連進去跑指令。 | **不推薦**。僅用於無法使用上述方法的特殊情況。 |

## 【實作題】

創建一個 project(github repo)，使用 terraform 創建一台 EC2，並且設定相關資源，例如 VPC（可選）、security group(firewall)、key pair 等。（可以嘗試跟 ai 詢問怎樣的檔案架構是比較好的。）
延續上一題，嘗試將一些可變動的參數改成使用 variables 輸入，以及使用 output 來輸出一些資訊（例如 ssh 登入指令或是 public ip 等）。
嘗試使用 draw.io 這類的工具，畫簡單的架構圖，並附於 github readme 中。

## 【進階題】

嘗試了解 s3 作為 remote backend 的使用方式，如果不嫌麻煩，做個範例吧！
嘗試了解 terragrunt 的使用方式，做個範例分享給其他同學。
