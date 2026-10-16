const API_ROOT = "https://pokeapi.co/api/v2";
const LIST_ENDPOINT = `${API_ROOT}/pokemon?limit=100000&offset=0`;
const PAGE_SIZE = 36;

const state = { pokemon: [], search: "", page: 1 };
const app = document.getElementById("app");

function titleCase(value) {
  return value.replace(/-/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function pokemonId(url) {
  return Number(url.match(/\/pokemon\/(\d+)\/?$/)?.[1]);
}

function showLoading() {
  app.replaceChildren(document.getElementById("loading-template").content.cloneNode(true));
  lucide.createIcons();
}

function showError(message) {
  app.innerHTML = `<section class="shell"><div class="error-panel"><div><i data-lucide="circle-alert"></i><p>${message}</p><a class="detail-button" href="#/">Tentar novamente</a></div></div></section>`;
  lucide.createIcons();
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`A PokeAPI respondeu com status ${response.status}.`);
  return response.json();
}

async function loadPokemonList() {
  if (state.pokemon.length) return;
  const payload = await fetchJson(LIST_ENDPOINT);
  state.pokemon = payload.results.map((pokemon) => ({ ...pokemon, id: pokemonId(pokemon.url) }));
}

function renderList() {
  const filtered = state.pokemon.filter((pokemon) => pokemon.name.includes(state.search));
  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  state.page = Math.min(state.page, totalPages);
  const start = (state.page - 1) * PAGE_SIZE;
  const currentPage = filtered.slice(start, start + PAGE_SIZE);

  app.innerHTML = `
    <section class="shell">
      <section class="catalog-intro" aria-labelledby="catalog-title">
        <div>
          <p class="eyebrow">PokeAPI / Catálogo nacional</p>
          <h1 id="catalog-title">Encontre o próximo Pokémon da sua equipe.</h1>
          <p class="intro-copy">Consulte toda a Pokédex pública, navegue por nome e abra uma ficha completa com atributos, habilidades, estatísticas, movimentos, versões e sprites oficiais.</p>
        </div>
        <div class="intro-aside"><strong>${state.pokemon.length.toLocaleString("pt-BR")}</strong><span>Pokémon disponíveis para consulta</span></div>
      </section>
      <section class="toolbar" aria-label="Filtros do catálogo">
        <label class="search-field"><i data-lucide="search"></i><input id="search-input" type="search" placeholder="Buscar por nome, ex.: pikachu" value="${state.search}" autocomplete="off" /></label>
        <span class="result-label">${filtered.length.toLocaleString("pt-BR")} resultado(s)</span>
      </section>
      <section class="pokemon-grid" aria-label="Lista de Pokémon">
        ${currentPage.map((pokemon) => `
          <article class="pokemon-card">
            <span class="pokemon-number">Nº ${String(pokemon.id).padStart(4, "0")}</span>
            <h2>${titleCase(pokemon.name)}</h2>
            <a class="detail-button" href="#/pokemon/${pokemon.id}">Detalhes <i data-lucide="arrow-up-right"></i></a>
          </article>
        `).join("") || `<div class="state-panel"><p>Nenhum Pokémon encontrado para esta busca.</p></div>`}
      </section>
      <nav class="pagination" aria-label="Paginação">
        <button class="page-button" id="previous-page" type="button" ${state.page === 1 ? "disabled" : ""}>Anterior</button>
        <span class="page-indicator">Página ${state.page} de ${totalPages}</span>
        <button class="page-button" id="next-page" type="button" ${state.page === totalPages ? "disabled" : ""}>Próxima</button>
      </nav>
    </section>`;

  document.getElementById("search-input").addEventListener("input", (event) => {
    state.search = event.target.value.trim().toLowerCase();
    state.page = 1;
    renderList();
  });
  document.getElementById("previous-page").addEventListener("click", () => { state.page -= 1; renderList(); });
  document.getElementById("next-page").addEventListener("click", () => { state.page += 1; renderList(); });
  lucide.createIcons();
}

function spriteEntries(sprites) {
  return Object.entries(sprites)
    .filter(([key, value]) => typeof value === "string" && value && !key.includes("back"))
    .map(([key, value]) => ({ key: key.replaceAll("_", " "), value }));
}

function names(items) {
  return items.map((item) => titleCase(item.name));
}

function escapeHtml(value) {
  return value.replace(/[&<>"]/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;",
  })[character]);
}

function renderNamedCollection(title, items, emptyMessage) {
  return `<details><summary>${title} (${items.length})</summary><div class="name-list">${items.length ? names(items).map((name) => `<span class="tag subtle">${name}</span>`).join("") : `<span class="tag subtle">${emptyMessage}</span>`}</div></details>`;
}

function renderDetail(pokemon) {
  const artwork = pokemon.sprites.other?.["official-artwork"]?.front_default || pokemon.sprites.front_default;
  const homeArtwork = pokemon.sprites.other?.home?.front_default;
  const sprites = spriteEntries({
    "official artwork": artwork,
    "home artwork": homeArtwork,
    front_default: pokemon.sprites.front_default,
    front_shiny: pokemon.sprites.front_shiny,
    front_female: pokemon.sprites.front_female,
  });
  const orderedStats = pokemon.stats.map((stat) => ({ name: titleCase(stat.stat.name), value: stat.base_stat }));
  const maximumStat = Math.max(...orderedStats.map((stat) => stat.value), 1);

  app.innerHTML = `
    <section class="shell">
      <a class="back-link" href="#/"><i data-lucide="arrow-left"></i> Voltar ao catálogo</a>
      <section class="pokemon-hero" aria-labelledby="pokemon-title">
        <div class="artwork-stage">${artwork ? `<img src="${artwork}" alt="Ilustração oficial de ${titleCase(pokemon.name)}" />` : `<i data-lucide="image-off"></i>`}</div>
        <div class="pokemon-overview">
          <p class="eyebrow">Ficha da PokeAPI</p>
          <div class="meta-line"><span>Nº ${String(pokemon.id).padStart(4, "0")}</span><span>Ordem ${pokemon.order}</span></div>
          <h1 id="pokemon-title">${titleCase(pokemon.name)}</h1>
          <div class="types">${pokemon.types.map((type) => `<span class="tag">${titleCase(type.type.name)}</span>`).join("")}</div>
          ${pokemon.cries?.latest ? `<audio controls src="${pokemon.cries.latest}">Seu navegador não suporta áudio.</audio>` : ""}
        </div>
      </section>
      <section class="detail-grid">
        <article class="detail-panel"><h2>Dados físicos</h2><div class="facts">
          <div class="fact"><span>Altura</span><strong>${(pokemon.height / 10).toLocaleString("pt-BR")} m</strong></div>
          <div class="fact"><span>Peso</span><strong>${(pokemon.weight / 10).toLocaleString("pt-BR")} kg</strong></div>
          <div class="fact"><span>Experiência base</span><strong>${pokemon.base_experience ?? "-"}</strong></div>
          <div class="fact"><span>Espécie</span><strong>${titleCase(pokemon.species.name)}</strong></div>
        </div></article>
        <article class="detail-panel"><h2>Habilidades</h2><div class="ability-list">${pokemon.abilities.map((entry) => `<span class="tag ${entry.is_hidden ? "subtle" : ""}">${titleCase(entry.ability.name)}${entry.is_hidden ? " (oculta)" : ""}</span>`).join("")}</div></article>
        <article class="detail-panel full"><h2>Estatísticas base</h2><div class="stat-list">${orderedStats.map((stat) => `<div><div class="stat-heading"><span>${stat.name}</span><strong>${stat.value}</strong></div><div class="stat-track"><div class="stat-fill" style="width:${Math.min(100, (stat.value / maximumStat) * 100)}%"></div></div></div>`).join("")}</div></article>
        <article class="detail-panel full"><h2>Galeria de sprites</h2><div class="sprite-gallery">${sprites.map((sprite) => `<figure class="sprite-tile"><img src="${sprite.value}" alt="Sprite ${sprite.key} de ${titleCase(pokemon.name)}" /><figcaption>${sprite.key}</figcaption></figure>`).join("") || "<p>Nenhum sprite disponível.</p>"}</div></article>
        <article class="detail-panel full"><h2>Outros dados do retorno</h2>
          ${renderNamedCollection("Movimentos", pokemon.moves.map((move) => move.move), "Nenhum movimento")}
          ${renderNamedCollection("Formas", pokemon.forms, "Nenhuma forma")}
          ${renderNamedCollection("Itens carregados", pokemon.held_items.map((item) => item.item), "Nenhum item")}
          ${renderNamedCollection("Versões de jogo", pokemon.game_indices.map((entry) => entry.version), "Nenhuma versão")}
          <details><summary>Resposta completa da PokeAPI</summary><pre class="json-view">${escapeHtml(JSON.stringify(pokemon, null, 2))}</pre></details>
        </article>
      </section>
    </section>`;
  lucide.createIcons();
}

async function route() {
  const match = location.hash.match(/^#\/pokemon\/(\d+)$/);
  try {
    showLoading();
    if (match) {
      renderDetail(await fetchJson(`${API_ROOT}/pokemon/${match[1]}/`));
      return;
    }
    await loadPokemonList();
    renderList();
  } catch (error) {
    showError(`Não foi possível carregar os dados. ${error.message}`);
  }
}

document.getElementById("theme-button").addEventListener("click", () => {
  document.documentElement.dataset.theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
  route();
});
window.addEventListener("hashchange", route);
route();