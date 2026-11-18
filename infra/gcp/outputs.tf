output "cluster_name" { value = google_container_cluster.primary.name }
output "cluster_region" { value = var.region }
output "database_connection_name" { value = google_sql_database_instance.postgres.connection_name }
