resource "google_compute_network" "vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet"
  ip_cidr_range = "10.30.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.40.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.50.0.0/20"
  }
}

resource "google_container_cluster" "primary" {
  name                     = "${var.name}-gke"
  location                 = var.region
  network                  = google_compute_network.vpc.id
  subnetwork               = google_compute_subnetwork.subnet.id
  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = true
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "${var.name}-nodes"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1
  node_config {
    machine_type = "e2-standard-2"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_sql_database_instance" "postgres" {
  name                = "${var.name}-postgres"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = false
  settings {
    tier      = "db-f1-micro"
    disk_size = 20
    ip_configuration {
      ipv4_enabled = true
    }
    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = "ideaboard"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = "ideaboard"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
