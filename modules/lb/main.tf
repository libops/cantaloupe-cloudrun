locals {
  metrics_json = file("${path.module}/dashboard.json")
  md5          = md5(local.metrics_json)
}

data "google_compute_global_address" "default" {
  project = var.project
  name    = "cantaloupe-ipv4"
}

data "google_compute_global_address" "default-v6" {
  project = var.project
  name    = "cantaloupe-ipv6"
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project
  name                  = "cantaloupe-https"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = data.google_compute_global_address.default.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_global_forwarding_rule" "https-v6" {
  project               = var.project
  name                  = "cantaloupe-https-v6"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = data.google_compute_global_address.default-v6.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_target_https_proxy" "default" {
  project = var.project
  name    = "cantaloupe-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id,
  ]
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "cantaloupe-tls"
  managed {
    domains = [
      "cantaloupe.libops.io"
    ]
  }
  project = var.project
}

resource "google_compute_url_map" "default" {
  name    = "cantaloupe-url-map"
  project = var.project

  default_service = var.backends.cantaloupe
}

# add a dashboard
# only updating it if we update our JSON
# since terraform and google's dashboard exports don't play nice
resource "null_resource" "metrics-json" {
  triggers = {
    md5 = local.md5
  }
}

resource "google_monitoring_dashboard" "dashboard" {
  project        = var.project
  dashboard_json = local.metrics_json

  lifecycle {
    ignore_changes = [
      dashboard_json
    ]
    replace_triggered_by = [null_resource.metrics-json.id]
  }
}
