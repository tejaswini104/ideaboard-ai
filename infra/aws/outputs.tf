output "cluster_name" { value = module.eks.cluster_name }
output "cluster_region" { value = var.region }
output "database_endpoint" { value = aws_db_instance.db.address }
output "database_name" { value = aws_db_instance.db.db_name }
