from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any

MONTH_NAMES = (
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
)
WEEKDAY_NAMES = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")


def build_date_rows(order_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    order_dates = [_as_date(row["OrderDate"]) for row in order_rows]
    if not order_dates:
        return []

    current_date = min(order_dates)
    last_date = max(order_dates)
    rows: list[dict[str, Any]] = []
    while current_date <= last_date:
        weekday_number = current_date.isoweekday()
        rows.append(
            {
                "DateKey": int(current_date.strftime("%Y%m%d")),
                "FullDate": current_date,
                "CalendarYear": current_date.year,
                "CalendarQuarter": ((current_date.month - 1) // 3) + 1,
                "CalendarMonth": current_date.month,
                "MonthName": MONTH_NAMES[current_date.month - 1],
                "DayOfMonth": current_date.day,
                "DayOfWeekNumber": weekday_number,
                "DayOfWeekName": WEEKDAY_NAMES[weekday_number - 1],
                "IsWeekend": weekday_number >= 6,
                "ISOWeekNumber": current_date.isocalendar().week,
            }
        )
        current_date += timedelta(days=1)
    return rows


def build_client_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    today = date.today()
    return [
        {
            **row,
            "CurrentAgeBand": age_band(_age_on(_as_date(row["BirthDate"]), today)),
        }
        for row in rows
    ]


def build_product_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [{**row, "PriceBand": price_band(row["UnitPrice"])} for row in rows]


def build_order_rows(
    rows: list[dict[str, Any]],
    client_keys: dict[int, int],
    payment_type_keys: dict[int, int],
) -> list[dict[str, Any]]:
    transformed_rows = []
    for row in rows:
        order_date = _as_date(row["OrderDate"])
        age_at_order = _age_on(_as_date(row["BirthDate"]), order_date)
        transformed_rows.append(
            {
                "OrderBusinessKey": row["OrderBusinessKey"],
                "DateKey": int(order_date.strftime("%Y%m%d")),
                "ClientKey": client_keys[row["ClientBusinessKey"]],
                "PaymentTypeKey": payment_type_keys[row["PaymentTypeBusinessKey"]],
                "OrderTimestamp": row["OrderTimestamp"],
                "PaymentTimestamp": row["PaymentTimestamp"],
                "CustomerAgeAtOrder": age_at_order,
                "CustomerAgeGroup": age_band(age_at_order),
                "ItemCount": row["ItemCount"],
                "TotalQuantity": row["TotalQuantity"],
                "OrderTotal": row["OrderTotal"],
                "PaymentAmount": row["PaymentAmount"],
            }
        )
    return transformed_rows


def build_order_item_rows(
    rows: list[dict[str, Any]],
    client_keys: dict[int, int],
    product_keys: dict[int, int],
) -> list[dict[str, Any]]:
    return [
        {
            "OrderItemBusinessKey": row["OrderItemBusinessKey"],
            "OrderBusinessKey": row["OrderBusinessKey"],
            "DateKey": int(_as_date(row["OrderDate"]).strftime("%Y%m%d")),
            "ClientKey": client_keys[row["ClientBusinessKey"]],
            "ProductKey": product_keys[row["ProductBusinessKey"]],
            "Quantity": row["Quantity"],
            "UnitPrice": row["UnitPrice"],
            "LineAmount": row["LineAmount"],
        }
        for row in rows
    ]


def age_band(age: int) -> str:
    if age < 18:
        return "Under 18"
    if age <= 24:
        return "18-24"
    if age <= 34:
        return "25-34"
    if age <= 44:
        return "35-44"
    if age <= 54:
        return "45-54"
    return "55+"


def price_band(unit_price: Any) -> str:
    price = float(unit_price)
    if price < 50:
        return "Budget"
    if price < 150:
        return "Standard"
    if price < 300:
        return "Premium"
    return "Collector"


def _as_date(value: date | datetime) -> date:
    return value.date() if isinstance(value, datetime) else value


def _age_on(birth_date: date, reference_date: date) -> int:
    return reference_date.year - birth_date.year - (
        (reference_date.month, reference_date.day) < (birth_date.month, birth_date.day)
    )