# Local Dev Installation: ingress-nginx + Argo CD + kube-prometheus-stack

This document describes how to install the three wrapper Helm charts for local development on Docker Desktop (Mac) using nip.io hostnames and no TLS.

Prerequisites:
- Docker Desktop Kubernetes enabled
- kubectl and helm v3 installed

1. Clone / open this repository (already done).

2. Install ingress-nginx (wrapper chart):

```
helm dependency update charts/ingress-nginx
helm install ingress charts/ingress-nginx -n ingress-nginx --create-namespace
```

Verify controller is Ready:
```
kubectl -n ingress-nginx get pods
```

3. Install Argo CD (wrapper chart):

```
helm dependency update charts/argocd
helm install argocd charts/argocd -n argocd --create-namespace
```

Retrieve initial admin password:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Access Argo CD UI (after ingress ready):
- http://argocd.127.0.0.1.nip.io

CLI login:
```
argocd login argocd.127.0.0.1.nip.io --insecure --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

4. Install kube-prometheus-stack (wrapper chart):

```
helm dependency update charts/kube-prometheus-stack
helm install observability charts/kube-prometheus-stack -n monitoring --create-namespace
```

Access UIs:
- Grafana: http://grafana.127.0.0.1.nip.io
- Prometheus: http://prometheus.127.0.0.1.nip.io
- Alertmanager: http://alertmanager.127.0.0.1.nip.io

Grafana credentials (dev):
- user: admin
- pass: admin

5. Troubleshooting:
- Check ingresses: `kubectl get ingress -A`
- Controller logs: `kubectl -n ingress-nginx logs deploy/ingress-ingress-nginx-controller`
- DNS hostnames use nip.io. If unreachable, append entries to /etc/hosts pointing to 127.0.0.1.

6. Uninstall everything:
```
helm uninstall observability -n monitoring || true
helm uninstall argocd -n argocd || true
helm uninstall ingress -n ingress-nginx || true
kubectl delete namespace monitoring argocd ingress-nginx --ignore-not-found
```

Done.