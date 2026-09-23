# 1. Define a Custom Monitoring Service to group the application target
resource "google_monitoring_service" "app_service" {
  service_id   = "devops-app-service"
  display_name = "DevOps Sample Application Service"

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      service_name = google_cloud_run_v2_service.sample_app.name
      location     = google_cloud_run_v2_service.sample_app.location
    }
  }
}

# 2. Availability SLO: 99.5% non-5xx responses over a 30-day rolling window
resource "google_monitoring_slo" "availability_slo" {
  service      = google_monitoring_service.app_service.service_id
  slo_id       = "availability-slo-99-5"
  display_name = "99.5% Availability over 30 Days"

  goal                = 0.995 # 99.5% target
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio_threshold {
      # Metric filtering for request counts
      good_service_filter  = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${google_cloud_run_v2_service.sample_app.name}\" response_code_class=\"2xx\""
      total_service_filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${google_cloud_run_v2_service.sample_app.name}\""
    }
  }
}

# 3. Latency SLO: 99% of requests < 300ms over a 7-day rolling window
resource "google_monitoring_slo" "latency_slo" {
  service      = google_monitoring_service.app_service.service_id
  slo_id       = "latency-slo-300ms"
  display_name = "99% Requests Latency < 300ms"

  goal                = 0.99
  rolling_period_days = 7

  request_based_sli {
    distribution_cut {
      distribution_filter = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${google_cloud_run_v2_service.sample_app.name}\""
      range {
        max = 300 # milliseconds
      }
    }
  }
}

# 4. Fast Burn Rate Alert Policy: Alert when 2% of Error Budget burns in 1 hour (14x rate)
resource "google_monitoring_alert_policy" "fast_burn_alert" {
  display_name = "SLO Fast Burn Rate Alert (Availability)"
  combiner     = "OR"

  conditions {
    display_name = "Availability SLO - Fast Burn (14x)"

    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability_slo.name}\", 3600s)"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 14

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  documentation {
    content   = "High error budget consumption rate detected on ${google_cloud_run_v2_service.sample_app.name}. Investigate recent deployments or service outages."
    mime_type = "text/markdown"
  }
}
