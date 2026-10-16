FROM node:20-alpine

WORKDIR /app

COPY aula-07/dashboard/package.json ./
RUN npm install --omit=dev

COPY aula-07/dashboard/server.js ./
COPY aula-07/dashboard/public ./public
COPY slides/assets/ada_logo.png ./public/assets/ada_logo.png
COPY slides/assets/swirl_green.png ./public/assets/swirl_green.png

EXPOSE 8080

CMD ["npm", "start"]