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
### 創建 aws credential（access key & secret），並且使用 aws cli 嘗試存取 ec2 列表（可以手動創建一台機器）及 s3 列表。
### 創建一個 user，名為 `s3_readonly`，並且僅給予其 s3 readonly 的權限，為此 user 創建 credential 並且設定在 aws 內，使用不同的 profile 可以指定用哪個 credential 跟 aws 溝通，驗證方式為嘗試取得 ec2 及 s3 的列表，其中一個會失敗。
### 嘗試創建 inline policy，使 s3_readonly 這個使用者在某個時間後就無法存取 s3，並且回答 inline policy 可以用在哪些地方。
### 嘗試創建 EC2，並且為其創建一個 S3ReadOnlyRole 的 role，使 ec2 上可以使用 aws cli（或是 sdk） 存取 s3 資源，並且不需要設定 access key。（這題可以用 aws linux，因為他有內建 aws cli）
