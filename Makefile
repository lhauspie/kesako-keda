
startup: provision_gke deploy_monitoring deploy_podinfo deploy_keda port_forward_monitoring deploy_restaurant deploy_perfect_restaurant deploy_dashboard wait_for_curls
	@echo "########################################################################################################################################"
	@echo "## You can now:"
	@echo "##  - Access Grafana at http://localhost:3000 (admin/admin)"
	@echo "##  - Access Prometheus at http://localhost:9090"
	@echo "##  - Make some requests to restaurant with http://$$(make get_restaurant_ip)/enter for example"
	@echo "##  - Make some requests to prefect_restaurant (if it's open) with http://$$(make get_perfect_restaurant_ip)/enter for example"
	@echo "########################################################################################################################################"

get_restaurant_ip:
	@kubectl -n restaurant          get ingress/restaurant-staff   --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

get_perfect_restaurant_ip:
	@kubectl -n perfect-restaurant  get ingress/restaurant-staff   --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

get_podinfo_ip:
	@kubectl -n podinfo             get ingress/podinfo            --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

wait_for_curls:
	@echo "Waiting for curls to be OK"
	@printf "Waiting for Prometheus ."
	@until [ $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9090) -eq 302 ]; do sleep 1; printf "."; done && echo " OK"
	@printf "Waiting for Grafana ."
	@until [ $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000) -eq 302 ]; do sleep 1; printf "."; done && echo " OK"
	@printf "Waiting for podinfo ."
	@until [ $$(curl -s -o /dev/null -w '%{http_code}' http://$$(make get_podinfo_ip)) -eq 200 ]; do sleep 1; printf "."; done && echo " OK"
	@printf "Waiting for restaurant ."
	@until [ $$(curl -s -o /dev/null -w '%{http_code}' http://$$(make get_restaurant_ip)/enter) -eq 200 ]; do sleep 1; printf "."; done && echo " OK"
	@echo "All curls are OK!"


###################################################
## K3S
################

install_k3d:
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

provision_k3s: # Create local cluster with k3s
	k3d cluster create kesako-keda --api-port 6550 -p "80:80@loadbalancer" --agents 2
	k3d kubeconfig get kesako-keda > kube.config
	kubectl create namespace monitoring

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
	cd gke && terraform destroy -auto-approve


###################################################
# Monitoring
################

build_manifest:
	# build kube-prometheus manifests
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci jb update
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci ./build.sh monitoring.jsonnet

deploy_monitoring:
	# Prepare namespaces for prometheus
	kubectl apply -f podinfo/setup/
	kubectl apply -f restaurant/setup/
	kubectl apply -f perfect-restaurant/setup/
	# Install kube-prometheus manifests
	kubectl apply -f kube-prometheus/manifests/setup/
	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo "."; done
	kubectl apply -f kube-prometheus/manifests/
	kubectl apply -f kube-prometheus/custom-metrics-apiservice.yaml

undeploy_monitoring:
	kubectl delete -f kube-prometheus/custom-metrics-apiservice.yaml   --ignore-not-found=true
	kubectl delete -f kube-prometheus/manifests/                       --ignore-not-found=true
	kubectl delete -f kube-prometheus/manifests/setup/                 --ignore-not-found=true

# Toujours à faire
port_forward_monitoring:
	ps -a | grep "port-forward" | grep -v grep | awk '{print $$1}' | xargs kill -9
	kubectl port-forward -n monitoring svc/prometheus-k8s 9090  2>&1 1>/dev/null &
	kubectl port-forward -n monitoring svc/grafana        3000  2>&1 1>/dev/null &


###################################################
# Applications
################

# Deploy
deploy_restaurant:
	kubectl apply -f restaurant/setup/
	kubectl apply -f restaurant/postgres/
	kubectl apply -f restaurant/common/
#	@echo '########################################################################################################################################'
#	@echo 'DON‘T FORGET TO RUN THE FOLLOWING COMMAND WHEN INGRESS IS DONE'
#	@echo '   export RESTAURANT_IP=$$(kubectl -n restaurant get ingress/restaurant-staff --output jsonpath="{.status.loadBalancer.ingress[0].ip}")'
#	@echo '########################################################################################################################################'


deploy_podinfo:
	kubectl apply -f podinfo/setup/
	kubectl apply -f podinfo/
#	@echo '########################################################################################################################################'
#	@echo 'DON‘T FORGET TO RUN THE FOLLOWING COMMAND WHEN INGRESS IS DONE'
#	@echo '   export PODINFO_IP=$$(kubectl -n podinfo get ingress/podinfo --output jsonpath="{.status.loadBalancer.ingress[0].ip}")'
#	@echo '########################################################################################################################################'

watch_podinfo:
	watch -n 0.5 curl -s $$(kubectl -n podinfo get ingress/podinfo --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Undeploy
undeploy_restaurant:
	kubectl delete -f restaurant/keda_scaling/opening_hours/  --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/history/        --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/attendance/     --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/custom/         --ignore-not-found=true
	kubectl delete -f restaurant/hpa_scaling/custom/          --ignore-not-found=true
	kubectl delete -f restaurant/hpa_scaling/cpu/             --ignore-not-found=true
	kubectl delete -f restaurant/postgres/                    --ignore-not-found=true
	kubectl delete -f restaurant/common/                      --ignore-not-found=true
#	kubectl delete -f restaurant/setup/                       --ignore-not-found=true

undeploy_podinfo:
	kubectl delete -f podinfo/                                --ignore-not-found=true


###################################################
# Perfect Restaurant
################

deploy_perfect_restaurant: deploy_monitoring
	kubectl apply -f perfect-restaurant/setup/
	kubectl apply -f perfect-restaurant/postgres/
	kubectl apply -f perfect-restaurant/application/
	kubectl apply -f perfect-restaurant/

undeploy_perfect_restaurant:
	kubectl delete -f perfect-restaurant/                     --ignore-not-found=true
	kubectl delete -f perfect-restaurant/application/         --ignore-not-found=true
	kubectl delete -f perfect-restaurant/postgres/            --ignore-not-found=true


###################################################
# Tools
################

deploy_dashboard:
	curl -s -X POST \
    		-u admin:admin \
    		-H "Accept: application/json" \
    		-H "Content-Type: application/json" \
    		-d "@mon_dashboard.json" \
    		http://localhost:3000/api/dashboards/db           | true

deploy_keda:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	kubectl create namespace keda                             | true
	helm install keda kedacore/keda --namespace keda          | true

simulation:
	@export RESTAURANT_IP=$$(kubectl -n restaurant get ingress/restaurant-staff --output jsonpath="{.status.loadBalancer.ingress[0].ip}") && \
	cd customers && make noon

remove_old_configuration:
	kubectl delete -f restaurant/hpa_scaling/custom/          --ignore-not-found=true
	kubectl delete -f restaurant/hpa_scaling/cpu/             --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/custom/         --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/attendance/     --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/history/        --ignore-not-found=true
	kubectl delete -f restaurant/keda_scaling/opening_hours/  --ignore-not-found=true
	kubectl delete -f restaurant/cron_job-simulation.yaml     --ignore-not-found=true

# Demo 0 stands for "restart from the beginning"
# This will remove all specific configurations then redeploy restaurant with all default configuration
demo0: remove_old_configuration deploy_restaurant

demo1: demo0 # Scalabilité sur la charge de travail
	kubectl apply -f restaurant/hpa_scaling/cpu/
	make simulation

demo2: demo0 deploy_keda # Scalabilité sur la charge de sollicitation (nb appels)
	sleep 60
	kubectl apply -f restaurant/hpa_scaling/custom/
	make simulation

demo3: demo0 deploy_keda # Scalabilité sur la charge de sollicitation (temps d'attente)
	sleep 60
	kubectl apply -f restaurant/keda_scaling/custom/
	make simulation

demo4: demo0 deploy_keda # Scalabilité sur la fréquentation
	sleep 60
	kubectl apply -f restaurant/keda_scaling/attendance/
	make simulation

demo5: demo0 deploy_keda # Scalabilité sur l’historique de fréquentation
	sleep 60
	kubectl apply -f restaurant/keda_scaling/history/
	kubectl apply -f restaurant/cron_job-simulation.yaml

demo6: demo0 deploy_keda # Scalabilité sur les horaires d’ouverture
	sleep 60
	kubectl apply -f restaurant/keda_scaling/opening_hours/

demo7: deploy_keda deploy_perfect_restaurant # Scalabilité + Scalabilité + Scalabilité



