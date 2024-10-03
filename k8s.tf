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
    name = "nginx-deployment"
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

resource "kubernetes_service" "nginx_service_instance" {
  metadata {
    name = "nginx-service-instance"
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
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
    name = "nginx-service-ip"
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
