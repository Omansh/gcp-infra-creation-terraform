variable "path" {
    type = string
    default = "./gcp-terraform-project-keys.json"
}

variable "vpc_name" {
    type = string
    default = "vpc-created-via-terraform"  
}

variable "custom_subnet_name" {
    type = string
    default = "subnet-created-via-terraform"
}

variable "custom_subnet_cidr_range" {
    type = string   
    default = "10.0.1.0/24"
}
 variable "custom_subnet_region" {
   type = string
   default = "us-central1"
}

variable "ansible_target_instance" {
    type = string
    default = "ansible-target-node"  
}

variable "machine_type" {
  type = string
  default = "e2-medium"
}

variable "machine_image" {
    type = string
    default = "debian-cloud/debian-11"
}

variable "service_account" {
    type = string
    default = "terraform-gcp@terrafrom-gcp-364213.iam.gserviceaccount.com"
}

variable "service_account_scopes" {
    type = list(string)
    default = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
}

variable "custom_template_name" {
    type = string
    default = "custom-template-created-via-terraform"
}

variable "custom_template_machine_type" {
  type = string
  default = "e2-micro"
}
