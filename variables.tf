# required for AWS
variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "eu-central-1"
}



# Domain without www. 
variable "domain" {
  default = "<your-domain>"
}