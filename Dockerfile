# Use slim version for smaller image size
FROM node:18-slim

# Set working directory
WORKDIR /app

# Install dependencies separately to leverage Docker layer caching
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps

# Copy rest of the app
COPY . .

# Build admin UI for production
RUN npm run build

# Expose port used by Strapi
EXPOSE 1337

# Start Strapi in production mode
CMD ["npm", "run", "start"]
