# #
#
# Load depencies for our provider
#
# #

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}


# #
#
# Makefiles variables (droplet_count && domain)
# NODOMAIN mean the droplet(s) will be configured to ipv4 connections
#
# #

variable "droplet_count" {
  description = "Number of droplets to create"
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "NODOMAIN"

  validation {
    condition     = var.domain_name == "NODOMAIN" || can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}$", var.domain_name))
    error_message = "Le domaine doit être valide (ex: 'example.com') ou 'NODOMAIN'."
  }
}


# #
#
# Load our .env file
# And apply the DO_TOKEN
#
# #

data "local_file" "env" {
  filename = "${path.module}/../.env"
}

provider "digitalocean" {
    token = regex("DO_TOKEN=(.*)", data.local_file.env.content)[0]
}


# #
#
# Load our SSL pub key,
# allowing us to connect with our private key
#
# #

resource "digitalocean_ssh_key" "dg_pub_key" {
  name = "dg-pub-key"
  public_key = file("${path.module}/id_rsa.pub")
}


# #
#
# Generate a random id
# added to our Firewall and VM's names
#
# #

resource "random_id" "unique" {
  byte_length = 4
}


# #
#
# Create our droplet
#
# #

resource "digitalocean_droplet" "web" {
    count = var.droplet_count
    
    image   = "ubuntu-20-04-x64"
    name    = "cloud-1-${count.index}-${random_id.unique.hex}"
    region  = "fra1"
    size    = "s-1vcpu-2gb"

    ssh_keys = [
      digitalocean_ssh_key.dg_pub_key.fingerprint
    ]

    connection {
      host  = self.ipv4_address
      type  = "ssh"
      user  = "root"
    }

    provisioner "remote-exec" {
      connection {
        host = self.ipv4_address
        user = "root"
        private_key = file("id_rsa")
      }
      inline = [
          "rm -rf /var/lib/apt/lists/*",
          "apt-get update",
          "apt-get upgrade -y",
          "apt-get install python3 -y"
      ]
    }

    provisioner "local-exec" {
      command = "echo '${self.ipv4_address}' >> hosts.ini"
    }
}


# #
#
# Create a Firewall for our droplet
# Only allowing inputs from 22, 80 and 443 ports
#  
# /!\ allowing 22 inbounds from all ips isn't safe but its a student project so..
#
# #

resource "digitalocean_firewall" "web" {
  name = "cloud-1-firewall-${random_id.unique.hex}"
  droplet_ids = digitalocean_droplet.web[*].id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}


# #
#
# Configure our DNS, and apply it to our droplet(s)
# If more than 1 droplet is created, then subdomains will be added
# Example: s1.domain.org, s2.domain.org, ...
#
# #

resource "digitalocean_domain" "main" {
  count = var.domain_name != "NODOMAIN" ? 1 : 0  # Create only if domain_name var is set
  name = var.domain_name
}

resource "digitalocean_record" "droplet_dns" {
  count = var.domain_name != "NODOMAIN" ? var.droplet_count : 0  # Create only if domain_name var is set

  domain = digitalocean_domain.main[0].name
  type   = "A"
  name   = var.droplet_count == 1 ? "@" : "s${count.index + 1}"
  value  = digitalocean_droplet.web[count.index].ipv4_address
  ttl    = 300
}



# #
#
# Create inventory.ini for Ansible
#
# #
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [web]
    %{ if var.domain_name != "NODOMAIN" ~}
      %{ if length(digitalocean_droplet.web) == 1 ~}
        ${var.domain_name} ansible_host=${digitalocean_droplet.web[0].ipv4_address}
      %{ else ~}
        %{ for i, droplet in digitalocean_droplet.web ~}
          s${i+1}.${var.domain_name} ansible_host=${droplet.ipv4_address}
        %{ endfor ~}
      %{ endif ~}
    %{ else ~}
      %{ for i, droplet in digitalocean_droplet.web ~}
        ${droplet.ipv4_address} ansible_host=${droplet.ipv4_address}
      %{ endfor ~}
    %{ endif ~}

    [web:vars]
    ansible_user=root
    ansible_ssh_private_key_file=${path.module}/id_rsa
    domain_name=${var.domain_name}
  EOT
  filename = "${path.module}/inventory.ini"
}


# #
#
# Run Ansible
#
# #
resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/inventory.ini -u root --private-key=${path.module}/id_rsa playbook.yml
    EOT
  }
}


# #
#
# Just output our droplet's ip in stdout 
#
# #

output "droplet_ip" {
    value = digitalocean_droplet.web[*].ipv4_address
}
