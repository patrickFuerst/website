FROM docker.io/library/caddy:2.10-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d

# Run as a fixed, unprivileged UID/GID. Defense in depth: under rootless Podman
# the container is already unprivileged on the host, but a non-root process in
# the container also cannot write the image filesystem if it is compromised.
RUN addgroup -g 10001 -S web \
 && adduser -u 10001 -S -G web web \
 # Serving on :3000 needs no privileged port, so strip the binary's
 # cap_net_bind_service file capability; that lets the container run with
 # no-new-privileges and all Linux capabilities dropped.
 && setcap -r /usr/bin/caddy

COPY --chown=10001:10001 Caddyfile /etc/caddy/Caddyfile
COPY --chown=10001:10001 public/ /srv/

# Keep every writable path caddy touches inside a single tmpfs mount, so the
# rest of the root filesystem can be mounted read-only at runtime.
ENV XDG_CONFIG_HOME=/tmp XDG_DATA_HOME=/tmp

USER 10001:10001

EXPOSE 3000

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
