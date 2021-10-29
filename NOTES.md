# Mes Notes pour le Jour J

## Pré-requis

Installer GCloud et se connecter avec `gcloud auth login`
Installer Kubectl
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
$ make build_manifest
```

Puis lancer le déploiement du monitoring :
```
$ make deploy_monitoring
```

/!\ /!\ /!\

Il est arrivé que le fichier `prometheus-operator-0prometheusCustomResourceDefinition.yaml` soit trop volumineux. La solution a été de supprimer toutes les balises `description` de ce fichier.

/!\ /!\ /!\

De même, les fichiers `prometheus-podDisruptionBudget.yaml` et `prometheus-adapter-podDisruptionBudget.yaml` ne sont pas passés. J'ai du mettre leur contenu en commentaire. En espérant que ça ne pose pas problème plus tard.

/!\ /!\ /!\


## Installer la simulation du restaurant :

```
$ make deploy_app
```


## Supprimer le cluster GKE

Pour supprimer tout le cluster GKE, il suffit de faire :
```
$ terraform destroy -auto-approve
```




