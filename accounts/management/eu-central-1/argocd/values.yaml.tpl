server:
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - argocd.${domain_name}
    tls:
      - secretName: argocd-server-tls
        hosts:
          - argocd.${domain_name}

configs:
  params:
    server.insecure: true