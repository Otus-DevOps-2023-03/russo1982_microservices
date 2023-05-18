

terraform {

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terr-state-file"
    region     = "ru-central1"
    key        = "prod/terraform.tfstate"
    access_key = "YCsdvsadvadfvrG1mVi"
    secret_key = "YSDVSDVsdvdvDV_xI-8i_HcuTNXHD"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
