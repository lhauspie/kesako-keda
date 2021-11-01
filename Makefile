from_scratch_with_k3s: install_k3d create_cluster build_manifest deploy_app deploy_monitoring
from_scratch_with_gke: provision_gke build_manifest deploy_app deploy_monitoring

startup: provision_gke deploy_monitoring deploy_podinfo port_forward_monitoring deploy_restaurant

get_restaurant_ip:
	kubectl -n restaurant get ingress/restaurant-staff --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

get_podinfo_ip:
	kubectl -n podinfo get ingress/podinfo-ingress --output jsonpath='{.status.loadBalancer.ingress[0].ip}'



###################################################
## K3S
################

install_k3d:
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

provision_k3s: # Create local cluster with k3s
	k3d cluster create kesako-keda --api-port 6550 -p "80:80@loadbalancer" --agents 2
	k3d kubeconfig get kesako-keda > kube.config
	export KUBECONFIG=kube.config
	kubectl create namespace monitoring
	echo "DON'T FORGET TO EXECUTE 'export KUBECONFIG=kube.config' COMMAND"

start_k3s:
	k3d cluster start kesako-keda

stop_k3s:
	k3d cluster stop kesako-keda

destroy_k3s:
	k3d cluster delete kesako-keda


###################################################
## GKE
################

provision_gke:
	cd gke && terraform init && terraform apply -auto-approve
	gcloud container clusters get-credentials lhauspie-tz-keda-gke --zone europe-west2-a

destroy_gke:
	cd gke && terraform destroy


###################################################
# Monitoring
################

build_manifest:
	# build kube-prometheus manifests
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci jb update
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci ./build.sh monitoring.jsonnet

deploy_monitoring:
	# Prepare namespaces for prometheus
	kubectl apply -f podinfo/setup
	kubectl apply -f restaurant/setup
	# Install kube-prometheus manifests
	kubectl apply -f kube-prometheus/manifests/setup/
	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo "."; done
	kubectl apply -f kube-prometheus/manifests/
	kubectl apply -f kube-prometheus/custom-metrics-apiservice.yaml

# Toujours à faire
port_forward_monitoring:
	kubectl --namespace monitoring port-forward svc/prometheus-k8s         9090 &
	kubectl --namespace monitoring port-forward svc/grafana                3000 &


###################################################
# Applications
################

# Deploy
deploy_restaurant:
	kubectl apply -f restaurant/setup
	kubectl apply -f restaurant/common
	kubectl apply -f restaurant/no_scaling

deploy_podinfo:
	kubectl apply -f podinfo/setup
	kubectl apply -f podinfo

# Undeploy
undeploy_restaurant:
	kubectl delete -f restaurant/*

undeploy_podinfo:
	kubectl delete -f podinfo/


# N'est pas necessaire avec GKE
port_forward_restaurant:
	kubectl --namespace restaurant port-forward svc/restaurant-staff-enter 8081:8081 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-order 8082:8082 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-pay   8083:8083 &



###################################################
# Tools
################

deploy_keda:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	kubectl create namespace keda
	helm install keda kedacore/keda --namespace keda

simulation:
	cd customers && make noon

demo0:
	kubectl apply -f restaurant/setup
	kubectl apply -f restaurant/common
	kubectl apply -f restaurant/no_scaling
	kubectl delete -f restaurant/hpa_scaling/custom           | true
	kubectl delete -f restaurant/hpa_scaling/cpu              | true
	kubectl delete -f restaurant/keda_scaling/prometheus      | true
	kubectl delete -f restaurant/keda_scaling/attendance      | true
	kubectl delete -f restaurant/keda_scaling/history         | true
	kubectl delete -f restaurant/keda_scaling/opening_hours   | true

demo1:
	kubectl apply -f podinfo

demo2: demo0 # Scalabilité sur la charge de travail
	kubectl apply -f restaurant/hpa_scaling/cpu

demo2: demo0 # Scalabilité sur la charge de sollicitation
	kubectl apply -f restaurant/hpa_scaling/custom

demo3: demo0 # Scalabilité sur la charge de sollicitation (bis)
	kubectl apply -f restaurant/keda_scaling/custom

demo4: demo0 # Scalabilité sur la fréquentation
	kubectl apply -f restaurant/keda_scaling/attendance

demo5: demo0 # Scalabilité sur l’historique de fréquentation
	kubectl apply -f restaurant/keda_scaling/history

demo6: demo0 # Scalabilité sur les horaires d’ouverture
	kubectl apply -f restaurant/keda_scaling/opening_hours

demo7: demo0 # Scalabilité + Scalabilité + Scalabilité
	kubectl apply -f restaurant/keda_scaling/attendance
	kubectl apply -f restaurant/keda_scaling/history
	kubectl apply -f restaurant/keda_scaling/opening_hours
