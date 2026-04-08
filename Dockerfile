FROM node:20-alpine

# Install language runtimes
RUN apk add --no-cache python3 py3-pip gcc g++ musl-dev go bash

WORKDIR /app

# Copy server files
COPY server/package*.json ./server/
RUN cd server && npm install --production

# Copy all files
COPY . .

EXPOSE 3000
CMD ["node", "server/index.js"]
