# ssp-channel-maker (ready to use)

Prepares films for the SMART STREAM PANEL feature "Create channel": uniform H.264/AAC encode on your NVIDIA GPU,
generated spots with your logo, and the `manifest.json` the panel needs. This repository IS the ready-made
folder, program included (one static binary for Ubuntu 24.04, x86_64); each version is also a tarball in **Releases**.

## English

1. Get the folder: `git clone https://github.com/michbott79-hue/ssp-channel-maker-dist.git ssp-channel-maker && cd ssp-channel-maker`
   (or download the tarball from the latest Release and extract it). Check the program: `sha256sum -c docs/ssp-channel-maker.sha256`.
2. Update later with `git pull`.
3. Build ffmpeg with NVIDIA NVENC once: `./install-ffmpeg-nvenc.sh --yes` (puts ffmpeg and ffprobe in `bin/`).
4. Check the machine: `./ssp-channel-maker doctor`.
5. Optional: put your own TMDB key in `config.toml` (`tmdb_key = "..."`, then `chmod 600 config.toml`).
6. Put your cleaned films in `in/`, your logo in `logos/`, and follow `docs/QUICKSTART.md` (full guide: `docs/GUIDE.md`).

## Italiano

1. Prendi la cartella: `git clone https://github.com/michbott79-hue/ssp-channel-maker-dist.git ssp-channel-maker && cd ssp-channel-maker`
   (oppure scarica il tarball dall'ultima Release ed estrailo). Controlla il programma: `sha256sum -c docs/ssp-channel-maker.sha256`.
2. Per aggiornare in seguito: `git pull`.
3. Compila ffmpeg con NVIDIA NVENC una volta sola: `./install-ffmpeg-nvenc.sh --yes` (mette ffmpeg e ffprobe in `bin/`).
4. Controlla il PC: `./ssp-channel-maker doctor`.
5. Facoltativo: metti la tua chiave TMDB in `config.toml` (`tmdb_key = "..."`, poi `chmod 600 config.toml`).
6. Metti i film puliti in `in/`, il logo in `logos/` e segui `docs/QUICKSTART.md` (guida completa: `docs/GUIDE.md`).

`example-spots/` has one sample spot (title "Example", no logo, 20 s countdown for the first seven, 10 s for the newer ones) for each built-in background: pick one with `--background NAME`.
In `example-spots/` trovi uno spot di esempio per ogni sfondo incluso: scegline uno con `--background NOME`.

Backgrounds (a still from each sample; the .mp4 files are in the same folder):

- `smoke1`: ![smoke1](example-spots/spot-smoke1.png)
- `smoke2`: ![smoke2](example-spots/spot-smoke2.png)
- `smoke3`: ![smoke3](example-spots/spot-smoke3.png)
- `gradient-blue`: ![gradient-blue](example-spots/spot-gradient-blue.png)
- `gradient-red`: ![gradient-red](example-spots/spot-gradient-red.png)
- `grain`: ![grain](example-spots/spot-grain.png)
- `black`: ![black](example-spots/spot-black.png)
- `smoke-gold`: ![smoke-gold](example-spots/spot-smoke-gold.png)
- `smoke-violet`: ![smoke-violet](example-spots/spot-smoke-violet.png)
- `smoke-teal`: ![smoke-teal](example-spots/spot-smoke-teal.png)
- `smoke-crimson`: ![smoke-crimson](example-spots/spot-smoke-crimson.png)
- `smoke-emerald`: ![smoke-emerald](example-spots/spot-smoke-emerald.png)
- `smoke-ice`: ![smoke-ice](example-spots/spot-smoke-ice.png)
- `smoke-amber`: ![smoke-amber](example-spots/spot-smoke-amber.png)
- `smoke-rose`: ![smoke-rose](example-spots/spot-smoke-rose.png)
- `gradient-gold`: ![gradient-gold](example-spots/spot-gradient-gold.png)
- `gradient-violet`: ![gradient-violet](example-spots/spot-gradient-violet.png)
- `gradient-teal`: ![gradient-teal](example-spots/spot-gradient-teal.png)
- `gradient-emerald`: ![gradient-emerald](example-spots/spot-gradient-emerald.png)
- `gradient-sunset`: ![gradient-sunset](example-spots/spot-gradient-sunset.png)
- `gradient-midnight`: ![gradient-midnight](example-spots/spot-gradient-midnight.png)
- `gradient-slate`: ![gradient-slate](example-spots/spot-gradient-slate.png)
- `gradient-wine`: ![gradient-wine](example-spots/spot-gradient-wine.png)
- `velvet-red`: ![velvet-red](example-spots/spot-velvet-red.png)
- `velvet-blue`: ![velvet-blue](example-spots/spot-velvet-blue.png)
- `velvet-green`: ![velvet-green](example-spots/spot-velvet-green.png)
- `velvet-plum`: ![velvet-plum](example-spots/spot-velvet-plum.png)
- `bokeh-gold`: ![bokeh-gold](example-spots/spot-bokeh-gold.png)
- `bokeh-blue`: ![bokeh-blue](example-spots/spot-bokeh-blue.png)
- `bokeh-rose`: ![bokeh-rose](example-spots/spot-bokeh-rose.png)
- `bokeh-emerald`: ![bokeh-emerald](example-spots/spot-bokeh-emerald.png)

Your TMDB key is personal: never share it.
