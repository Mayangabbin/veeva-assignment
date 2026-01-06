# Deployment for each app
resource "kubernetes_deployment" "apps" {
  for_each = var.apps
  metadata {
    name      = each.key
    namespace = var.namespace
    labels = {
      app = each.key
    }
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = {
        app = each.key
      }
    }

    template {
      metadata {
        labels = {
          app = each.key
        }
      }

      spec {
        # Spread pods across AZs for HA
        topology_spread_constraint {
          max_skew = 1
          topology_key = "topology.kubernetes.io/zone"
          label_selector {
            match_labels = {
              app = each.key
            }
          }
        }
        container {
          name  = each.key
          image = each.value.image
          resources {
            requests = {
              cpu    = each.value.cpu_request    
              memory = each.value.memory_request 
            }
            limits = {
              cpu    = each.value.cpu_limit    
              memory = each.value.memory_limit  
            }
          }

          port {
            container_port = each.value.port
          }
        }
      }
    }
  }

}

# Cluster IP service for each app
resource "kubernetes_service" "apps" {
  for_each = var.apps

  metadata {
    name      = each.key
    namespace = var.namespace
    labels = {
      app = each.key
    }
  }

  spec {
    selector = {
      app = each.key
    }
    port {
      port        = each.value.port
      target_port = each.value.port
    }
    type = "ClusterIP"
  }
}

# ALB Ingress for frontend
resource "kubernetes_ingress" "frontend" {
  metadata {
    name      = "frontend-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internal"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTP": 80}])
    }
  }

  spec {
    rule {
      http {
        path {
          path     = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.apps["frontend"].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# HPA
resource "kubernetes_horizontal_pod_autoscaler_v2" "apps" {
  for_each = var.apps

  metadata {
    name      = "${each.key}-hpa"
    namespace = var.namespace
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.apps[each.key].metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.cpu_target_percentage
        }
      }
    }
  }
}
