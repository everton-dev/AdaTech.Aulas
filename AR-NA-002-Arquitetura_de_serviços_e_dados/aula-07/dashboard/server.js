import express from "express";
import sql from "mssql";

const app = express();
const port = Number(process.env.PORT || 8080);

const databaseConfig = {
  server: process.env.ANALYTICS_DB_HOST || "analytics-db",
  port: Number(process.env.ANALYTICS_DB_PORT || 1433),
  database: process.env.ANALYTICS_DB_NAME || "analytics_db",
  user: process.env.DB_USER || "everton",
  password: process.env.DB_PASSWORD || "@da123*",
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
  pool: {
    max: 5,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let poolPromise;

function getPool() {
  if (!poolPromise) {
    poolPromise = sql.connect(databaseConfig).catch((error) => {
      poolPromise = undefined;
      throw error;
    });
  }
  return poolPromise;
}

async function getReport() {
  const pool = await getPool();
  const [kpis, weekdaySales, agePurchases, productPerformance, paymentMethods] = await Promise.all([
    pool.request().query("SELECT * FROM dbo.vw_SalesKpis;"),
    pool.request().query("SELECT * FROM dbo.vw_WeekdaySalesFlow ORDER BY DayOfWeekNumber;"),
    pool.request().query("SELECT * FROM dbo.vw_ClientPurchasesByAge ORDER BY CustomerAgeGroup, CustomerAgeAtOrder;"),
    pool.request().query("SELECT TOP (8) * FROM dbo.vw_ProductPerformance ORDER BY Revenue DESC;"),
    pool.request().query("SELECT * FROM dbo.vw_PaymentMethodPerformance ORDER BY PaidAmount DESC;"),
  ]);

  return {
    generatedAt: new Date().toISOString(),
    kpis: kpis.recordset[0] || {},
    weekdaySales: weekdaySales.recordset,
    agePurchases: agePurchases.recordset,
    productPerformance: productPerformance.recordset,
    paymentMethods: paymentMethods.recordset,
  };
}

app.use(express.static("public"));

app.get("/api/report", async (_request, response) => {
  try {
    response.json(await getReport());
  } catch (error) {
    console.error("Unable to retrieve analytics report.", error);
    response.status(503).json({
      message: "Analytics data is not available. Run the ETL and try again.",
    });
  }
});

app.get("/health", async (_request, response) => {
  try {
    const pool = await getPool();
    await pool.request().query("SELECT 1 AS Healthy;");
    response.json({ status: "healthy" });
  } catch (error) {
    response.status(503).json({ status: "unhealthy", message: error.message });
  }
});

app.listen(port, () => {
  console.log(`Geek Store dashboard listening on port ${port}.`);
});