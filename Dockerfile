# --------- Stage 1: Build ---------
FROM node:18 AS builder

# Set working directory inside container
WORKDIR /app

# Copy package.json and lock file
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the Strapi Admin UI
RUN npm run build

# --------- Stage 2: Runtime ---------
FROM node:18-slim AS runner

# Set working directory
WORKDIR /app

# Copy package.json and install only production dependencies
COPY package*.json ./
RUN npm install --production

# Copy built app from builder stage
COPY --from=builder /app ./

# Expose Strapi default port
EXPOSE 1337

# Start the Strapi server in production mode
CMD ["npm", "start"]
