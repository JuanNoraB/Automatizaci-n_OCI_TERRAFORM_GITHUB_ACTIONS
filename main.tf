# qué recursos OCI se crean y cómo se conectan entre sí

# ==================== Consulta de zonas disponibles ====================
# Obtiene la lista de zonas de disponibilidad en la región
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# ==================== Red Principal (VCN) ====================
# Crea la red principal (VCN) con el bloque de CIDR especificado
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = local.vcn_name
  dns_label      = local.vcn_dns_label
}

# ==================== Puerta a Internet ====================
resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.internet_gateway_name
  enabled        = true
}

# ==================== Tabla de Rutas ====================
# Todo el tráfico a internet (0.0.0.0/0) va por el Internet Gateway
resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.route_table_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

# ==================== Reglas de Firewall ====================
resource "oci_core_security_list" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = local.security_list_name

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

  # Tráfico entrante: ICMP desde la VCN interna
  ingress_security_rules {
    source      = var.vcn_cidr
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

# ==================== Subred Pública ====================
# Aquí vive la VM, con acceso a internet y reglas de seguridad
resource "oci_core_subnet" "this" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.subnet_cidr
  display_name               = local.subnet_name
  dns_label                  = local.subnet_dns_label
  route_table_id             = oci_core_route_table.this.id
  security_list_ids          = [oci_core_security_list.this.id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
}

# ==================== Máquina Virtual ====================
resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = local.instance_name
  shape               = var.shape

  fault_domain = "FAULT-DOMAIN-1"

  # Configuración de CPU y RAM
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  # Configuración de red: IP pública
  create_vnic_details {
    subnet_id        = oci_core_subnet.this.id
    assign_public_ip = true
    display_name     = local.vnic_name
    hostname_label   = local.vm_hostname_label
  }

  # Llave SSH para acceder a la VM
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  # Imagen del sistema operativo y disco
  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
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