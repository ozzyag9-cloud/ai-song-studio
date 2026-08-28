# STUDIOFLOW MVP

STUDIOFLOW is the cross-platform web companion for AI Song Studio. The implementation is intentionally provider-agnostic so a working studio can ship before heavyweight GPU providers are configured.

## Current deployment

- Public app: https://studioflow-ilyxr9.v2.appdeploy.ai/
- Deployment: AppDeploy
- Branch: `studioflow`
- Backend persistence: AppDeploy database
- Frontend: Next.js static export
- Backend: TypeScript API routes

## Functional workflows

1. Create a song brief with title, genre, mood, tempo, key, lyrics/creative direction and voice model.
2. Persist projects through the backend.
3. Run the STUDIOFLOW production pipeline and persist a generated track record.
4. Display the generated output, metadata, pipeline stages and recent tracks.
5. Recover projects and tracks after reload.
6. Validate required song title and surface backend failures.
7. Responsive mobile studio layout.

## Provider architecture

The current release uses a deterministic Studioflow Demo Provider for the generation workflow. This keeps the application fully testable and usable without paid GPU infrastructure. The provider boundary is designed to be replaced by YuE, MusicGen, ElevenLabs, RVC/F5-TTS and mastering services without changing the studio UX.

## Next production integrations

- YuE / MusicGen GPU provider adapter
- Supabase Auth + PostgreSQL migration
- Cloudflare R2 audio storage and signed URLs
- Celery/Redis worker orchestration
- Real waveform/audio assets
- RVC/F5-TTS voice pipeline
- FFmpeg/Matchering mastering

## Security

No provider keys or secrets are stored in source control. Production credentials belong in platform secret storage.
