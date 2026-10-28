output "instance_id" {
  value = oci_core_instance.this.id
}

output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "subnet_id" {
  value = oci_core_subnet.this.id
}

output "public_ip" {
  description = "IP pública de la VM"
  value       = oci_core_instance.this.public_ip
}