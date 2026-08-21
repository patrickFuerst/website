# patrickfuerst.at

Personal website of Patrick Fürst. A static site served by Caddy, packaged as
a container image.

- `public/` — the static site
- `Caddyfile` — serves `public/` on port 3000 and sets response security
  headers (HSTS is left to the rootful edge, which terminates TLS)
- `Dockerfile` — Caddy image running as a non-root user on port 3000

The rootless Podman Quadlet that runs the image lives in the
[infra](https://github.com/patrickFuerst/infra) repository
(`roles/pf_website`), which owns the host deployment end to end.

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
`main` tag), then promote the resulting digest through the
[infra](https://github.com/patrickFuerst/infra) repository's
`promote-application.yml` release contract: infra records the digest in its
`WEBSITE_RELEASE` repository variable, runs its protected host deployment
(the `pf_website` Ansible role installs the Quadlet under the dedicated
`website` account), and verifies the result; this CI only watches that run.
This repository holds no SSH, host, or TLS credential, and the host never
checks out this repository. Keep the GHCR package public — the host pulls
the pinned digest anonymously. Caddy's rootful edge (infra repo) proxies the
apex to the Quadlet's loopback-only port `127.0.0.1:18080`; DNS lives on
Cloudflare, managed by the infra repo's OpenTofu.

Promotion authenticates with the `pf-infra-deploy` GitHub App, installed on
the infra repository with only the **Actions: read and write** permission:

| Location | Name | Purpose |
|---|---|---|
| Repository variable | `PF_DEPLOY_APP_CLIENT_ID` | client ID of the deployment GitHub App |
| Repository secret | `PF_DEPLOY_APP_PRIVATE_KEY` | private key of the deployment GitHub App (1Password: `github-deploy-app`) |

To redeploy the current `main` without a content change, re-run the Deploy
website workflow (or dispatch it manually); rollbacks happen on the infra
side by resetting `WEBSITE_RELEASE` and dispatching its deployment.
