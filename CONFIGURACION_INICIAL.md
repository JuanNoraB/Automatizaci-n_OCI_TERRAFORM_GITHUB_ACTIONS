# 🚀 Configuración Inicial para Terraform + OCI

## ✅ PASO 1: Credenciales OCI (COMPLETAR MANUALMENTE)

Ve a https://cloud.oracle.com/ y obtén estos valores:

### 1.1 Tenancy OCID
- Menú ☰ → **Governance & Administration** → **Tenancy Details**
- Copia el OCID (empieza con `ocid1.tenancy.oc1..`)

### 1.2 User OCID
- Clic en tu **perfil** (arriba derecha) → tu nombre
- Copia el OCID (empieza con `ocid1.user.oc1..`)

### 1.3 API Key y Fingerprint
1. En la página de usuario → Tokens and keys, sección **API Keys**
2. **Add API Key** → **Generate API Key Pair**
3. **Download Private Key** (guárdala como `oci_api_key.pem`)
4. **Add** → Copia el **Fingerprint** (formato: `aa:bb:cc:dd:...`) #Desde la pagina de API keys

### 1.4 Mover la llave descargada
```bash
mv ~/Downloads/oci_api_key.pem ~/.oci/ #(juan.brito@fpalatam.com-2026-04-24T15_44_09.287Z.pem)
chmod 600 ~/.oci/oci_api_key.pem

```

---

## ✅ PASO 2: Llave SSH (YA CREADA ✓)

**Llave SSH generada en:** `~/.ssh/oci_vm_key`

**Tu llave pública SSH es:**
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCx4RLjYcY4lDToN+xhMpdrov3f7Op35w95IjA/O8XH5UVGkvSyECtPHnbN8BRN5ZnesFFWmwOquzvTrgN7vqcoj7qh6FAK0wL1ql+vcgu20PKDh4r9Rz00mPllpQTtK4bBBLADcVfZwawP2oUXqRiPHWftnENtFSnpgWUk9a6QA53fcXXPJgFS2hgsBIkAlwThqkMXgriGIgcgE2gHOS6Lf2h9bitFVm7xGgOEe0rLMt9WxLLuiGm6eUkLG0hibp+OD7bF+7+TXeTG52ny7I8f/1IGyEEoBIy5DAqTLgP0FwIVZhhhcA0n9u5xuOyPFHg+4LSxNrtx1NeKXZoPFYEUMycm42WAt1XeVGs9lLZRD76aAlCP7GCOYUGIiys0DTSlQnYO4AWe8ziehSvMs4hjMhhKeALZJasPci+BzaxNK0RgmI19wyUPORpjb6fv90mY92nU0cY/Zd4E8zzlfy/k+ejgicW7VB8g9gGTN6lbfdRbJo/OW18jAzKRUAjAFxrq3QNgs5RbLjwZxkRDufKavfhze9NR0gjjuijttJSvKlVhgmx+pXcq+Syd41hcgMmF+HuU5+EJgeo9J9Y1IzUVL42qoYb8m+YmXWfX+Y25uqyQg+jEv1eYpVWUTC0OxPn08RcK8FaZmE+FQMAIvmoUOITmOEl8IdSspVIAqA0Q2w== oci-vm-key
```

**Para conectarte luego a la VM:**
```bash
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_PUBLICA_DE_LA_VM>
```

---

## ✅ PASO 3: Actualizar `terraform.tfvars`

Abre el archivo `terraform. tfvars` y reemplaza:

```hcl
# ==================== Credenciales OCI ====================
tenancy_ocid     = "PEGA_AQUI_TU_TENANCY_OCID"
user_ocid        = "PEGA_AQUI_TU_USER_OCID"
fingerprint      = "PEGA_AQUI_TU_FINGERPRINT"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"

# ==================== Imagen y SSH ====================
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCx4RLjYcY4lDToN+xhMpdrov3f7Op35w95IjA/O8XH5UVGkvSyECtPHnbN8BRN5ZnesFFWmwOquzvTrgN7vqcoj7qh6FAK0wL1ql+vcgu20PKDh4r9Rz00mPllpQTtK4bBBLADcVfZwawP2oUXqRiPHWftnENtFSnpgWUk9a6QA53fcXXPJgFS2hgsBIkAlwThqkMXgriGIgcgE2gHOS6Lf2h9bitFVm7xGgOEe0rLMt9WxLLuiGm6eUkLG0hibp+OD7bF+7+TXeTG52ny7I8f/1IGyEEoBIy5DAqTLgP0FwIVZhhhcA0n9u5xuOyPFHg+4LSxNrtx1NeKXZoPFYEUMycm42WAt1XeVGs9lLZRD76aAlCP7GCOYUGIiys0DTSlQnYO4AWe8ziehSvMs4hjMhhKeALZJasPci+BzaxNK0RgmI19wyUPORpjb6fv90mY92nU0cY/Zd4E8zzlfy/k+ejgicW7VB8g9gGTN6lbfdRbJo/OW18jAzKRUAjAFxrq3QNgs5RbLjwZxkRDufKavfhze9NR0gjjuijttJSvKlVhgmx+pXcq+Syd41hcgMmF+HuU5+EJgeo9J9Y1IzUVL42qoYb8m+YmXWfX+Y25uqyQg+jEv1eYpVWUTC0OxPn08RcK8FaZmE+FQMAIvmoUOITmOEl8IdSspVIAqA0Q2w== oci-vm-key"
```

---

## ✅ PASO 4: Ejecutar Terraform

Una vez que hayas actualizado `terraform.tfvars`:

### 4.1 Inicializar Terraform
```bash
cd /home/juanchx/Documents/Trabajo/TERRAFORM_GITHUB_ACTIONS_OCI
terraform init
```

### 4.2 Ver qué se va a crear (sin crear nada)
```bash
terraform plan
```

### 4.3 Crear los recursos
```bash
terraform apply
```
- Te preguntará si quieres continuar, escribe `yes`

---

## ✅ PASO 5: Verificar recursos creados

### Obtener outputs
```bash
terraform output
```

### Ver recursos en OCI
Ve a la consola web: https://cloud.oracle.com/
- **Networking** → **Virtual Cloud Networks** → Verás tu VCN
- **Compute** → **Instances** → Verás tu VM

### Conectarte a la VM
```bash
# Espera 2-3 minutos después del apply
terraform output instance_id
# Luego obtén la IP pública desde la consola o con OCI CLI
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_PUBLICA>
```

---

## 🗑️ Destruir todo (cuando termines)

```bash
terraform destroy
```
- Escribe `yes` para confirmar
- Esto eliminará TODOS los recursos creados
