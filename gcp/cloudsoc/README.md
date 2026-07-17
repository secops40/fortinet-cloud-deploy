# Fortinet CloudSOC

在 GCP 上部署 FortiSIEM + FortiSOAR 的 Terraform Template。

---

## 建立的資源

| 資源類型 | 說明 |
|----------|------|
| `google_compute_network` | VPC（MTU 1500，關閉 auto subnet） |
| `google_compute_subnetwork` | 2 個 Subnet，各對應一個 Zone，每個 /24 |
| `google_compute_firewall` × 2 | Management（全埠）+ HTTPS（TCP 443） |
| `google_compute_address` × N | 所有 Instance 的固定 Public IP |
| `google_compute_disk` × 4N | FortiSIEM 每台 4 顆 Extra Disk（/opt /svn /cmdb /data） |
| `google_compute_instance` × N | FortiSIEM 1~4 台 + FortiSOAR 1 台 |

---

## 前置條件

| 項目 | 版本 / 說明 |
|------|-------------|
| Terraform | >= 1.3 |
| Google Provider | >= 5.0（自動下載） |
| GCP IAM 權限 | `compute.admin`、`iam.serviceAccountUser` |
| **GCP Image** | **FortiSIEM / FortiSOAR Image 需事先匯入 GCP 專案，或可從指定 `image_project` 存取** |

> **注意：** GCP Image 必須在部署前確認已存在且可存取，否則 `terraform apply` 將會失敗。
> 匯入方式請參閱 [IMPORT IMAGES](IMPORT_IMAGES.md)；如有問題，請洽 **Support SE**。

---

## 快速開始

```bash
# 1. 複製範例設定
cp terraform.tfvars.example terraform.tfvars

# 2. 編輯 terraform.tfvars，至少填入必填欄位
#    project_id、prefix、ssh_public_keys

# 3. 初始化並部署
terraform init
terraform plan
terraform apply
```

Apply 完成後，Terminal 會輸出所有 Instance 的名稱、Zone 和 Public IP。

---

## 登入說明

### FortiSIEM

使用 SSH Key 登入，username 與 `fsm_ssh_keys` 中指定的一致：

```bash
ssh <yourusername>@<fsm_public_ip> -i /path/to/private_key
```

Public IP 從 output 取得：

```bash
terraform output fsm_instances
```

### FortiSOAR

**第一次登入使用預設密碼： changeme**

```bash
ssh csadmin@<fsr_public_ip>
# 預設密碼：changeme
```

**第一次登入後，修改密碼後，之後即可以 private key 進行登入。**

之後可改用 Key 登入：

```bash
ssh csadmin@<fsr_public_ip> -i /path/to/private_key
```

Public IP 從 output 取得：

```bash
terraform output fsr_instance
```

---

## 銷毀資源

```bash
terraform destroy
```

所有由 Terraform 建立的資源（Instance、Disk、IP、VPC）都會一併刪除。

### 若啟用了 `deletion_protection = true`

GCP 會拒絕刪除受保護的 Instance，`terraform destroy` 會失敗。需先關閉保護：

```hcl
# terraform.tfvars
deletion_protection = false
```

```bash
terraform apply   # 先套用關閉保護
terraform destroy # 再銷毀
```

> Extra Disk（/opt /svn /cmdb /data）為獨立資源，`terraform destroy` 會一併刪除，請確認資料已備份。

---

## 變數參考

### 必填

| 變數 | 說明 |
|------|------|
| `project_id` | GCP Project ID |
| `prefix` | 資源名稱前綴，如 `test` → `test-vpc`、`test-fsm-1` |

### 網路

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `region` | `asia-east1` | 部署 Region（台灣） |
| `zones_override` | `[]` | 覆寫兩個 Zone，空 = 自動使用 `<region>-a` 和 `<region>-b` |
| `ip_block` | `10.0.0.0/16` | VPC IP 範圍 /16，自動切出兩個 /24 Subnet |
| `management_source_ips` | 預設 5 個 IP | 允許全埠存取的來源 CIDR 清單 |
| `https_source_ips` | `0.0.0.0/0` | 允許 TCP 443 的來源 CIDR 清單 |

### Instance 保護

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `deletion_protection` | `false` | `true` = 防止 Terraform 或手動誤刪 Instance；建議 Prod 設 `true` |

### FortiSIEM

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `fsm_count` | `1` | Instance 數量（1~4）|
| `fsm_image` | `fortisiem-gcp-7-5-1-0620` | Boot Image 名稱 |
| `fsm_image_project` | `""` | Image 所在 Project；空 = 與 `project_id` 相同 |
| `fsm_machine_type` | `n2-standard-8` | Machine Type |
| `fsm_boot_disk_type` | `pd-ssd` | Boot Disk 類型 |
| `fsm_disk_type` | `pd-ssd` | Extra Disk 類型（/opt /svn /cmdb /data 共用） |
| `fsm_disk5_size_gb` | `60` | /data Disk 大小（最小 60 GB） |
| `fsm_use_spot` | `false` | 啟用 SPOT 定價 |
| `fsm_spot_termination_action` | `STOP` | SPOT 被回收時：`STOP`（保留 VM 狀態）或 `DELETE` |

### FortiSOAR

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `fsr_image` | `fortisoar-vmware-8-0-0-6034` | Machine Image 名稱（非 Boot Disk Image） |
| `fsr_image_project` | `""` | Machine Image 所在 Project；空 = 與 `project_id` 相同 |
| `fsr_machine_type` | `n2-standard-8` | Machine Type |
| `fsr_use_spot` | `false` | 啟用 SPOT 定價 |
| `fsr_spot_termination_action` | `DELETE` | SPOT 被回收時：`DELETE` 或 `STOP` |

> FortiSOAR 使用 **Machine Image** 建立，磁碟設定繼承自 Machine Image，無需另設 boot disk type。

### SSH

| 變數 | 必填 | 說明 |
|------|------|------|
| `fsm_ssh_keys` | **是** | FortiSIEM SSH Key，格式：`"yourusername:ssh-rsa AAAA..."`；username 填你的帳號 |
| `fsr_ssh_keys` | 否 | FortiSOAR SSH Key，若設定 username 必須是 `csadmin`；預設空 = 不注入 |

> 查詢你的 SSH username：`gcloud config get-value account | cut -d@ -f1`

---

## FortiSIEM Disk 說明

每台 FortiSIEM 建立 5 顆 Disk（含 Boot Disk）：

| Disk | 命名範例（prefix=test, n=1） | 掛載點 | 大小 |
|------|------------------------------|--------|------|
| Disk 1（Boot） | `test-fsm-1`（隨 Instance） | `/` | Image 預設 |
| Disk 2 | `test-fsm-1-opt` | `/opt` | 100 GB |
| Disk 3 | `test-fsm-1-svn` | `/svn` | 60 GB |
| Disk 4 | `test-fsm-1-cmdb` | `/cmdb` | 60 GB |
| Disk 5 | `test-fsm-1-data` | `/data` | 60 GB（可設定） |

> Disk 2 (/opt) 會由 `configFSM.sh` 自動分為 `/opt` 和 `swap` 兩個 Partition。

所有 Disk 都有 Label `keep_resource=true`。

---

## Zone 分配說明

FortiSIEM Instance 以 **Round-Robin** 方式分散到兩個 Zone，確保 HA。
每台 Instance 的 4 顆 Extra Disk 也在**相同的 Zone**（GCP 硬性要求）。

| Instance | Zone | 說明 |
|----------|------|------|
| fsm-1 | zones[0]（如 asia-east1-a） | index 0 % 2 = 0 |
| fsm-2 | zones[1]（如 asia-east1-b） | index 1 % 2 = 1 |
| fsm-3 | zones[0] | index 2 % 2 = 0 |
| fsm-4 | zones[1] | index 3 % 2 = 1 |
| fsr-1  | zones[0] | 固定放在與 fsm-1 相同的 Zone |

---

## SPOT Instance 說明

SPOT 比 On-Demand 便宜約 60~80%，但 GCP 可能在資源不足時回收。

| 設定 | FortiSIEM 預設 | FortiSOAR 預設 |
|------|---------------|---------------|
| `use_spot` | `false` | `false` |
| `spot_termination_action` | `STOP`（停機保留資料）| `DELETE`（刪除 Instance） |

- **FortiSIEM** 建議 `STOP`：/svn、/cmdb、/data 的資料可保留，重啟後恢復服務。
- **FortiSOAR** 建議 `DELETE`：SOAR 屬無狀態服務，重新部署較單純。

---

## ⚠️ SSH 注意事項

本 Template 預設啟用 `block-project-ssh-keys = true`，會封鎖 Project 層級的 SSH Key。

**若不設定 `ssh_public_keys`**，所有 Instance 不接受任何 SSH 連線，只能透過：
- GCP Console → **查看序列埠輸出**
- **IAP Tunnel**：`gcloud compute ssh <instance> --tunnel-through-iap`

```hcl
ssh_public_keys = [
  "username:ssh-rsa AAAA...你的公鑰... comment",
]
```

> 若 GCP Project 啟用了 **OS Login**（`enable-oslogin=TRUE`），metadata 的 SSH key 會被忽略。確認方式：
> ```bash
> gcloud compute project-info describe --format="value(commonInstanceMetadata.items)"
> ```

---

## 常用範例

### 範例 1：最小化部署（1 台 FSM + 1 台 FSR）

```hcl
project_id = "my-project"
prefix     = "dev"

fsm_count = 1

fsm_ssh_keys = ["yourusername:ssh-rsa AAAA..."]
```

### 範例 2：完整 HA 部署（4 台 FSM，分散兩 Zone）

```hcl
project_id = "my-project"
prefix     = "prod"

fsm_count           = 4
deletion_protection = true

fsm_ssh_keys = ["yourusername:ssh-rsa AAAA..."]
```

### 範例 3：SPOT 省錢部署（開發測試用）

```hcl
project_id = "my-project"
prefix     = "staging"

fsm_count                   = 2
fsm_use_spot                = true
fsm_spot_termination_action = "STOP"

fsr_use_spot                = true
fsr_spot_termination_action = "DELETE"

fsm_ssh_keys = ["yourusername:ssh-rsa AAAA..."]
```

### 範例 4：使用其他 Region 和不同 IP Block

```hcl
project_id = "my-project"
prefix     = "sg"

region   = "asia-southeast1"
ip_block = "10.10.0.0/16"

fsm_count = 1
```

---

## Outputs

`terraform apply` 完成後會輸出：

```
subnet_info = {
  "asia-east1-a" = { cidr = "10.0.1.0/24", name = "test-vpc-asia-east1-a" }
  "asia-east1-b" = { cidr = "10.0.2.0/24", name = "test-vpc-asia-east1-b" }
}
vpc_name = "test-vpc"
fsm_instances = {
  "test-fsm-1" = { public_ip = "x.x.x.x", zone = "asia-east1-a" }
  "test-fsm-2" = { public_ip = "x.x.x.x", zone = "asia-east1-b" }
}
fsr_instance = {
  name      = "test-fsr-1"
  public_ip = "x.x.x.x"
  zone      = "asia-east1-a"
}
```

事後也可以用 `terraform output` 重新查看。

