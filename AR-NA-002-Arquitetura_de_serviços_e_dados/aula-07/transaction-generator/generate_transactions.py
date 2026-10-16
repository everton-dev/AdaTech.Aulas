from __future__ import annotations

import argparse
import os
import random
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pyodbc
from dotenv import load_dotenv


MAX_TRANSACTIONS = 200
MAX_PRODUCTS_PER_ORDER = 5
MAX_QUANTITY_PER_ITEM = 5


@dataclass(frozen=True)
class DatabaseConfig:
    host: str
    database: str
    username: str
    password: str
    driver: str

    @property
    def connection_string(self) -> str:
        return (
            f"DRIVER={{{self.driver}}};"
            f"SERVER={self.host};"
            f"DATABASE={self.database};"
            f"UID={self.username};"
            f"PWD={self.password};"
            "Encrypt=no;TrustServerCertificate=yes;Connection Timeout=30;"
        )


@dataclass(frozen=True)
class Product:
    product_id: int
    unit_price: Decimal
    stock_quantity: int


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate random paid orders and payments in transaction_db."
    )
    parser.add_argument(
        "--count",
        type=int,
        default=50,
        help=f"Number of transactions to generate (1-{MAX_TRANSACTIONS}, default: 50).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Optional random seed for reproducible generated transactions.",
    )
    arguments = parser.parse_args()
    if not 1 <= arguments.count <= MAX_TRANSACTIONS:
        parser.error(f"--count must be between 1 and {MAX_TRANSACTIONS}.")
    return arguments


def get_database_config() -> DatabaseConfig:
    load_dotenv()
    return DatabaseConfig(
        host=os.getenv("TRANSACTION_DB_HOST", "localhost,14331"),
        database=os.getenv("TRANSACTION_DB_NAME", "transaction_db"),
        username=os.getenv("DB_USER", "everton"),
        password=os.getenv("DB_PASSWORD", "@da123*"),
        driver=os.getenv("SQL_SERVER_DRIVER", "ODBC Driver 18 for SQL Server"),
    )


def random_order_date(generator: random.Random) -> datetime:
    now = datetime.now(timezone.utc).replace(microsecond=0, tzinfo=None)
    return now - timedelta(
        days=generator.randint(0, 30),
        hours=generator.randint(0, 23),
        minutes=generator.randint(0, 59),
    )


def load_reference_data(cursor: pyodbc.Cursor) -> tuple[list[int], list[int], list[Product]]:
    client_ids = [row.ClientId for row in cursor.execute("SELECT ClientId FROM dbo.Client").fetchall()]
    payment_type_ids = [
        row.PaymentTypeId
        for row in cursor.execute("SELECT PaymentTypeId FROM dbo.PaymentType").fetchall()
    ]
    products = [
        Product(row.ProductId, Decimal(row.UnitPrice), row.StockQuantity)
        for row in cursor.execute(
            """
            SELECT ProductId, UnitPrice, StockQuantity
            FROM dbo.Product
            WHERE IsActive = 1 AND StockQuantity > 0
            """
        ).fetchall()
    ]
    if not client_ids or not payment_type_ids or not products:
        raise RuntimeError(
            "Missing clients, payment types, or active products with stock in transaction_db."
        )
    return client_ids, payment_type_ids, products


def choose_order_products(generator: random.Random, products: list[Product]) -> list[tuple[Product, int]]:
    available_products = [product for product in products if product.stock_quantity > 0]
    if not available_products:
        raise RuntimeError("Product stock was exhausted before all transactions were generated.")

    line_count = generator.randint(1, min(MAX_PRODUCTS_PER_ORDER, len(available_products)))
    selected_products = generator.sample(available_products, k=line_count)
    return [
        (product, generator.randint(1, min(MAX_QUANTITY_PER_ITEM, product.stock_quantity)))
        for product in selected_products
    ]


def insert_order(
    cursor: pyodbc.Cursor,
    client_id: int,
    order_date: datetime,
    order_total: Decimal,
) -> int:
    external_code = f"GEN-{uuid.uuid4().hex[:22].upper()}"
    return cursor.execute(
        """
        INSERT INTO dbo.[Order] (ExternalOrderCode, ClientId, OrderDate, Status, TotalAmount)
        OUTPUT INSERTED.OrderId
        VALUES (?, ?, ?, N'PAID', ?);
        """,
        external_code,
        client_id,
        order_date,
        order_total,
    ).fetchval()


def create_transaction(
    connection: pyodbc.Connection,
    generator: random.Random,
    client_ids: list[int],
    payment_type_ids: list[int],
    products: list[Product],
) -> None:
    selected_products = choose_order_products(generator, products)
    order_total = sum(
        (product.unit_price * quantity for product, quantity in selected_products),
        start=Decimal("0.00"),
    )
    order_date = random_order_date(generator)
    cursor = connection.cursor()

    try:
        order_id = insert_order(
            cursor,
            client_id=generator.choice(client_ids),
            order_date=order_date,
            order_total=order_total,
        )
        for product, quantity in selected_products:
            cursor.execute(
                """
                INSERT INTO dbo.OrderItem (OrderId, ProductId, Quantity, UnitPrice)
                VALUES (?, ?, ?, ?);
                """,
                order_id,
                product.product_id,
                quantity,
                product.unit_price,
            )
            cursor.execute(
                """
                UPDATE dbo.Product
                SET StockQuantity = StockQuantity - ?
                WHERE ProductId = ? AND StockQuantity >= ?;
                """,
                quantity,
                product.product_id,
                quantity,
            )
            if cursor.rowcount != 1:
                raise RuntimeError(f"Insufficient stock for product {product.product_id}.")
            product_index = products.index(product)
            products[product_index] = Product(
                product.product_id,
                product.unit_price,
                product.stock_quantity - quantity,
            )

        payment_date = order_date + timedelta(minutes=generator.randint(0, 10))
        cursor.execute(
            """
            INSERT INTO dbo.Payment (OrderId, PaymentTypeId, PaymentDate, Amount, PaymentReference)
            VALUES (?, ?, ?, ?, ?);
            """,
            order_id,
            generator.choice(payment_type_ids),
            payment_date,
            order_total,
            f"PAY-{uuid.uuid4().hex[:30].upper()}",
        )
        connection.commit()
    except Exception:
        connection.rollback()
        raise


def main() -> None:
    arguments = parse_arguments()
    generator = random.Random(arguments.seed)
    database_config = get_database_config()

    with pyodbc.connect(database_config.connection_string) as connection:
        cursor = connection.cursor()
        client_ids, payment_type_ids, products = load_reference_data(cursor)
        for transaction_number in range(1, arguments.count + 1):
            create_transaction(connection, generator, client_ids, payment_type_ids, products)
            print(f"Generated transaction {transaction_number}/{arguments.count}.")

    print(f"Successfully generated {arguments.count} paid transactions.")


if __name__ == "__main__":
    main()