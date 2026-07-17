# 前置作業：匯入 GCP Image

在執行 `terraform apply` 之前，FortiSIEM 和 FortiSOAR 的 Image 必須先匯入 GCP 專案。
兩者的 Image 類型不同，匯入方式也不同。

| 產品 | GCP Image 類型 | Terraform 變數 |
|------|---------------|----------------|
| FortiSIEM | **GCP Image**（`google_compute_image`） | `fsm_image` |
| FortiSOAR | **Machine Image**（`google_compute_machine_image`） | `fsr_image` |

---

## FortiSIEM — 匯入 GCP Image

FortiSIEM 使用標準 GCP Image，匯入前請先將 Fortinet 提供的 ZIP 檔解壓縮，並使用其中的 .tar.gz 檔進行後續匯入。

請參閱官方文件：
> **[Import FortiSIEM GCP Image into Google Cloud Image](https://docs.fortinet.com/document/fortisiem/7.5.1/google-cloud-platform-gcp-installation-guide/131018/fresh-installation#Import)**

匯入完成後，記下 Image 名稱（例如 `fortisiem-gcp-7-5-1-0620`），填入 `terraform.tfvars`：

```hcl
fsm_image         = "fortisiem-gcp-7-5-1-0620"
fsm_image_project = ""   # 空 = 與 project_id 相同；若 Image 在其他 project 則填入該 project ID
```

確認 Image 存在：

```bash
gcloud compute images list --filter="name~fortisiem" --no-standard-images
```

---

## FortiSOAR — 匯入 Machine Image

FortiSOAR 使用 GCP **Machine Image**（從 OVA 檔案匯入），需先將 OVA 上傳至 Google Cloud Storage，再透過 `gcloud compute migration` 工具匯入。

### Prerequisites
1. 授予 VM Migration 服務帳戶 Storage 讀取權限: <br />
    Machine Image 匯入過程需要從 Cloud Storage 讀取 OVA 檔案，因此必須授予 VM Migration Service Agent Storage Object Viewer 權限。
    ```
    PROJECT_ID="<your-project-id>"
    BUCKET="<your-bucket>" 
    PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")

    gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-vmmigration.iam.gserviceaccount.com --role=roles/storage.objectViewer
    ```
2. 確認有至少一個 VPC Network 存在: <br />
    Machine Image 匯入期間，GCP 會建立暫存虛擬機。因此，專案內至少需要一組可用的 VPC Network，且 `subnet-mode` 為 `auto`，以自動在各個區域建立 Subnet。<br />
    若專案內沒有合適的 VPC Network，可建立一組僅供 Machine Image 匯入使用的隔離網路：
    ```
    gcloud compute networks create "default" \ 
    --subnet-mode="auto" \ 
    --mtu="1500" \ 
    --description="Isolated VPC for machine image migration only" \ 
    --bgp-routing-mode="regional"
    ```

### Step 1：匯入

```bash
gcloud compute migration machine-image-imports create fortisoar-vmware-8-0-0-6034 \
  --source-file=gs://<your-bucket>/fortisoar-vmware-enterprise-8.0.0-6034.ova \
  --labels="keep_resource=true" \
  --description="FortiSOAR 8.0.0"
```

> 將 `<your-bucket>` 換成實際的 GCS bucket 名稱。

### Step 2：確認匯入狀態

```bash
gcloud compute migration machine-image-imports list
```

等待 `STATE` 欄位變為 `SUCCEEDED` 後再繼續。

### Step 3：清除匯入紀錄（完成後）

匯入完成後，`machine-image-imports` 只是操作記錄，刪除不影響已建立的 Machine Image：

```bash
gcloud compute migration machine-image-imports delete fortisoar-vmware-8-0-0-6034
```

### Step 4：確認 Machine Image 存在

```bash
gcloud beta compute machine-images list --filter="name~fortisoar"
```

確認後，填入 `terraform.tfvars`：

```hcl
fsr_image         = "fortisoar-vmware-8-0-0-6034"
fsr_image_project = ""   # 空 = 與 project_id 相同；若 Machine Image 在其他 project 則填入該 project ID
```

---

## 完成後

兩個 Image 都確認存在後，即可執行部署：

```bash
terraform init
terraform plan
terraform apply
```
