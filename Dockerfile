# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Production stage
FROM node:20-alpine

WORKDIR /app

# Créer un user non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copier les dépendances depuis le build stage
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copier le code source
COPY --chown=nodejs:nodejs index.js ./
COPY --chown=nodejs:nodejs package*.json ./

# Utiliser le user non-root
USER nodejs

# Exposer le port
EXPOSE 3001

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/status', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

# Démarrer l'application
CMD ["node", "index.js"]

