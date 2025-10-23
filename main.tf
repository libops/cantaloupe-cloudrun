terraform {
  required_version = "= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.8.0"
    }
  }

  backend "gcs" {
    bucket = "libops-cantaloupe-terraform"
    prefix = "/github"
  }
}

provider "google" {
  alias   = "default"
  project = var.project
}


resource "google_storage_bucket" "data" {
  project                     = var.project
  name                        = "${var.project}-data"
  location                    = "US"
  uniform_bucket_level_access = true
}

data "google_service_account" "cr" {
  project    = var.project
  account_id = "cr-cantaloupe"
}

data "google_service_account" "github" {
  project    = var.project
  account_id = "github"
}

resource "google_storage_bucket_iam_member" "gcs-admin" {
  for_each = toset([
    data.google_service_account.cr.email,
  ])
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${each.value}"
}

resource "google_storage_bucket_iam_member" "gcs-bucket-viewer" {
  for_each = toset([
    data.google_service_account.github.email,
  ])
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.legacyBucketOwner"
  member = "serviceAccount:${each.value}"
}

module "cantaloupe" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.3"

  name    = "cantaloupe"
  project = var.project
  gsa     = data.google_service_account.cr.name
  containers = tolist([
    {
      name   = "cantaloupe",
      image  = "islandora/cantaloupe:6.0.3@sha256:c9c20854074d4531078c2f8fd9a2dd359f122a46731473d7ce1afc9edbfec044"
      port   = 8182
      memory = "16Gi"
      cpu    = "4000m"
      volume_mounts = [
        {
          name       = "cantaloupe-data",
          mount_path = "/data"
        },
      ]
    }
  ])

  addl_env_vars = tolist([
    {
      name  = "CANTALOUPE_PROCESSOR_STREAM_RETRIEVAL_STRATEGY"
      value = "CacheStrategy"
    },
    {
      name  = "CANTALOUPE_HTTPSOURCE_CHUNKING_ENABLED"
      value = "false"
    },
    {
      name  = "CANTALOUPE_CACHE_SERVER_DERIVATIVE_ENABLED"
      value = "true"
    },
    {
      name  = "CANTALOUPE_CACHE_SERVER_DERIVATIVE"
      value = "FilesystemCache"
    },
    {
      name  = "CANTALOUPE_LOG_APPLICATION_LEVEL"
      value = "info"
    }
  ])

  gcs_volumes = [
    {
      name      = "cantaloupe-data"
      bucket    = google_storage_bucket.data.name
      read_only = false
    }
  ]

  providers = {
    google = google.default
  }
}

module "lb" {
  source = "./modules/lb"

  project = var.project
  backends = {
    "cantaloupe" = module.cantaloupe.backend,
  }
}

resource "google_monitoring_uptime_check_config" "availability" {
  for_each = toset([
    "cantaloupe",
  ])
  display_name = "${each.value}-availability"
  timeout      = "10s"
  period       = "60s"
  project      = var.project
  selected_regions = [
    "USA_OREGON",
    "USA_VIRGINIA",
    "USA_IOWA"
  ]
  http_check {
    path         = "/health"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project
      host       = "cantaloupe.libops.io"
    }
  }
}
