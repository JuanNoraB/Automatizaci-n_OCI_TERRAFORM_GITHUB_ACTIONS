# ==================== Credenciales OCI ====================
variable "tenancy_ocid" {} # Cuenta principal/empresa completa dentro de OCI.
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

# ==================== Recursos compartidos ====================
variable "compartment_ocid" {} # En qué compartment se crean los recursos (compartido por todas las empresas).
variable "image_ocid" {}       # La imagen de sistema operativo de la VM (compartida por todas las empresas).

# ==================== Empresas / Clientes ====================
# Cada entrada del mapa crea su propia VCN + Subnet + Security List + VM,
# totalmente aislada de las demás empresas. La key del mapa (ej: "isagen-prod")
# se usa como nombre único para todos los recursos de esa empresa.
variable "empresas" {
  description = "Mapa de empresas/clientes. Cada una genera su propia infraestructura aislada."
  type = map(object({
    vcn_cidr                = string # Rango IP de la VCN de esta empresa. Ejemplo: 10.0.0.0/16
    subnet_cidr             = string # Rango IP de la subred de esta empresa. Ejemplo: 10.0.2.0/24
    vcn_dns_label           = string # Único, solo letras/números, máx 15 caracteres.
    subnet_dns_label        = string # Único, solo letras/números, máx 15 caracteres.
    vm_hostname_label       = string # Único, solo letras/números, máx 15 caracteres.
    ssh_public_key          = string # Llave SSH pública para acceder a la VM de esta empresa.
    shape                   = optional(string, "VM.Standard.A1.Flex")
    ocpus                   = optional(number, 4)
    memory_in_gbs           = optional(number, 24)
    boot_volume_size_in_gbs = optional(number, 100)
    boot_volume_vpus_per_gb = optional(number, 10) # 10 = Balanced, 20 = High Performance.
  }))
}