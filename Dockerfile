# SearXNG for Hugging Face Docker Spaces.
# Keep the upstream entrypoint; only force Granian onto port 7860 (HF requirement).

FROM docker.io/searxng/searxng:latest

USER root

COPY settings.yml /etc/searxng/settings.yml
COPY entrypoint.sh /hf-entrypoint.sh

RUN chmod +x /hf-entrypoint.sh \
    && chown -R 977:977 /etc/searxng /hf-entrypoint.sh \
    && sed -i 's/change-me-on-start/zuzu-searxng-hf-replace-via-SEARXNG_SECRET/' /etc/searxng/settings.yml || true

# HF Spaces expect listen on 7860 (upstream default is 8080).
ENV GRANIAN_HOST="0.0.0.0" \
    GRANIAN_PORT="7860" \
    GRANIAN_INTERFACE="wsgi" \
    GRANIAN_WEBSOCKETS="false" \
    SEARXNG_SETTINGS_PATH="/etc/searxng/settings.yml" \
    FORCE_OWNERSHIP="false"

EXPOSE 7860

# Patch secret then hand off to upstream /usr/local/searxng/entrypoint.sh
ENTRYPOINT ["/hf-entrypoint.sh"]
