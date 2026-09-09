-- ============================================================
-- 01_create_tables.sql
-- Dashboard Financeiro - DRE, Fluxo de Caixa e KPIs
-- PostgreSQL
--
-- Objetivo:
-- Base financeira gerencial para análise de dados.
--
-- Escopo:
-- DRE + Fluxo de Caixa + Orçamento + KPIs
-- ============================================================


-- ============================================================
-- 1. CADASTROS BÁSICOS
-- ============================================================

CREATE TABLE contas_contabeis (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(150) NOT NULL,

    -- A classificação da conta determina seu papel na DRE.
    -- Não é armazenada nos lançamentos para evitar redundância.
    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Receita', 'Custo', 'Despesa'))
);


CREATE TABLE centros_custo (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL
);


CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    segmento VARCHAR(50) NOT NULL,
    regiao VARCHAR(50) NOT NULL
);


CREATE TABLE fornecedores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    categoria VARCHAR(50) NOT NULL
);


CREATE TABLE produtos_servicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Produto', 'Serviço')),
    categoria VARCHAR(50) NOT NULL,
    preco_unitario NUMERIC(12,2)
        CHECK (
            preco_unitario IS NULL
            OR preco_unitario >= 0
        ),
    custo_unitario NUMERIC(12,2)
        CHECK (
            custo_unitario IS NULL
            OR custo_unitario >= 0
        )
);


-- ============================================================
-- 2. DOCUMENTOS FISCAIS
-- ============================================================

CREATE TABLE notas_fiscais (
    id SERIAL PRIMARY KEY,

    data DATE NOT NULL,

    -- Entrada/Saída representa a natureza da operação fiscal.
    -- A classificação como Receita/Custo/Despesa é definida
    -- posteriormente pela conta contábil vinculada ao lançamento.
    tipo_operacao VARCHAR(20) NOT NULL
        CHECK (tipo_operacao IN ('Entrada', 'Saída')),

    -- No escopo do projeto:
    -- Saída -> cliente
    -- Entrada -> fornecedor
    cliente_id INTEGER
        REFERENCES clientes(id),

    fornecedor_id INTEGER
        REFERENCES fornecedores(id),

    -- Toda NF do projeto representa uma operação sobre
    -- um produto ou serviço.
    produto_servico_id INTEGER NOT NULL
        REFERENCES produtos_servicos(id),

    valor_bruto NUMERIC(14,2) NOT NULL
        CHECK (valor_bruto >= 0),

    impostos NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (impostos >= 0),

    valor_liquido NUMERIC(14,2) NOT NULL
        CHECK (valor_liquido >= 0),

    -- Controle simplificado do ciclo financeiro da NF.
    -- Não são modeladas parcelas/títulos separadamente.
    data_vencimento DATE,

    -- Representa a data em que o pagamento foi efetivamente realizado.
    data_pagamento DATE,

    status_pagamento VARCHAR(20) NOT NULL DEFAULT 'Pendente'
        CHECK (
            status_pagamento IN (
                'Pendente',
                'Pago',
                'Cancelado'
            )
        ),

    CHECK (
        valor_liquido = valor_bruto - impostos
    ),

    CHECK (
        impostos <= valor_bruto
    ),

    CHECK (
        data_vencimento IS NULL
        OR data_vencimento >= data
    ),

    CHECK (
        data_pagamento IS NULL
        OR data_pagamento >= data
    ),

    -- Um documento pago precisa possuir a data efetiva de pagamento.
    CHECK (
        status_pagamento <> 'Pago'
        OR data_pagamento IS NOT NULL
    ),

    -- No modelo simplificado, documentos não pagos não possuem
    -- data de pagamento.
    CHECK (
        status_pagamento = 'Pago'
        OR data_pagamento IS NULL
    ),

    -- Garante consistência entre o tipo da operação e a parte envolvida.
    CHECK (
        (
            tipo_operacao = 'Saída'
            AND cliente_id IS NOT NULL
            AND fornecedor_id IS NULL
        )
        OR
        (
            tipo_operacao = 'Entrada'
            AND cliente_id IS NULL
            AND fornecedor_id IS NOT NULL
        )
    )
);


-- ============================================================
-- 3. LANÇAMENTOS FINANCEIROS / CONTÁBEIS
-- ============================================================

CREATE TABLE lancamentos_contabeis (
    id SERIAL PRIMARY KEY,

    -- Base da análise por competência e da DRE.
    data_competencia DATE NOT NULL,

    conta_id INTEGER NOT NULL
        REFERENCES contas_contabeis(id),

    centro_custo_id INTEGER NOT NULL
        REFERENCES centros_custo(id),

    -- A NF é opcional porque nem todo lançamento financeiro
    -- precisa estar associado a um documento fiscal.
    nota_fiscal_id INTEGER
        REFERENCES notas_fiscais(id),

    valor NUMERIC(14,2) NOT NULL
        CHECK (valor > 0),

    descricao VARCHAR(255)
);


-- ============================================================
-- 4. CONTAS BANCÁRIAS
-- ============================================================

CREATE TABLE contas_bancarias (
    id SERIAL PRIMARY KEY,

    banco VARCHAR(100) NOT NULL,

    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Corrente', 'Aplicação'))
);


-- ============================================================
-- 5. MOVIMENTAÇÕES / CONCILIAÇÃO BANCÁRIA
-- ============================================================

CREATE TABLE conciliacoes (
    id SERIAL PRIMARY KEY,

    -- Data da movimentação efetiva no caixa.
    -- É diferente da data de competência utilizada na DRE.
    data DATE NOT NULL,

    conta_bancaria_id INTEGER NOT NULL
        REFERENCES contas_bancarias(id),

    -- O vínculo é opcional porque uma movimentação bancária
    -- pode não estar diretamente associada a um lançamento.
    lancamento_contabil_id INTEGER
        REFERENCES lancamentos_contabeis(id),

    valor NUMERIC(14,2) NOT NULL
        CHECK (valor > 0),

    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Entrada', 'Saída')),

    descricao VARCHAR(255),

    -- Indica se a movimentação bancária foi conciliada.
    conciliado BOOLEAN NOT NULL DEFAULT FALSE
);


-- ============================================================
-- 6. ORÇAMENTO
-- ============================================================

CREATE TABLE orcamento (
    id SERIAL PRIMARY KEY,

    conta_id INTEGER NOT NULL
        REFERENCES contas_contabeis(id),

    centro_custo_id INTEGER NOT NULL
        REFERENCES centros_custo(id),

    -- Representa o mês e ano do orçamento.
    --
    -- Exemplo:
    -- 2026-01-01 = Janeiro/2026
    -- 2026-02-01 = Fevereiro/2026
    --
    -- O dia 01 não possui significado de negócio.
    -- É apenas a convenção técnica para representar o mês.
    mes_ano DATE NOT NULL,

    valor_orcado NUMERIC(14,2) NOT NULL
        CHECK (valor_orcado >= 0),

    -- Para cada conta + centro de custo + mês,
    -- existe apenas um orçamento.
    CONSTRAINT unique_orcamento
        UNIQUE (
            conta_id,
            centro_custo_id,
            mes_ano
        ),

    -- Padroniza a representação do mês:
    -- sempre o primeiro dia do mês.
    CONSTRAINT check_mes_inicio
        CHECK (
            mes_ano = DATE_TRUNC('month', mes_ano)::DATE
        )
);


-- ============================================================
-- 7. ÍNDICES PARA CONSULTAS ANALÍTICAS
-- ============================================================
--
-- Foram priorizados índices nas colunas de data que serão
-- utilizadas nas principais análises temporais do projeto.
-- Não são criados índices adicionais em todas as FKs,
-- pois isso não é necessário para o volume esperado.
-- ============================================================

-- DRE e análises por competência.
CREATE INDEX idx_lancamentos_data
    ON lancamentos_contabeis(data_competencia);

-- Faturamento e documentos por período.
CREATE INDEX idx_notas_fiscais_data
    ON notas_fiscais(data);

-- Contas a pagar/receber e análise de vencimentos.
CREATE INDEX idx_notas_fiscais_vencimento
    ON notas_fiscais(data_vencimento);

-- Fluxo de caixa e movimentações bancárias.
CREATE INDEX idx_conciliacoes_data
    ON conciliacoes(data);

-- Orçado x realizado por mês.
CREATE INDEX idx_orcamento_mes
    ON orcamento(mes_ano);