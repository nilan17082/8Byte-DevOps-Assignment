# Stage 1: Build Stage (Includes Node & npm)
FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./

# Install production dependencies
RUN npm install --omit=dev

# Copy application source code
COPY . .

# Stage 2: Production Stage (Lean, No npm)
FROM alpine:3.21

# Install only the Node.js runtime (no npm)
RUN apk add --no-cache nodejs

WORKDIR /app

# Copy the app and installed dependencies from the builder stage
COPY --from=builder /app ./

# Create a non-root user for better security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

# Run the app directly with node, bypassing npm entirely
CMD ["node", "app.js"]