resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}
resource "kubernetes_namespace" "app" {
  depends_on = [helm_release.aws_lbc]
  metadata {
    name = "app"
  }
}

resource "kubernetes_deployment" "nginx_deployment" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.14.2"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Service Examples

resource "kubernetes_service" "nginx_service_instance" {
  metadata {
    name      = "nginx-lb-svc-instance-public"
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = kubernetes_deployment.nginx_deployment.metadata[0].labels.app
    }

    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}

resource "kubernetes_service" "nginx_service_ip" {
  metadata {
    name      = "nginx-lb-svc-ip-private"
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = kubernetes_deployment.nginx_deployment.metadata[0].labels.app
    }

    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}

# Ingress Examples

# We start with Service Cluster IPs, and use AWS LBC Ingress to expose & route
resource "kubernetes_service" "nginx_cip_svc_first" {
  metadata {
    name      = "nginx-cip-svc-first"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = kubernetes_deployment.nginx_deployment.metadata[0].labels.app
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "nginx_cip_svc_second" {
  metadata {
    name      = "nginx-cip-svc-second"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = kubernetes_deployment.nginx_deployment.metadata[0].labels.app
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "aws_lbc_ingress" {
  metadata {
    name      = "aws-lbc-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/"
      "alb.ingress.kubernetes.io/load-balancer-name" = "aws-lbc-ingress"
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"        = "ip"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/first"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nginx_cip_svc_first.metadata[0].name

              port {
                number = kubernetes_service.nginx_cip_svc_first.spec[0].port[0].port
              }
            }
          }
        }

        path {
          path      = "/second"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nginx_cip_svc_second.metadata[0].name

              port {
                number = kubernetes_service.nginx_cip_svc_second.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
