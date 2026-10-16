# PokeDex Explorer

SPA estática que consome a [PokeAPI](https://pokeapi.co/api/v2). A rota inicial consulta `https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0`, permite pesquisar e paginar a lista, e abre uma rota de detalhe por Pokémon.

O detalhe consulta a URL recebida na propriedade `url` de cada item da lista. A tela apresenta dados físicos, tipos, habilidades, estatísticas, sprites, áudio, movimentos, formas, itens e versões de jogo.

Execute um servidor local a partir desta pasta:

```powershell
py -m http.server 8090
```

Abra `http://localhost:8090` no navegador. O servidor local é necessário para que o navegador permita as consultas à PokeAPI.