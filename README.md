# ssp-channel-maker (ready to use)

Prepares films for the SMART STREAM PANEL feature "Create channel": uniform H.264/AAC encode on your NVIDIA GPU,
generated spots with your logo, and the `manifest.json` the panel needs. This repository holds the ready-made
folder; the program itself is in **Releases** (one static binary for Ubuntu 24.04, x86_64).

## English

1. Download `ssp-channel-maker-<version>.tar.gz` and its `.sha256` from the latest Release, then check it:
   `sha256sum -c ssp-channel-maker-<version>.tar.gz.sha256`
2. Extract it: `tar xzf ssp-channel-maker-<version>.tar.gz` and `cd ssp-channel-maker`.
3. Build ffmpeg with NVIDIA NVENC once: `./install-ffmpeg-nvenc.sh --yes` (puts ffmpeg and ffprobe in `bin/`).
4. Check the machine: `./ssp-channel-maker doctor`.
5. Optional: put your own TMDB key in `config.toml` (`tmdb_key = "..."`, then `chmod 600 config.toml`).
6. Put your cleaned films in `in/`, your logo in `logos/`, and follow `docs/QUICKSTART.md` (full guide: `docs/GUIDE.md`).

## Italiano

1. Scarica `ssp-channel-maker-<versione>.tar.gz` e il suo `.sha256` dall'ultima Release e controllalo:
   `sha256sum -c ssp-channel-maker-<versione>.tar.gz.sha256`
2. Estrailo: `tar xzf ssp-channel-maker-<versione>.tar.gz` e `cd ssp-channel-maker`.
3. Compila ffmpeg con NVIDIA NVENC una volta sola: `./install-ffmpeg-nvenc.sh --yes` (mette ffmpeg e ffprobe in `bin/`).
4. Controlla il PC: `./ssp-channel-maker doctor`.
5. Facoltativo: metti la tua chiave TMDB in `config.toml` (`tmdb_key = "..."`, poi `chmod 600 config.toml`).
6. Metti i film puliti in `in/`, il logo in `logos/` e segui `docs/QUICKSTART.md` (guida completa: `docs/GUIDE.md`).

The binary is not in this repository on purpose: only Releases carry it. Your TMDB key is personal: never share it.
