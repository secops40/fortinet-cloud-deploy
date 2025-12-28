
output "Username" {
  value = "admin"
}

output "FGT1_PublicIP" {
  value = aws_eip.FGTPublicIP.public_ip
}

output "FGT1_Password" {
  value = aws_instance.fgtvm.id
}

output "FGT2_PublicIP" {
  value = aws_eip.FGT2PublicIP.public_ip
}

output "FGT2_Password" {
  value = aws_instance.fgtvm2.id
}

output "GWLB_PrivateIP" {
  value = data.aws_network_interface.vpcendpointip.private_ip
}

output "GWLB_PrivateIP2" {
  value = data.aws_network_interface.vpcendpointip2.private_ip
}

output "GWLB_Endpoint_Service" {
  value = aws_vpc_endpoint_service.fgtgwlbservice.service_name
}