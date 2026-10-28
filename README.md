# Terraform OCI: guía rápida (Windows)

Crea en Oracle Cloud (OCI) una red y una VM Ubuntu para un cliente nuevo.
Los comandos se ejecutan en **PowerShell**. Para el detalle técnico completo ver [README_TECNICO.md](README_TECNICO.md).

> **Una carpeta = un cliente.** Cada clon del repositorio tiene su propio estado de Terraform, por eso no afecta a lo que ya existe en otros equipos.

---

## 1. Instalar Terraform y Git


## 2. Verificar la instalación

```powershell
terraform -version
git --version
```

## 3. Crear la llave SSH (para conectarse a la VM)

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh"
ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\oci_vm_key" -C "oci-vm-key"
```

Presionar Enter dos veces (sin contraseña).


## 4. Obtener los datos de OCI

Se necesitan estos valores de la consola de OCI (https://cloud.oracle.com/):

| Variable | Dónde se obtiene |
|---|---|
| `tenancy_ocid` | Menú de perfil (arriba a la derecha), **Tenancy**, botón **Copy** junto al OCID. |
| `user_ocid` | Menú de perfil, **My profile**, botón **Copy** junto al OCID. |
| `fingerprint` y llave privada `.pem` | **My profile**, **Tokens and keys**, **Add API key**, **Generate API key pair**, **Download private key**, **Add**. OCI muestra el `fingerprint` en la ventana "Configuration file preview". |
| `region` | En esa misma ventana, campo `region` (por ejemplo `us-ashburn-1`). |
| `compartment_ocid` | Menú, **Identity & Security**, **Compartments**, abrir el compartment, botón **Copy** junto al OCID. Si se usa el compartment raíz, es el mismo valor que `tenancy_ocid`. |

Guardar el archivo `.pem` descargado en `C:\Users\<USUARIO>\.oci\` (crear la carpeta si no existe).


## 5. Clonar el repositorio

```powershell
git clone https://github.com/JuanNoraB/Automatizaci-n_OCI_TERRAFORM_GITHUB_ACTIONS.git MEGAMXI
cd MEGAMXI
```

Si el repositorio es privado, Git abrirá el navegador para iniciar sesión en GitHub.

## 6. Editar `terraform.tfvars`

```powershell
notepad terraform.tfvars
```

Cambiar estos valores:

| Variable | Valor |
|---|---|
| `project_name` | Nombre del cliente, por ejemplo `"MEGAMXI"`. |
| `environment` | `"dev"`, `"staging"` o `"prod"`. |
| `ssh_public_key` | La llave pública del paso 3 (una sola línea). |
| `private_key_path` | Ruta del `.pem`, con barras normales: `"C:/Users/<USUARIO>/.oci/mi_llave.pem"` |
| `fingerprint` | El del paso 4. |
| `tenancy_ocid`, `user_ocid`, `region`, `compartment_ocid` | Solo si el cliente usa otra cuenta o compartment de OCI (paso 4). |

Con `project_name` y `environment` se generan solos los nombres de todos los recursos y las etiquetas DNS (por ejemplo `MEGAMXI-prod-vcn`, `MEGAMXI-prod-vm`). No hay que cambiar nada más.

## 7. Crear la infraestructura

```powershell
terraform init
terraform plan
terraform apply
```

- `terraform plan` debe terminar con: `Plan: 6 to add, 0 to change, 0 to destroy.`
- Si indica algo distinto de `0 to destroy`, **no continuar**: se está en una carpeta que ya tiene recursos de otro cliente.
- `terraform apply` pide confirmación: escribir `yes`.

## 8. Conectarse a la VM

```powershell
terraform output public_ip
ssh -i "$HOME\.ssh\oci_vm_key" ubuntu@<IP_PUBLICA>
```

La VM puede tardar 2 o 3 minutos en aceptar conexiones.

---

## Notas

- **Nunca** subir a Git el archivo `.pem`, las llaves SSH ni `terraform.tfstate` (ya están en `.gitignore`).
- Respaldar el `terraform.tfstate` de cada cliente: sin él, Terraform no sabe qué recursos creó.
- Para eliminar los recursos de un cliente, ejecutar `terraform destroy` dentro de su carpeta.
- Para no modificar la plantilla de `main`, trabajar en una rama por cliente: `git checkout -b cliente-megamxi`.
