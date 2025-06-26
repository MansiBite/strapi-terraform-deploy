# Dockerfile → for ECS Production
FROM node:18

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install --legacy-peer-deps

COPY . .

# Build admin UI for production
RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "start"]
