variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}
variable "location" {
  description = "Azure region"
  type        = string
  default     = "koreacentral"
}
variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}
variable "admin_username" {
  description = "Linux administrator username"
  type        = string
  default     = "azureadmin"
}
variable "ssh_public_key" {
  description = "Public SSH key for Azure VM"
  type        = string
}
variable "admin_source_cidr" {
  description = "Public IP allowed to SSH into VM"
  type        = string
}