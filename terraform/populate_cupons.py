#!/usr/bin/env python3

import boto3
from decimal import Decimal
from datetime import datetime, timezone

# Cliente DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('cupons')

# Dados de teste
cupons_teste = [
    {
        'cupom_id': 'DESCONTO10',
        'nome': 'Desconto 10%',
        'descricao': 'Desconto de 10% em todas as entregas',
        'tipo': 'percentual',
        'valor': Decimal('10.0'),
        'valor_minimo': Decimal('50.0'),
        'status': 'disponivel',
        'data_criacao': datetime.now(timezone.utc).isoformat(),
        'data_expiracao': '2024-12-31T23:59:59Z',
        'uso_maximo': 100,
        'uso_atual': 0
    },
    {
        'cupom_id': 'FRETE_GRATIS',
        'nome': 'Frete Grátis',
        'descricao': 'Frete grátis para pedidos acima de R$ 100',
        'tipo': 'frete_gratis',
        'valor': Decimal('0.0'),
        'valor_minimo': Decimal('100.0'),
        'status': 'disponivel',
        'data_criacao': datetime.now(timezone.utc).isoformat(),
        'data_expiracao': '2024-12-31T23:59:59Z',
        'uso_maximo': 200,
        'uso_atual': 5
    },
    {
        'cupom_id': 'DESCONTO25',
        'nome': 'Super Desconto 25%',
        'descricao': 'Desconto especial de 25% para novos clientes',
        'tipo': 'percentual',
        'valor': Decimal('25.0'),
        'valor_minimo': Decimal('200.0'),
        'status': 'disponivel',
        'data_criacao': datetime.now(timezone.utc).isoformat(),
        'data_expiracao': '2024-12-31T23:59:59Z',
        'uso_maximo': 50,
        'uso_atual': 12
    },
    {
        'cupom_id': 'ESGOTADO',
        'nome': 'Cupom Esgotado',
        'descricao': 'Este cupom já foi totalmente utilizado',
        'tipo': 'percentual',
        'valor': Decimal('15.0'),
        'valor_minimo': Decimal('75.0'),
        'status': 'esgotado',
        'data_criacao': datetime.now(timezone.utc).isoformat(),
        'data_expiracao': '2024-12-31T23:59:59Z',
        'uso_maximo': 10,
        'uso_atual': 10
    }
]

print("Populando tabela de cupons...")

for cupom in cupons_teste:
    try:
        table.put_item(Item=cupom)
        print(f"✅ Cupom inserido: {cupom['cupom_id']} - {cupom['nome']}")
    except Exception as e:
        print(f"❌ Erro ao inserir cupom {cupom['cupom_id']}: {str(e)}")

print(f"\n🎉 Processo concluído! {len(cupons_teste)} cupons inseridos na tabela.")
print("\n📋 Cupons disponíveis para teste:")
for cupom in cupons_teste:
    if cupom['status'] == 'disponivel':
        desconto = cupom['valor'] / 100 if cupom['tipo'] == 'percentual' else 0
        print(f"  - {cupom['cupom_id']}: {desconto:.2f} de desconto")