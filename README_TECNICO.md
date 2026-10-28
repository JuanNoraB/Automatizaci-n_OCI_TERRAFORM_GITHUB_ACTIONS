# Despliegue de infraestructura en Oracle Cloud (OCI) con Terraform

> Documentación técnica detallada. Para una guía corta paso a paso ver [README.md](README.md).

Plantilla de Terraform que aprovisiona en Oracle Cloud Infrastructure (OCI) la infraestructura base de un cliente: una red virtual con acceso a Internet y una máquina virtual Ubuntu con arquitectura ARM.

Principio de operación: **una carpeta equivale a un cliente**. Terraform registra lo que crea en un archivo de estado local (`terraform.tfstate`) ubicado en la carpeta donde se ejecuta. Por ello, cada cliente debe disponer de su propia carpeta (o su propio clon del repositorio) para que sus recursos permanezcan aislados de los de otros clientes.

## Contenido

1. [Archivos del repositorio](#1-archivos-del-repositorio)
2. [Arquitectura desplegada](#2-arquitectura-desplegada)
3. [Detalle de los recursos (`main.tf`)](#3-detalle-de-los-recursos-maintf)
4. [Referencia de variables](#4-referencia-de-variables)
5. [Outputs](#5-outputs)
6. [Prerrequisitos (Linux y Windows)](#6-prerrequisitos-linux-y-windows)
7. [Procedimiento: crear un cliente nuevo](#7-procedimiento-crear-un-cliente-nuevo)
8. [Gestión de múltiples clientes con Git](#8-gestión-de-múltiples-clientes-con-git)
9. [Seguridad](#9-seguridad)
10. [Límites del Free Tier de OCI](#10-límites-del-free-tier-de-oci)
11. [Solución de problemas](#11-solución-de-problemas)
12. [Eliminación de la infraestructura de un cliente](#12-eliminación-de-la-infraestructura-de-un-cliente)
13. [Documentos relacionados](#13-documentos-relacionados)

---

## 1. Archivos del repositorio

El repositorio contiene cinco archivos de Terraform:

| Archivo | Función |
|---|---|
| `provider.tf` | Define la versión requerida de Terraform y del proveedor `oracle/oci`, así como las credenciales con las que Terraform se autentica en OCI. |
| `variables.tf` | Declara las variables de entrada (tipo, descripción y valor por defecto) y los nombres derivados de los recursos (`locals`). |
| `terraform.tfvars.example` | Plantilla con valores de ejemplo (`xxx`). Se copia como `terraform.tfvars`. |
| `terraform.tfvars` | Contiene los valores reales de cada cliente. **Es el único archivo que se edita para un cliente nuevo.** No se sube al repositorio (`.gitignore`). |
| `main.tf` | Declara los recursos de OCI que se crean y la relación entre ellos. |
| `outputs.tf` | Define los datos que Terraform muestra al finalizar (IP pública e identificadores). |

El archivo `.gitignore` excluye los archivos que cada equipo genera localmente o que no deben publicarse: `terraform.tfstate`, `.terraform/`, `.terraform.lock.hcl`, llaves privadas (`*.pem`, `*.key`) y planes guardados.

---

## 2. Arquitectura desplegada

```
Internet
   |
Internet Gateway
   |
Route Table (0.0.0.0/0 -> Internet Gateway)
   |
VCN (vcn_cidr)
   |
   +-- Security List (firewall)
   |
   +-- Subnet pública (subnet_cidr)
          |
          +-- VM Ubuntu ARM (IP pública)
```

---

## 3. Detalle de los recursos (`main.tf`)

Todos los nombres de los recursos se construyen a partir de `project_name` y `environment`. Por ejemplo, con `project_name = "MEGAMXI"` y `environment = "prod"` se crean `MEGAMXI-prod-vcn`, `MEGAMXI-prod-vm`, etc. Los números de línea corresponden a `main.tf`.

### 3.1 Availability Domains (líneas 3-7)

- **Tipo:** consulta (`data source`). No crea ningún recurso.
- **Función:** obtiene la lista de dominios de disponibilidad (AD-1, AD-2, AD-3) de la región configurada.
- **Parámetros requeridos:** `compartment_ocid`.
- **Resultado:** la VM se despliega en el primer dominio de disponibilidad de la lista.

### 3.2 VCN: red virtual principal (líneas 9-16)

- **Función:** crea la red virtual privada (Virtual Cloud Network) que contiene el resto de recursos de red.
- **Parámetros:**
  - `compartment_ocid`: compartment donde se crea la VCN.
  - `cidr_blocks = [vcn_cidr]`: rango de direcciones IP de la red. Por ejemplo, `10.0.0.0/16` proporciona 65 536 direcciones.
  - `display_name`: `<project_name>-<environment>-vcn`. Es el nombre que se muestra en la consola de OCI.
  - `dns_label = vcn_dns_label` (por defecto derivada de `project_name` + `environment`): etiqueta DNS de la VCN. Solo admite letras y números, sin guiones, con un máximo de 15 caracteres.

### 3.3 Internet Gateway (líneas 18-24)

- **Función:** permite que los recursos de la VCN se comuniquen con Internet.
- **Parámetros:**
  - `compartment_ocid`.
  - `vcn_id`: depende de la VCN (`oci_core_vcn.this.id`).
  - `display_name`: `<project_name>-<environment>-igw`.
  - `enabled = true`: el gateway queda habilitado desde su creación.
- **Dependencias:** VCN.

### 3.4 Route Table: tabla de rutas (líneas 26-38)

- **Función:** define la salida del tráfico de la red hacia Internet.
- **Parámetros:**
  - `compartment_ocid`.
  - `vcn_id`: depende de la VCN.
  - `display_name`: `<project_name>-<environment>-rt`.
  - Regla de ruta: `destination = 0.0.0.0/0` (todo el tráfico con destino a Internet) con `network_entity_id` igual al Internet Gateway (`oci_core_internet_gateway.this.id`).
- **Dependencias:** VCN e Internet Gateway.

### 3.5 Security List: reglas de firewall (líneas 40-113)

- **Función:** controla el tráfico que puede entrar y salir de la subred.
- **Parámetros:**
  - `compartment_ocid`.
  - `vcn_id`: depende de la VCN.
  - `display_name`: `<project_name>-<environment>-sl`.

**Tráfico saliente (egress):**

| Protocolo | Destino | Descripción |
|---|---|---|
| Todos (`all`) | `0.0.0.0/0` | Se permite todo el tráfico saliente. |

**Tráfico entrante (ingress):**

| Regla | Protocolo y puerto | Origen |
|---|---|---|
| SSH | TCP 22 | `0.0.0.0/0` |
| ICMP (tipo 3, código 4) | ICMP | `0.0.0.0/0` |
| ICMP interno (tipo 3) | ICMP | `vcn_cidr` (la propia VCN) |
| HTTP | TCP 80 | `0.0.0.0/0` |
| HTTPS | TCP 443 | `0.0.0.0/0` |

- **Dependencias:** VCN.
- **Nota de seguridad:** el acceso SSH está abierto a cualquier dirección IP. Para entornos de producción se recomienda restringir el origen de la regla SSH a direcciones conocidas (ver [Seguridad](#9-seguridad)).

### 3.6 Subnet pública (líneas 115-127)

- **Función:** segmento de la VCN en el que se aloja la VM. Permite asignar direcciones IP públicas.
- **Parámetros:**
  - `compartment_ocid`.
  - `vcn_id`: depende de la VCN.
  - `cidr_block = subnet_cidr`: rango de direcciones de la subred. Por ejemplo, `10.0.2.0/24` proporciona 256 direcciones. Debe estar contenido dentro de `vcn_cidr`.
  - `display_name`: `<project_name>-<environment>-subnet-public`.
  - `dns_label = subnet_dns_label`.
  - `route_table_id`: depende de la Route Table.
  - `security_list_ids`: depende de la Security List.
  - `prohibit_internet_ingress = false` y `prohibit_public_ip_on_vnic = false`: permiten tráfico entrante desde Internet y la asignación de IP pública a las VMs.
- **Dependencias:** VCN, Route Table y Security List.

### 3.7 Instance: máquina virtual (líneas 129-174)

- **Función:** servidor virtual donde se ejecutan las aplicaciones del cliente.

**Parámetros generales:**

| Parámetro | Valor |
|---|---|
| `compartment_ocid` | Compartment donde se crea la VM. |
| `availability_domain` | Primer dominio de disponibilidad obtenido en la consulta inicial. |
| `display_name` | `<project_name>-<environment>-vm` |
| `shape` | `VM.Standard.A1.Flex` (arquitectura ARM). |
| `fault_domain` | `FAULT-DOMAIN-1` |

**Capacidad de cómputo (`shape_config`):**

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `ocpus` | 2 | Número de núcleos. |
| `memory_in_gbs` | 12 | Memoria RAM en GB. |

**Red (`create_vnic_details`):**

| Parámetro | Valor |
|---|---|
| `subnet_id` | Depende de la Subnet. |
| `assign_public_ip` | `true` |
| `display_name` | `<project_name>-<environment>-vnic` |
| `hostname_label` | `vm_hostname_label` |

**Acceso SSH (`metadata`):**

- `ssh_authorized_keys = ssh_public_key`: llave pública que se instala en la VM para permitir el acceso por SSH.

**Sistema operativo y disco (`source_details`):**

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `source_id` | `image_ocid` | Imagen del sistema operativo (por ejemplo, Ubuntu 22.04 Minimal aarch64). |
| `boot_volume_size_in_gbs` | 100 | Tamaño del disco de arranque en GB. |
| `boot_volume_vpus_per_gb` | 10 | Rendimiento del disco: 10 equivale a Balanced y 20 a High Performance. |

**Seguridad y disponibilidad:**

| Parámetro | Valor | Descripción |
|---|---|---|
| `is_pv_encryption_in_transit_enabled` | `true` | Cifrado en tránsito del volumen. |
| `network_type` | `PARAVIRTUALIZED` | Tipo de interfaz de red. |
| `recovery_action` | `RESTORE_INSTANCE` | Si el host falla, la instancia se restaura automáticamente. |

- **Dependencias:** Subnet y, por extensión, todos los recursos anteriores.

### 3.8 Orden de creación

Terraform determina el orden de creación a partir de las dependencias entre recursos, sin que sea necesario indicarlo manualmente:

```
1. Availability Domains   (consulta)
2. VCN
3. Internet Gateway       (requiere VCN)
4. Route Table            (requiere VCN e Internet Gateway)
5. Security List          (requiere VCN)
6. Subnet                 (requiere VCN, Route Table y Security List)
7. Instance (VM)          (requiere Subnet y los recursos anteriores)
```

En total se crean **6 recursos** (pasos 2 al 7) y se ejecuta una consulta (paso 1).

---

## 4. Referencia de variables

Todas las variables se declaran en `variables.tf` y sus valores se asignan en `terraform.tfvars`.

### 4.1 Variables que se deben modificar para un cliente nuevo

Los nombres de todos los recursos y las etiquetas DNS **se generan automáticamente** a partir de `project_name` y `environment` (ver [4.4](#44-valores-derivados-automáticamente)).

| Variable | Descripción | Ejemplo |
|---|---|---|
| `project_name` | Nombre del cliente. Forma parte del nombre de todos los recursos. | `"MEGAMXI"` |
| `environment` | Ambiente: `dev`, `staging` o `prod`. | `"prod"` |
| `ssh_public_key` | Llave pública SSH del cliente (contenido del archivo `.pub`). | `"ssh-rsa AAAA... cliente-vm-key"` |

### 4.2 Variables que se modifican solo si cambia la cuenta de OCI o la red

| Variable | Descripción | Cuándo modificarla |
|---|---|---|
| `tenancy_ocid` | Identificador de la cuenta principal (tenancy) de OCI. | Si el cliente utiliza otro tenancy. |
| `user_ocid` | Identificador del usuario de OCI. | Si se utiliza otro usuario. |
| `fingerprint` | Huella de la API Key del usuario. | Si se utiliza otra API Key. |
| `private_key_path` | Ruta local a la llave privada `.pem` de la API Key. | Depende de cada computadora (ver [sección 7.2](#72-editar-terraformtfvars)). |
| `region` | Región de OCI. | Si se despliega en otra región. |
| `compartment_ocid` | Compartment donde se crean los recursos. | Si el cliente utiliza otro compartment. |
| `vcn_cidr` | Rango IP de la VCN (por ejemplo, `10.0.0.0/16`). | Solo si se prevé interconectar redes. |
| `subnet_cidr` | Rango IP de la subred (por ejemplo, `10.0.2.0/24`). Debe estar dentro de `vcn_cidr`. | Solo si se prevé interconectar redes. |
| `image_ocid` | Imagen del sistema operativo. **Es específica de cada región.** | Si se cambia de región o de sistema operativo. |

### 4.3 Variables con valor por defecto

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `shape` | `VM.Standard.A1.Flex` | Tipo de instancia. |
| `ocpus` | `2` | Número de OCPUs. |
| `memory_in_gbs` | `12` | Memoria RAM en GB. |
| `boot_volume_size_in_gbs` | `100` | Tamaño del disco de arranque en GB. |
| `boot_volume_vpus_per_gb` | `10` | Rendimiento del disco: 10 (Balanced) o 20 (High Performance). |

Estas variables se pueden sobrescribir en `terraform.tfvars` si el cliente requiere otra capacidad.

### 4.4 Valores derivados automáticamente

Con `project_name = "MEGAMXI"` y `environment = "prod"`:

| Valor | Resultado |
|---|---|
| Prefijo de nombres | `MEGAMXI-prod` |
| VCN, Internet Gateway, Route Table, Security List, Subnet, VM, VNIC | `MEGAMXI-prod-vcn`, `-igw`, `-rt`, `-sl`, `-subnet-public`, `-vm`, `-vnic` |
| Etiqueta DNS de la VCN | `megamxiprodvcn` |
| Etiqueta DNS de la subred | `megamxiprodsub` |
| Hostname de la VM | `megamxiprodvm` |

Las etiquetas DNS se calculan en `variables.tf` (`locals`): se concatenan `project_name` y `environment`, se pasan a minúsculas, se eliminan los caracteres que no sean letras o números, se limita la base a 12 caracteres y se agrega el sufijo `vcn`, `sub` o `vm`. El resultado nunca supera los 15 caracteres que permite OCI. El nombre del proyecto debe comenzar con una letra.

Las variables `vcn_dns_label`, `subnet_dns_label` y `vm_hostname_label` siguen existiendo como **opcionales**: si se definen en `terraform.tfvars`, reemplazan el valor generado.

---

## 5. Outputs

Al finalizar `terraform apply`, y en cualquier momento con `terraform output`, se muestran los siguientes valores:

| Output | Descripción |
|---|---|
| `public_ip` | Dirección IP pública de la VM. |
| `instance_id` | OCID de la instancia. |
| `vcn_id` | OCID de la VCN. |
| `subnet_id` | OCID de la subred. |

---

## 6. Prerrequisitos (Linux y Windows)

### 6.1 Terraform (versión 1.5 o superior)

- **Linux:** seguir las instrucciones de https://developer.hashicorp.com/terraform/install
- **Windows:** ejecutar `winget install Hashicorp.Terraform`, o descargar el archivo `.zip` desde el sitio oficial y agregar su carpeta a la variable de entorno `PATH`.

Se debe abrir una terminal nueva y verificar la instalación:

```bash
terraform -version
```

### 6.2 Git

Necesario para clonar el repositorio. Verificar con `git --version`.

### 6.3 Credenciales de API de OCI

No es necesario instalar la OCI CLI; Terraform se autentica directamente con la API Key.

1. Ingresar a la consola de OCI: https://cloud.oracle.com/
2. Abrir el perfil de usuario: **User settings**, **Tokens and keys**.
3. En la sección **API Keys**, seleccionar **Add API Key** y luego **Generate API Key Pair**.
4. Descargar la llave privada (archivo `.pem`).
5. Seleccionar **Add** y copiar el **fingerprint** que muestra OCI (formato `aa:bb:cc:...`).
6. Obtener también `tenancy_ocid`, `user_ocid` y `compartment_ocid` desde la consola de OCI.
7. Guardar el archivo `.pem` **fuera del repositorio**:

| Sistema | Ubicación recomendada | Permisos |
|---|---|---|
| Linux | `~/.oci/mi_llave.pem` | `chmod 600 ~/.oci/mi_llave.pem` |
| Windows | `C:\Users\<USUARIO>\.oci\mi_llave.pem` | No aplica |

### 6.4 Llave SSH para acceder a la VM

Se debe generar un par de llaves. La llave **pública** se registra en `ssh_public_key` y la **privada** se conserva para conectarse a la VM.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oci_vm_key -C "cliente-vm-key"
```

En Windows (PowerShell) se utiliza el mismo comando, sustituyendo la ruta por `$HOME\.ssh\oci_vm_key`. El cliente OpenSSH está incluido en Windows 10 y versiones posteriores.

El contenido del archivo `oci_vm_key.pub` se copia en la variable `ssh_public_key` de `terraform.tfvars`.

---

## 7. Procedimiento: crear un cliente nuevo

### 7.1 Clonar el repositorio en una carpeta nueva

Se debe clonar en una carpeta con el nombre del cliente. Una carpeta nueva no contiene `terraform.tfstate`, por lo que Terraform no conoce ningún recurso previo.

```bash
git clone https://github.com/JuanNoraB/Automatizaci-n_OCI_TERRAFORM_GITHUB_ACTIONS.git MEGAMXI
cd MEGAMXI
```

### 7.2 Crear y editar `terraform.tfvars`

El archivo `terraform.tfvars` no está en el repositorio (está en `.gitignore`). Se crea a partir de la plantilla:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Modificar las variables indicadas en las secciones [4.1](#41-variables-que-se-deben-modificar-para-un-cliente-nuevo) y [4.2](#42-variables-que-se-modifican-solo-si-cambia-la-cuenta-de-oci-o-la-red).

La variable `private_key_path` depende del equipo:

```hcl
# Linux
private_key_path = "~/.oci/mi_llave.pem"

# Windows: ruta completa con barras normales ("/"), no con barras invertidas ("\")
private_key_path = "C:/Users/<USUARIO>/.oci/mi_llave.pem"
```

Ejemplo mínimo de los valores que cambian para un cliente nuevo:

```hcl
project_name = "MEGAMXI"
environment  = "prod"

ssh_public_key = "ssh-rsa AAAA... cliente-vm-key"
```

### 7.3 Inicializar, revisar y aplicar

```bash
terraform init
terraform plan
terraform apply
```

| Comando | Función |
|---|---|
| `terraform init` | Descarga el proveedor de OCI y prepara la carpeta de trabajo. |
| `terraform plan` | Muestra los cambios que se realizarían, sin ejecutarlos. |
| `terraform apply` | Crea los recursos. Solicita confirmación escribiendo `yes`. |

**Verificación previa a la confirmación:** el resumen de `terraform plan` en una carpeta nueva debe indicar:

```
Plan: 6 to add, 0 to change, 0 to destroy.
```

Si el resumen indica cualquier valor distinto de `0 to destroy`, **no se debe aplicar**. Esto significa que la carpeta contiene el estado de otro cliente o que existe un error en las variables.

### 7.4 Verificar y conectarse a la VM

```bash
terraform output public_ip
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_PUBLICA>
```

En Windows (PowerShell):

```powershell
ssh -i $HOME\.ssh\oci_vm_key ubuntu@<IP_PUBLICA>
```

La VM puede tardar entre 2 y 3 minutos en aceptar conexiones después de finalizar `terraform apply`. Los recursos también se pueden verificar en la consola de OCI:

- **Networking**, **Virtual Cloud Networks**: VCN del cliente.
- **Compute**, **Instances**: VM del cliente.

---

## 8. Gestión de múltiples clientes con Git

- El archivo de estado `terraform.tfstate` **no se almacena en Git**. Cada computadora solo conoce los recursos que ella misma creó.
- Si se clona el repositorio en otro equipo y se utilizan los valores de un cliente ya desplegado, Terraform intentará crear todos los recursos nuevamente y fallará por nombres o etiquetas DNS duplicados. Para cada cliente nuevo debe cambiarse siempre `project_name` (las etiquetas DNS se derivan de él).
- Para no modificar la plantilla de la rama `main`, se recomienda utilizar una rama por cliente:

  ```bash
  git checkout -b cliente-megamxi
  ```

  Los cambios en `terraform.tfvars` se registran en esa rama y no en `main`.
- **Se debe respaldar el archivo `terraform.tfstate` de cada cliente.** Si se pierde, Terraform deja de conocer los recursos creados y será necesario importarlos manualmente (`terraform import`) o eliminarlos desde la consola de OCI.
- No se debe ejecutar `terraform apply` en una carpeta que contiene el estado de un cliente después de cambiar `project_name`. Terraform interpretaría el cambio como una modificación de los recursos existentes y los renombraría o destruiría.

---

## 9. Seguridad

- `terraform.tfvars` contiene identificadores de la cuenta de OCI (OCIDs) y el fingerprint, por eso está en `.gitignore` y no se sube al repositorio. Solo se versiona `terraform.tfvars.example` con valores `xxx`.
- La llave privada de la API Key (`.pem`) y la llave privada SSH nunca deben incluirse en el repositorio. El archivo `.gitignore` bloquea `*.pem`, `*.key` y las llaves SSH habituales.
- La variable `ssh_public_key` contiene únicamente la llave pública, que puede compartirse.
- `terraform.tfstate` puede contener información sensible y por eso está excluido de Git. Debe respaldarse por un medio seguro.
- La Security List permite SSH (puerto 22) desde `0.0.0.0/0`. En producción se recomienda restringir el campo `source` de esa regla en `main.tf` a las direcciones IP autorizadas.

---

## 10. Límites del Free Tier de OCI

- **Instancias A1 Flex:** máximo de 4 OCPU y 24 GB de RAM **en total por tenancy**. Con los valores por defecto (2 OCPU y 12 GB por VM) caben 2 clientes en el mismo tenancy.
- **Almacenamiento en bloque:** máximo de 200 GB en total. Cada VM utiliza 100 GB por defecto.

Si se excede alguno de estos límites, la creación de la VM falla.

---

## 11. Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `401-NotAuthenticated` | `fingerprint`, `user_ocid`, `tenancy_ocid` o `private_key_path` incorrectos, o llave privada que no corresponde a la API Key registrada. | Verificar los valores y que el `.pem` corresponda al fingerprint. En Windows, verificar la ruta con barras normales. |
| `404-NotAuthorizedOrNotFound` | El usuario no tiene permisos sobre el compartment, o `compartment_ocid` es incorrecto. | Verificar el OCID del compartment y las políticas del usuario. |
| Error por `dns_label` o `hostname_label` | Etiqueta con guiones, de más de 15 caracteres o ya usada en la misma VCN. | Si se definieron manualmente, utilizar solo letras y números, con un máximo de 15 caracteres. Si se generan automáticamente, el nombre del proyecto debe comenzar con una letra. |
| Error por nombres duplicados o recursos que ya existen | Se usaron los valores de un cliente ya desplegado. | Cambiar `project_name`. |
| `Out of host capacity` al crear la VM | No hay capacidad A1 disponible en el dominio de disponibilidad. | Reintentar más tarde o cambiar de región. |
| `LimitExceeded` | Se excedió un límite de servicio del tenancy (ver [sección 10](#10-límites-del-free-tier-de-oci)). | Reducir `ocpus`, `memory_in_gbs` o el tamaño del disco, o eliminar otras instancias. |
| Error de imagen no encontrada | `image_ocid` pertenece a otra región. | Utilizar una imagen disponible en la región configurada. |
| `Permission denied (publickey)` al conectarse por SSH | La llave privada usada no corresponde a `ssh_public_key`. | Utilizar la llave privada del par cuya llave pública se registró. |
| `terraform` no se reconoce como comando (Windows) | La instalación no está en el `PATH` o la terminal estaba abierta durante la instalación. | Abrir una terminal nueva o agregar Terraform al `PATH`. |

---

## 12. Eliminación de la infraestructura de un cliente

Se debe ejecutar dentro de la carpeta de ese cliente, es decir, la que contiene su `terraform.tfstate`:

```bash
terraform destroy
```

Terraform lista los recursos que se eliminarán y solicita confirmación escribiendo `yes`. **La operación elimina todos los recursos del cliente y no es reversible.** Antes de confirmar se debe verificar que la carpeta corresponde al cliente correcto.

---

## 13. Documentos relacionados

- `CONFIGURACION_INICIAL.md`: guía para obtener las credenciales de OCI.
- `COMANDOS_UTILES_OCI.md`: comandos de la OCI CLI para listar recursos.
