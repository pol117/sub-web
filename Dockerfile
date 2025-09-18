# =========================
# Vue (Vite) SPA - Dockerfile
# 使用 pnpm@latest + 多阶段构建 + Nginx(使用项目根目录的 nginx.conf)
# =========================

# ---- deps：只安装依赖，最大化缓存命中 ----
FROM node:20-alpine AS deps
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY package.json pnpm-lock.yaml* ./
RUN pnpm fetch

# ---- build：实际打包 ----
FROM node:20-alpine AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY --from=deps /root/.local/share/pnpm /root/.local/share/pnpm
COPY --from=deps /app/pnpm-lock.yaml* ./
COPY package.json ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM nginx:1.24-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
# 拷贝构建产物
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
CMD ["nginx", "-g", "daemon off;"]
