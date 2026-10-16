FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
USER root
CMD ["node", "server.js"]
