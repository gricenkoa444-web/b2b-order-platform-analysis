# Статусная модель заказа

Диаграмма: [diagrams/order-state.puml](../diagrams/order-state.puml)

| Из статуса | В статус | Триггер | Кто инициирует | Побочные эффекты |
|---|---|---|---|---|
| NEW | AWAITING_APPROVAL | Заказ создан, сумма выше порога | Система | Событие `OrderCreated`, уведомление руководителю |
| NEW | CONFIRMED | Заказ создан, лимит и резерв в порядке, сумма ниже порога | Система | События `OrderCreated`, `OrderConfirmed` |
| AWAITING_APPROVAL | CONFIRMED | Руководитель согласовал, лимит подтверждён, резерв выполнен | Руководитель / система | Событие `OrderConfirmed` |
| AWAITING_APPROVAL | REJECTED | Руководитель отклонил или лимит превышен | Руководитель / система | Снятие резерва, событие `OrderRejected` |
| CONFIRMED | PARTIALLY_SHIPPED | Отгружена часть позиций | WMS | Событие `ShipmentCreated` |
| CONFIRMED, PARTIALLY_SHIPPED | SHIPPED | Отгружено полностью | WMS | Событие `OrderShipped`, передача в ERP |
| SHIPPED | DELIVERED | Подтверждена доставка | Перевозчик / клиент | Событие `OrderDelivered` |
| NEW, AWAITING_APPROVAL, CONFIRMED | CANCELLED | Отмена | Закупщик / менеджер | Снятие резерва, событие `OrderCancelled` |

## Правила

- Все остальные переходы запрещены, API возвращает 409.
- Из статусов REJECTED, DELIVERED, CANCELLED переходов нет (финальные).
- Отмена после начала отгрузки (PARTIALLY_SHIPPED и далее) выполняется отдельным процессом возврата и в этой модели не рассматривается.
- Каждый переход записывается в журнал аудита (NFR-06).
