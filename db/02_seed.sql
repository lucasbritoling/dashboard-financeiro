-- ============================================================
-- 02_seed.sql
-- Dashboard Financeiro - DRE, Fluxo de Caixa e KPIs
-- PostgreSQL
--
-- Seed compatível exclusivamente com o Schema V4.
-- Período: Janeiro/2024 a Dezembro/2025
--
-- Observação:
-- Esta seed prioriza integridade referencial, variedade e volume
-- suficientes para exploração no PostgreSQL/Power BI.
-- Não cria tabelas, colunas ou regras fora do Schema V4.
-- ============================================================

BEGIN;

-- ============================================================
-- 0. LIMPEZA
-- ============================================================
-- Permite executar a seed novamente em um banco de desenvolvimento.
-- As tabelas são truncadas na ordem reversa das dependências.
-- ============================================================

TRUNCATE TABLE
    conciliacoes,
    lancamentos_contabeis,
    notas_fiscais,
    orcamento,
    contas_bancarias,
    produtos_servicos,
    clientes,
    fornecedores,
    centros_custo,
    contas_contabeis
RESTART IDENTITY CASCADE;


-- ============================================================
-- 1. CONTAS CONTÁBEIS
-- ============================================================

INSERT INTO contas_contabeis (codigo, nome, tipo) VALUES
    ('1.01', 'Receita de Produtos', 'Receita'),
    ('1.02', 'Receita de Serviços', 'Receita'),
    ('2.01', 'Custo de Mercadorias Vendidas', 'Custo'),
    ('2.02', 'Custo de Serviços Prestados', 'Custo'),
    ('2.03', 'Logística e Distribuição', 'Custo'),
    ('3.01', 'Despesas Comerciais', 'Despesa'),
    ('3.02', 'Marketing', 'Despesa'),
    ('3.03', 'Despesas Administrativas', 'Despesa'),
    ('3.04', 'Tecnologia', 'Despesa'),
    ('3.05', 'Despesas Gerais', 'Despesa');


-- ============================================================
-- 2. CENTROS DE CUSTO
-- ============================================================

INSERT INTO centros_custo (codigo, nome) VALUES
    ('CC01', 'Comercial'),
    ('CC02', 'Marketing'),
    ('CC03', 'Administrativo'),
    ('CC04', 'Operações'),
    ('CC05', 'Tecnologia');


-- ============================================================
-- 3. CLIENTES
-- ============================================================

INSERT INTO clientes (nome, segmento, regiao)
SELECT
    'Cliente ' || LPAD(g::text, 2, '0'),
    CASE ((g - 1) % 5)
        WHEN 0 THEN 'Indústria'
        WHEN 1 THEN 'Varejo'
        WHEN 2 THEN 'Serviços'
        WHEN 3 THEN 'Tecnologia'
        ELSE 'Distribuição'
    END,
    CASE ((g - 1) % 5)
        WHEN 0 THEN 'Sudeste'
        WHEN 1 THEN 'Sul'
        WHEN 2 THEN 'Centro-Oeste'
        WHEN 3 THEN 'Nordeste'
        ELSE 'Norte'
    END
FROM generate_series(1, 30) AS g;


-- ============================================================
-- 4. FORNECEDORES
-- ============================================================

INSERT INTO fornecedores (nome, categoria)
SELECT
    'Fornecedor ' || LPAD(g::text, 2, '0'),
    CASE ((g - 1) % 6)
        WHEN 0 THEN 'Mercadorias'
        WHEN 1 THEN 'Serviços'
        WHEN 2 THEN 'Logística'
        WHEN 3 THEN 'Marketing'
        WHEN 4 THEN 'Tecnologia'
        ELSE 'Administrativo'
    END
FROM generate_series(1, 20) AS g;


-- ============================================================
-- 5. PRODUTOS / SERVIÇOS
-- ============================================================

INSERT INTO produtos_servicos
    (nome, tipo, categoria, preco_unitario, custo_unitario)
VALUES
    ('Produto A', 'Produto', 'Linha A', 250.00, 135.00),
    ('Produto B', 'Produto', 'Linha A', 400.00, 220.00),
    ('Produto C', 'Produto', 'Linha B', 650.00, 360.00),
    ('Produto D', 'Produto', 'Linha B', 900.00, 500.00),
    ('Produto E', 'Produto', 'Linha C', 1250.00, 700.00),
    ('Produto F', 'Produto', 'Linha C', 1800.00, 1000.00),
    ('Produto G', 'Produto', 'Linha D', 2400.00, 1350.00),
    ('Produto H', 'Produto', 'Linha D', 3200.00, 1800.00),
    ('Serviço A', 'Serviço', 'Consultoria', 1500.00, 600.00),
    ('Serviço B', 'Serviço', 'Implantação', 3000.00, 1200.00),
    ('Serviço C', 'Serviço', 'Suporte', 800.00, 300.00),
    ('Serviço D', 'Serviço', 'Treinamento', 2200.00, 900.00),
    ('Serviço E', 'Serviço', 'Projetos', 5000.00, 2200.00),
    ('Produto I', 'Produto', 'Linha E', 550.00, 300.00),
    ('Produto J', 'Produto', 'Linha E', 1100.00, 610.00);


-- ============================================================
-- 6. CONTAS BANCÁRIAS
-- ============================================================

INSERT INTO contas_bancarias (banco, tipo) VALUES
    ('Banco Principal', 'Corrente'),
    ('Banco Operacional', 'Corrente'),
    ('Aplicação Financeira', 'Aplicação');


-- ============================================================
-- 7. NOTAS FISCAIS DE SAÍDA
-- ============================================================
-- Uma NF representa uma operação sobre um único produto/serviço,
-- exatamente como definido no Schema V4.
--
-- São geradas 80 NFs de saída por mês.
-- Parte das NFs permanece pendente para permitir análise de
-- contas a receber e aging.
-- ============================================================

INSERT INTO notas_fiscais
(
    data,
    tipo_operacao,
    cliente_id,
    fornecedor_id,
    produto_servico_id,
    valor_bruto,
    impostos,
    valor_liquido,
    data_vencimento,
    data_pagamento,
    status_pagamento
)
SELECT
    x.data_emissao,
    'Saída',
    x.cliente_id,
    NULL,
    x.produto_servico_id,
    x.valor_bruto,
    x.impostos,
    x.valor_bruto - x.impostos,
    x.data_emissao + x.prazo_dias,
    CASE
        WHEN x.pago
             AND x.data_emissao + x.prazo_dias + x.atraso_dias
                 <= DATE '2025-12-31'
        THEN x.data_emissao + x.prazo_dias + x.atraso_dias
        ELSE NULL
    END,
    CASE
        WHEN x.pago
             AND x.data_emissao + x.prazo_dias + x.atraso_dias
                 <= DATE '2025-12-31'
        THEN 'Pago'
        ELSE 'Pendente'
    END
FROM (
    SELECT
        m.mes::date + ((n.n - 1) % 26) AS data_emissao,
        ((n.n - 1) % 30) + 1 AS cliente_id,
        ((n.n - 1) % 15) + 1 AS produto_servico_id,
        ROUND(
            (
                CASE ((n.n - 1) % 15)
                    WHEN 0 THEN 250
                    WHEN 1 THEN 400
                    WHEN 2 THEN 650
                    WHEN 3 THEN 900
                    WHEN 4 THEN 1250
                    WHEN 5 THEN 1800
                    WHEN 6 THEN 2400
                    WHEN 7 THEN 3200
                    WHEN 8 THEN 1500
                    WHEN 9 THEN 3000
                    WHEN 10 THEN 800
                    WHEN 11 THEN 2200
                    WHEN 12 THEN 5000
                    WHEN 13 THEN 550
                    ELSE 1100
                END
                * (5 + ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 8))
            )::numeric,
            2
        ) AS valor_bruto,
        0.10::numeric AS aliquota_imposto,
        CASE ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 4)
            WHEN 0 THEN 15
            WHEN 1 THEN 30
            WHEN 2 THEN 45
            ELSE 60
        END AS prazo_dias,
        CASE
            WHEN
                (
                    EXTRACT(MONTH FROM m.mes)::integer
                    + n.n
                ) % 10 IN (0, 1, 2, 3, 4, 5, 6)
            THEN TRUE
            ELSE FALSE
        END AS pago,
        CASE ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 5)
            WHEN 0 THEN 0
            WHEN 1 THEN 3
            WHEN 2 THEN 7
            WHEN 3 THEN 15
            ELSE 25
        END AS atraso_dias,
        ROUND(
            (
                (
                    CASE ((n.n - 1) % 15)
                        WHEN 0 THEN 250
                        WHEN 1 THEN 400
                        WHEN 2 THEN 650
                        WHEN 3 THEN 900
                        WHEN 4 THEN 1250
                        WHEN 5 THEN 1800
                        WHEN 6 THEN 2400
                        WHEN 7 THEN 3200
                        WHEN 8 THEN 1500
                        WHEN 9 THEN 3000
                        WHEN 10 THEN 800
                        WHEN 11 THEN 2200
                        WHEN 12 THEN 5000
                        WHEN 13 THEN 550
                        ELSE 1100
                    END
                    * (5 + ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 8))
                )
                * 0.10
            )::numeric,
            2
        ) AS impostos
    FROM generate_series(
        DATE '2024-01-01',
        DATE '2025-12-01',
        INTERVAL '1 month'
    ) AS m(mes)
    CROSS JOIN generate_series(1, 80) AS n(n)
) AS x;


-- ============================================================
-- 8. NOTAS FISCAIS DE ENTRADA
-- ============================================================
-- Uma parte representa mercadorias/serviços adquiridos.
-- ============================================================

INSERT INTO notas_fiscais
(
    data,
    tipo_operacao,
    cliente_id,
    fornecedor_id,
    produto_servico_id,
    valor_bruto,
    impostos,
    valor_liquido,
    data_vencimento,
    data_pagamento,
    status_pagamento
)
SELECT
    x.data_emissao,
    'Entrada',
    NULL,
    x.fornecedor_id,
    x.produto_servico_id,
    x.valor_bruto,
    x.impostos,
    x.valor_bruto - x.impostos,
    x.data_emissao + x.prazo_dias,
    CASE
        WHEN x.pago
             AND x.data_emissao + x.prazo_dias + x.atraso_dias
                 <= DATE '2025-12-31'
        THEN x.data_emissao + x.prazo_dias + x.atraso_dias
        ELSE NULL
    END,
    CASE
        WHEN x.pago
             AND x.data_emissao + x.prazo_dias + x.atraso_dias
                 <= DATE '2025-12-31'
        THEN 'Pago'
        ELSE 'Pendente'
    END
FROM (
    SELECT
        m.mes::date + ((n.n - 1) % 26) AS data_emissao,
        ((n.n - 1) % 20) + 1 AS fornecedor_id,
        ((n.n - 1) % 15) + 1 AS produto_servico_id,
        ROUND(
            (
                CASE ((n.n - 1) % 15)
                    WHEN 0 THEN 250
                    WHEN 1 THEN 400
                    WHEN 2 THEN 650
                    WHEN 3 THEN 900
                    WHEN 4 THEN 1250
                    WHEN 5 THEN 1800
                    WHEN 6 THEN 2400
                    WHEN 7 THEN 3200
                    WHEN 8 THEN 1500
                    WHEN 9 THEN 3000
                    WHEN 10 THEN 800
                    WHEN 11 THEN 2200
                    WHEN 12 THEN 5000
                    WHEN 13 THEN 550
                    ELSE 1100
                END
                * (3 + ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 6))
            )::numeric,
            2
        ) AS valor_bruto,
        0.05::numeric AS aliquota_imposto,
        CASE ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 4)
            WHEN 0 THEN 15
            WHEN 1 THEN 30
            WHEN 2 THEN 45
            ELSE 60
        END AS prazo_dias,
        CASE
            WHEN (n.n + EXTRACT(MONTH FROM m.mes)::integer) % 10 IN
                 (0, 1, 2, 3, 4, 5, 6, 7)
            THEN TRUE
            ELSE FALSE
        END AS pago,
        CASE ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 4)
            WHEN 0 THEN 0
            WHEN 1 THEN 2
            WHEN 2 THEN 7
            ELSE 15
        END AS atraso_dias,
        ROUND(
            (
                (
                    CASE ((n.n - 1) % 15)
                        WHEN 0 THEN 250
                        WHEN 1 THEN 400
                        WHEN 2 THEN 650
                        WHEN 3 THEN 900
                        WHEN 4 THEN 1250
                        WHEN 5 THEN 1800
                        WHEN 6 THEN 2400
                        WHEN 7 THEN 3200
                        WHEN 8 THEN 1500
                        WHEN 9 THEN 3000
                        WHEN 10 THEN 800
                        WHEN 11 THEN 2200
                        WHEN 12 THEN 5000
                        WHEN 13 THEN 550
                        ELSE 1100
                    END
                    * (3 + ((n.n + EXTRACT(MONTH FROM m.mes)::integer) % 6))
                )
                * 0.05
            )::numeric,
            2
        ) AS impostos
    FROM generate_series(
        DATE '2024-01-01',
        DATE '2025-12-01',
        INTERVAL '1 month'
    ) AS m(mes)
    CROSS JOIN generate_series(1, 40) AS n(n)
) AS x;


-- ============================================================
-- 9. LANÇAMENTOS CONTÁBEIS ASSOCIADOS ÀS NFs
-- ============================================================
-- Saídas fiscais:
--   Produto -> Receita de Produtos
--   Serviço -> Receita de Serviços
--
-- Entradas fiscais:
--   Produto -> Custo de Mercadorias Vendidas
--   Serviço -> Custo de Serviços Prestados
--
-- A classificação da DRE vem da conta_contabil.
-- ============================================================

INSERT INTO lancamentos_contabeis
(
    data_competencia,
    conta_id,
    centro_custo_id,
    nota_fiscal_id,
    valor,
    descricao
)
SELECT
    nf.data,
    cc.id,
    CASE
        WHEN nf.tipo_operacao = 'Saída' THEN
            CASE
                WHEN ps.tipo = 'Produto' THEN
                    (SELECT id FROM centros_custo WHERE codigo = 'CC04')
                ELSE
                    (SELECT id FROM centros_custo WHERE codigo = 'CC04')
            END
        ELSE
            (SELECT id FROM centros_custo WHERE codigo = 'CC04')
    END,
    nf.id,
    nf.valor_liquido,
    CASE
        WHEN nf.tipo_operacao = 'Saída'
            THEN 'Receita - NF ' || nf.id
        ELSE
            'Custo - NF ' || nf.id
    END
FROM notas_fiscais nf
JOIN produtos_servicos ps
    ON ps.id = nf.produto_servico_id
JOIN contas_contabeis cc
    ON cc.codigo = CASE
        WHEN nf.tipo_operacao = 'Saída'
             AND ps.tipo = 'Produto' THEN '1.01'
        WHEN nf.tipo_operacao = 'Saída'
             AND ps.tipo = 'Serviço' THEN '1.02'
        WHEN nf.tipo_operacao = 'Entrada'
             AND ps.tipo = 'Produto' THEN '2.01'
        WHEN nf.tipo_operacao = 'Entrada'
             AND ps.tipo = 'Serviço' THEN '2.02'
    END;


-- ============================================================
-- 10. LANÇAMENTOS DE LOGÍSTICA
-- ============================================================
-- Despesa/custo adicional sem NF, permitido pelo Schema V4.
-- ============================================================

INSERT INTO lancamentos_contabeis
(
    data_competencia,
    conta_id,
    centro_custo_id,
    nota_fiscal_id,
    valor,
    descricao
)
SELECT
    m.mes::date,
    (SELECT id FROM contas_contabeis WHERE codigo = '2.03'),
    (SELECT id FROM centros_custo WHERE codigo = 'CC04'),
    NULL,
    ROUND(
        (
            18000
            + (EXTRACT(MONTH FROM m.mes)::integer * 750)
            + CASE
                WHEN EXTRACT(YEAR FROM m.mes)::integer = 2025
                THEN 9000
                ELSE 0
              END
        )::numeric,
        2
    ),
    'Logística e Distribuição - ' ||
    TO_CHAR(m.mes, 'YYYY-MM')
FROM generate_series(
    DATE '2024-01-01',
    DATE '2025-12-01',
    INTERVAL '1 month'
) AS m(mes);


-- ============================================================
-- 11. DESPESAS OPERACIONAIS
-- ============================================================
-- Cinco contas de despesa x centros de custo.
-- Os valores variam por mês para permitir análise temporal.
-- ============================================================

INSERT INTO lancamentos_contabeis
(
    data_competencia,
    conta_id,
    centro_custo_id,
    nota_fiscal_id,
    valor,
    descricao
)
SELECT
    m.mes::date,
    c.id,
    cc.id,
    NULL,
    ROUND(
        (
            CASE c.codigo
                WHEN '3.01' THEN 28000
                WHEN '3.02' THEN 22000
                WHEN '3.03' THEN 25000
                WHEN '3.04' THEN 10000
                WHEN '3.05' THEN 18000
            END
            *
            CASE
                WHEN EXTRACT(YEAR FROM m.mes)::integer = 2024
                    THEN 1.00
                ELSE 1.15
            END
            *
            (
                1
                + (
                    EXTRACT(MONTH FROM m.mes)::integer - 1
                ) * 0.012
            )
            *
            CASE cc.codigo
                WHEN 'CC01' THEN 1.00
                WHEN 'CC02' THEN 0.90
                WHEN 'CC03' THEN 0.80
                WHEN 'CC04' THEN 0.75
                ELSE 0.70
            END
        )::numeric,
        2
    ),
    c.nome || ' - ' || cc.nome || ' - ' ||
    TO_CHAR(m.mes, 'YYYY-MM')
FROM generate_series(
    DATE '2024-01-01',
    DATE '2025-12-01',
    INTERVAL '1 month'
) AS m(mes)
CROSS JOIN contas_contabeis c
CROSS JOIN centros_custo cc
WHERE c.tipo = 'Despesa';


-- ============================================================
-- 12. CONCILIAÇÕES DAS NFs PAGAS
-- ============================================================
-- Uma movimentação bancária para cada NF efetivamente paga.
-- ============================================================

INSERT INTO conciliacoes
(
    data,
    conta_bancaria_id,
    lancamento_contabil_id,
    valor,
    tipo,
    descricao,
    conciliado
)
SELECT
    nf.data_pagamento,
    CASE
        WHEN nf.id % 3 = 0
            THEN (SELECT id FROM contas_bancarias
                  WHERE banco = 'Banco Operacional')
        ELSE (SELECT id FROM contas_bancarias
              WHERE banco = 'Banco Principal')
    END,
    lc.id,
    nf.valor_liquido,
    CASE
        WHEN nf.tipo_operacao = 'Saída' THEN 'Entrada'
        ELSE 'Saída'
    END,
    CASE
        WHEN nf.tipo_operacao = 'Saída'
            THEN 'Recebimento de cliente - NF ' || nf.id
        ELSE
            'Pagamento de fornecedor - NF ' || nf.id
    END,
    TRUE
FROM notas_fiscais nf
JOIN lancamentos_contabeis lc
    ON lc.nota_fiscal_id = nf.id
WHERE nf.status_pagamento = 'Pago';


-- ============================================================
-- 13. CONCILIAÇÕES DAS DESPESAS OPERACIONAIS
-- ============================================================
-- As despesas sem NF também podem possuir movimentação bancária,
-- conforme permitido pelo Schema V4.
-- ============================================================

INSERT INTO conciliacoes
(
    data,
    conta_bancaria_id,
    lancamento_contabil_id,
    valor,
    tipo,
    descricao,
    conciliado
)
SELECT
    lc.data_competencia + 10,
    CASE
        WHEN lc.id % 3 = 0
            THEN (SELECT id FROM contas_bancarias
                  WHERE banco = 'Banco Operacional')
        ELSE (SELECT id FROM contas_bancarias
              WHERE banco = 'Banco Principal')
    END,
    lc.id,
    lc.valor,
    'Saída',
    'Pagamento de despesa - ' || lc.descricao,
    TRUE
FROM lancamentos_contabeis lc
JOIN contas_contabeis c
    ON c.id = lc.conta_id
WHERE c.tipo = 'Despesa'
  AND lc.nota_fiscal_id IS NULL;


-- ============================================================
-- 14. MOVIMENTAÇÕES BANCÁRIAS NÃO CONCILIADAS
-- ============================================================
-- O Schema V4 permite movimentações sem lançamento associado.
-- Algumas são incluídas para testar a análise de conciliação.
-- ============================================================

INSERT INTO conciliacoes
(
    data,
    conta_bancaria_id,
    lancamento_contabil_id,
    valor,
    tipo,
    descricao,
    conciliado
)
SELECT
    DATE '2024-01-15' + (g * INTERVAL '60 days'),
    (SELECT id FROM contas_bancarias WHERE banco = 'Banco Principal'),
    NULL,
    2500.00 + (g * 375.00),
    CASE WHEN g % 2 = 0 THEN 'Entrada' ELSE 'Saída' END,
    CASE
        WHEN g % 2 = 0 THEN 'Movimentação bancária pendente de identificação'
        ELSE 'Tarifa/movimentação bancária pendente de identificação'
    END,
    FALSE
FROM generate_series(1, 10) AS g;


-- ============================================================
-- 15. ORÇAMENTO
-- ============================================================
-- Granularidade do Schema V4:
-- conta + centro de custo + mês.
--
-- São gerados orçamentos para as cinco contas de despesa.
-- ============================================================

INSERT INTO orcamento
(
    conta_id,
    centro_custo_id,
    mes_ano,
    valor_orcado
)
SELECT
    c.id,
    cc.id,
    m.mes::date,
    ROUND(
        (
            CASE c.codigo
                WHEN '3.01' THEN 30000
                WHEN '3.02' THEN 24000
                WHEN '3.03' THEN 26000
                WHEN '3.04' THEN 11000
                WHEN '3.05' THEN 19000
            END
            *
            CASE cc.codigo
                WHEN 'CC01' THEN 1.00
                WHEN 'CC02' THEN 0.95
                WHEN 'CC03' THEN 0.85
                WHEN 'CC04' THEN 0.80
                ELSE 0.75
            END
            *
            (
                1
                + (
                    EXTRACT(MONTH FROM m.mes)::integer - 1
                ) * 0.01
            )
        )::numeric,
        2
    )
FROM generate_series(
    DATE '2024-01-01',
    DATE '2025-12-01',
    INTERVAL '1 month'
) AS m(mes)
CROSS JOIN contas_contabeis c
CROSS JOIN centros_custo cc
WHERE c.tipo = 'Despesa';


-- ============================================================
-- 16. VALIDAÇÕES BÁSICAS DA SEED
-- ============================================================
-- Estas consultas não alteram dados.
-- Servem para conferir rapidamente integridade e volume.
-- ============================================================

-- Quantidade de registros por tabela:
SELECT 'contas_contabeis' AS tabela, COUNT(*) AS registros
FROM contas_contabeis
UNION ALL
SELECT 'centros_custo', COUNT(*)
FROM centros_custo
UNION ALL
SELECT 'clientes', COUNT(*)
FROM clientes
UNION ALL
SELECT 'fornecedores', COUNT(*)
FROM fornecedores
UNION ALL
SELECT 'produtos_servicos', COUNT(*)
FROM produtos_servicos
UNION ALL
SELECT 'contas_bancarias', COUNT(*)
FROM contas_bancarias
UNION ALL
SELECT 'notas_fiscais', COUNT(*)
FROM notas_fiscais
UNION ALL
SELECT 'lancamentos_contabeis', COUNT(*)
FROM lancamentos_contabeis
UNION ALL
SELECT 'conciliacoes', COUNT(*)
FROM conciliacoes
UNION ALL
SELECT 'orcamento', COUNT(*)
FROM orcamento
ORDER BY tabela;


-- NFs por tipo de operação/status:
SELECT
    tipo_operacao,
    status_pagamento,
    COUNT(*) AS quantidade,
    SUM(valor_bruto) AS valor_bruto,
    SUM(valor_liquido) AS valor_liquido
FROM notas_fiscais
GROUP BY tipo_operacao, status_pagamento
ORDER BY tipo_operacao, status_pagamento;


-- Conferência do valor líquido das NFs:
SELECT COUNT(*) AS nfs_com_divergencia
FROM notas_fiscais
WHERE valor_liquido <> valor_bruto - impostos;


-- Conferência das NFs pagas:
SELECT COUNT(*) AS nfs_pagas_sem_data_pagamento
FROM notas_fiscais
WHERE status_pagamento = 'Pago'
  AND data_pagamento IS NULL;


-- Conferência do orçamento duplicado:
SELECT
    conta_id,
    centro_custo_id,
    mes_ano,
    COUNT(*) AS quantidade
FROM orcamento
GROUP BY conta_id, centro_custo_id, mes_ano
HAVING COUNT(*) > 1;


COMMIT;

-- ============================================================
-- FIM DA SEED
-- ============================================================
