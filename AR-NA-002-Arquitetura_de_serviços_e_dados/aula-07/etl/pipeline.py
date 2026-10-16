from __future__ import annotations

import logging
import sys
from collections.abc import Callable
from typing import Any

import pyodbc

from .config import Settings
from .extract import TransactionRepository
from .load import WarehouseLoader
from .transform import (
    build_client_rows,
    build_date_rows,
    build_order_item_rows,
    build_order_rows,
    build_product_rows,
)

LOGGER = logging.getLogger("geek_store_etl")


def configure_logging(level: str) -> None:
    logging.basicConfig(
        level=level,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )


def run_pipeline(settings: Settings) -> None:
    source_connection = pyodbc.connect(settings.source.connection_string)
    target_connection = pyodbc.connect(settings.target.connection_string)
    try:
        repository = TransactionRepository(source_connection)
        loader = WarehouseLoader(target_connection)

        clients = repository.fetch_clients()
        products = repository.fetch_products()
        payment_types = repository.fetch_payment_types()
        orders = repository.fetch_orders()
        order_items = repository.fetch_order_items()
        LOGGER.info(
            "Extracted source records: clients=%d products=%d payment_types=%d orders=%d order_items=%d",
            len(clients), len(products), len(payment_types), len(orders), len(order_items),
        )

        _load_and_log(loader, "DimDate", ("DateKey",), build_date_rows(orders))
        _load_and_log(loader, "DimClient", ("ClientBusinessKey",), build_client_rows(clients))
        _load_and_log(loader, "DimProduct", ("ProductBusinessKey",), build_product_rows(products))
        _load_and_log(loader, "DimPaymentType", ("PaymentTypeBusinessKey",), payment_types)

        client_keys = loader.key_map("DimClient", "ClientBusinessKey", "ClientKey")
        product_keys = loader.key_map("DimProduct", "ProductBusinessKey", "ProductKey")
        payment_type_keys = loader.key_map("DimPaymentType", "PaymentTypeBusinessKey", "PaymentTypeKey")
        _load_and_log(
            loader,
            "FactOrder",
            ("OrderBusinessKey",),
            build_order_rows(orders, client_keys, payment_type_keys),
        )
        _load_and_log(
            loader,
            "FactOrderItem",
            ("OrderItemBusinessKey",),
            build_order_item_rows(order_items, client_keys, product_keys),
        )
        _validate_load(loader, orders, order_items)
        LOGGER.info("ETL completed successfully.")
    finally:
        source_connection.close()
        target_connection.close()


def _load_and_log(
    loader: WarehouseLoader,
    table_name: str,
    key_columns: tuple[str, ...],
    rows: list[dict[str, Any]],
) -> None:
    loader.upsert(table_name, key_columns, rows)
    LOGGER.info("Loaded %d records into %s.", len(rows), table_name)


def _validate_load(
    loader: WarehouseLoader,
    source_orders: list[dict[str, Any]],
    source_order_items: list[dict[str, Any]],
) -> None:
    expected_counts: dict[str, int] = {
        "FactOrder": len(source_orders),
        "FactOrderItem": len(source_order_items),
    }
    for table_name, expected_count in expected_counts.items():
        actual_count = loader.count(table_name)
        if actual_count != expected_count:
            raise RuntimeError(
                f"Validation failed for {table_name}: expected {expected_count}, found {actual_count}."
            )
        LOGGER.info("Validated %s row count: %d.", table_name, actual_count)


def main() -> None:
    settings = Settings.from_environment()
    configure_logging(settings.log_level)
    try:
        run_pipeline(settings)
    except pyodbc.Error as error:
        LOGGER.exception("Database operation failed: %s", error)
        sys.exit(1)
    except Exception as error:
        LOGGER.exception("ETL failed: %s", error)
        sys.exit(1)