FROM nginx:1.31.3-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html app.js product-shelf.svg /usr/share/nginx/html/

EXPOSE 80