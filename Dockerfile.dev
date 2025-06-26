# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /app

# Copy dependency files first
COPY package.json package-lock.json ./

# Install dependencies with no cache & ignore optional packages
RUN npm install --legacy-peer-deps

# Copy app files
COPY . .

# Expose Strapi default port
EXPOSE 1337

# Start in development mode
CMD ["npm", "run", "develop"]
