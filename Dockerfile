# --------- Stage 1: Build ---------
FROM node:18 AS builder

# Set working directory
WORKDIR /app

# Copy only package files
COPY package*.json ./

# Install dependencies (including dev)
RUN npm install

# Copy rest of the app
COPY . .

# Build admin panel
RUN npm run build

# --------- Stage 2: Production ---------
FROM node:18-slim AS runner

# Set working directory
WORKDIR /app

# Copy only package files for production install
COPY package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy everything from builder except dev dependencies
COPY --from=builder /app .

# Expose port
EXPOSE 1337

# Run in production
CMD ["npm", "start"]
