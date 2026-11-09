output "vm_public_ip" {
  description = "Public IP of Azure VM"
  value       = azurerm_public_ip.public_ip.ip_address
}
output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}