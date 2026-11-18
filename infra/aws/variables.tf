variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "name" {
  type    = string
  default = "ideaboard"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "db_username" {
  type    = string
  default = "ideaboard"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
