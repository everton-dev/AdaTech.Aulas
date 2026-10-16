-- Criar tabela Cliente
CREATE TABLE Cliente (
    ClienteId INT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Endereco VARCHAR(255),
    Email VARCHAR(100),
    Telefone VARCHAR(20)
);

-- Criar tabela Pedidos
CREATE TABLE Pedidos (
    PedidoId INT PRIMARY KEY,
    ClienteId INT,
    DataPedido DATETIME NOT NULL,
    CONSTRAINT FK_Pedidos_Cliente FOREIGN KEY (ClienteId) REFERENCES Cliente(ClienteId)
);

-- Criar tabela Produtos
CREATE TABLE Produtos (
    ProdutoId INT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Descricao VARCHAR(255),
    Preco DECIMAL(10, 2) NOT NULL,
    QuantidadeEmEstoque INT NOT NULL
);

-- Criar tabela ItensPedido
CREATE TABLE ItensPedido (
    PedidoId INT,
    ProdutoId INT,
    Quantidade INT NOT NULL,
    PrecoUnitario DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (PedidoId, ProdutoId),
    CONSTRAINT FK_ItensPedido_Pedidos FOREIGN KEY (PedidoId) REFERENCES Pedidos(PedidoId),
    CONSTRAINT FK_ItensPedido_Produtos FOREIGN KEY (ProdutoId) REFERENCES Produtos(ProdutoId)
);

-- Inserir dados na tabela Cliente
INSERT INTO Cliente (ClienteId, Nome, Endereco, Email, Telefone) VALUES
(1, 'João Silva', 'Rua A, 123', 'joao.silva@example.com', '123456789'),
(2, 'Maria Oliveira', 'Avenida B, 456', 'maria.oliveira@example.com', '987654321'),
(3, 'Carlos Souza', 'Travessa C, 789', 'carlos.souza@example.com', '456123789');

-- Inserir dados na tabela Pedidos
INSERT INTO Pedidos (PedidoId, ClienteId, DataPedido) VALUES
(1, 1, '2023-01-01'),
(2, 2, '2023-01-02'),
(3, 3, '2023-01-03');

-- Inserir dados na tabela Produtos
INSERT INTO Produtos (ProdutoId, Nome, Descricao, Preco, QuantidadeEmEstoque) VALUES
(1, 'Produto A', 'Descrição do Produto A', 10.00, 100),
(2, 'Produto B', 'Descrição do Produto B', 20.00, 200),
(3, 'Produto C', 'Descrição do Produto C', 30.00, 300);

-- Inserir dados na tabela ItensPedido
INSERT INTO ItensPedido (PedidoId, ProdutoId, Quantidade, PrecoUnitario) VALUES
(1, 1, 2, 10.00),
(1, 2, 1, 20.00),
(2, 2, 3, 20.00),
(2, 3, 1, 30.00),
(3, 1, 1, 10.00),
(3, 3, 2, 30.00);