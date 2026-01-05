locals {
  apps = {
    frontend = {
      port = 80
      image = "veeva/frontend:latest"
    }
    backend = {
      port = 8080
      image = "veeva/backend:latest"
    }
    datastream = {
      port = 9090
      image = "veeva/datastream:latest"
    }
  }
}

# Deployment for each app
resource "kubernetes_deployment" "apps" {
  for_each = local.apps
  metadata {
    name      = each.key
    namespace = "default"
    labels = {
      app = each.key
    }
  }

  spec {
    replicas = 2

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
  for_each = local.apps

  metadata {
    name      = each.key
    namespace = "default"
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
    namespace = "default"
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
