from __future__ import annotations

from typing import Any

import pyodbc


class TransactionRepository:
    """Reads the source tables without exposing SQL details to the pipeline."""

    def __init__(self, connection: pyodbc.Connection) -> None:
        self._connection = connection

    def fetch_clients(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT ClientId AS ClientBusinessKey, FullName, Email, BirthDate
            FROM dbo.Client
            ORDER BY ClientId;
            """
        )

    def fetch_products(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT
                product.ProductId AS ProductBusinessKey,
                product.ProductName,
                product_type.ProductTypeName,
                product.UnitPrice,
                product.IsActive
            FROM dbo.Product AS product
            INNER JOIN dbo.ProductType AS product_type ON product_type.ProductTypeId = product.ProductTypeId
            ORDER BY product.ProductId;
            """
        )

    def fetch_payment_types(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT PaymentTypeId AS PaymentTypeBusinessKey, PaymentTypeName
            FROM dbo.PaymentType
            ORDER BY PaymentTypeId;
            """
        )

    def fetch_orders(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT
                sales_order.OrderId AS OrderBusinessKey,
                CAST(sales_order.OrderDate AS date) AS OrderDate,
                sales_order.OrderDate AS OrderTimestamp,
                client.ClientId AS ClientBusinessKey,
                client.BirthDate,
                payment_type.PaymentTypeId AS PaymentTypeBusinessKey,
                payment.PaymentDate AS PaymentTimestamp,
                sales_order.TotalAmount AS OrderTotal,
                payment.Amount AS PaymentAmount,
                COUNT(order_item.OrderItemId) AS ItemCount,
                SUM(order_item.Quantity) AS TotalQuantity
            FROM dbo.[Order] AS sales_order
            INNER JOIN dbo.Client AS client ON client.ClientId = sales_order.ClientId
            INNER JOIN dbo.Payment AS payment ON payment.OrderId = sales_order.OrderId
            INNER JOIN dbo.PaymentType AS payment_type ON payment_type.PaymentTypeId = payment.PaymentTypeId
            INNER JOIN dbo.OrderItem AS order_item ON order_item.OrderId = sales_order.OrderId
            GROUP BY
                sales_order.OrderId,
                sales_order.OrderDate,
                client.ClientId,
                client.BirthDate,
                payment_type.PaymentTypeId,
                payment.PaymentDate,
                sales_order.TotalAmount,
                payment.Amount
            ORDER BY sales_order.OrderId;
            """
        )

    def fetch_order_items(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT
                order_item.OrderItemId AS OrderItemBusinessKey,
                sales_order.OrderId AS OrderBusinessKey,
                CAST(sales_order.OrderDate AS date) AS OrderDate,
                client.ClientId AS ClientBusinessKey,
                product.ProductId AS ProductBusinessKey,
                order_item.Quantity,
                order_item.UnitPrice,
                order_item.LineTotal AS LineAmount
            FROM dbo.OrderItem AS order_item
            INNER JOIN dbo.[Order] AS sales_order ON sales_order.OrderId = order_item.OrderId
            INNER JOIN dbo.Client AS client ON client.ClientId = sales_order.ClientId
            INNER JOIN dbo.Product AS product ON product.ProductId = order_item.ProductId
            ORDER BY order_item.OrderItemId;
            """
        )

    def _fetch_all(self, query: str) -> list[dict[str, Any]]:
        cursor = self._connection.cursor()
        cursor.execute(query)
        column_names = [column[0] for column in cursor.description]
        return [dict(zip(column_names, row, strict=True)) for row in cursor.fetchall()]