locals {
  ou_path = var.environment == "prd" ? (
    "OU=SQL_Servers,OU=EWL,OU=MGMT,OU=EMIS${upper(var.environment)}SS,DC=shared-services,DC=emis-web,DC=com"
  ) : (
    "OU=SQL_Servers,OU=EWL,OU=MGMT,OU=EMIS${upper(var.environment)}SS,DC=${var.environment},DC=shared-services,DC=emis-web,DC=com"
  )
  instance_service_name = "EWEBLOGS"
}