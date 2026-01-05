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
    replicas = var.replicas

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
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
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
