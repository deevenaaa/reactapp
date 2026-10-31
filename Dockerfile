# ---- Stage 1: Build ----
FROM node:24-alpine AS build
WORKDIR /app
# Copy dependency manifests first for better layer caching
COPY package.json package-lock.json ./
# Install dependencies (ci ensures a clean, reproducible install)
RUN npm ci
# Copy the rest of the source code
COPY . .
# Build the production bundle
RUN npm run build
# ---- Stage 2: Serve ----
FROM nginx:1.27-alpine
# Remove default Nginx static assets & config
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf
# Copy the custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy the production build from the build stage
COPY --from=build /app/build /usr/share/nginx/html
# Expose port 80
EXPOSE 80
# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]