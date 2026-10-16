# syntax=docker/dockerfile:1.7
FROM node:20-bookworm-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS base
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --omit=dev
COPY src ./src
USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
