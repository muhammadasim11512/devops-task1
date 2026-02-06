FROM nginx:1.25-alpine
RUN addgroup -g 1001 appuser && \
    adduser -D -u 1001 -G appuser appuser && \
    chown -R appuser:appuser /usr/share/nginx/html /var/cache/nginx /var/run
COPY --chown=appuser:appuser *.html *.css *.js /usr/share/nginx/html/
COPY --chown=appuser:appuser nginx.conf /etc/nginx/nginx.conf
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
