// This file contains JavaScript functions to handle HTTP requests for querying, adding, updating, and deleting products.

const apiUrl = 'https://meuservico.azure.com/products';

// Function to fetch and display products
async function fetchProducts() {
    try {
        const response = await fetch(apiUrl);
        const products = await response.json();
        displayProducts(products);
    } catch (error) {
        console.error('Error fetching products:', error);
    }
}

// Function to display products in the UI
function displayProducts(products) {
    const productList = document.getElementById('product-list');
    productList.innerHTML = '';
    products.forEach(product => {
        const productItem = document.createElement('div');
        productItem.className = 'product-item';
        productItem.innerHTML = `
            <h5>${product.name}</h5>
            <p>${product.description}</p>
            <button onclick="deleteProduct('${product.id}')">Delete</button>
            <button onclick="showUpdateForm('${product.id}', '${product.name}', '${product.description}')">Update</button>
        `;
        productList.appendChild(productItem);
    });
}

// Function to add a new product
async function addProduct(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const product = {
        name: formData.get('name'),
        description: formData.get('description')
    };

    try {
        await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(product)
        });
        fetchProducts();
    } catch (error) {
        console.error('Error adding product:', error);
    }
}

// Function to delete a product
async function deleteProduct(productId) {
    try {
        await fetch(`${apiUrl}/${productId}`, {
            method: 'DELETE'
        });
        fetchProducts();
    } catch (error) {
        console.error('Error deleting product:', error);
    }
}

// Function to show the update form with existing product data
function showUpdateForm(productId, name, description) {
    const updateForm = document.getElementById('update-form');
    updateForm.elements['id'].value = productId;
    updateForm.elements['name'].value = name;
    updateForm.elements['description'].value = description;
}

// Function to update a product
async function updateProduct(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const productId = formData.get('id');
    const product = {
        name: formData.get('name'),
        description: formData.get('description')
    };

    try {
        await fetch(`${apiUrl}/${productId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(product)
        });
        fetchProducts();
    } catch (error) {
        console.error('Error updating product:', error);
    }
}

// Initial fetch of products when the page loads
document.addEventListener('DOMContentLoaded', fetchProducts);