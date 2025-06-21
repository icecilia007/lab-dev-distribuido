#!/bin/bash

AWS_REGION="${AWS_REGION}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
ECR_REPO_NAME="${ECR_REPO_NAME}"
IMAGE_TAG="${IMAGE_TAG}"
LAMBDA_UPDATE="${LAMBDA_UPDATE}"

ECR_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

MAX_RETRIES=5
RETRY_INTERVAL=15

for ((i=1; i<=MAX_RETRIES; i++)); do
  echo "Tentativa ${i} de ${MAX_RETRIES}: Atualizando a função Lambda ${LAMBDA_UPDATE}..."
  aws lambda update-function-code --function-name $LAMBDA_UPDATE --image-uri ${ECR_REPO_URL}:${IMAGE_TAG} --region ${AWS_REGION}
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "Atualização bem-sucedida da função Lambda ${LAMBDA_UPDATE}."
    exit 0
  fi

  echo "Erro ao atualizar a função Lambda ${LAMBDA_UPDATE}. Possivelmente uma atualização em andamento."
  echo "Aguardando ${RETRY_INTERVAL} segundos antes de tentar novamente..."
  sleep $RETRY_INTERVAL
done

echo "Erro: Não foi possível atualizar a função Lambda ${LAMBDA_UPDATE} após ${MAX_RETRIES} tentativas devido a conflito de recurso."
exit 1
