# se llenan las variables declaradas en variables.tf
# Esta carpeta es la PLANTILLA de un cliente. Para un cliente nuevo: copia toda la carpeta
# y cambia project_name + credenciales + vcn_cidr/subnet_cidr + ssh_public_key.

# ==================== Proyecto y Ambiente ====================
project_name = "INSAGEN"
environment  = "prod"

# ==================== Credenciales OCI ====================
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaakgtaqiqkauosq5zcaqfhzmk7ivd3lukir72peb3balx4dnbdueja"
user_ocid        = "ocid1.user.oc1..aaaaaaaaydvcxpy556gze2gx7zuffg7dpr46xeyrufavmci5syu72ananvuq"
fingerprint      = "94:bd:44:46:63:82:44:61:6a:7e:d5:20:41:a8:93:d7"
private_key_path = "~/.oci/juan.brito@fpalatam.com-2026-04-24T15_44_09.287Z.pem"
region           = "us-ashburn-1"

# ==================== Compartment y Red ====================
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaanu6fe32jvlpzauz5rhmg5okqexcipuzoqzhxff72xsyy7yxnii4q"
vcn_cidr         = "10.0.0.0/16"
subnet_cidr      = "10.0.2.0/24"

# ==================== DNS Labels (únicos, máx 15 caracteres) ====================
vcn_dns_label     = "insagenprodvcn"
subnet_dns_label  = "insagenprodsub"
vm_hostname_label = "insagenprodvm"

# ==================== Imagen y SSH ====================
image_ocid     = "ocid1.image.oc1.iad.aaaaaaaaqoeodp5azjlglyddmmsnkncciwtrrof7gz7xhe3ikeibnmnahqga"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCx4RLjYcY4lDToN+xhMpdrov3f7Op35w95IjA/O8XH5UVGkvSyECtPHnbN8BRN5ZnesFFWmwOquzvTrgN7vqcoj7qh6FAK0wL1ql+vcgu20PKDh4r9Rz00mPllpQTtK4bBBLADcVfZwawP2oUXqRiPHWftnENtFSnpgWUk9a6QA53fcXXPJgFS2hgsBIkAlwThqkMXgriGIgcgE2gHOS6Lf2h9bitFVm7xGgOEe0rLMt9WxLLuiGm6eUkLG0hibp+OD7bF+7+TXeTG52ny7I8f/1IGyEEoBIy5DAqTLgP0FwIVZhhhcA0n9u5xuOyPFHg+4LSxNrtx1NeKXZoPFYEUMycm42WAt1XeVGs9lLZRD76aAlCP7GCOYUGIiys0DTSlQnYO4AWe8ziehSvMs4hjMhhKeALZJasPci+BzaxNK0RgmI19wyUPORpjb6fv90mY92nU0cY/Zd4E8zzlfy/k+ejgicW7VB8g9gGTN6lbfdRbJo/OW18jAzKRUAjAFxrq3QNgs5RbLjwZxkRDufKavfhze9NR0gjjuijttJSvKlVhgmx+pXcq+Syd41hcgMmF+HuU5+EJgeo9J9Y1IzUVL42qoYb8m+YmXWfX+Y25uqyQg+jEv1eYpVWUTC0OxPn08RcK8FaZmE+FQMAIvmoUOITmOEl8IdSspVIAqA0Q2w== oci-vm-key"