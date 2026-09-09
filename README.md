# Mermaid

<details>
<summary><b>Clique para expandir o diagrama do banco de dados</b></summary>

```mermaid
erDiagram
    %% Relacionamentos - Documentos Fiscais
    clientes |o--o{ notas_fiscais : "cliente_id"
    fornecedores |o--o{ notas_fiscais : "fornecedor_id"
    produtos_servicos ||--o{ notas_fiscais : "produto_servico_id"

    %% Relacionamentos - Lançamentos Contábeis
    contas_contabeis ||--o{ lancamentos_contabeis : "conta_id"
    centros_custo ||--o{ lancamentos_contabeis : "centro_custo_id"
    notas_fiscais |o--o{ lancamentos_contabeis : "nota_fiscal_id"

    %% Relacionamentos - Orçamento
    contas_contabeis ||--o{ orcamento : "conta_id"
    centros_custo ||--o{ orcamento : "centro_custo_id"

    %% Relacionamentos - Movimentações e Conciliação
    contas_bancarias ||--o{ conciliacoes : "conta_bancaria_id"
    lancamentos_contabeis |o--o{ conciliacoes : "lancamento_contabil_id"

    %% Entidades e Atributos
    contas_contabeis {
        int id PK
        varchar codigo UK
        varchar nome
        varchar tipo
    }

    centros_custo {
        int id PK
        varchar codigo UK
        varchar nome
    }

    clientes {
        int id PK
        varchar nome
        varchar segmento
        varchar regiao
    }

    fornecedores {
        int id PK
        varchar nome
        varchar categoria
    }

    produtos_servicos {
        int id PK
        varchar nome
        varchar tipo
        varchar categoria
        numeric preco_unitario
        numeric custo_unitario
    }

    notas_fiscais {
        int id PK
        date data
        varchar tipo_operacao
        int cliente_id FK
        int fornecedor_id FK
        int produto_servico_id FK
        numeric valor_bruto
        numeric impostos
        numeric valor_liquido
        date data_vencimento
        date data_pagamento
        varchar status_pagamento
    }

    lancamentos_contabeis {
        int id PK
        date data_competencia
        int conta_id FK
        int centro_custo_id FK
        int nota_fiscal_id FK
        numeric valor
        varchar descricao
    }

    contas_bancarias {
        int id PK
        varchar banco
        varchar tipo
    }

    conciliacoes {
        int id PK
        date data
        int conta_bancaria_id FK
        int lancamento_contabil_id FK
        numeric valor
        varchar tipo
        varchar descricao
        boolean conciliado
    }

    orcamento {
        int id PK
        int conta_id FK
        int centro_custo_id FK
        date mes_ano
        numeric valor_orcado
    }
