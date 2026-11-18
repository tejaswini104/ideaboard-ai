variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "asia-south1"
}
variable "name" {
  type    = string
  default = "ideaboard"
}
variable "db_password" {
  type      = string
  sensitive = true
}
