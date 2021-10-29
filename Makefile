install_k3d:
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

create_cluster:
	# Spawn k3s cluster
	k3d cluster create kesako-keda
	k3d kubeconfig get kesako-keda > kube.config
	export KUBECONFIG=kube.config
	kubectl create namespace monitoring
	echo "DON'T FORGET TO EXECUTE 'export KUBECONFIG=kube.config' COMMAND"

deploy_app:
	export KUBECONFIG=kube.config
	kubectl apply -f k8s_restaurant/

deploy_whoami:
	export KUBECONFIG=kube.config
	kubectl apply -f k8s_whoami/

build_manifest:
	# build kube-prometheus manifests
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci jb update -h
	docker run --rm -v ${PWD}/kube-prometheus:/kube-prometheus --workdir /kube-prometheus quay.io/coreos/jsonnet-ci ./build.sh monitoring.jsonnet

deploy_monitoring:
	export KUBECONFIG=kube.config
	# Install kube-prometheus manifests
	kubectl apply -f kube-prometheus/manifests/setup/
	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo "."; done
	kubectl apply -f kube-prometheus/manifests/


port_forward_prometheus:
	export KUBECONFIG=kube.config
	kubectl --namespace monitoring port-forward svc/prometheus-k8s         9090 &

port_forward_grafana:
	export KUBECONFIG=kube.config
	kubectl --namespace monitoring port-forward svc/grafana                3000 &

port_forward_restaurant:
	export KUBECONFIG=kube.config
	kubectl --namespace restaurant port-forward svc/restaurant-staff-enter 8081:8081 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-order 8082:8082 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-pay   8083:8083 &

port_forward:
	export KUBECONFIG=kube.config
	kubectl --namespace monitoring port-forward svc/prometheus-k8s         9090 &
	kubectl --namespace monitoring port-forward svc/grafana                3000 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-enter 8081:8081 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-order 8082:8082 &
	kubectl --namespace restaurant port-forward svc/restaurant-staff-pay   8083:8083 &


from_scratch: install_k3d create_cluster build_manifest deploy_monitoring deploy_app

spawn: create_cluster deploy_monitoring deploy_app

start:
	k3d cluster start kesako-keda

stop:
	k3d cluster stop kesako-keda

destroy:
	k3d cluster delete kesako-keda

demo1:
demo2:
