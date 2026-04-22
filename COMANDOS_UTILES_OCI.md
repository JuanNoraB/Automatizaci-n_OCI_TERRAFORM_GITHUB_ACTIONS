# Comandos Útiles para OCI

## Listar Recursos
<COMPARTMENT_OCID> = ocid1.compartment.oc1..aaaaaaaaswbxg4qrsmc54zigpev3uf2iaoyxaqtjpp4vylrdxhlc7iq7uzfa
<VCN_OCID> = ocid1.vcn.oc1.iad.amaaaaaaiap4fzyajelzqsmgocclr3ufyn6awiefrinpyvaczrzxpry5drjq
<INSTANCE_OCID> = ocid1.instance.oc1.iad.anuwcljsiap4fzyckckctnhbwwngkdrgpxr2r4fu7urx45gryorsgo3r7i4a

Para listar VCN:
oci network vcn list --compartment-id <COMPARTMENT_OCID>

Para listar subnets:
oci network subnet list --compartment-id <COMPARTMENT_OCID> --vcn-id <VCN_OCID>

Para internet gateway:
oci network internet-gateway list --compartment-id <COMPARTMENT_OCID> --vcn-id <VCN_OCID>

Para route tables:
oci network route-table list --compartment-id <COMPARTMENT_OCID> --vcn-id <VCN_OCID>

Para security lists:
oci network security-list list --compartment-id <COMPARTMENT_OCID> --vcn-id <VCN_OCID>

Para la VM:
oci compute instance list --compartment-id <COMPARTMENT_OCID>

Y para ver el detalle de la VM:
oci compute instance get --instance-id <INSTANCE_OCID>

Y si quieres el VNIC/IP pública:
oci compute vnic-attachment list --compartment-id <COMPARTMENT_OCID> --instance-id <INSTANCE_OCID>
oci network vnic get --vnic-id <VNIC_OCID>