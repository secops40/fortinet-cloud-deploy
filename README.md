# Infrastructure Deployment

此專案基於 [Fortinet FortiGate Terraform Deploy](https://github.com/fortinet/fortigate-terraform-deploy) 並進行修改。  
目標是讓使用者能夠直接部署到工作環境，同時實現 **Infrastructure as Code (IaC)** 的特性。


## 專案介紹
本專案提供自動化腳本，讓使用者可以快速開始在不同雲端平台部署 Fortinet 相關資源。

目前支援的平台：
 - [aws](./aws/)
    - [AWS Transit Gateway (FortiGate A-P HA)](./aws/transitgwy/)
    - [AWS GWLB (FortiGate Cross-AZ)](./aws/gwlb-crossaz/)
