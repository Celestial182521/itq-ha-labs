#!/bin/bash
# Lab 1.3 - De Docker a Kubernetes local
# Corre todo el flujo y guarda la salida de cada paso en ../lab-1.3/*.txt
#
# Uso (desde catalog-service/):
#   ./lab-1.3.sh build    -> compila, docker build, push, rm y pull desde Docker Hub
#   ./lab-1.3.sh deploy   -> kubectl apply + espera a que el pod esté Ready
#   ./lab-1.3.sh check    -> describe pod + port-forward + curl a los endpoints
#   ./lab-1.3.sh clean    -> borra deployment y service
#
# Antes: docker login  y  minikube start --driver=docker (o kind create cluster)

set -e
DOCKERHUB_USER="${DOCKERHUB_USER:-celestial1825}"
IMAGE="$DOCKERHUB_USER/catalog-service:1.0.0"
OUT="../lab-1.3"
PORT=9090   # 8080 está ocupado en la Pi, por eso el port-forward va a 9090
mkdir -p "$OUT"

case "$1" in
  build)
    ./mvnw clean package -DskipTests
    docker build -t "$IMAGE" .
    docker push "$IMAGE" 2>&1 | tee "$OUT/docker-push.txt"
    docker image rm "$IMAGE"
    docker pull "$IMAGE" 2>&1 | tee "$OUT/docker-pull.txt"
    ;;
  deploy)
    grep "image:" k8s/01-deployment.yaml | tee "$OUT/deployment-image.txt"
    kubectl apply -f k8s/01-deployment.yaml
    kubectl apply -f k8s/02-service.yaml
    kubectl rollout status deployment/catalog-service --timeout=180s
    {
      echo "\$ kubectl get deployment catalog-service"; kubectl get deployment catalog-service; echo
      echo "\$ kubectl get pods -l app=catalog-service"; kubectl get pods -l app=catalog-service; echo
      echo "\$ kubectl get service catalog-service";     kubectl get service catalog-service
    } | tee "$OUT/kubectl-get.txt"
    ;;
  check)
    POD=$(kubectl get pods -l app=catalog-service -o jsonpath='{.items[0].metadata.name}')
    kubectl describe pod "$POD" | tee "$OUT/describe-pod.txt"
    kubectl port-forward svc/catalog-service $PORT:8080 >/dev/null 2>&1 &
    PF=$!; sleep 3
    {
      for ep in /v1/products /v1/products /v1/products /health /ready /live; do
        echo "\$ curl -s http://localhost:$PORT$ep"
        curl -s "http://localhost:$PORT$ep"; echo; echo
      done
    } | tee "$OUT/curl-endpoints.txt"
    kill $PF
    ;;
  clean)
    kubectl delete deployment catalog-service
    kubectl delete service catalog-service
    ;;
  *)
    echo "Uso: ./lab-1.3.sh {build|deploy|check|clean}"; exit 1 ;;
esac
