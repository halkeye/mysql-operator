KIND_CLUSTER ?= mysql-operator
IMAGE        ?= mysql-operator:dev

.PHONY: kind-up kind-load kind-deploy kind-test kind-down

kind-up:
	kind get clusters | grep -qx $(KIND_CLUSTER) || kind create cluster --name $(KIND_CLUSTER)

kind-load:
	docker build -t $(IMAGE) -f build/Dockerfile .
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER)

kind-deploy:
	kubectl kustomize deploy \
		| sed 's#ghcr.io/halkeye/mysql-operator:latest#$(IMAGE)#' \
		| kubectl --context kind-$(KIND_CLUSTER) apply -f -
	kubectl --context kind-$(KIND_CLUSTER) -n mysql-operator rollout restart deploy/mysql-operator
	kubectl --context kind-$(KIND_CLUSTER) -n mysql-operator rollout status deploy/mysql-operator --timeout=180s

kind-test: kind-up kind-load kind-deploy
	kubectl config use-context kind-$(KIND_CLUSTER)
	./test/e2e.sh

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)
