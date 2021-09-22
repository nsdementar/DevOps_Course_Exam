[all]

%{ for name,ip in etcd-node ~}
etcd-node-${name} ansible_host=${ip}
%{ endfor ~}
%{ for name,ip in worker-node ~}
worker-node-${name} ansible_host=${ip}
%{ endfor ~}
%{ for name,ip in master-node ~}
master-node-${name} ansible_host=${ip}
%{ endfor ~}

[kube_control_plane]
%{ for name,ip in master-node ~}
master-node-${name} ansible_host=${ip}
%{ endfor ~}

[etcd]
%{ for name,ip in etcd-node ~}
etcd-node-${name} ansible_host=${ip}
%{ endfor ~}

[kube_node]
%{ for name,ip in worker-node ~}
worker-node-${name} ansible_host=${ip}
%{ endfor ~}

[k8s_cluster:children]
kube_control_plane
kube_node