# Defini que variables existen que tipo son y su valor por defecto
# no existen valores reales sono son definiciones de que forma deben tener
# ==================== Credenciales OCI ====================
variable "tenancy_ocid" {} # Cuenta principal/empresa completa dentro de OCI.
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

# ==================== Proyecto y Ambiente ====================
variable "project_name" {
  description = "Nombre del proyecto/empresa. Cada cliente tiene su propia copia de esta carpeta con su propio project_name."
  type        = string
}

variable "environment" {
  description = "Ambiente: dev, staging, prod"
  type        = string
}

# ==================== Recursos ====================
variable "compartment_ocid" {} # En qué compartment se crean los recursos.
variable "vcn_cidr" {}         # El rango IP de la red grande. Ejemplo: 10.0.0.0/16
variable "subnet_cidr" {}      # El rango IP de la subred. Ejemplo: 10.0.2.0/24
variable "ssh_public_key" {}   # La llave pública que se inyecta en la VM para que luego entres por SSH.
variable "image_ocid" {}       # La imagen de sistema operativo de la VM. Ubuntu 22.04 Minimal aarch64.

# Opcionales. Si no se definen, se generan solos a partir de project_name + environment (ver locals).
# Solo letras/números, sin guiones, máx 15 caracteres.
variable "vcn_dns_label" {
  description = "Etiqueta DNS de la VCN. Opcional: por defecto <project_name><environment>vcn."
  type        = string
  default     = null
}

variable "subnet_dns_label" {
  description = "Etiqueta DNS de la subnet. Opcional: por defecto <project_name><environment>sub."
  type        = string
  default     = null
}

variable "vm_hostname_label" {
  description = "Hostname de la VM. Opcional: por defecto <project_name><environment>vm."
  type        = string
  default     = null
}

variable "shape" {
  description = "Tipo de instancia"
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Número de OCPUs"
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memoria RAM en GB"
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Tamaño del disco en GB"
  default     = 100
}

variable "boot_volume_vpus_per_gb" {
  description = "10 = Balanced, 20 = High Performance. Nivel de rendimiento del disco."
  default     = 10
}

# ==================== Locals ====================
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Nombres de recursos (puedes sobrescribir estas variables si quieres nombres personalizados)
  vcn_name              = "${local.name_prefix}-vcn"
  subnet_name           = "${local.name_prefix}-subnet-public"
  internet_gateway_name = "${local.name_prefix}-igw"
  route_table_name      = "${local.name_prefix}-rt"
  security_list_name    = "${local.name_prefix}-sl"
  instance_name         = "${local.name_prefix}-vm"
  vnic_name             = "${local.name_prefix}-vnic"

  # Etiquetas DNS: minúsculas, solo letras/números, base de máx 12 caracteres (límite de OCI: 15)
  dns_base          = substr(lower(replace("${var.project_name}${var.environment}", "/[^a-zA-Z0-9]/", "")), 0, 12)
  vcn_dns_label     = coalesce(var.vcn_dns_label, "${local.dns_base}vcn")
  subnet_dns_label  = coalesce(var.subnet_dns_label, "${local.dns_base}sub")
  vm_hostname_label = coalesce(var.vm_hostname_label, "${local.dns_base}vm")
}