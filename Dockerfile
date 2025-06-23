# --------- Stage 1: Build ---------
FROM node:18 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# --------- Stage 2: Runtime ---------
FROM node:18-slim AS runner

WORKDIR /app

COPY --from=builder /app /app

RUN npm ci --omit=dev

EXPOSE 1337

CMD ["npm", "start"]
