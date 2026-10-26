# События Kafka

## Топики

| Топик | Ключ сообщения | Партиции | Retention | Продюсер |
|---|---|---|---|---|
| `orders.events` | `orderId` | 6 | 7 дней | Order Service |
| `orders.events.dlq` | `orderId` | 1 | 30 дней | Потребители при исчерпании попыток |

Ключ `orderId` гарантирует, что все события одного заказа попадают в одну партицию и обрабатываются в порядке возникновения.

## Потребители

| Consumer group | Сервис | Реакция |
|---|---|---|
| `erp-integration` | Интеграция с ERP | Создаёт документы по `OrderConfirmed`, `OrderShipped` |
| `notification` | Notification Service | Отправляет письма и push по изменению статуса |
| `analytics` | Аналитика | Загружает события в витрину |
| `wms-adapter` | Адаптер WMS | Запускает сборку по `OrderConfirmed`, снимает резерв по `OrderCancelled` |

## Формат события

Общие поля (envelope):

| Поле | Тип | Обязательное | Описание |
|---|---|---|---|
| eventId | uuid | да | Уникальный идентификатор, используется для дедупликации |
| eventType | string | да | Тип события |
| eventVersion | integer | да | Версия схемы |
| occurredAt | date-time (UTC) | да | Момент возникновения |
| orderId | string | да | Идентификатор заказа |

Пример `OrderConfirmed`:

```json
{
  "eventId": "e5a1c7b2-4d1a-4a0e-9c55-0f2b7a1d3c11",
  "eventType": "OrderConfirmed",
  "eventVersion": 1,
  "occurredAt": "2026-10-26T09:20:11Z",
  "orderId": "ORD-558201",
  "contractId": "CTR-1042",
  "totalAmount": { "value": 184500.00, "currency": "RUB" },
  "items": [
    { "sku": "SKU-1001", "quantity": 120 },
    { "sku": "SKU-2040", "quantity": 30 }
  ]
}
```

## Типы событий

`OrderCreated`, `OrderConfirmed`, `OrderRejected`, `OrderCancelled`, `ShipmentCreated`, `OrderShipped`, `OrderDelivered`.

## Гарантии и правила

- Доставка at-least-once: потребители обязаны быть идемпотентными (хранят обработанные `eventId`).
- Публикация через Outbox (см. [ADR-0002](adr/0002-outbox-and-idempotency.md)).
- Потребитель делает до 5 повторов с экспоненциальной задержкой, затем отправляет сообщение в `orders.events.dlq` и создаёт задачу оператору.
- Схемы хранятся в Schema Registry; допустимы только обратно совместимые изменения (добавление необязательных полей). Несовместимое изменение требует нового `eventVersion` и периода параллельной публикации.
- Мониторинг: лаг потребителей, размер DLQ, доля ошибок обработки.
