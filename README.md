# patrickfuerst.at

Personal website of Patrick Fürst. A static site served by Caddy, packaged as
a container image.

- `public/` — the static site
- `Caddyfile` — serves `public/` on port 3000 and sets response security
  headers (HSTS is left to the rootful edge, which terminates TLS)
- `Dockerfile` — Caddy image running as a non-root user on port 3000
- `deploy/app-website.container` — the rootless Podman Quadlet (read-only
  rootfs, dropped capabilities, resource limits) installed on the host by the
  deployment workflow

## Local preview

```sh
podman run --rm -p 4173:3000 \
  -v ./public:/srv:ro -v ./Caddyfile:/etc/caddy/Caddyfile:ro \
  docker.io/library/caddy:2.10-alpine \
  caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
```

Open <http://localhost:4173>. (Or any static file server over `public/`.)

## Deployment

Pushes to `main` build and publish
`ghcr.io/patrickfuerst/website` (immutable `sha-<commit>` tag plus a moving
`main` tag), then install the resulting digest as the `app-website` rootless
Quadlet under the dedicated `website` account on the
[infra](https://github.com/patrickFuerst/infra)-managed host. The host does
not check out this repository. Caddy's rootful edge (infra repo) proxies the
apex to the Quadlet's loopback-only port `127.0.0.1:18080`; DNS lives on
Cloudflare, managed by the infra repo's OpenTofu.

The `production` environment needs three secrets:

| Name | Purpose |
|---|---|
| `DEPLOY_TARGET` | SSH destination for the deploy account, `user@host` (kept out of this public repo; masked in Actions logs) |
| `WEBSITE_DEPLOY_SSH_KEY` | restricted deploy key for the `website` account (1Password: `website-ssh-key-deploy`) |
| `WEBSITE_DEPLOY_KNOWN_HOSTS` | pinned host key line for the production host, obtained over a trusted channel |
