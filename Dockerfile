FROM node:22-slim

# 1. Installing essential system libraries
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# 2. Pinning pnpm to version 10 to prevent version conflicts
RUN npm install -g pnpm@10

# 3. Set the working directory (All files created hereafter will be owned by 'node').
WORKDIR /home/node/app

# 4. Create the volume mount directory as root and transfer ownership to user 'node' (UID 1000)
RUN mkdir -p /home/node/app/node_modules /home/node/app/.next \
    && chown -R 1000:1000 /home/node/app

# 5. Change the runtime user to 'node' for all subsequent operations
USER node
EXPOSE 3000
