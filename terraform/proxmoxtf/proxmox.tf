resource "proxmox_virtual_environment_vm" "k3s-server" {
  count       = 3
  name        = "k3s-server-${count.index}"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu"]

  node_name = "pve"
  vm_id     = 4321 + count.index
  clone {
    vm_id     = 9000
    full      = true
    retries   = 25
  }
  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
  }
  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores        = 2
    type         = "x86-64-v2-AES"  # recommended for modern CPUs
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "nas"
    # file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format = "raw"
    size = 64
    interface = "scsi0"
  }


  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.${100 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }

    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = random_password.ubuntu_vm_password.result
      username = "adminuser"
    }

  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version = "v2.0"
  }

  serial_device {}
}

resource "proxmox_virtual_environment_vm" "k3s-worker" {
  count       = 3
  name        = "k3s-worker-${count.index}"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu"]

  node_name = "pve"
  vm_id     = 4341 + count.index

  clone {
    vm_id     = 9000
    full      = true
    retries   = 25     # Proxmox errors with timeout when creating multiple clones at once
  }

  #   dynamic "hostpci" {
  #   for_each = { for device in each.value.devices : device.mapping => device if device.type == "pci" }
  #   content {
  #     device  = "hostpci${hostpci.key}"  # `key` from for_each is used for the index
  #     mapping = hostpci.value.mapping
  #     pcie    = true
  #     mdev    = try(hostpci.value.mdev, null) != "" ? hostpci.value.mdev : null
  #     rombar  = hostpci.value.rombar
  #   }
  # }

  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores        = 8
    type         = "host"  # recommended for modern CPUs
  }

  memory {
    dedicated = 32768
  }

  disk {
    datastore_id = "nas"
    # file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format = "raw"
    size = 3072
    interface = "scsi0"
  }
  # disk {
  #   datastore_id = "nas"
  #   size = 1024
  #   interface = "scsi1"
  #   file_format = "raw"
  # }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.${120 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }

    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = random_password.ubuntu_vm_password.result
      username = "adminuser"
    }

  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version = "v2.0"
  }

  serial_device {}
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_vm_password" {
  value     = random_password.ubuntu_vm_password.result
  sensitive = true
}

output "ubuntu_vm_private_key" {
  value     = tls_private_key.ubuntu_vm_key.private_key_pem
  sensitive = true
}

output "ubuntu_vm_public_key" {
  value = tls_private_key.ubuntu_vm_key.public_key_openssh
}
