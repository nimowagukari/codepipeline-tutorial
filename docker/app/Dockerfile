# ビルド用コンテナ
FROM node:18.17.0-alpine as builder

COPY --chown=node:node package.json package-lock.json tsconfig.json /workspace/
COPY --chown=node:node src /workspace/src
WORKDIR /workspace
USER node

# パッケージインストール
RUN npm ci

# ts のビルド
RUN npx tsc



# Web コンテナ
FROM nginx:1.24-alpine
COPY --chown=nginx:nginx dist /usr/share/nginx/html
COPY --chown=nginx:nginx --from=builder /workspace/dist /usr/share/nginx/html
