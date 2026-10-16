import pandas as pd
import sqlalchemy
import os

# Exemplo de Extração de Dados
# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(script_dir, 'sales_data.db')
engine = sqlalchemy.create_engine(f'sqlite:///{db_path}')  # Criar uma conexão com o banco de dados SQLite
query = "SELECT * FROM sales"  # Definir a consulta SQL para extrair os dados de vendas
data = pd.read_sql(query, engine)  # Ler os dados da consulta SQL em um DataFrame pandas
print(data.head())  # Exibir as primeiras linhas dos dados extraídos

# Exemplo de Transformação de Dados
data['sales_amount'] = data['quantity'] * data['unit_price']  # Calcular o valor total das vendas
monthly_sales = data.groupby(['year', 'month']).agg(total_sales=('sales_amount', 'sum'))  # Agregar as vendas mensais
monthly_sales['sales_growth'] = monthly_sales['total_sales'].pct_change()  # Calcular o crescimento das vendas

# Reset index to make year and month regular columns
monthly_sales = monthly_sales.reset_index()

# Add month_name column
month_names = {
    1: 'January', 2: 'February', 3: 'March', 4: 'April', 
    5: 'May', 6: 'June', 7: 'July', 8: 'August',
    9: 'September', 10: 'October', 11: 'November', 12: 'December'
}
monthly_sales['month_name'] = monthly_sales['month'].map(month_names)

print(monthly_sales.head())  # Exibir as primeiras linhas dos dados transformados

# Exemplo de Carregamento de Dados
monthly_sales.to_sql('monthly_sales', engine, if_exists='replace', index=False)  # Carregar os dados transformados em uma nova tabela do banco de dados
print("Dados carregados com sucesso!")  # Mensagem de confirmação de sucesso do carregamento