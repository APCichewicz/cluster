terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

provider proxmox {
    endpoint = "https://192.168.1.155:8006/"
    username = "root@pam"
    password = "9Princesinamber"
    insecure = true
    tmp_dir = "/var/tmp"
    
    ssh {
        agent = true
    }
}