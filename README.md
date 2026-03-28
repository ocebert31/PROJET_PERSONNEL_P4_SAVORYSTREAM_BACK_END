# SavoryStream — back-end (API)

API **Rails 8.1** en mode **API-only** (PostgreSQL, authentification par mot de passe, CORS pour le front). Aujourd’hui centrée sur l’**authentification** ; le reste du contrat et de la stack est décrit dans Notion.

## Documentation

La **spec complète** (routes, contrat JSON, validations, structure, tests, CI, Dependabot…) est sur Notion :

**[Spec — Savorystream Back-End - Documentation API](https://www.notion.so/32fd2d722f2d81fb9c99eb55f1b5470b)**

## Stack (résumé)

| Domaine        | Choix principaux                          |
|----------------|-------------------------------------------|
| Langage        | Ruby 3.4.9                                |
| Framework      | Rails 8.1 (API-only)                      |
| Base de données| PostgreSQL                                |
| Auth           | `bcrypt` / `has_secure_password`          |
| CORS           | `rack-cors`                               |
| Tests          | RSpec (`rspec-rails`)                     |
| Qualité        | RuboCop, Brakeman, bundler-audit          |

## Structure du dépôt (aperçu)

- `app/controllers/api/v1/` — API versionnée (ex. `users/registrations`).
- `app/models/` — Active Record.
- `spec/` — specs **modèle** et **request** (contrat HTTP).
- `.github/` — **CI** (`workflows/ci.yml`), **Dependabot** (`dependabot.yml`).

Le détail des flux et conventions : **spec Notion**.

## Prérequis & installation

- **Ruby** 3.4.9 (voir `.ruby-version`) · **PostgreSQL** · **Bundler**
- À la racine : `bundle install` puis `bin/rails db:prepare` (adapter `config/database.yml` si besoin).

## Variables d’environnement

| Variable           | Rôle |
|--------------------|------|
| `CORS_ORIGINS`     | Origines autorisées pour `/api/*`, séparées par des virgules (défaut : `http://localhost:5173`). |
| `RAILS_MASTER_KEY` | Prod / CI si tu n’as pas `config/master.key` en local. |

Ne pas versionner `master.key`, `.env` ni secrets.

## Commandes utiles

| Commande        | Usage |
|-----------------|--------|
| `bin/rails server` | API locale ([localhost:3000](http://localhost:3000)) |
| `bin/rspec`        | Suite de tests (`bin/rails db:test:prepare` si la DB test manque) |
| `bin/ci`           | Enchaînement proche de la CI (lint, sécu, specs) |

`GET /up` : health check. Préfixe API actuel : **`/api/v1`** (détail des routes : **spec Notion**).

## Qualité & intégration continue

Les **pull requests** et les **push** sur `main` déclenchent la **CI** (audit gems, RuboCop, RSpec avec PostgreSQL). Comportement exact et **Dependabot** : **spec Notion**.
