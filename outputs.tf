output "instance_id" {
  description = "OCID de la VM de cada empresa"
  value       = { for k, v in oci_core_instance.this : k => v.id }
}

output "vcn_id" {
  description = "OCID de la VCN de cada empresa"
  value       = { for k, v in oci_core_vcn.this : k => v.id }
}

output "subnet_id" {
  description = "OCID de la subred de cada empresa"
  value       = { for k, v in oci_core_subnet.this : k => v.id }
}

output "public_ip" {
  description = "IP pública de la VM de cada empresa"
  value       = { for k, v in oci_core_instance.this : k => v.public_ip }
}