// create a new service account for rowy hooks
resource "google_service_account" "rowy_hooks_serviceAccount" {
  // random account id
  account_id   = "rowy-hooks${random_integer.number.result}"
  display_name = "Rowy Hooks service Account"
}
// cloud run service with unauthenticated access
resource "google_cloud_run_service" "rowy_hooks" {
  name     = "rowy-hooks"
  location = var.region
  project  = var.project
  template {
    spec {
      containers {
        image = "gcr.io/rowy-run/rowy-hooks@sha256:604dd7ab71f19375519af3a7442d9c741da4c165933895362b7c696986ce6432"
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