# 1Password Secret Export Action

A GitHub Action that securely exports secrets from 1Password vaults to environment variables or `.env` files in GitHub Actions workflows.

## Description

This action uses the 1Password CLI to fetch secrets from a specified vault and item, then makes them available as environment variables in your GitHub Actions workflow or optionally creates a `.env` file. It includes security validations to ensure only allowed item categories are processed.

## Features

- Exports secrets from 1Password vaults to GitHub Actions environment variables
- Optional creation of `.env` files with exported secrets
- Support for specific sections within 1Password items
- Security validation (only allows SECURE_NOTE category items)
- Error handling with detailed error reporting

## Inputs

| Input              | Description                                               | Required | Default            |
| ------------------ | --------------------------------------------------------- | -------- | ------------------ |
| `vault`            | 1Password vault name or ID                                | Yes      | -                  |
| `item`             | 1Password item name or ID                                 | Yes      | -                  |
| `token`            | 1Password service account token                           | Yes      | -                  |
| `sections`         | Comma-separated list of 1Password item sections to export | No       | `''` (exports all) |
| `export_variables` | Export secrets to GitHub Actions environment variables    | No       | `true`             |
| `create_env_file`  | Create a `.env` file with the secrets                     | No       | `false`            |

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
    export_environment_variables: "false"
    create_dot_env_file: "true"
```

## Requirements

- 1Password service account token stored as a GitHub secret
- 1Password item must be of category `SECURE_NOTE`
- The action automatically installs the 1Password CLI

## Security Considerations

- Only items with category `SECURE_NOTE` are allowed for security reasons
- Service account tokens should be stored as GitHub encrypted secrets
- The action uses error handling to prevent sensitive information leakage
- Fields named `notesPlain` are automatically excluded from export

## Environment Variables

The action sets the following internal environment variables:

- `OP_VAULT`: The vault name/ID
- `OP_ITEM`: The item name/ID
- `OP_SERVICE_ACCOUNT_TOKEN`: The service account token
- `OP_SECTIONS`: The sections to export
- `OP_EXPORT_ENVIRONMENT_VARIABLES`: Whether to export to env vars
- `OP_CREATE_DOT_ENV_FILE`: Whether to create .env file

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
