# B2B Order Platform: аналитическая документация

Учебный портфолио-проект системного аналитика. Предметная область: оптовая платформа с интернет-магазином на общем бэкенде. Показаны артефакты, которые аналитик передаёт в разработку: контракт API, требования, статусная модель, события Kafka, модель данных, диаграммы и архитектурные решения с обоснованием.

## Бизнес-контекст

Компания продаёт товары юридическим лицам (договоры, индивидуальные прайс-листы, отсрочка платежа, кредитный лимит) и физическим лицам (витрина). Фокус проекта: **оформление B2B-заказа**.

## Состав репозитория

| Артефакт | Файл |
|---|---|
| Контракт REST API (OpenAPI 3.0) | [openapi/orders.yaml](openapi/orders.yaml) |
| Требования FR/NFR, критерии приёмки | [docs/requirements.md](docs/requirements.md) |
| Статусная модель заказа | [docs/order-status-model.md](docs/order-status-model.md) |
| События Kafka: топики, схемы, гарантии | [docs/events-kafka.md](docs/events-kafka.md) |
| Sequence-диаграмма создания заказа (PlantUML) | [diagrams/create-order-sequence.puml](diagrams/create-order-sequence.puml) |
| State machine заказа (PlantUML) | [diagrams/order-state.puml](diagrams/order-state.puml) |
| Схема БД | [sql/schema.sql](sql/schema.sql) |
| Типовые аналитические запросы | [sql/queries.sql](sql/queries.sql) |
| ADR: синхронно или асинхронно | [docs/adr/0001-sync-vs-async.md](docs/adr/0001-sync-vs-async.md) |
| ADR: Outbox и идемпотентность | [docs/adr/0002-outbox-and-idempotency.md](docs/adr/0002-outbox-and-idempotency.md) |

## Ключевые проектные решения

1. Критичные для ответа клиенту шаги (проверка лимита, резервирование) выполняются синхронно, остальные (ERP, уведомления, аналитика) асинхронно через Kafka.
2. Защита от дублей заказа: заголовок `Idempotency-Key` и уникальный индекс в БД.
3. Надёжная публикация событий: паттерн Outbox.
4. Консистентность между сервисами: сага с компенсирующими действиями (оркестрация из Order Service).
5. Недопустимые переходы статусов отклоняются с кодом 409.

Обоснование каждого решения: в папке [docs/adr](docs/adr).

## Как просматривать диаграммы

Файлы `.puml` открываются в [PlantUML Web Server](https://www.plantuml.com/plantuml) или плагином PlantUML для VS Code.
