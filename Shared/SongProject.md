# Song Project Contract

A Song Project is the portable unit shared by the native Apple client and web studio.

## Required fields

- `id`
- `title`
- `brief`
- `language`
- `lyrics`
- `style`
- `mood`
- `durationSeconds`
- `producerMode`
- `generationEngine`
- `createdAt`
- `updatedAt`

## Producer modes

- `local`: prefer on-device Core AI.
- `cloud`: use configured cloud engines.
- `hybrid`: use Core AI for planning/analysis and cloud engines for music generation.

## Design rule

The project format must not contain API secrets or provider authentication material.
