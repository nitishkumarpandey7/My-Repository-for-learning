FROM node:22-alpine AS base
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
COPY migrations ./migrations
COPY seeds ./seeds
COPY scripts ./scripts
COPY swagger ./swagger

ENV NODE_ENV=production
EXPOSE 8080
CMD ["node", "src/server.js"]

