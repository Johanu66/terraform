resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}



resource "google_compute_instance" "vm_instance" {
  count = 3
  name         = "vm-instance-${count.index}"
  machine_type = "n2-standard-2"
  zone         = "${var.region}-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "vpc-network"

    access_config {

    }
  }
}



resource "google_sql_database_instance" "db_instance" {
  name             = "db-instance"
  region           = var.region
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.self_link
    }
  }
  deletion_protection = "true"
}



resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.db_instance.name
}



resource "google_dns_record_set" "dns_record" {
  name = "dns-record.${google_dns_managed_zone.prod.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = [google_compute_instance.vm_instance[0].network_interface[0].access_config[0].nat_ip]
}



resource "google_dns_managed_zone" "prod" {
  name     = "prod-zone"
  dns_name = "prod.mydomain.com."
}