import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime

# Extração de dados
data = pd.read_csv('dados_vendas.csv')

# Transformação de dados
data['total_vendas'] = data['quantidade'] * data['preco_unitario']
data['transformacao_date'] = datetime.now()

# Carregamento de dados
engine = create_engine('sqlite:///banco_de_dados.db')
data.to_sql('vendas', engine, index=False, if_exists='replace')