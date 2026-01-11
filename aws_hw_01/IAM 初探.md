## 【問答題】

### root user 跟 iam user 的差別？

| 特性 | Root User | IAM User |
| :----: | :----: | :----: |
| 如何創建 | 註冊 AWS 帳號時使用的 Email。 | 由 Root User 或管理者在 IAM 頁面手動建立。 |
| 權限範圍 | **無限制**。擁有帳號內所有資源、帳單與關閉帳號的最高權限。 | **預設無權限**。必須被賦予 Policy 才能執行特定動作。 |
| 安全性 | 非常危險。若外洩，整個帳號都會被掌控。 | 相對安全。遵循「最小權限原則」，外洩時影響有限。 |

<br>

---

<br>

### user, group, role, policy 彼此間的關係為何？policy 的格式為何？

<img width="2878" height="1620" alt="image" src="https://github.com/user-attachments/assets/494aefd0-9ecf-40d6-ae76-9ad8c37e32b2" />

這四個元件的關係可以用一個簡單的公式來理解：「 `誰 (User/Group/Role)` + `透過什麼規則 (Policy)` + 能做什麼事」。

#### 彼此間的關係 
* **User (使用者)**：代表一個具體的人（例如你）。每個人都有自己的登入帳號與密碼。

* **Group (使用者群組)**：使用者的集合。你可以把多個 User 丟進同一個 Group。
  * 關係：你把 Policy 掛在 Group 上，裡面所有的 User 就會自動繼承這些權限，方便大量管理。

* **Role (角色)**：代表一個虛擬的身分。它沒有固定的密碼或金鑰，而是給「有需要的人或服務」臨時`切換（Assume）`進去使用的。
  * 關係：User 可以「變身」成某個 Role；EC2 機器也可以「戴上」某個 Role 來獲得權限。

* **Policy (策略)**：這是一份純文字文件，規定了「准許」或「拒絕」哪些動作。
  * 關係：Policy 是靈魂，它必須**附加（Attach）**在 User、Group 或 Role 上，這些身分才會有權限。

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

### 為 root account 創建 MFA 登入。

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

### 創建 aws credential（access key & secret），並且使用 aws cli 嘗試存取 ec2 列表（可以手動創建一台機器）及 s3 列表。

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

### 創建一個 user，名為 `s3_readonly`，並且僅給予其 s3 readonly 的權限，為此 user 創建 credential 並且設定在 aws 內，使用不同的 profile 可以指定用哪個 credential 跟 aws 溝通，驗證方式為嘗試取得 ec2 及 s3 的列表，其中一個會失敗。

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
* *結果：* 應該能正常執行，列出空列表或現有的 Bucket。

2. **驗證 EC2 存取（預期失敗）**：
```bash
aws ec2 describe-instances --profile s3_user
```
* *結果：* 應該會噴出報錯訊息：`An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation...`。

* 結果圖示
  * <img width="1113" height="626" alt="image" src="https://github.com/user-attachments/assets/36254f9b-8414-4ef5-9b60-350ee587f284" />

<br>

---

<br>

### 嘗試創建 inline policy，使 s3_readonly 這個使用者在某個時間後就無法存取 s3，並且回答 inline policy 可以用在哪些地方。

<br>

---

<br>

### 嘗試創建 EC2，並且為其創建一個 S3ReadOnlyRole 的 role，使 ec2 上可以使用 aws cli（或是 sdk） 存取 s3 資源，並且不需要設定 access key。（這題可以用 aws linux，因為他有內建 aws cli）
