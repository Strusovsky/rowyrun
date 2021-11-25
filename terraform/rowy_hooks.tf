// create a new service account for rowy hooks
resource "google_service_account" "rowy_hooks_serviceAccount" {
  // random account id
  account_id   = "rowy-hooks${random_integer.number.result}"
  display_name = "Rowy Run service Account"
}
resource "google_project_iam_binding" "rowy_hooks_roles" {
  project  = var.project
  for_each = toset(local.rowy_hooks_required_roles)
  role     = each.key
  members = [
    "serviceAccount:${google_service_account.rowy_hooks_serviceAccount.email}",
  ]
  depends_on = [google_service_account.rowy_hooks_serviceAccount]
}
// cloud run service with unauthenticated access
resource "google_cloud_run_service" "rowy_hooks" {
  name     = "rowy-hooks"
  location = var.region
  project  = var.project
  template {
    spec {
      containers {
        image = "gcr.io/rowy-run/rowy-hooks@sha256:5fd759afaa20ddb7f5c44a2a46ee298c5eb892a3ec7a31da63a1987d2c1bb09c"
        ports {
          container_port = 8080
        }
      }
      service_account_name = google_service_account.rowy_hooks_serviceAccount.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_service_account.rowy_hooks_serviceAccount
  ]
}

resource "google_cloud_run_service_iam_policy" "rowy_kooks_noauth" {
  location    = google_cloud_run_service.rowy_hooks.location
  project     = google_cloud_run_service.rowy_hooks.project
  service     = google_cloud_run_service.rowy_hooks.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
output "rowy_hooks_url" {
  value       = google_cloud_run_service.rowy_hooks.status[0].url
  description = "Rowy Hooks url"
}
output "rowy_hooks_service_account_email" {
  value       = google_service_account.rowy_hooks_serviceAccount.email
  description = "The created service account email"
}