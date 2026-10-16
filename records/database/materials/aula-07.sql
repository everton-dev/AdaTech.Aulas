

SELECT * FROM Cliente
SELECT * FROM Produtos
SELECT * FROM Pedidos
SELECT * FROM ItensPedido

CREATE NONCLUSTERED INDEX IX_ClienteNome ON Cliente (Nome)

SELECT 
	  Cliente.Nome
	, Cliente.Telefone
	, Pedidos.DataPedido
	, Produtos.Nome AS NomeProduto
	, ItensPedido.PrecoUnitario
	, ItensPedido.Quantidade
FROM Cliente
	INNER JOIN Pedidos
		ON Cliente.ClienteId = Pedidos.ClienteId
	INNER JOIN ItensPedido 
		ON Pedidos.PedidoId = ItensPedido.PedidoId
	INNER JOIN Produtos
		ON ItensPedido.ProdutoId = Produtos.ProdutoId
WHERE Cliente.ClienteId = 3

-- CLIENTES COM MAIS DE 2 PEDIDOS
SELECT Cliente.ClienteId, Cliente.Nome, COUNT(1) AS Qty
FROM Cliente
	INNER JOIN Pedidos
		ON Cliente.ClienteId = Pedidos.ClienteId
GROUP BY Cliente.ClienteId, Cliente.Nome
HAVING COUNT(1) > 2

-- PEDIDOS COM MAIS DE 5 ITENS
SELECT Pedidos.PedidoId, COUNT(1) AS Qty
FROM Pedidos
	INNER JOIN ItensPedido
		ON Pedidos.PedidoId = ItensPedido.PedidoId
GROUP BY Pedidos.PedidoId
HAVING COUNT(1) > 5


-- CTE para combinar as tabelas Cliente, Pedidos, Produtos e ItensPedido
WITH CTE_Combined AS (
    SELECT 
        c.ClienteId,
        c.Nome AS ClienteNome,
        c.Endereco,
        c.Email,
        c.Telefone,
        p.PedidoId,
        p.DataPedido,
        pr.ProdutoId,
        pr.Nome AS ProdutoNome,
        pr.Descricao,
        pr.Preco,
        ip.Quantidade,
        ip.PrecoUnitario
    FROM 
        Cliente c
    JOIN 
        Pedidos p ON c.ClienteId = p.ClienteId
    JOIN 
        ItensPedido ip ON p.PedidoId = ip.PedidoId
    JOIN 
        Produtos pr ON ip.ProdutoId = pr.ProdutoId
)
SELECT * FROM CTE_Combined ORDER BY ClienteNome;
