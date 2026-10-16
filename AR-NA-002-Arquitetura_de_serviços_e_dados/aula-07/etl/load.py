from __future__ import annotations

from collections.abc import Iterable, Sequence
from typing import Any

import pyodbc


class WarehouseLoader:
    """Loads a SQL Server warehouse using temporary staging tables and MERGE."""

    def __init__(self, connection: pyodbc.Connection) -> None:
        self._connection = connection

    def upsert(
        self,
        table_name: str,
        key_columns: Sequence[str],
        rows: list[dict[str, Any]],
    ) -> None:
        if not rows:
            return

        columns = list(rows[0])
        stage_name = f"#stage_{table_name}"
        cursor = self._connection.cursor()
        quoted_columns = self._quoted_list(columns)
        cursor.execute(f"SELECT TOP (0) {quoted_columns} INTO {stage_name} FROM dbo.[{table_name}];")

        placeholders = ", ".join("?" for _ in columns)
        cursor.executemany(
            f"INSERT INTO {stage_name} ({quoted_columns}) VALUES ({placeholders});",
            [tuple(row[column] for column in columns) for row in rows],
        )

        join_condition = " AND ".join(
            f"target.[{column}] = source.[{column}]" for column in key_columns
        )
        update_columns = [column for column in columns if column not in key_columns]
        update_set = ", ".join(f"target.[{column}] = source.[{column}]" for column in update_columns)
        if update_set and table_name != "DimDate":
            update_set += ", target.[LoadedAt] = SYSUTCDATETIME()"

        cursor.execute(
            f"""
            MERGE dbo.[{table_name}] WITH (HOLDLOCK) AS target
            USING {stage_name} AS source
            ON {join_condition}
            WHEN MATCHED THEN UPDATE SET {update_set}
            WHEN NOT MATCHED BY TARGET THEN
                INSERT ({quoted_columns}) VALUES ({", ".join(f"source.[{column}]" for column in columns)});
            """
        )
        self._connection.commit()

    def key_map(self, table_name: str, business_key: str, surrogate_key: str) -> dict[int, int]:
        cursor = self._connection.cursor()
        cursor.execute(f"SELECT [{business_key}], [{surrogate_key}] FROM dbo.[{table_name}];")
        return {int(row[0]): int(row[1]) for row in cursor.fetchall()}

    def count(self, table_name: str) -> int:
        cursor = self._connection.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM dbo.[{table_name}];")
        return int(cursor.fetchone()[0])

    @staticmethod
    def _quoted_list(columns: Iterable[str]) -> str:
        return ", ".join(f"[{column}]" for column in columns)