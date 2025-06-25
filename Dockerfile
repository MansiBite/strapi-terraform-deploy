# --------- Strapi Dev Mode Image ---------
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install Strapi CLI globally
RUN npm install -g strapi@latest

# Copy project files
COPY . .

# Install dependencies
RUN npm install

# ⚠️ Do NOT build admin panel
# RUN npm run build 

# Expose Strapi default port
EXPOSE 1337

# Set environment to development (also done in ECS task but safe here too)
ENV NODE_ENV=development

# Start Strapi in development mode
CMD ["npm", "run", "develop"]
