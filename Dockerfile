FROM node:20-alpine

# Upgrade Alpine packages to patch OS-level security vulnerabilities
RUN apk update && apk upgrade --no-cache

WORKDIR /app

COPY package*.json ./

# Use modern --omit=dev instead of deprecated --production flag
RUN npm install --omit=dev

COPY . .

EXPOSE 3000

CMD ["npm", "start"]