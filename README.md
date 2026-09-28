Los 5 archivos:
- `provider.tf` → cómo Terraform se conecta a OCI
- `variables.tf` → qué cosas pueden cambiar
- `terraform.tfvars` → los valores reales que tú usas
- `main.tf` → los recursos que se van a crear
- `outputs.tf` → lo que Terraform te devuelve al final

1️⃣ Availability Domains (líneas 3-7)
Qué hace: Consulta las zonas disponibles en tu región

Necesita:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
Resultado: Te devuelve las zonas donde puedes crear recursos (ej: AD-1, AD-2, AD-3)

2️⃣ VCN - Red Principal (líneas 9-16)
Qué hace: Crea tu red privada grande en OCI

Necesita 4 cosas:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa → Dónde crear la VCN
cidr_blocks = ["10.0.0.0/16"] → Rango de IPs (65,536 direcciones IP disponibles)
display_name = integrator-v1-dev-vcn → Nombre que verás en la consola
dns_label = integratorv1devvcn → Etiqueta DNS sin caracteres especiales
3️⃣ Internet Gateway (líneas 18-24)
Qué hace: Puerta para que tu red pueda acceder a internet

Necesita 4 cosas:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
vcn_id = DEPENDE del VCN que creaste arriba (oci_core_vcn.this.id)
display_name = integrator-v1-dev-igw
enabled = true → Activado desde el inicio
Dependencia: No puedes crear esto sin la VCN primero

4️⃣ Route Table - Tabla de Rutas (líneas 26-38)
Qué hace: Define cómo sale el tráfico de tu red hacia internet

Necesita 3 cosas + 1 regla:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
vcn_id = DEPENDE del VCN (oci_core_vcn.this.id)
display_name = integrator-v1-dev-rt
Regla de ruta:

destination = 0.0.0.0/0 → Todo el tráfico a internet
network_entity_id = DEPENDE del Internet Gateway (oci_core_internet_gateway.this.id)
Dependencia: Necesita VCN e Internet Gateway

5️⃣ Security List - Firewall (líneas 40-89)
Qué hace: Controla qué tráfico puede entrar/salir de tu red

Necesita 3 cosas + reglas:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
vcn_id = DEPENDE del VCN (oci_core_vcn.this.id)
display_name = integrator-v1-dev-sl
Reglas de tráfico SALIENTE (egress):

Permitir TODO (protocol = "all") hacia 0.0.0.0/0 (internet completo)
Reglas de tráfico ENTRANTE (ingress):

SSH (puerto 22): Desde 0.0.0.0/0 (cualquier IP puede conectarse por SSH)
ICMP (ping): Desde 0.0.0.0/0 (tipo 3, código 4)
ICMP interno: Desde 10.0.0.0/16 (tu propia VCN, tipo 3)
Dependencia: Necesita VCN

6️⃣ Subnet - Subred Pública (líneas 91-103)
Qué hace: Una sección específica dentro de tu VCN donde vive tu VM

Necesita 8 cosas:

compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
vcn_id = DEPENDE del VCN (oci_core_vcn.this.id)
cidr_block = 10.0.2.0/24 → Rango de IPs para esta subred (256 IPs)
display_name = integrator-v1-dev-subnet-public
dns_label = integratorv1devsubnet
route_table_id = DEPENDE de Route Table (oci_core_route_table.this.id)
security_list_ids = DEPENDE de Security List ([oci_core_security_list.this.id])
assign_public_ip = true → Las VMs tendrán IP pública
Dependencia: Necesita VCN, Route Table y Security List

7️⃣ Instance - Máquina Virtual (líneas 105-149)
Qué hace: Tu servidor/VM donde corren tus aplicaciones

Necesita MUCHAS cosas:

Básico (5):
compartment_ocid = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
availability_domain = DEPENDE de la consulta inicial (primera zona disponible)
display_name = integrator-v1-dev-vm
shape = VM.Standard.A1.Flex → Tipo de máquina (ARM)
fault_domain = FAULT-DOMAIN-1 → Para alta disponibilidad
CPU y RAM (2):
ocpus = 4 → 4 núcleos
memory_in_gbs = 24 → 24 GB de RAM
Red (1):
subnet_id = DEPENDE de Subnet (oci_core_subnet.this.id)
assign_public_ip = true → IP pública asignada
vnic_name = integrator-v1-dev-vnic
Acceso SSH (1):
ssh_authorized_keys = PEGA_AQUI_TU_PUBLIC_KEY → Tu llave SSH pública
Sistema operativo y disco (3):
image_ocid = ocid1.image.oc1.iad.aaaaaaaaqoeodp5azjlglyddmmsnkncciwtrrof7gz7xhe3ikeibnmnahqga → Ubuntu 22.04 ARM
boot_volume_size_in_gbs = 100 → Disco de 100 GB
boot_volume_vpus_per_gb = 10 → Rendimiento balanceado
Seguridad (1):
is_pv_encryption_in_transit_enabled = true → Encriptación activada
Dependencia: Necesita Subnet (que a su vez necesita TODO lo anterior)

🔗 Orden de creación (dependencias)
1. Availability Domains (consulta)
2. VCN
3. Internet Gateway (necesita VCN)
4. Route Table (necesita VCN + Internet Gateway)
5. Security List (necesita VCN)
6. Subnet (necesita VCN + Route Table + Security List)
7. Instance/VM (necesita Subnet + todo lo anterior)
Terraform automáticamente crea los recursos en el orden correcto basándose en estas dependencias 👌


