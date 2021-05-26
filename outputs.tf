output "machineip" {
  value = "${azurerm_public_ip.publicip.ip_address}"
}

output "vnetid" {
    value = "${azurerm_virtual_network.myvnet.id}"
}

output "sub1" {
    value = "${azurerm_subnet.sub1.id}"
}


output "sub2" {
    value = "${azurerm_subnet.sub2.id}"
}