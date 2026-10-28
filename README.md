# Terraform OCI - Plantilla por cliente

Crea en Oracle Cloud (OCI) una red completa y una VM Ubuntu ARM para un cliente.
**Una carpeta = un cliente.** Cada carpeta tiene su propio estado de Terraform, por eso no se pisan entre sí.

## Los 5 archivos que viven en Git

| Archivo | Para qué sirve |
|---|---|
| `provider.tf` | Cómo Terraform se conecta a OCI |
| `variables.tf` | Qué valores pueden cambiar (y sus defaults) |
| `terraform.tfvars` | **Los valores reales del cliente. Es el único archivo que editas.** |
| `main.tf` | Los recursos que se crean |
| `outputs.tf` | Lo que se imprime al final (IP pública, IDs) |

Lo demás (`.terraform/`, `terraform.tfstate`, `.terraform.lock.hcl`, `*.pem`) lo ignora `.gitignore` y se genera en cada computadora.

## Qué recursos crea

Terraform los crea en este orden, según sus dependencias:

1. VCN (red principal, `vcn_cidr`)
2. Internet Gateway
3. Route Table (`0.0.0.0/0` hacia el Internet Gateway)
4. Security List (entrada: SSH 22, HTTP 80, HTTPS 443, ICMP; salida: todo)
5. Subnet pública (`subnet_cidr`)
6. VM `VM.Standard.A1.Flex` con IP pública (por defecto 2 OCPU, 12 GB RAM, 100 GB de disco)

Todos los nombres salen de `project_name` y `environment`. Por ejemplo, `MEGAMXI` + `prod` crea `MEGAMXI-prod-vcn`, `MEGAMXI-prod-vm`, etc.

## Nuevo cliente: qué cambiar en `terraform.tfvars`

| Variable | Qué hacer |
|---|---|
| `project_name` | Nombre del cliente, por ejemplo `"MEGAMXI"` |
| `environment` | `dev`, `staging` o `prod` |
| `vcn_dns_label`, `subnet_dns_label`, `vm_hostname_label` | Únicos por cliente. Solo letras y números, sin guiones, máximo 15 caracteres |
| `ssh_public_key` | Llave pública SSH del cliente (ver más abajo) |
| `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, `region`, `compartment_ocid` | Cámbialos solo si el cliente usa otra cuenta, otro usuario o otro compartment de OCI |
| `vcn_cidr`, `subnet_cidr` | Opcional. Cámbialos solo si vas a conectar redes entre sí |

> **Regla de oro:** nunca corras `terraform apply` en una carpeta que ya tiene el estado de otro cliente después de cambiar `project_name`. Terraform entendería que quieres renombrar o destruir lo existente. Para un cliente nuevo usa siempre una carpeta o un clone nuevo, donde no existe `terraform.tfstate`.

## Prerrequisitos (Linux o Windows)

1. **Terraform >= 1.5**
   - Linux: https://developer.hashicorp.com/terraform/install
   - Windows: `winget install Hashicorp.Terraform`, o descarga el `.zip` y agrega la carpeta al `PATH`. Abre una terminal nueva y verifica con `terraform -version`.
2. **Git**
3. **Credenciales de API de OCI** (no necesitas instalar la OCI CLI):
   - Consola OCI: tu perfil, **User settings**, **Tokens and keys**, **Add API Key**, **Generate API Key Pair**.
   - Descarga la llave privada `.pem` y copia el fingerprint que muestra OCI.
   - Guarda el `.pem` **fuera del repo**:
     - Linux: `~/.oci/mi_llave.pem` y luego `chmod 600 ~/.oci/mi_llave.pem`
     - Windows: `C:\Users\TU_USUARIO\.oci\mi_llave.pem`
4. **Llave SSH para entrar a la VM** (la pública va en `ssh_public_key`):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/oci_vm_key -C "cliente-vm-key"
   ```
   En Windows (PowerShell) es el mismo comando con `$HOME\.ssh\oci_vm_key`. Pega el contenido de `oci_vm_key.pub` en `ssh_public_key`.

## Paso a paso

### 1. Clonar

```bash
git clone https://github.com/JuanNoraB/Automatizaci-n_OCI_TERRAFORM_GITHUB_ACTIONS.git MEGAMXI
cd MEGAMXI
```

### 2. Editar `terraform.tfvars`

Cambia las variables de la tabla de arriba. Ojo con `private_key_path`, que depende de la computadora:

```hcl
# Linux
private_key_path = "~/.oci/mi_llave.pem"

# Windows: usa la ruta completa y barras normales "/" (no "\")
private_key_path = "C:/Users/TU_USUARIO/.oci/mi_llave.pem"
```

### 3. Inicializar, revisar y aplicar

```bash
terraform init
terraform plan
terraform apply
```

- Antes de escribir `yes`, mira el resumen del `plan`. En una carpeta nueva debe decir `Plan: 6 to add, 0 to change, 0 to destroy`.
- Si dice cualquier cosa distinta de `0 to destroy`, **no apliques** y revisa que estás en la carpeta correcta.

### 4. Conectarte a la VM

```bash
terraform output public_ip
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_PUBLICA>
```

Espera 2 o 3 minutos después del `apply`. En Windows usa `ssh -i $HOME\.ssh\oci_vm_key ubuntu@<IP_PUBLICA>`.

## Trabajar con varios clientes y Git

- El estado (`terraform.tfstate`) **no está en Git**. Cada computadora solo conoce lo que ella misma creó.
- Si clonas en otra computadora y usas los mismos valores que un cliente existente, Terraform intentará crear todo de nuevo y fallará por nombres o DNS duplicados. Cambia siempre `project_name` y los DNS labels.
- Para no pisar la plantilla en `main`, usa una rama por cliente:
  ```bash
  git checkout -b cliente-megamxi
  ```
  Edita ahí el `terraform.tfvars` y haz commit de los cambios en esa rama, no en `main`.
- **Respalda el `terraform.tfstate`** de cada cliente. Si lo pierdes, Terraform olvida lo que creó y tendrías que importar los recursos a mano o borrarlos desde la consola de OCI.

## Seguridad

- El repo contiene `terraform.tfvars` con OCIDs y fingerprint. **Mantén el repositorio privado.**
- Nunca subas el `.pem`. `.gitignore` ya lo bloquea.
- Para pruebas, `ssh_public_key` es solo la llave pública, que sí se puede compartir.
- La Security List abre SSH (22) a `0.0.0.0/0`. En producción restringe ese origen a tu IP.

## Límites del Free Tier de OCI

- A1 Flex: máximo 4 OCPU y 24 GB de RAM **en total por tenancy**. Con los defaults (2 OCPU y 12 GB) caben 2 clientes.
- Disco: máximo 200 GB en total, y cada VM usa 100 GB por defecto.

## Destruir un cliente

Dentro de la carpeta de ese cliente (la que tiene su `terraform.tfstate`):

```bash
terraform destroy
```

## Otros documentos

- `CONFIGURACION_INICIAL.md`: guía inicial para obtener las credenciales de OCI.
- `COMANDOS_UTILES_OCI.md`: comandos de la OCI CLI para listar recursos.
