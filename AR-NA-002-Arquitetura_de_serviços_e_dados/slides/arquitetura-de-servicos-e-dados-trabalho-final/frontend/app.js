const apiUrl = "/api/products";
const form = document.querySelector("#product-form");
const nameInput = document.querySelector("#product-name");
const counter = document.querySelector("#name-counter");
const title = document.querySelector("#form-title");
const hint = document.querySelector("#form-hint");
const submitButton = document.querySelector("#submit-button");
const cancelButton = document.querySelector("#cancel-button");
const list = document.querySelector("#product-list");
const message = document.querySelector("#list-message");
const count = document.querySelector("#product-count");
const toast = document.querySelector("#toast");
let editingId = null;
let products = [];

const icons = {
  edit: '<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>',
  remove: '<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M8 6V4h8v2m-9 0 1 14h8l1-14M10 11v5m4-5v5"/></svg>'
};

function showToast(text) {
  toast.textContent = text;
  toast.hidden = false;
  setTimeout(() => { toast.hidden = true; }, 2800);
}

async function request(url, options) {
  const response = await fetch(url, options);
  if (response.status === 204) return null;
  const body = await response.json();
  if (!response.ok) throw new Error(body.error ?? "Não foi possível concluir a operação.");
  return body;
}

function createIconButton(label, icon, action) {
  const button = document.createElement("button");
  button.className = "icon-button";
  button.type = "button";
  button.title = label;
  button.setAttribute("aria-label", label);
  button.innerHTML = icon;
  button.addEventListener("click", action);
  return button;
}

function renderProducts() {
  list.replaceChildren();
  count.textContent = `${products.length} ${products.length === 1 ? "produto" : "produtos"}`;
  message.hidden = products.length > 0;
  message.textContent = products.length ? "" : "Nenhum produto cadastrado.";

  products.forEach((product) => {
    const item = document.createElement("li");
    item.className = "product";
    const id = document.createElement("span");
    id.className = "product-id";
    id.textContent = product.id;
    const name = document.createElement("span");
    name.className = "product-name";
    name.textContent = product.name;
    const actions = document.createElement("div");
    actions.className = "row-actions";
    actions.append(
      createIconButton("Editar produto", icons.edit, () => startEditing(product)),
      createIconButton("Excluir produto", icons.remove, () => removeProduct(product))
    );
    item.append(id, name, actions);
    list.append(item);
  });
}

async function loadProducts() {
  try {
    products = await request(apiUrl);
    renderProducts();
  } catch (error) {
    message.hidden = false;
    message.textContent = error.message;
    count.textContent = "Indisponível";
  }
}

function resetForm() {
  editingId = null;
  form.reset();
  counter.textContent = "0/50";
  title.textContent = "Novo produto";
  hint.textContent = "Adicione um item ao catálogo.";
  submitButton.textContent = "Adicionar";
  cancelButton.hidden = true;
}

function startEditing(product) {
  editingId = product.id;
  nameInput.value = product.name;
  counter.textContent = `${product.name.length}/50`;
  title.textContent = "Editar produto";
  hint.textContent = `Atualizando o item #${product.id}.`;
  submitButton.textContent = "Salvar";
  cancelButton.hidden = false;
  nameInput.focus();
}

async function removeProduct(product) {
  if (!confirm(`Excluir "${product.name}"?`)) return;
  try {
    await request(`${apiUrl}/${product.id}`, { method: "DELETE" });
    if (editingId === product.id) resetForm();
    showToast("Produto excluído.");
    await loadProducts();
  } catch (error) {
    showToast(error.message);
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const name = nameInput.value.trim();
  if (!name) return;
  submitButton.disabled = true;
  try {
    await request(editingId ? `${apiUrl}/${editingId}` : apiUrl, {
      method: editingId ? "PUT" : "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name })
    });
    showToast(editingId ? "Produto atualizado." : "Produto adicionado.");
    resetForm();
    await loadProducts();
  } catch (error) {
    showToast(error.message);
  } finally {
    submitButton.disabled = false;
  }
});

nameInput.addEventListener("input", () => { counter.textContent = `${nameInput.value.length}/50`; });
cancelButton.addEventListener("click", resetForm);
loadProducts();