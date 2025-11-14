FROM n8nio/n8n:latest

# Install any extra packages you need in the future
# RUN apk add --no-cache <your-package>

# Copy custom entrypoint if needed
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["n8n"]