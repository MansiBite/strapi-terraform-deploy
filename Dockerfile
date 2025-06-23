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

# Copy built app from builder stage
COPY --from=builder /app /app

# Install only production dependencies (already copied package.json from builder)
RUN npm install --omit=dev

EXPOSE 1337

CMD ["npm", "start"]
