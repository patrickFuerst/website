FROM docker.io/library/caddy:2.10-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d

COPY public/ /srv/

EXPOSE 3000

CMD ["caddy", "file-server", "--root", "/srv", "--listen", ":3000"]
