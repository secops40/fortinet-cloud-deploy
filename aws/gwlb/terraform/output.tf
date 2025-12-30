output "Username" {
  value = "admin"
}

output "FGT1_PublicIP" {
  value = aws_eip.FGTPublicIP.public_ip
}

output "FGT1_Password" {
  value = aws_instance.fgtvm.id
}

output "GWLB_PrivateIP-az1" {
  value = data.aws_network_interface.vpcendpointip.private_ip
}

output "GWLB_Endpoint_Service" {
  value = aws_vpc_endpoint_service.fgtgwlbservice.service_name
}

output "SpokeVpc" {
  value = var.spokeVpc ? aws_vpc.customer-vpc[0].id : null
}

output "SecVpc" {
  value = aws_vpc.fgtvm-vpc.id
}
