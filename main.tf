/* VPC Creation */
resource "google_compute_network" "custom_vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

/* Subnet Creation */
resource "google_compute_subnetwork" "custom_subnet" {
  name          = var.custom_subnet_name
  ip_cidr_range = var.custom_subnet_cidr_range
  region        = var.custom_subnet_region
  network       = google_compute_network.custom_vpc_network.id
}

/* Firewall Rule allow-http */

resource "google_compute_firewall" "allow_http" {
  name        = "allow-http"
  network     = google_compute_network.custom_vpc_network.id
  description = "Creates allow-http firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["80", "8080", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-http"]
}

/* Firewall Rule allow-icmp */

resource "google_compute_firewall" "allow_icmp" {
  name        = "allow-icmp"
  network     = google_compute_network.custom_vpc_network.id
  description = "Creates allow-icmp firewall rule targeting tagged instances"

  allow {
    protocol  = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["icmp"]
}

/* Firewall Rule allow-ssh */

resource "google_compute_firewall" "allow_ssh" {
  name        = "allow-ssh"
  network     = google_compute_network.custom_vpc_network.id
  description = "Creates allow-icmp firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-ssh"]
}

/* Firewall Rule allow-sonar */

resource "google_compute_firewall" "allow_sonar" {
  name        = "allow-sonar"
  network     = google_compute_network.custom_vpc_network.id
  description = "Creates allow-icmp firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports = ["9000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-sonar"]
}

resource "google_compute_firewall" "allow_nexus" {
  name        = "allow-nexus"
  network     = google_compute_network.custom_vpc_network.id
  description = "Creates allow-icmp firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports = ["8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-nexus"]
}

/* Compute Instance Creation */

resource "google_compute_instance" "vm_ansible_target_node1" {

  name = var.ansible_target_instance
  machine_type = var.machine_type
  zone = "us-central1-a"
  allow_stopping_for_update = true
   boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
   network_interface {
     network = google_compute_network.custom_vpc_network.id
     subnetwork = google_compute_subnetwork.custom_subnet.id
     access_config {}
  }
  tags = [ "allow-http", "allow-ssh", "allow-icmp", "allow-sonar", "allow-nexus"]

  metadata_startup_script = file("./shell_scripts/ansible_target_node.sh")

  service_account {
    email = var.service_account
    scopes = var.service_account_scopes
  }
}

/* Custom Template Creation */
resource "google_compute_instance_template" "custom-template" {
  name        = var.custom_template_name
  description = "This template is used to create web app server instances."

  tags = ["allow-http", "allow-ssh", "allow-icmp", "allow-sonar", "allow-nexus" ]

  labels = {
    environment = "dev"
  }

  instance_description = "Description assigned to instances"
  machine_type         = var.custom_template_machine_type
  can_ip_forward       = false


  // Create a new boot disk from an image
  disk {
    source_image      = "debian-cloud/debian-11"
    auto_delete       = true
    boot              = true
  }

  network_interface {
     network = google_compute_network.custom_vpc_network.id
     subnetwork = google_compute_subnetwork.custom_subnet.id
     access_config {}
  }

  metadata_startup_script = file("./shell_scripts/mig_startup.sh")

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email = var.service_account
    scopes = var.service_account_scopes
  }
}

/* MIG Created Via Terraform */
resource "google_compute_region_instance_group_manager" "mig" {
  name               = "mig-created-via-terraform"
  base_instance_name = "mig-instance"
  version {
    instance_template  = google_compute_instance_template.custom-template.self_link
  }
  region             = "us-central1"
  target_size        = 2
  wait_for_instances = true

  timeouts {
    create = "15m"
    update = "15m"
  }
}

/* Cloud Load Balancer */
# reserved IP address
resource "google_compute_global_address" "default" {
  name = "static-ip"
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_backend_service" "default" {
  name        = "backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  load_balancing_scheme    = "EXTERNAL"
  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_http_health_check.default.id]
}

resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}
