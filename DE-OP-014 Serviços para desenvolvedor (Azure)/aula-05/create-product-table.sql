CREATE TABLE Product (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    Quantity INT NOT NULL
);

INSERT INTO Product (Name, Description, Price, Quantity) VALUES
-- PlayStation
(N'PlayStation 5',                  N'Console Sony PlayStation 5 com leitor de disco, 825GB SSD',                  4499.90, 30),
(N'PlayStation 5 Digital Edition',  N'Console Sony PlayStation 5 edição digital sem leitor de disco, 825GB SSD',   3999.90, 25),
(N'DualSense PS5',                 N'Controle sem fio DualSense para PlayStation 5, branco',                       469.90,  80),
(N'DualSense Edge PS5',            N'Controle profissional DualSense Edge para PlayStation 5',                     1299.90, 15),
(N'God of War Ragnarök PS5',       N'Jogo God of War Ragnarök para PS5 - mídia física',                            249.90,  50),
(N'Spider-Man 2 PS5',              N'Jogo Marvel''s Spider-Man 2 para PS5 - mídia física',                          299.90,  45),
(N'Horizon Forbidden West PS5',    N'Jogo Horizon Forbidden West Complete Edition para PS5',                       199.90,  40),
(N'Gran Turismo 7 PS5',            N'Jogo Gran Turismo 7 para PS5 - simulador de corrida',                         199.90,  35),
(N'The Last of Us Part I PS5',     N'Jogo The Last of Us Part I Remake para PS5',                                  249.90,  60),
(N'PS5 Pulse 3D Headset',         N'Headset sem fio Sony Pulse 3D para PlayStation 5, áudio 3D',                   599.90,  20),
-- Nintendo Switch
(N'Nintendo Switch OLED',          N'Console Nintendo Switch modelo OLED com tela de 7 polegadas',                2499.90, 35),
(N'Nintendo Switch Lite',          N'Console portátil Nintendo Switch Lite, turquesa',                             1499.90, 50),
(N'Joy-Con Par Neon',              N'Par de controles Joy-Con neon vermelho e azul para Nintendo Switch',           499.90,  70),
(N'Pro Controller Switch',         N'Controle Pro Controller para Nintendo Switch, preto',                          449.90,  40),
(N'The Legend of Zelda: TotK',     N'Jogo The Legend of Zelda: Tears of the Kingdom para Switch',                   349.90,  55),
(N'Super Mario Bros. Wonder',      N'Jogo Super Mario Bros. Wonder para Nintendo Switch',                           299.90,  65),
(N'Mario Kart 8 Deluxe',          N'Jogo Mario Kart 8 Deluxe para Nintendo Switch',                               299.90,  70),
(N'Pokémon Scarlet Switch',        N'Jogo Pokémon Scarlet para Nintendo Switch',                                   299.90,  45),
(N'Splatoon 3 Switch',            N'Jogo Splatoon 3 para Nintendo Switch',                                        249.90,  30),
(N'Animal Crossing NH Switch',    N'Jogo Animal Crossing: New Horizons para Nintendo Switch',                      249.90,  55);
