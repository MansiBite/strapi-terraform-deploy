# --------- Stage 1: Build ---------
FROM node:18 AS builder

# Set working directory
WORKDIR /app

# Copy only package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the entire project and build the Strapi admin panel
COPY . .
RUN npm run build

# --------- Stage 2: Runtime ---------
FROM node:18-slim AS runner

# Install only production dependencies
WORKDIR /app
COPY package*.json ./
RUN npm install --production

# Copy built project from builder
COPY --from=builder /app ./

# Expose Strapi default port
EXPOSE 1337

# Start the app
CMD ["npm", "start"]