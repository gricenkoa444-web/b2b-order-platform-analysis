-- PostgreSQL. Упрощённая модель B2B-заказов.

CREATE TABLE organization (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    inn         VARCHAR(12) NOT NULL UNIQUE
);

CREATE TABLE contract (
    id                  BIGSERIAL PRIMARY KEY,
    organization_id     BIGINT        NOT NULL REFERENCES organization(id),
    price_list_id       BIGINT        NOT NULL,
    payment_terms_days  INTEGER       NOT NULL DEFAULT 0,
    credit_limit        NUMERIC(14,2) NOT NULL DEFAULT 0,
    valid_to            DATE
);

CREATE TABLE "order" (
    id              BIGSERIAL PRIMARY KEY,
    contract_id     BIGINT        NOT NULL REFERENCES contract(id),
    status          VARCHAR(32)   NOT NULL,
    total_amount    NUMERIC(14,2) NOT NULL,
    currency        CHAR(3)       NOT NULL DEFAULT 'RUB',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE order_item (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT        NOT NULL REFERENCES "order"(id),
    sku         VARCHAR(32)   NOT NULL,
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(12,2) NOT NULL
);

CREATE TABLE shipment (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT      NOT NULL REFERENCES "order"(id),
    status      VARCHAR(32) NOT NULL,
    shipped_at  TIMESTAMPTZ
);

CREATE TABLE payment (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT        NOT NULL REFERENCES "order"(id),
    amount      NUMERIC(14,2) NOT NULL,
    paid_at     TIMESTAMPTZ
);

-- Идемпотентность создания заказа
CREATE TABLE idempotency_key (
    key             UUID PRIMARY KEY,
    request_hash    CHAR(64)    NOT NULL,
    response_status INTEGER,
    response_body   JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Outbox для надёжной публикации событий
CREATE TABLE outbox (
    id           BIGSERIAL PRIMARY KEY,
    event_id     UUID        NOT NULL UNIQUE,
    event_type   VARCHAR(64) NOT NULL,
    aggregate_id VARCHAR(64) NOT NULL,
    payload      JSONB       NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at      TIMESTAMPTZ
);

-- Журнал аудита смен статусов
CREATE TABLE order_status_history (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT       NOT NULL REFERENCES "order"(id),
    from_status VARCHAR(32),
    to_status   VARCHAR(32)  NOT NULL,
    changed_by  VARCHAR(64)  NOT NULL,
    changed_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_order_contract_created ON "order"(contract_id, created_at);
CREATE INDEX idx_order_item_order       ON order_item(order_id);
CREATE INDEX idx_outbox_unsent          ON outbox(created_at) WHERE sent_at IS NULL;
