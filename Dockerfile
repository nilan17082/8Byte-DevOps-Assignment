FROM node:20-alpine

# Upgrade OS packages and update the global npm binary to the latest patched version
RUN apk update && apk upgrade --no-cache && \
    npm install -g npm@latest

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

EXPOSE 3000
CMD ["npm", "start"]