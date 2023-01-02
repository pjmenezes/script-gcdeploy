#!/bin/bash


gcloud auth login

gcloud config set project animated-alloy-369522

echo "*************ativar api clouddeploy*************"
gcloud services enable clouddeploy.googleapis.com

echo "Adicione o papel clouddeploy.jobRunner:"
 
 gcloud projects add-iam-policy-binding animated-alloy-369522 \
    --member=serviceAccount:$(gcloud projects describe animated-alloy-369522 \
    --format="value(projectNumber)")-compute@developer.gserviceaccount.com \
    --role="roles/clouddeploy.jobRunner"

echo "Adicionando as permissões de desenvolvedor do Kubernetes:"
 
    gcloud projects add-iam-policy-binding animated-alloy-369522 \
    --member=serviceAccount:$(gcloud projects describe animated-alloy-369522 \
    --format="value(projectNumber)")-compute@developer.gserviceaccount.com \
    --role="roles/container.developer"

echo "*************ativando Kubernetes Engine API*************"
gcloud services enable container.googleapis.com

echo "*************criando network default*************"
gcloud compute networks create default --project=animated-alloy-369522 --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional

echo "instando plugin gke"
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y

echo "*************Criando 2 clusters no Google Kubernetes Engine*************"

gcloud container clusters create-auto quickstart-cluster-qsdev --project=animated-alloy-369522 --region=us-central1 && gcloud container clusters create-auto quickstart-cluster-qsprod --project=animated-alloy-369522 --region=us-central1


echo "*************Criando um novo diretório chamado deploy-gke-quickstart e navegando até ele.*************"

mkdir deploy-gke-quickstart
cd deploy-gke-quickstart

echo "*************Preparar a configuração do Skaffold e o manifesto do Kubernetes*************"

file="skaffold.yaml"

if [ -f "$file" ] ; then
    rm "$file"
fi
echo "***********"
echo "apiVersion: skaffold/v2beta16
kind: Config
deploy:
  kubectl:
    manifests:
      - k8s-*" >> skaffold.yaml
cat skaffold.yaml 
date -r skaffold.yaml
ls -lt skaffold.yaml



echo "*************criando arquivo*************"
file="k8s-pod.yaml"

if [ -f "$file" ] ; then
    rm "$file"
fi
echo "***********"
echo "apiVersion: v1
kind: Pod
metadata:
  name: getting-started
spec:
  containers:
  - name: echoserver
    image: my-app-image" >> k8s-pod.yaml
cat k8s-pod.yaml
date -r k8s-pod.yaml
ls -lt k8s-pod.yaml



echo "*************Criar pipelines e entregas de entrega..*************"
file="clouddeploy.yaml"

if [ -f "$file" ] ; then
    rm "$file"
fi
echo "***********"
echo "apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: my-gke-demo-app-1
description: main application pipeline
serialPipeline:
 stages:
 - targetId: qsdev
   profiles: []
 - targetId: qsprod
   profiles: []
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: qsdev
description: development cluster
gke:
 cluster: projects/animated-alloy-369522/locations/us-central1/clusters/quickstart-cluster-qsdev
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: qsprod
description: production cluster
gke:
 cluster: projects/animated-alloy-369522/locations/us-central1/clusters/quickstart-cluster-qsprod" >> clouddeploy.yaml
cat clouddeploy.yaml
date -r clouddeploy.yaml
ls -lt clouddeploy.yaml

echo "*************Registrando o pipeline e destinos com o serviço do Google Cloud Deploy*************"
gcloud deploy apply --file=clouddeploy.yaml --region=us-central1 --project=animated-alloy-369522

echo "*************Criar release*************"

gcloud deploy releases create test-release-001 \
  --project=animated-alloy-369522 \
  --region=us-central1 \
  --delivery-pipeline=my-gke-demo-app-1 \
  --images=my-app-image=k8s.gcr.io/echoserver:1.4