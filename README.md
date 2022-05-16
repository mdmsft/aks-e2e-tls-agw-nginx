# AKS e2e TLS with Application Gateway and NGINX ingress controller

## NGINX installation
In the `k8s/nginx.values.yaml` replace `0.0.0.0` with the `backend_address_pool_ip_address` output value and then:
```sh
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace -f k8s/nginx.values.yaml
```

## Image creation
```sh
az acr build --registry crdemo --image hello-world-dotnet:1.0.0 app
```

## Chart values
```yaml
image:
  registry: crdemo.azurecr.io

keyVaultName: kv-demo-dev-weu
keyVaultTenant: 72f988bf-baad-dead-f00d-2d7cd011db47
clientId: e8c519d2-dead-baad-f00d-966089b55918
hostname: contoso.com
certificateName: demo
```

## Chart installation
```sh
 helm upgrade --install hello-world k8s/chart -f k8s/app.values.yaml
```
