# Installation

## Avertissement
Toutes les commandes et les fichiers de description ont été créés et exécutés avec la version suivante :
```
$ kubectl version

Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.2", GitCommit:"8b5a19147530eaac9476b0ab82980b4088bbc1b2", GitTreeState:"clean", BuildDate:"2021-09-15T21:31:32Z", GoVersion:"go1.16.9", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"20+", GitVersion:"v1.20.10-gke.301", GitCommit:"17ad7bd6afa01033d7bd3f02ce5de56f940a915d", GitTreeState:"clean", BuildDate:"2021-08-24T05:18:54Z", GoVersion:"go1.15.15b5", Compiler:"gc", Platform:"linux/amd64"}
WARNING: version difference between client (1.22) and server (1.20) exceeds the supported minor version skew of +/-1
```
Il est donc possible que les fichiers de description ne soient pas compatibles avec une version suppérieure.

Aussi, tous ces scripts ne sont clairement pas production-ready. Donc ne pas les utilisez pour provisionner votre GKE de Prod.

## Pré-requis
- [Installer GCloud](https://cloud.google.com/sdk/docs/install) et se connecter avec `gcloud auth login`
- [Installer Kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/)
- [Installer Helm](https://helm.sh/docs/intro/install/)
- [Installer Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

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

Copier la valeur de la `zone` et du `kubernetes_cluster_name` pour construire la commande :
```
$ gcloud container clusters get-credentials lhauspie-tz-keda-gke --zone europe-west2-a
```

## Installer le monitoring

### Les fichiers Manifest
Copier le fichier de configuration `monitoring.jsonnet` dans le dossier `kube-prometheus` :
```
$ cp monitoring.jsonnet kube-prometheus/monitoring.jsonnet
```

Fabriquer les manifests de `kube-prometheus` :
```
$ docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci jb update
$ docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci ./build.sh monitoring.jsonnet
```

### Modification des fichiers

Pour les besoins de la présentation, il faut modifier la `ConfigMap` du `promertheus-adapter` (i.e. `kube-prometheus/manifests/prometheus-adapter-configMap.yaml`) pour y ajouter le bloc suivant au même niveau que le `resourceRules` déjà présent :
```
    "rules":
      - "seriesQuery": "http_server_requests_seconds_count"
        "resources":
          "overrides":
            "namespace":
              "resource": "namespace"
            "pod":
              "resource": "pod"
        "metricsQuery": 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)'
        "name":
          "matches": "^(.*)_seconds_count$"
          "as": "${1}_per_second"
```

⚠️ ⚠️ ⚠️️ ⚠️️ ⚠️️ ⚠️️ ⚠️

Lors de mes tentatives, le fichier `prometheus-operator-0prometheusCustomResourceDefinition.yaml` était trop volumineux. Le contournement a été de supprimer toutes les balises `description` de ce fichier.

⚠️ ⚠️ ⚠️️ ⚠️️ ⚠️️ ⚠️️ ⚠️

De même, les fichiers `prometheus-podDisruptionBudget.yaml` et `prometheus-adapter-podDisruptionBudget.yaml` ne sont pas passés car le kind `PodDisruptionBudget` existe depuis la version 1.21 de Kubernetes mais GKE est en version 1.20 au moment de l'écriture de cette doc.

J'ai dû mettre leur contenu en commentaire. En espérant que ça ne pose pas de problèmes plus tard.

⚠️ ⚠️ ⚠️️ ⚠️️ ⚠️️ ⚠️️ ⚠️

### Déploiement
Puis lancer le déploiement du monitoring :
```
$ # Prepare namespaces for prometheus
$ kubectl apply -f podinfo/setup
$ kubectl apply -f restaurant/setup
$ kubectl apply -f perfect_restaurant/setup
$ # Install kube-prometheus manifests
$ kubectl apply -f kube-prometheus/manifests/setup/
$ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo "."; done
$ kubectl apply -f kube-prometheus/manifests/
```

Une fois la commande finie, il est possible de suivre l'avancement avec :
```
$ kubectl get pods -n monitoring --watch
```
Ce qui donne ceci :
```
NAME                                  READY   STATUS    RESTARTS   AGE
prometheus-operator-5c875b748-jjfjf   2/2     Running   0          2m41s
grafana-644c98fd57-q9x4r              1/1     Running   0          2m30s
kube-state-metrics-6c699dfb8-bqdtl    3/3     Running   0          2m29s
prometheus-adapter-7dc46dd46d-8tgcg   1/1     Running   0          2m26s
prometheus-adapter-7dc46dd46d-zspdn   1/1     Running   0          2m26s
prometheus-k8s-0                      2/2     Running   0          2m23s
prometheus-k8s-1                      2/2     Running   0          2m23s
```

### Accèder aux Dashboards
Pour tester l'accès aux Dashboards, il faut rediriger les ports de la machine vers les Services Grafana et Prometheus.

Grafana :
```
$ kubectl -n monitoring port-forward svc/prometheus-k8s 9090 &
$ curl localhost:9090
```

Prometheus :
```
$ kubectl -n monitoring port-forward svc/grafana        3000 &
$ curl localhost:3000
```


# Tester (c'est douté)

## Load Balancing :

Déployer des podinfo pour vérifier le LoadBalancing :
```
$ kubectl apply -f podinfo/setup
$ kubectl apply -f podinfo
```

Vérifier le bon déploiement :
```
$ kubectl get pods -n podinfo

NAME                       READY   STATUS    RESTARTS   AGE
podinfo-6597f6f47d-7g7ld   1/1     Running   0          8s
podinfo-6597f6f47d-g5wqt   1/1     Running   0          8s
podinfo-6597f6f47d-xr2ng   1/1     Running   0          8s
podinfo-6597f6f47d-zqh8g   1/1     Running   0          8s
```

Retrouver l'addresse IP de l'ingress exposant le service :
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
```

```
$ curl $IP

Hostname: podinfo-7d666f84d8-7ntw7
[...]
X-Forwarded-For: 85.168.26.74, 34.120.46.102
X-Forwarded-Proto: http
```

# Le restaurant

Cette simulation se trouvera dans le namespace kubernetes `restaurant`.
Il est possible de créer le namespace avec une de ces commandes au choix :
```
$ kubectl apply -f restaurant/setup
```
ou
```
$ kubectl create namespace restaurant
```

## Postgres
La simulation du restaurant a besoin d'une base de données PostgreSQL.

Pour installer PostgreSQL, il faut executer la commande :
```
$ kubectl apply -f restaurant/postgres/
```

Cet instance de PostgreSQL sera déployée dans le namespace `restaurant`. Si le namespace n'existe pas encore, la commande tombera en erreur. Il faudra donc executer la commande suivante pour créer le namespace :
```
$ kubectl apply -f restaurant/setup
```

## Installer la simulation du restaurant :

Veillez à bien avoir déployé postgres avant d'executer ces commandes :
```
$ kubectl apply -f restaurant/setup/
$ kubectl apply -f restaurant/common/
```

Cela peut prendre plusieurs minutes pour tout installer et disposer de l'addresse IP Externe. Je conseille d'utiliser la commande pour en suivre l'avancement :
```
$ kubectl get ingress -n restaurant --watch

NAME               CLASS    HOSTS   ADDRESS         PORTS   AGE
restaurant-staff   <none>   *       34.107.196.47   80      12m
```

Pour vérifier que tout a fonctionné correctement, il est possible de lancer une requête sur le endpoint `/enter` :
```
$ curl -s http://$(kubectl -n restaurant get ingress/restaurant-staff --output jsonpath='{.status.loadBalancer.ingress[0].ip}')/enter

Entered
```


## Supprimer le cluster GKE

Pour supprimer tout le cluster GKE, il suffit de faire (penser à valider l'action en tapant `yes`) :
```
$ cd ./gke
$ terraform destroy
```


# Postgres

## Test locally

```
$ docker run --rm --name postgres -d \
-e POSTGRES_PASSWORD=lhauspie \
-e POSTGRES_USER=lhauspie \
-e POSTGRES_DB=restaurant \
-p 5432:5432 postgres:14.0

$ docker run -it --rm \
--name postgres-client \
--link postgres \
--entrypoint psql \
postgres:14.0 \
restaurant -h postgres -U lhauspie --password -p 5432

Password: lhauspie
# select * from pg_catalog.pg_tables;
```

## Test inside GKE

```
$ kubectl apply -f restaurant/deployment-ubuntu.yaml

$ kubectl get pods -n restaurant
NAME                                      READY   STATUS    RESTARTS   AGE
postgres-stateful-set-0                   1/1     Running   0          10m
[...]
ubuntu-556d66858c-rjvzb                   1/1     Running   0          9m25s

$ kubectl -n restaurant exec --stdin --tty ubuntu-556d66858c-rjvzb -- /bin/bash
root@ubuntu-556d66858c-rjvzb:/# apt update
root@ubuntu-556d66858c-rjvzb:/# apt install postgresql postgresql-contrib
root@ubuntu-556d66858c-rjvzb:/# psql restaurant -h postgres -U lhauspie --password -p 5432
restaurant=# select * from customerarrival;
 id | arrivaltime 
----+-------------
(0 rows)
```

