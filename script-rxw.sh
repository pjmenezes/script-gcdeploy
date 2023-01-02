#!/bin/bash
echo "Para evitar cobranças pelos recursos usados nesta, o ideal é excluir os cluster."
echo "excluindo qsdev"

gcloud container clusters delete quickstart-cluster-qsdev --region=us-central1 --project=animated-alloy-369522

echo "Excluir o cluster qsprod:"
gcloud container clusters delete quickstart-cluster-qsprod --region=us-central1 --project=animated-alloy-369522
echo "Excluir o pipeline de entrega:"
gcloud deploy delivery-pipelines delete my-gke-demo-app-1 --force --region=us-central1 --project=animated-alloy-369522
