## 【問答題】

* root user 跟 iam user 的差別？

| 特性 | Root User | IAM User |
| :----: | :----: | :----: |
| 如何創建 | 註冊 AWS 帳號時使用的 Email。 | 由 Root User 或管理者在 IAM 頁面手動建立。 |
| 權限範圍 | **無限制**。擁有帳號內所有資源、帳單與關閉帳號的最高權限。 | **預設無權限**。必須被賦予 Policy 才能執行特定動作。 |
| 安全性 | 非常危險。若外洩，整個帳號都會被掌控。 | 相對安全。遵循「最小權限原則」，外洩時影響有限。 |

* user, group, role, policy 彼此間的關係為何？policy 的格式為何？

## 【實作題】

* 為 root account 創建 MFA 登入。
* 創建 aws credential（access key & secret），並且使用 aws cli 嘗試存取 ec2 列表（可以手動創建一台機器）及 s3 列表。
* 創建一個 user，名為 `s3_readonly`，並且僅給予其 s3 readonly 的權限，為此 user 創建 credential 並且設定在 aws 內，使用不同的 profile 可以指定用哪個 credential 跟 aws 溝通，驗證方式為嘗試取得 ec2 及 s3 的列表，其中一個會失敗。
* 嘗試創建 inline policy，使 s3_readonly 這個使用者在某個時間後就無法存取 s3，並且回答 inline policy 可以用在哪些地方。
* 嘗試創建 EC2，並且為其創建一個 S3ReadOnlyRole 的 role，使 ec2 上可以使用 aws cli（或是 sdk） 存取 s3 資源，並且不需要設定 access key。（這題可以用 aws linux，因為他有內建 aws cli）
