# Sample target application service for monitoring
resource "google_cloud_run_v2_service" "sample_app" {
  name     = "devops-sample-app"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }
    }
  }
}

# Allow unauthenticated invocations for testing
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.sample_app.project
  location = google_cloud_run_v2_service.sample_app.location
  name     = google_cloud_run_v2_service.sample_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_v2_service.sample_app.uri
}
