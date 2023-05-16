

terraform {

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terr-state-file"
    region     = "ru-central1"
    key        = "stage/terraform.tfstate"
    access_key = "YCAJEPyrG1mVi"
    secret_key = "YCOx3MIZOU4aP_xI-8i_HcuTNXHD"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
