FROM docker.io/library/caddy:2.10-alpine

COPY public/ /srv/

EXPOSE 3000

CMD ["caddy", "file-server", "--root", "/srv", "--listen", ":3000"]
