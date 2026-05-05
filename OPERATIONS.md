# Meta.X Advisor — Manual Operacional

## Versionamento

Formato: `MAJOR.MINOR.PATCH`

| Tipo | Quando usar | Exemplo |
|------|-------------|---------|
| MAJOR (X.0.0) | Mudança estrutural que quebra compatibilidade | v2.0.0 — novo banco de dados |
| MINOR (1.X.0) | Novos módulos ou recursos significativos | v1.3.0 — módulo de relatórios |
| PATCH (1.1.X) | Correções de bugs e melhorias pequenas | v1.2.1 — fix mobile Safari |

**Regra:** atualizar `APP_VERSION` em `index.html` a cada deploy. O changelog (`CHANGELOG`) deve ter a nova entrada no topo.

---

## Política de Branches

| Branch | Ambiente | Regra |
|--------|----------|-------|
| `main` | Produção | Somente versões aprovadas e testadas |
| `staging` | Homologação | Validação interna antes de ir para prod |
| `dev` | Desenvolvimento | Ajustes e novas features em construção |

**Nunca** fazer push direto para `main` sem passar por `staging`.

---

## Checklist de Deploy

Antes de cada merge para `main`:

- [ ] Backup/export dos dados de produção realizado
- [ ] `APP_VERSION` incrementada
- [ ] Entrada adicionada no `CHANGELOG` dentro do `index.html`
- [ ] Testado no mobile (iOS Safari + Android Chrome)
- [ ] Testado no desktop (Chrome + Firefox)
- [ ] Dashboard renderizando sem erros no console
- [ ] Permissões de admin e líder validadas
- [ ] Nenhum `console.error` novo introduzido

---

## Rollback

Se um deploy quebrar produção:

1. Identificar o commit anterior estável com `git log --oneline`
2. Reverter: `git revert HEAD` (cria novo commit, não destrói histórico)
3. Push para `main`: `git push origin main`
4. Netlify faz redeploy automático em ~60s

**Nunca usar `git reset --hard` em `main`.**

---

## Preservação de Dados

O store é salvo em `localStorage` com a chave `metax_1to1_v3`.

A função `migrateStore()` em `index.html` garante:
- Campos novos são adicionados com valores padrão
- Registros antigos nunca são sobrescritos
- Novos campos entram como opcionais

Ao alterar a estrutura do store:
1. Adicionar campo novo em `migrateStore()` com valor padrão
2. **Nunca** mudar a chave `STORE_KEY` sem migrar os dados existentes

---

## Audit Log

Todas as ações críticas são registradas em `localStorage` com a chave `metax_audit_log`:

| Evento | Quando é registrado |
|--------|---------------------|
| `login` | Login bem-sucedido |
| `login_failed` | Tentativa de login com credencial errada |
| `session_saved` | Reunião 1:1 finalizada |
| `anamnese_completed` | Anamnese de líder concluída |
| `leader_deleted` | Líder removido do sistema |
| `data_exported` | Backup/export realizado |
| `changelog_viewed` | Usuário acessou novidades da versão |

O log mantém os últimos **500 registros**. Pode ser exportado via botão "Backup" na sidebar.

---

## Backup

O botão **⬇ Backup** na sidebar exporta um arquivo `metax-backup-YYYY-MM-DD.json` contendo:
- Todo o store (usuários, líderes, sessões, alertas, planos de ação, CEO Digital)
- Audit log completo
- Versão e data do export

**Recomendação:** realizar export antes de qualquer deploy em produção.

---

## Governança

| Papel | Permissões |
|-------|------------|
| Márcio (Owner/Admin) | Acesso total, aprovar versões, ver audit log, fazer backup |
| Tech Lead | Push para `staging`, criar PRs para `main` |
| Dev | Push para `dev`, criar PRs para `staging` |
| QA | Acesso de leitura ao staging, validar checklist |

---

## Monitoramento Recomendado

- **Netlify** — notificações de build failure (configurar em Site Settings > Notifications)
- **UptimeRobot** — monitor de uptime gratuito para `advisor.metax.ind.br`
- **Sentry** — captura de erros JS em produção (integração futura)

---

*Última atualização: 2026-05-05 — v1.2.0*
