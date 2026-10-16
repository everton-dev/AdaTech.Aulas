from __future__ import annotations

import os
from dataclasses import dataclass

from dotenv import load_dotenv


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
class Settings:
    source: DatabaseConfig
    target: DatabaseConfig
    log_level: str

    @classmethod
    def from_environment(cls) -> "Settings":
        load_dotenv()
        driver = os.getenv("SQL_SERVER_DRIVER", "ODBC Driver 18 for SQL Server")
        username = os.getenv("DB_USER", "everton")
        password = os.getenv("DB_PASSWORD", "@da123*")
        return cls(
            source=DatabaseConfig(
                host=os.getenv("TRANSACTION_DB_HOST", "localhost,14331"),
                database=os.getenv("TRANSACTION_DB_NAME", "transaction_db"),
                username=username,
                password=password,
                driver=driver,
            ),
            target=DatabaseConfig(
                host=os.getenv("ANALYTICS_DB_HOST", "localhost,14332"),
                database=os.getenv("ANALYTICS_DB_NAME", "analytics_db"),
                username=username,
                password=password,
                driver=driver,
            ),
            log_level=os.getenv("ETL_LOG_LEVEL", "INFO").upper(),
        )