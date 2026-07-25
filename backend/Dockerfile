# ---- Build stage ----
FROM node:20-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
COPY prisma ./prisma
RUN npm install
COPY . .
RUN npx prisma generate && npm run build

# ---- Runtime stage ----
FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN apt-get update && apt-get install -y openssl ca-certificates \
    chromium fonts-liberation && rm -rf /var/lib/apt/lists/*
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
COPY package*.json ./
COPY prisma ./prisma
RUN npm install --omit=dev && npx prisma generate
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main"]
