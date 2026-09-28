# ==================== Credenciales OCI ====================
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaakgtaqiqkauosq5zcaqfhzmk7ivd3lukir72peb3balx4dnbdueja"
user_ocid        = "ocid1.user.oc1..aaaaaaaaydvcxpy556gze2gx7zuffg7dpr46xeyrufavmci5syu72ananvuq"
fingerprint      = "94:bd:44:46:63:82:44:61:6a:7e:d5:20:41:a8:93:d7"
private_key_path = "~/.oci/juan.brito@fpalatam.com-2026-04-24T15_44_09.287Z.pem"
region           = "us-ashburn-1"

# ==================== Compartment e Imagen (compartidos por todas las empresas) ====================
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaanu6fe32jvlpzauz5rhmg5okqexcipuzoqzhxff72xsyy7yxnii4q"
image_ocid       = "ocid1.image.oc1.iad.aaaaaaaaqoeodp5azjlglyddmmsnkncciwtrrof7gz7xhe3ikeibnmnahqga"

# ==================== Empresas / Clientes ====================
# Cada entrada crea su propia VCN + Subnet + Security List + VM, totalmente aislada.
# Para agregar una empresa nueva, copia un bloque y cambia sus valores (dns_labels únicos, máx 15 caracteres).
empresas = {
  "integrator-v1-dev" = {
    vcn_cidr          = "10.0.0.0/16"
    subnet_cidr       = "10.0.2.0/24"
    vcn_dns_label     = "intv1devvcn"
    subnet_dns_label  = "intv1devsub"
    vm_hostname_label = "intv1devvm"
    ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCx4RLjYcY4lDToN+xhMpdrov3f7Op35w95IjA/O8XH5UVGkvSyECtPHnbN8BRN5ZnesFFWmwOquzvTrgN7vqcoj7qh6FAK0wL1ql+vcgu20PKDh4r9Rz00mPllpQTtK4bBBLADcVfZwawP2oUXqRiPHWftnENtFSnpgWUk9a6QA53fcXXPJgFS2hgsBIkAlwThqkMXgriGIgcgE2gHOS6Lf2h9bitFVm7xGgOEe0rLMt9WxLLuiGm6eUkLG0hibp+OD7bF+7+TXeTG52ny7I8f/1IGyEEoBIy5DAqTLgP0FwIVZhhhcA0n9u5xuOyPFHg+4LSxNrtx1NeKXZoPFYEUMycm42WAt1XeVGs9lLZRD76aAlCP7GCOYUGIiys0DTSlQnYO4AWe8ziehSvMs4hjMhhKeALZJasPci+BzaxNK0RgmI19wyUPORpjb6fv90mY92nU0cY/Zd4E8zzlfy/k+ejgicW7VB8g9gGTN6lbfdRbJo/OW18jAzKRUAjAFxrq3QNgs5RbLjwZxkRDufKavfhze9NR0gjjuijttJSvKlVhgmx+pXcq+Syd41hcgMmF+HuU5+EJgeo9J9Y1IzUVL42qoYb8m+YmXWfX+Y25uqyQg+jEv1eYpVWUTC0OxPn08RcK8FaZmE+FQMAIvmoUOITmOEl8IdSspVIAqA0Q2w== oci-vm-key"
  }

  # Ejemplo para agregar otra empresa (descomenta y ajusta):
  # "isagen-prod" = {
  #   vcn_cidr          = "10.1.0.0/16"
  #   subnet_cidr       = "10.1.2.0/24"
  #   vcn_dns_label     = "isagenprodvcn"
  #   subnet_dns_label  = "isagenprodsub"
  #   vm_hostname_label = "isagenprodvm"
  #   ssh_public_key    = "ssh-rsa AAAA..."
  # }
}