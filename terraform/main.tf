# =================== #
# Deploying VMware VM #
# =================== #
# Connect to VMware vSphere vCenter
provider "vsphere" {
user = var.vsphere-user
password = var.vsphere-password
vsphere_server = var.vsphere-vcenter
# If you have a self-signed cert
allow_unverified_ssl = var.vsphere-unverified-ssl
}
# Define VMware vSphere
data "vsphere_datacenter" "dc" {
name = var.vsphere-datacenter
}
data "vsphere_datastore" "datastore" {
name = var.vm-datastore
datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_compute_cluster" "cluster" {
name = var.vsphere-cluster
datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
name = var.vm-network
datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "template" {
name = "/${var.vsphere-datacenter}/vm/${var.vsphere-template-folder}/${var.vm-template-name}"
datacenter_id = data.vsphere_datacenter.dc.id
}
# Create Master-node VM
resource "vsphere_virtual_machine" "master-node" {
count = var.master-count
name = "${var.master-name}-${count.index + 1}"
resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
datastore_id = data.vsphere_datastore.datastore.id
num_cpus = var.vm-cpu
#num_cores_per_socket = var.vm-cores-per-socket
memory = var.vm-ram
guest_id = var.vm-guest-id
network_interface {
  network_id = data.vsphere_network.network.id
}
disk {
  label = "${var.master-name}-${count.index + 1}-disk"
  size  = var.master-disk-size
  eagerly_scrub = false
  thin_provisioned = false
}
clone {
  template_uuid = data.vsphere_virtual_machine.template.id
  customize {
    timeout = 0
    
    linux_options {
      host_name = "master-node-${count.index + 1}"
      domain = var.vm-domain
    }
    
    network_interface {}
  }
 }
}

resource "vsphere_virtual_machine" "etcd-node" {
count = var.etcd-count
name = "${var.etcd-name}-${count.index + 1}"
resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
datastore_id = data.vsphere_datastore.datastore.id
num_cpus = var.vm-cpu
#num_cores_per_socket = var.vm-cores-per-socket
memory = var.vm-ram
guest_id = var.vm-guest-id
network_interface {
  network_id = data.vsphere_network.network.id
}
disk {
  label = "${var.etcd-name}-${count.index + 1}-disk"
  size  = var.etcd-disk-size
  eagerly_scrub = false
  thin_provisioned = false
}
clone {
  template_uuid = data.vsphere_virtual_machine.template.id
  customize {
    timeout = 0
    
    linux_options {
      host_name = "etcd-node-${count.index + 1}"
      domain = var.vm-domain
    }
    
    network_interface {}
  }
 }
}

resource "vsphere_virtual_machine" "worker-node" {
count = var.worker-count
name = "${var.worker-name}-${count.index + 1}"
resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
datastore_id = data.vsphere_datastore.datastore.id
num_cpus = var.vm-cpu
#num_cores_per_socket = var.vm-cores-per-socket
memory = var.vm-ram
guest_id = var.vm-guest-id
network_interface {
  network_id = data.vsphere_network.network.id
}
disk {
  label = "${var.worker-name}-${count.index + 1}-disk"
  size  = var.worker-disk-size
  eagerly_scrub = false
  thin_provisioned = false
}
clone {
  template_uuid = data.vsphere_virtual_machine.template.id
  customize {
    timeout = 0
    
    linux_options {
      host_name = "worker-node-${count.index + 1}"
      domain = var.vm-domain
    }
    
    network_interface {}
  }
 }
}

# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("templates/inventory.tpl",
    {
      master-node = vsphere_virtual_machine.master-node.*.default_ip_address
      etcd-node = vsphere_virtual_machine.etcd-node.*.default_ip_address
      worker-node = vsphere_virtual_machine.worker-node.*.default_ip_address
    }
  )
  filename = "./hosts"
}
