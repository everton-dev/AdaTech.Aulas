# Bootstrap Product Management Website

This project is a simple web application for managing products using Bootstrap for styling and layout. It allows users to query, add, update, and delete products through a service hosted at `https://meuservico.azure.com`.

## Project Structure

```
bootstrap-website
├── src
│   ├── css
│   │   └── styles.css        # Custom CSS styles for the website
│   ├── js
│   │   └── scripts.js        # JavaScript functions for handling HTTP requests
│   ├── index.html            # Main HTML file with Bootstrap components
│   └── products.html         # HTML file for displaying and managing products
├── package.json              # npm configuration file
└── README.md                 # Project documentation
```

## Setup Instructions

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd bootstrap-website
   ```

2. **Install dependencies** (if any):
   ```
   npm install
   ```

3. **Open the project**:
   Open `src/index.html` in your web browser to view the application.

## Usage Guidelines

- **Query Products**: Navigate to the products page to view the list of existing products.
- **Add a Product**: Use the form on the products page to add a new product.
- **Update a Product**: Select a product from the list and update its details using the provided form.
- **Delete a Product**: Click the delete button next to a product to remove it from the list.

## Additional Information

- The application uses Bootstrap for responsive design and layout.
- JavaScript functions in `src/js/scripts.js` handle all interactions with the product management service.
- Custom styles can be added in `src/css/styles.css` to enhance the appearance of the application.