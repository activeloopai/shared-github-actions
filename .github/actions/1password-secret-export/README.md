# 1Password Secret Export Action

A GitHub Action that securely exports secrets from 1Password to GitHub Actions workflows and optionally to `.env` file.

## Description

This action uses the 1Password CLI to fetch secrets from a specified vault and item, then makes them available as environment variables in your GitHub Actions workflow or optionally creates a `.env` file. Currently only `SECURE_NOTE` item types are supported.

## Features

- Exports secrets from 1Password vaults to GitHub Actions environment variables
- Optional creation of `.env` files with exported secrets
- Support for specific sections within 1Password items
  - merge same values from sections, merge order is the same as section names, at the end it will be merged with root keys

## Supported item categories

- secure notes

## Inputs

| Input              | Description                                               | Required | Default                       |
| ------------------ | --------------------------------------------------------- | -------- | ----------------------------- |
| `vault`            | 1Password vault name or ID                                | Yes      | -                             |
| `item`             | 1Password item name or ID                                 | Yes      | -                             |
| `token`            | 1Password service account token                           | Yes      | -                             |
| `sections`         | Comma-separated list of 1Password item sections to export | No       | `''` (exports only root keys) |
| `export_variables` | Export secrets to GitHub Actions environment variables    | No       | `true`                        |
| `export_to_file`   | Whether to create .env file (appends if exist)            | No       | `false`                       |

## Usage

### Basic Usage

```yaml
- name: Export secrets from 1Password
  uses: ./.github/actions/1password-secret-export
  with:
    vault: "my-vault"
    item: "my-secrets"
    token: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

### Export Specific Sections

```yaml
- name: Export database secrets
  uses: ./.github/actions/1password-secret-export
  with:
    vault: "production"
    item: "database-config"
    token: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    sections: "database,redis"
```

### Create .env File

```yaml
- name: Export to .env file
  uses: ./.github/actions/1password-secret-export
  with:
    vault: "development"
    item: "app-secrets"
    token: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    export_variables: "false"
    export_to_file: "true"
```

## Requirements

- 1Password service account token stored as a GitHub secret
- 1Password item must be of category `SECURE_NOTE`
- The action automatically installs the 1Password CLI

## Environment Variables

The action sets the following internal environment variables:

- `OP_VAULT`: The vault name/ID
- `OP_ITEM`: The item name/ID
- `OP_SERVICE_ACCOUNT_TOKEN`: The service account token
- `OP_SECTIONS`: The sections to export
- `EXPORT_VARIABLES`: Whether to export to env vars
- `EXPORT_TO_FILE`: Whether to create .env file (appends if exist)

## Error Handling

The action includes comprehensive error handling:

- Validates required environment variables
- Checks item category restrictions
- Provides detailed error messages with line numbers
- Fails fast on any error condition

## Example Workflow

```yaml
name: Deploy Application

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Export production secrets
        uses: ./.github/actions/1password-secret-export
        with:
          vault: "production"
          item: "app-secrets"
          token: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}

      - name: Deploy application
        run: |
          # Your deployment commands here
          # Secrets are now available as environment variables
```
