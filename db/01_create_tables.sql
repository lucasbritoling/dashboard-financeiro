-- ============================================================
-- 01_create_tables.sql
-- Schema inicial do dashboard financeiro (DRE, Fluxo de Caixa, KPIs)
-- ============================================================

-- ============================================================
-- 1. Cadastros básicos
-- ============================================================

-- Plano de contas contábeis
CREATE TABLE contas_contabeis (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,      -- ex.: '3.1.1', '4.2.3'
    nome VARCHAR(150) NOT NULL,              -- ex.: 'Receita de Vendas', 'CMV'
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Receita', 'Custo', 'Despesa')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Centros de custo
CREATE TABLE centros_custo (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,      -- ex.: 'ADM', 'COM', 'PROD'
    nome VARCHAR(100) NOT NULL,              -- ex.: 'Administrativo', 'Comercial'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    segmento VARCHAR(50) NOT NULL,           -- ex.: 'Varejo', 'Indústria', 'Serviços'
    regiao VARCHAR(50) NOT NULL,             -- ex.: 'Sudeste', 'Sul'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fornecedores
CREATE TABLE fornecedores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    categoria VARCHAR(50) NOT NULL,          -- ex.: 'Matéria-prima', 'Logística', 'TI'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Produtos e serviços
CREATE TABLE produtos_servicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Produto', 'Serviço')),
    categoria VARCHAR(50) NOT NULL,          -- ex.: 'Matéria-prima', 'Serviço Recorrente'
    preco_unitario NUMERIC(12,2),            -- opcional, para análise de margem
    custo_unitario NUMERIC(12,2),            -- opcional
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. Lançamentos e notas fiscais
-- ============================================================

-- Lançamentos contábeis (base da DRE)
CREATE TABLE lancamentos_contabeis (
    id SERIAL PRIMARY KEY,
    data DATE NOT NULL,
    conta_id INTEGER NOT NULL REFERENCES contas_contabeis(id),
    centro_custo_id INTEGER NOT NULL REFERENCES centros_custo(id),
    valor NUMERIC(14,2) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Receita', 'Custo', 'Despesa')),
    descricao VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notas fiscais (origem fiscal de receitas e custos)
CREATE TABLE notas_fiscais (
    id SERIAL PRIMARY KEY,
    data DATE NOT NULL,
    tipo_operacao VARCHAR(20) NOT NULL CHECK (tipo_operacao IN ('Entrada', 'Saída')),
    cliente_id INTEGER REFERENCES clientes(id),         -- para venda
    fornecedor_id INTEGER REFERENCES fornecedores(id),  -- para compra
    produto_servico_id INTEGER REFERENCES produtos_servicos(id),
    valor_bruto NUMERIC(14,2) NOT NULL,
    impostos NUMERIC(14,2) NOT NULL DEFAULT 0,
    valor_liquido NUMERIC(14,2) NOT NULL,
    cfop VARCHAR(10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. Banco e conciliação
-- ============================================================

-- Contas bancárias
CREATE TABLE contas_bancarias (
    id SERIAL PRIMARY KEY,
    banco VARCHAR(100) NOT NULL,
    agencia VARCHAR(20),
    conta VARCHAR(20),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Corrente', 'Aplicação')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Conciliações bancárias (movimentos de entrada/saída)
CREATE TABLE conciliacoes (
    id SERIAL PRIMARY KEY,
    data DATE NOT NULL,
    conta_bancaria_id INTEGER NOT NULL REFERENCES contas_bancarias(id),
    lancamento_contabil_id INTEGER REFERENCES lancamentos_contabeis(id),
    valor NUMERIC(14,2) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Entrada', 'Saída')),
    descricao VARCHAR(255),
    conciliado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. Orçamento (budget)
-- ============================================================

-- Orçamento por conta, centro de custo e mês
CREATE TABLE orcamento (
    id SERIAL PRIMARY KEY,
    conta_id INTEGER NOT NULL REFERENCES contas_contabeis(id),
    centro_custo_id INTEGER NOT NULL REFERENCES centros_custo(id),
    mes_ano DATE NOT NULL,                 -- ex.: '2024-01-01' para jan/2024
    valor_orcado NUMERIC(14,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_orcamento UNIQUE (conta_id, centro_custo_id, mes_ano)
);

-- ============================================================
-- Fim do schema inicial
-- ============================================================