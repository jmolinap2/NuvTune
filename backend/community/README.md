# NuvTune Comunidad (backend)

Worker de Cloudflare + D1. Fase 1: cuentas y amistades. El audio no pasa por aqui.

## Desplegar (una vez)

```powershell
cd backend/community
pnpm install
pnpm exec wrangler login
pnpm exec wrangler d1 create nuvtune-community   # copia el database_id a wrangler.toml
pnpm db:init                                      # crea las tablas en la nube
pnpm deploy                                       # imprime la URL *.workers.dev
```

Pega esa URL en `CommunityApi.baseUrl` (`lib/features/community/community_api.dart`).

## Probar en local

```powershell
pnpm db:init:local
pnpm dev        # http://127.0.0.1:8787
```

## Pendiente conocido

- Sin limite de intentos de login: activa una regla de Rate Limiting de Cloudflare
  sobre `/login` y `/register` antes de abrirlo a mas gente.
