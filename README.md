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
    PK id int
    UK codigo varchar
    nome varchar
    tipo varchar
}

centros_custo {
    PK id int
    UK codigo varchar
    nome varchar
}

clientes {
    PK id int
    nome varchar
    segmento varchar
    regiao varchar
}

fornecedores {
    PK id int
    nome varchar
    categoria varchar
}

produtos_servicos {
    PK id int
    nome varchar
    tipo varchar
    categoria varchar
    preco_unitario numeric
    custo_unitario numeric
}

notas_fiscais {
    PK id int
    data date
    tipo_operacao varchar
    FK cliente_id int
    FK fornecedor_id int
    FK produto_servico_id int
    valor_bruto numeric
    impostos numeric
    valor_liquido numeric
    data_vencimento date
    data_pagamento date
    status_pagamento varchar
}

lancamentos_contabeis {
    PK id int
    data_competencia date
    FK conta_id int
    FK centro_custo_id int
    FK nota_fiscal_id int
    valor numeric
    descricao varchar
}

contas_bancarias {
    PK id int
    banco varchar
    tipo varchar
}

conciliacoes {
    PK id int
    data date
    FK conta_bancaria_id int
    FK lancamento_contabil_id int
    valor numeric
    tipo varchar
    descricao varchar
    conciliado boolean
}

orcamento {
    PK id int
    FK conta_id int
    FK centro_custo_id int
    mes_ano date
    valor_orcado numeric
}
```

**Nota**: o modelo foi desenhado para análise financeira gerencial. `lancamentos_contabeis` representa fatos classificados para análise de DRE, não um diário contábil de partidas dobradas completo. Além disso, ele não mostra regras condicionais (como NF entrada/saída determinando fornecedor ou cliente). Para mais detalhes, consultar o arquivo 01_create_tables.sql
