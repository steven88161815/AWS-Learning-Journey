## 【問答題】

### 1. root user 跟 iam user 的差別？

| 特性 | Root User | IAM User |
| :----: | :----: | :----: |
| 如何創建 | 註冊 AWS 帳號時使用的 Email。 | 由 Root User 或管理者在 IAM 頁面手動建立。 |
| 權限範圍 | **無限制**。擁有帳號內所有資源、帳單與關閉帳號的最高權限。 | **預設無權限**。必須被賦予 Policy 才能執行特定動作。 |
| 安全性 | 非常危險。若外洩，整個帳號都會被掌控。 | 相對安全。遵循「最小權限原則」，外洩時影響有限。 |

<br>

---

<br>

### 2. user, group, role, policy 彼此間的關係為何？policy 的格式為何？

<img width="2878" height="1620" alt="image" src="https://github.com/user-attachments/assets/494aefd0-9ecf-40d6-ae76-9ad8c37e32b2" />

這四個元件的關係可以用一個簡單的公式來理解：「 `誰 (User/Group/Role)` + `透過什麼規則 (Policy)` + 能做什麼事」。

#### 彼此間的關係 
* **User (使用者)**：代表一個具體的人（例如你）。每個人都有自己的登入帳號與密碼。

* **Group (使用者群組)**：使用者的集合。你可以把多個 User 丟進同一個 Group。
  * 關係：你把 Policy 掛在 Group 上，裡面所有的 User 就會自動繼承這些權限，方便大量管理。

* **Role (角色)**：代表一個虛擬的身分。它沒有固定的密碼或金鑰，而是給「有需要的人或服務」臨時`切換（Assume）`進去使用的。
  * 關係：User 可以「變身」成某個 Role；EC2 機器也可以「戴上」某個 Role 來獲得權限。

* **Policy (策略)**：這是一份純文字文件，規定了「准許」或「拒絕」哪些動作。
  * 關係：Policy 是靈魂，它必須**附加**在 User、Group 或 Role 上，這些身分才會有權限。

| 實體 (Entity) | 是否能直接附加 Policy？ | 是否能加入 Group？ |
| :----: | :----: | :----: |
| User (使用者) | 可以，但不建議（個別管理太累）。 | 可以。 |
| Group (群組) | 可以，這是管理 User 的標準做法。 | 不可以（群組內不能有群組）。 |
| Role (角色) | 可以，這是賦予 Role 權限的唯一方式。 | 不可以（Role 不能加入 Group）。 |

#### Policy 的格式 (JSON)

AWS 的 Policy 是以 JSON 格式 撰寫的，裡面主要包含以下四個關鍵字：

``` JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",          // 准許 (Allow) 還是 拒絕 (Deny)
      "Action": "s3:ListBucket",   // 做了什麼動作
      "Resource": "arn:aws:s3:::my-bucket" // 對哪個資源做
    }
  ]
}
```

* Effect：決定這條規則是「Pass」還是「Block」。
* Action：具體的 API 動作（例如 ec2:RunInstances 或 s3:GetObject）。
* Resource：受影響的資源範圍（使用 ARN 格式表示）。
* Condition (可選)：在什麼特定條件下才生效（例如：限制來源 IP 或限制時間）。

<br>

---

<br>

## 【實作題】

### 1. 為 root account 創建 MFA 登入。

1. 進入 IAM 控制台：
* 在上方搜尋列輸入 IAM 並進入。
* 在儀表板右側的「Security Status」或「IAM resources」下方，你會看到 「Add MFA for root user」 的警告提示，點擊 Assign MFA。
2. 選擇設備類型：
* 選擇 Authenticator app（虛擬 MFA 設備）。這是最方便的做法，不需要買實體硬體。
* <img width="984" height="769" alt="image" src="https://github.com/user-attachments/assets/f7067189-eb63-4941-b50a-c7cf8f532430" />
3. 設定 App：
* 在手機下載 Google Authenticator。
* 點擊 AWS 上的 Show QR code。
* 用手機 App 掃描 QR code。
4. 完成驗證：
* 手機會出現每 30 秒更換一次的 6 位數字。
* 在 AWS 畫面上輸入連續產生的兩組驗證碼（MFA code 1 & MFA code 2）。
* 點擊 Add MFA。
5. 完成截圖
* <img width="1905" height="938" alt="image" src="https://github.com/user-attachments/assets/ed31daf4-58e2-4732-bd4f-89c0d1fe627e" />
* 「現在登入 Root 帳號時，除了輸入 Email 和密碼，還需要從手機 App 取得 6 位數密碼，大幅降低了帳號被盜的風險」。

<br>

---

<br>

### 2. 創建 aws credential（access key & secret），並且使用 aws cli 嘗試存取 ec2 列表（可以手動創建一台機器）及 s3 列表。

`Access Key` 和 `Secret Access Key` 就像是你的身份證與密碼的「電腦版」，專門給程式（如 AWS CLI）使用。

#### 第一步：創建 Access Key (在網頁上)
* 進入 IAM 控制台，點擊右上角帳號名 $\rightarrow$ Security Credentials。
* 向下滾動到 Access keys 區塊，點擊 Create access key。
* 重要： 點擊下載 .csv 檔或複製金鑰。
  * ⚠️ 注意： 這是你唯一一次能看到 Secret Access Key 的機會，弄丟了就要重新建一個。
 
#### 第二步：設定 AWS CLI (在你的電腦上)
如果你還沒安裝 AWS CLI，請先下載安裝。接著開啟終端機（CMD 或 Terminal）：

* 輸入 `aws configure`。
* 依序填入：
  * AWS Access Key ID: (貼上剛才的 ID)
  * AWS Secret Access Key: (貼上剛才的 Secret)
  * Default region name: `ap-northeast-1` (東京，或是你常用的區域)
  * Default output format: `json`

#### 第三步：驗證並嘗試存取列表
* 列出 S3 桶子：
``` Bash
aws s3 ls
```

* 列出 EC2 列表：
``` Bash
aws ec2 describe-instances
```

* 結果圖示
  * <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/5d4ef393-d0ad-472e-b4a9-2bcd130b02d4" />
 
<br>

---

<br>

### 3. 創建一個 user，名為 `s3_readonly`，並且僅給予其 s3 readonly 的權限，為此 user 創建 credential 並且設定在 aws 內，使用不同的 profile 可以指定用哪個 credential 跟 aws 溝通，驗證方式為嘗試取得 ec2 及 s3 的列表，其中一個會失敗。

這題的核心在於練習 **「最小權限原則」** 以及如何透過 **Profile** 在同一台電腦上切換不同的身分。

#### 第一步：在 IAM 控制台創建受限使用者
* **建立 User**：
  * 名稱：`s3_readonly`。
  * 存取類型：勾選 **「Provide user access to the AWS Management Console」**（選填，但為了實作題建議也幫他建立 Access Key）。

* **設定權限 (Set permissions)**：
  * 選擇 **「Attach policies directly」**。
  * 在搜尋框輸入 `S3ReadOnly`，勾選 **`AmazonS3ReadOnlyAccess`**。
  * **注意：** 不要勾選任何與 EC2 相關的 Policy。
  * <img width="1458" height="571" alt="image" src="https://github.com/user-attachments/assets/cbcc0586-e9f4-4a39-beaf-295806cfe7de" />

* **產生 Access Key**：
  * 在該使用者的「Security credentials」分頁下，點擊 **Create access key**。
  * 選擇 **CLI**，並記錄下這組新的 `Access Key ID` 和 `Secret Access Key`。
  * <img width="1905" height="877" alt="image" src="https://github.com/user-attachments/assets/ed026e25-2783-40f9-8f0c-9ce0d6437c06" />

#### 第二步：在 CLI 設定新的 Profile
現在你要教你的電腦認識這個「新身分」，但不能覆蓋掉你原本的管理者權限。

請在終端機輸入：
```bash
aws configure --profile s3_user
```

* **Access Key ID**: 貼上 `s3_readonly` 的金鑰。
* **Secret Access Key**: 貼上 `s3_readonly` 的私鑰。
* **Region**: `ap-northeast-1` (或是你原本用的區域)。
* **Output**: `json`。

#### 第三步：進行驗證（這部分是作業的精華）
請依序執行以下兩條指令，並觀察差異：

1. **驗證 S3 存取（預期成功）**：
```bash
aws s3 ls --profile s3_user
```
* 結果：應該能正常執行，列出空列表或現有的 Bucket。

2. **驗證 EC2 存取（預期失敗）**：
```bash
aws ec2 describe-instances --profile s3_user
```
* 結果：應該會噴出報錯訊息：`An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation...`。

* 結果圖示
  * <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/36254f9b-8414-4ef5-9b60-350ee587f284" />

<br>

---

<br>

### 4. 嘗試創建 inline policy，使 s3_readonly 這個使用者在某個時間後就無法存取 s3，並且回答 inline policy 可以用在哪些地方。

從「現成的 Policy」進階到「手動客製化 Policy」，並且加入**時間限制**這個進階條件。

#### 什麼是 Inline Policy？

* **定義**：Inline Policy（內嵌策略）是直接嵌入在某個 User、Group 或 Role 中的 Policy。它與該身分是「共生」的，如果你刪除了該 User，這筆 Policy 也會跟著消失。
* **可以用在哪裡？**：
  * **特定單一使用者**：當某個權限非常特殊，且你確定不會給其他人用時。
  * **確保權限不被誤用**：因為它不能像 Managed Policy 那樣被隨意掛載給別人。
  * **強一致性**：確保身分與權限綁死，不會因為有人修改了外部的 Managed Policy 而受影響。

#### 實作步驟：讓 `s3_readonly` 在特定時間後失效

1. **移除原有的 Managed Policy**

在進行時間限制測試前，必須先拿掉原本的「永久通行證」。

* **進入 IAM 控制台**：點擊左側 **Users**，選擇 `s3_readonly`。
* **移除權限**：在 **Permissions** 標籤頁中，找到 `AmazonS3ReadOnlyAccess`，點擊該政策旁邊的 **Remove**。
* **確認**：此時該使用者的權限列表應該是空的，或者只有你即將建立的 Inline Policy。
* <img width="1920" height="945" alt="image" src="https://github.com/user-attachments/assets/47c04a52-be60-42f6-adfa-007b8548baca" />


2. **創建帶有時間限制的 Inline Policy**

現在我們為他量身打造一個「有期限的通行證」。

* **建立 Inline Policy**：在同一個使用者頁面，點擊 **Add permissions**  **Create inline policy**。
* **切換至 JSON 編輯器**：將以下內容貼入。
* **注意**：請將 `DateLessThan` 的時間設定為**現在時間往後推 5~10 分鐘**。
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*",
      "Condition": {
        "DateLessThan": {
          "aws:CurrentTime": "2026-01-11T14:10:00Z" 
        }
      }
    }
  ]
}
```
* **命名與儲存**：命名為 `S3TempAccess` 並儲存。

3. **驗證步驟 (雙重測試)**

* **測試 A：時間到期前**
  * 輸入：`aws s3 ls --profile s3_user`
  * **預期結果**：成功列出 S3 資源。

* **測試 B：時間到期後**
  * 輸入：`aws s3 ls --profile s3_user`
  * **預期結果**：噴出錯誤訊息 `An error occurred (AccessDenied) when calling the ListBuckets operation`。

* 結果圖示
  * <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/bade2fcd-c79b-43be-a0e9-00bb546584ce" />
  * <img width="1130" height="626" alt="image" src="https://github.com/user-attachments/assets/1924b8a1-c471-4639-a79c-1c1182af1dea" />

<br>

---

<br>

### 5. 嘗試創建 EC2，並且為其創建一個 S3ReadOnlyRole 的 role，使 ec2 上可以使用 aws cli（或是 sdk） 存取 s3 資源，並且不需要設定 access key。（這題可以用 aws linux，因為他有內建 aws cli）

這題是 IAM 實作中最精華的部分，它介紹了 **「IAM Role (角色)」** 如何讓 AWS 資源（如 EC2）之間進行**無金鑰**（Keyless）的安全通訊。

這題的重點是：**不要在 EC2 裡面設定 Access Key**。我們改用「賦予身分」的方式讓 EC2 具備權限。

---

#### 第一步：創建 IAM Role

首先，我們要建立一個專門給 EC2 穿的「制服」。

1. 進入 **IAM 控制台**，點擊左側 **Roles**  **Create role**。
2. **Select trusted entity**：選擇 **AWS service**，並在下方選擇 **EC2**（這代表這套制服是給 EC2 穿的）。
3. **Add permissions**：搜尋並勾選 `AmazonS3ReadOnlyAccess`。
4. **Name, review, and create**：將 Role 命名為 `EC2S3ReadOnlyRole`。
* <img width="1920" height="941" alt="image" src="https://github.com/user-attachments/assets/0fd33222-a47e-4ed3-9ae6-30aa022955b2" />
<img width="1920" height="866" alt="image" src="https://github.com/user-attachments/assets/c8bb3159-1762-4a27-b62a-840fe817f5a7" />


#### 第二步：創建 EC2 並關聯 Role

1. 進入 **EC2 控制台**，點擊 **Launch instance**。
2. **設定規格**：選擇 Amazon Linux 2023（內建已安裝 AWS CLI）。
3. **關鍵設定 (Advanced details)**：
* 向下滾動找到 **IAM instance profile**。
* 在下拉選單中選擇你剛剛建立的 **`EC2S3ReadOnlyRole`**。
* <img width="1920" height="1032" alt="image" src="https://github.com/user-attachments/assets/4c0a4ea1-fa47-4d2f-813f-5f9fae2917ad" />

4. **啟動機器**：完成其餘設定（如 Key pair 和 Security Group）後啟動。
* <img width="1920" height="1032" alt="image" src="https://github.com/user-attachments/assets/7491f1fb-a6dc-43ad-9a39-81552408aeed" />


#### 第三步：驗證（不設定 Access Key）

* 透過 SSH 或 **Instance Connect** 登入你的 EC2。
```bash
ssh -i C:\Users\Steven\Downloads\aws-0111.pem ec2-user@35.77.99.8
```

* **直接執行指令**（千萬不要下 `aws configure`）：
```bash
aws s3 ls
```

* **觀察結果**：你會發現指令成功執行了！即便你沒有輸入任何 Access Key。

* 結果圖示
  * <img width="1130" height="626" alt="image" src="https://github.com/user-attachments/assets/3159d9e0-cf0e-469d-8ec2-eafc1945287c" />





