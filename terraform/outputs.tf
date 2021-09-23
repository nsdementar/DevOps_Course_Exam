output "master-ip" {
  value = {
    for instance in vsphere_virtual_machine.master-node :
    instance.name => instance.default_ip_address
  }
}

output "worker-ip" {
  value = {
    for instance in vsphere_virtual_machine.worker-node :
    instance.name => instance.default_ip_address
  }
}

output "etcd-ip" {
  value = {
    for instance in vsphere_virtual_machine.etcd-node :
    instance.name => instance.default_ip_address
  }
}
