-- 1. Оборот клиентов за месяц, только с оборотом выше 500 000
SELECT o.name,
       SUM(ord.total_amount) AS turnover
FROM organization o
JOIN contract c  ON c.organization_id = o.id
JOIN "order" ord ON ord.contract_id = c.id
WHERE ord.created_at >= DATE '2026-10-01'
  AND ord.created_at <  DATE '2026-11-01'
  AND ord.status NOT IN ('CANCELLED', 'REJECTED')
GROUP BY o.name
HAVING SUM(ord.total_amount) > 500000
ORDER BY turnover DESC;

-- 2. Клиенты, у которых нет ни одного заказа
SELECT o.name
FROM organization o
LEFT JOIN contract c  ON c.organization_id = o.id
LEFT JOIN "order" ord ON ord.contract_id = c.id
WHERE ord.id IS NULL;

-- 3. Последний заказ каждой организации (оконная функция)
SELECT organization_id, id AS order_id, created_at
FROM (
    SELECT c.organization_id,
           ord.id,
           ord.created_at,
           ROW_NUMBER() OVER (
               PARTITION BY c.organization_id
               ORDER BY ord.created_at DESC
           ) AS rn
    FROM "order" ord
    JOIN contract c ON c.id = ord.contract_id
) t
WHERE rn = 1;

-- 4. Доступный кредитный лимит по договору
SELECT c.id,
       c.credit_limit
         - COALESCE(SUM(ord.total_amount) FILTER (
               WHERE ord.status IN ('AWAITING_APPROVAL','CONFIRMED','PARTIALLY_SHIPPED','SHIPPED')
           ), 0)
         + COALESCE(SUM(p.amount), 0) AS available_limit
FROM contract c
LEFT JOIN "order" ord ON ord.contract_id = c.id
LEFT JOIN payment p   ON p.order_id = ord.id
GROUP BY c.id, c.credit_limit;
-- Упрощение: расчёт учитывает оплаты по заказам в зачёт лимита. Точная формула
-- определяется бизнес-правилами договора (открытый вопрос в docs/requirements.md).

-- 5. Необработанные события outbox (мониторинг)
SELECT id, event_type, aggregate_id, created_at
FROM outbox
WHERE sent_at IS NULL
ORDER BY created_at
LIMIT 100;
