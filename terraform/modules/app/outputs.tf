output "deployment_names" {
  value = [for d in kubernetes_deployment.apps : d.metadata[0].name]
}

output "service_names" {
  value = [for s in kubernetes_service.apps : s.metadata[0].name]
}

output "frontend_ingress_name" {
  value = length(kubernetes_ingress.frontend) > 0 ? kubernetes_ingress.frontend[0].metadata[0].name : ""
}
