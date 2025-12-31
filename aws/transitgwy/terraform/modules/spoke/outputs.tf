# Spoke VPC 1 Outputs
output "spoke_vpc1_id" {
  description = "The ID of Spoke VPC 1"
  value       = aws_vpc.spoke_vpc1.id
}

output "spoke_vpc2_id" {
  description = "The ID of Spoke VPC 2"
  value       = aws_vpc.spoke_vpc2.id
}

