# Mermaid

```mermaid
erDiagram
    CLIENTE ||--o{ NOTA_FISCAL : "emite para"
    FORNECEDOR ||--o{ NOTA_FISCAL : "recebe de"
    PRODUTO_SERVICO ||--o{ NOTA_FISCAL : "fatura"

    NOTA_FISCAL |o--o{ LANCAMENTO_CONTABIL : "gera"
    CONTA_CONTABIL ||--o{ LANCAMENTO_CONTABIL : "classifica"
    CENTRO_CUSTO ||--o{ LANCAMENTO_CONTABIL : "apropria"

    CONTA_CONTABIL ||--o{ ORCAMENTO : "meta de"
    CENTRO_CUSTO ||--o{ ORCAMENTO : "aloca em"

    LANCAMENTO_CONTABIL |o--o{ CONCILIACAO : "comprova"
    CONTA_BANCARIA ||--o{ CONCILIACAO : "registra"

    CLIENTE {
        nome
        segmento
        regiao
    }

    FORNECEDOR {
        nome
        categoria
    }

    PRODUTO_SERVICO {
        nome
        tipo
        categoria
    }

    NOTA_FISCAL {
        data
        tipo_operacao
        valor_liquido
        status_pagamento
    }

    CONTA_CONTABIL {
        codigo
        nome
        tipo
    }

    CENTRO_CUSTO {
        codigo
        nome
    }

    LANCAMENTO_CONTABIL {
        data_competencia
        valor
        descricao
    }

    ORCAMENTO {
        mes_ano
        valor_orcado
    }

    CONTA_BANCARIA {
        banco
        tipo
    }

    CONCILIACAO {
        data
        valor
        conciliado
    }
```
