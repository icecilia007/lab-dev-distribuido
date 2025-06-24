{
  "info": {
    "name": "Cupons API - AWS API Gateway",
    "description": "Collection for testing the cupons API deployed on AWS API Gateway with Lambda integration",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "_postman_id": "cupons-api-collection",
    "version": "1.0.0"
  },
  "item": [
    {
      "name": "List Cupons",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Accept",
            "value": "application/json",
            "type": "text"
          }
        ],
        "url": {
          "raw": "${api_base_url}/cupons",
          "protocol": "https",
          "host": [
            "${api_gateway_id}",
            "execute-api",
            "${aws_region}",
            "amazonaws",
            "com"
          ],
          "path": [
            "${stage}",
            "cupons"
          ]
        },
        "description": "List all available cupons from DynamoDB"
      },
      "response": []
    },
    {
      "name": "Get Cupom by ID",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Accept",
            "value": "application/json",
            "type": "text"
          }
        ],
        "url": {
          "raw": "${api_base_url}/cupons/:id",
          "protocol": "https",
          "host": [
            "${api_gateway_id}",
            "execute-api",
            "${aws_region}",
            "amazonaws",
            "com"
          ],
          "path": [
            "${stage}",
            "cupons",
            ":id"
          ],
          "variable": [
            {
              "key": "id",
              "value": "12345",
              "description": "Cupom ID to retrieve"
            }
          ]
        },
        "description": "Retrieve a specific cupom by ID from DynamoDB"
      },
      "response": []
    },
    {
      "name": "Trigger Campaign",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json",
            "type": "text"
          },
          {
            "key": "Accept",
            "value": "application/json",
            "type": "text"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"nome\": \"Black Friday 2024 - Sistema de Logística\",\n  \"assunto\": \"🔥 Black Friday - Até 50% OFF em entregas!\",\n  \"conteudo\": \"Não perca a maior promoção do ano! Descontos imperdíveis em todos os nossos serviços de logística. Aproveite frete grátis e entrega expressa com preços especiais. Válido apenas hoje!\",\n  \"grupos\": [\n    {\n      \"tipo\": \"premium\",\n      \"clientes\": [\n        {\n          \"id\": \"1\",\n          \"nome\": \"Ari Henrique\",\n          \"email\": \"arihenriquedev@hotmail.com\",\n          \"regiao\": \"sudeste\"\n        }\n      ]\n    },\n    {\n      \"tipo\": \"regiao_sul\",\n      \"clientes\": [\n        {\n          \"id\": \"2\",\n          \"nome\": \"Maria Silva\",\n          \"email\": \"maria.silva@email.com\",\n          \"regiao\": \"sul\"\n        }\n      ]\n    },\n    {\n      \"tipo\": \"geral\",\n      \"clientes\": [\n        {\n          \"id\": \"3\",\n          \"nome\": \"João Santos\",\n          \"email\": \"joao.santos@email.com\",\n          \"regiao\": \"nordeste\"\n        }\n      ]\n    }\n  ]\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "${api_base_url}/campanhas/trigger",
          "protocol": "https",
          "host": [
            "${api_gateway_id}",
            "execute-api",
            "${aws_region}",
            "amazonaws",
            "com"
          ],
          "path": [
            "${stage}",
            "campanhas",
            "trigger"
          ]
        },
        "description": "Trigger promotional campaigns with customer segmentation and email notifications"
      },
      "response": []
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "${api_base_url}",
      "type": "string"
    },
    {
      "key": "api_gateway_id",
      "value": "${api_gateway_id}",
      "type": "string"
    },
    {
      "key": "aws_region",
      "value": "${aws_region}",
      "type": "string"
    },
    {
      "key": "stage",
      "value": "${stage}",
      "type": "string"
    }
  ]
}