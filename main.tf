# qué recursos OCI se crean y cómo se conectan entre sí
# Cada empresa definida en var.empresas genera su propio set de recursos, aislado del resto.

# ==================== Consulta de zonas disponibles ====================
# Obtiene la lista de zonas de disponibilidad en la región
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# ==================== Red Principal (VCN) - una por empresa ====================
resource "oci_core_vcn" "this" {
  for_each       = var.empresas
  compartment_id = var.compartment_ocid
  cidr_blocks    = [each.value.vcn_cidr]
  display_name   = "${each.key}-vcn"
  dns_label      = each.value.vcn_dns_label
}

# ==================== Puerta a Internet - una por empresa ====================
resource "oci_core_internet_gateway" "this" {
  for_each       = var.empresas
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this[each.key].id
  display_name   = "${each.key}-igw"
  enabled        = true
}

# ==================== Tabla de Rutas - una por empresa ====================
# Todo el tráfico a internet (0.0.0.0/0) va por el Internet Gateway de esa empresa
resource "oci_core_route_table" "this" {
  for_each       = var.empresas
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this[each.key].id
  display_name   = "${each.key}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this[each.key].id
  }
}

# ==================== Reglas de Firewall - una por empresa ====================
resource "oci_core_security_list" "this" {
  for_each       = var.empresas
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this[each.key].id
  display_name   = "${each.key}-sl"

  # Tráfico saliente: permitir todo
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  # Tráfico entrante: SSH (puerto 22)
  ingress_security_rules {
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Tráfico entrante: ICMP desde internet
  ingress_security_rules {
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "1"

    icmp_options {
      type = 3
      code = 4
    }
  }

  # Tráfico entrante: ICMP desde la VCN interna de esa empresa
  ingress_security_rules {
    source      = each.value.vcn_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "1"

    icmp_options {
      type = 3
    }
  }

  # Tráfico entrante: HTTP (puerto 80) para la app web
  ingress_security_rules {
    description = "HTTP API"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Tráfico entrante: HTTPS (puerto 443) para la app web
  ingress_security_rules {
    description = "API HTTPS"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"

    tcp_options {
      min = 443
      max = 443
    }
  }
}

# ==================== Subred Pública - una por empresa ====================
# Aquí vive la VM de cada empresa, con acceso a internet y reglas de seguridad propias
resource "oci_core_subnet" "this" {
  for_each                   = var.empresas
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this[each.key].id
  cidr_block                 = each.value.subnet_cidr
  display_name               = "${each.key}-subnet-public"
  dns_label                  = each.value.subnet_dns_label
  route_table_id             = oci_core_route_table.this[each.key].id
  security_list_ids          = [oci_core_security_list.this[each.key].id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
}

# ==================== Máquina Virtual - una por empresa ====================
resource "oci_core_instance" "this" {
  for_each             = var.empresas
  compartment_id       = var.compartment_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name         = "${each.key}-vm"
  shape                = each.value.shape

  fault_domain = "FAULT-DOMAIN-1"

  # Configuración de CPU y RAM
  shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_in_gbs
  }

  # Configuración de red: IP pública
  create_vnic_details {
    subnet_id        = oci_core_subnet.this[each.key].id
    assign_public_ip = true
    display_name     = "${each.key}-vnic"
    hostname_label   = each.value.vm_hostname_label
  }

  # Llave SSH para acceder a la VM de esta empresa
  metadata = {
    ssh_authorized_keys = each.value.ssh_public_key
  }

  # Imagen del sistema operativo y disco (compartida entre todas las empresas)
  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = each.value.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = each.value.boot_volume_vpus_per_gb
  }

  # Opciones de seguridad y disponibilidad
  launch_options {
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
  }

  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
}