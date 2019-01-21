## Kubernetes

Install and use this Matomo Image within a Kubernetes Cluster.

### Prerequisites

* Running Kubernetes and access to `kubectl`
* Some Storage Provider configured
* Optional: Ingress Controller (i.e. `ingress-nginx`)

### Install
To install simply apply all files with `kubectl`. You can use the direct GitHub links without cloning or downloading this repository.

```bash
# Create matomo namespace
kubectl apply -f https://raw.githubusercontent.com/crazy-max/docker-matomo/master/examples/kubernetes/01-namespace.yaml

# Add PersistentVolumeClaim matomo-pvc
kubectl apply -f https://raw.githubusercontent.com/crazy-max/docker-matomo/master/examples/kubernetes/02-volume.yaml

# Deployment
kubectl apply -f https://raw.githubusercontent.com/crazy-max/docker-matomo/master/examples/kubernetes/03-deployment.yml

# Service
kubectl apply -f https://raw.githubusercontent.com/crazy-max/docker-matomo/master/examples/kubernetes/04-service.yml
```

If u can't use a persistent volume, then skip the Volume and edit the `04-deployment.yaml` to use some other storage implementations like emptyDir or hostPath. 

### Optional Ingress
To enable external access use the following ingress and change the domain. If your Kubernetes Cluster also running a `cert-manager` instance, you can issue a Let's Encrypt certificate by uncomment the `tls` part and the additional annotations:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: matomo-ingress
  namespace: matomo
  annotations:
#    ingress.kubernetes.io/ssl-redirect: "true"
#    kubernetes.io/tls-acme: "true"
  kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - host: matomo.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: matomo
              servicePort: 8000
#  tls:
#    - hosts:
#      - matomo.example.com
#      secretName: matomo-ingress-tls
```
