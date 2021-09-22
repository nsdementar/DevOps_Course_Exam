terraform {
  backend "s3" {
    bucket = "tms-exam"
    key    = "TMS/terraform.tfstate"
    region = "us-west-2"
  }
}
