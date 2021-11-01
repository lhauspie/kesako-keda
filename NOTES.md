# Installation

## Pré-requis

Installer GCloud et se connecter avec `gcloud auth login`
Installer Kubectl
Installer Helm
Installer Terraform

## Kubernetes Cluster Provisioning

Provisioner un Cluster Kubernetes :
```
$ cd ./gke
$ terraform init
$ terraform apply -auto-approve

Outputs:
kubernetes_cluster_host = "xx.xx.xx.xx"
kubernetes_cluster_name = "lhauspie-tz-keda-gke"
project_id = "lhauspie-tz-keda"
region = "europe-west2"
zone = "europe-west2-a"
```

Copier la valeur de la `zone` et de du `kubernetes_cluster_name` pour construire la commande :
```
$ gcloud container clusters get-credentials lhauspie-tz-keda-gke --zone europe-west2-a
```

## Installer le monitoring

Copier le fichier de configuration `monitoring.jsonnet` dans le dossier `kube-prometheus` :
```
$ cp monitoring.jsonnet kube-prometheus/monitoring.jsonnet
```

Fabriquer les manifests de `kube-prometheus` :
```
$ docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci jb update
$ docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci ./build.sh monitoring.jsonnet
```

Puis lancer le déploiement du monitoring :
```
$ # Prepare namespaces for prometheus
$ kubectl apply -f podinfo/setup
$ kubectl apply -f restaurant/setup
$ # Install kube-prometheus manifests
$ kubectl apply -f kube-prometheus/manifests/setup/
$ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo "."; done
$ kubectl apply -f kube-prometheus/manifests/
```

/!\ /!\ /!\

Il est arrivé que le fichier `prometheus-operator-0prometheusCustomResourceDefinition.yaml` soit trop volumineux. La solution a été de supprimer toutes les balises `description` de ce fichier.

/!\ /!\ /!\

De même, les fichiers `prometheus-podDisruptionBudget.yaml` et `prometheus-adapter-podDisruptionBudget.yaml` ne sont pas passés car le kind `PodDisruptionBudget` existe depuis la version 1.21 de Kubernetes mais GKE est en version 1.20. J'ai dû mettre leur contenu en commentaire. En espérant que ça ne pose pas de problèmes plus tard.

/!\ /!\ /!\


Une fois la commande finie, il est possible de suivre l'avancement avec :
```
$ watch kubectl get pods -n monitoring
```
Ce qui donne ceci :
```
NAME                                  READY   STATUS    RESTARTS   AGE
grafana-644c98fd57-q9x4r              1/1     Running   0          2m30s
kube-state-metrics-6c699dfb8-bqdtl    3/3     Running   0          2m29s
prometheus-adapter-7dc46dd46d-8tgcg   1/1     Running   0          2m26s
prometheus-adapter-7dc46dd46d-zspdn   1/1     Running   0          2m26s
prometheus-k8s-0                      2/2     Running   0          2m23s
prometheus-k8s-1                      2/2     Running   0          2m23s
prometheus-operator-5c875b748-jjfjf   2/2     Running   0          2m41s
```

Pour tester l'accès à Grafana :
```
$ kubectl --namespace monitoring port-forward svc/prometheus-k8s         9090 &
$ curl localhost:9090
```

Pour tester l'accès à Prometheus :
```
$ kubectl --namespace monitoring port-forward svc/grafana                3000 &
$ curl localhost:3000
```

# Tester (c'est douté)

## Load Balancing :

```
$ kubectl apply -f podinfo/setup
$ kubectl apply -f podinfo
```

Vérifier le bon déploiement :
```
$ kubectl get pods -n podinfo
```

Retrouver l'addresse IP :
```
$ export IP=$(kubectl -n podinfo get ingress/podinfo --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Vérification :
```
$ curl $IP
Hostname: podinfo-7d666f84d8-k8ldw
[...]
X-Forwarded-For: 85.168.26.74, 34.120.46.102
X-Forwarded-Proto: http

$ curl $IP
Hostname: podinfo-7d666f84d8-7ntw7
[...]
X-Forwarded-For: 85.168.26.74, 34.120.46.102
X-Forwarded-Proto: http
```


## Installer la simulation du restaurant :

```
$ make deploy_app
```

Cela peut prendre plusieurs minutes pour tout installer et disposer de l'addresse IP Externe. Je conseille d'utiliser la commande pour en suivre l'avancement :
```
$ watch kubectl get ingress -n restaurant 
```

Pour vérifier que tout a fonctionné correctement, il est possible de lancer une salve de 300 requêtes sur le endpoint `/enter` :
```
$ export RESTAURANT=$(kubectl -n restaurant get ingress/restaurant-staff --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ for ((i = 0; i < 300; i++)); curl http://$RESTAURANT/enter &; echo "DONE"
```





## Supprimer le cluster GKE

Pour supprimer tout le cluster GKE, il suffit de faire :
```
$ terraform destroy -auto-approve
```




