# Transaction Generator

Generates random paid orders, order items, and one matching payment per order in `transaction_db` to simulate a new workload before running the ETL.

The generator uses existing clients, payment types, and active products with stock. Every generated transaction is committed independently, reduces product stock, and has a payment equal to the order total.

Run it from the `aula-07` folder after the transactional database is healthy:

```powershell
py transaction-generator/generate_transactions.py --count 50
```

Use `--count` with a value from `1` to `200`. For reproducible random data, add `--seed`:

```powershell
py transaction-generator/generate_transactions.py --count 200 --seed 42
```

The connection defaults match the local Compose deployment. It accepts the same environment variables used by the ETL: `TRANSACTION_DB_HOST`, `TRANSACTION_DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `SQL_SERVER_DRIVER`.