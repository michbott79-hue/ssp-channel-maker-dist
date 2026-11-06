# ssp-channel-maker - quick start / avvio rapido

English first, Italian below. Full guide: `docs/GUIDE.md` (English + Italiano).

## English

This folder is your workspace. Work inside it; nothing else needs installing except ffmpeg (step 1).

```
ssp-channel-maker      the program (static binary, Ubuntu 24.04, x86_64)
install-ffmpeg-nvenc.sh  builds ffmpeg with NVIDIA NVENC on your PC (once), puts it in bin/
bin/       ffmpeg and ffprobe (created by the script above)
config.toml  already here, edit it: your own TMDB key (optional) and, only if needed, ffmpeg paths (`doctor --save`): `tmdb_key = "..."` (personal, never share this file)
in/        put your cleaned films here (.mkv named like (Title)-(Year).mkv)
out/       finished folders appear here, ready to upload by SFTP
logos/     your channel logo (png)
docs/      GUIDE.md (how to clean, name and encode your films), NAMING.md, QUICKSTART.md, ssp-channel-maker.sha256
```

1. **ffmpeg (once).** With an NVIDIA GPU and driver installed: `./install-ffmpeg-nvenc.sh --yes`
   (read its `--help`; the build takes some minutes and needs the compiler packages listed there). Only `ffmpeg` and `ffprobe` are
   installed, into `bin/` of this folder; nothing goes anywhere else.
   You already have your own ffmpeg 8.1? Skip this: copy the two programs into `bin/`, or use `--ffmpeg` / `--ffprobe`
   (add `doctor --ffmpeg ... --ffprobe ... --save` to remember them in `config.toml`).
2. **Check the setup.** `./ssp-channel-maker doctor`. Exit code 2 means something is missing; the message says what.
3. **Check the names.** `./ssp-channel-maker check --rename` (reads `in/`; then `--rename --apply` to rename).
4. **Plan, build, verify.**
   ```
   ./ssp-channel-maker plan   --name "My Cinema"
   ./ssp-channel-maker build  --name "My Cinema" --folder-name my_cinema --logo logos/logo.png
   ./ssp-channel-maker verify --folder-name my_cinema
   ```
   (films are read from `in/`, the result goes to `out/`; other folders: `--input DIR`, `--output DIR`)
5. **Upload** the folder `out/my_cinema` to your node by SFTP. The panel shows it as Ready.

TMDB (optional, finds titles and years): the key is yours alone, put it in `config.toml` as `tmdb_key = "..."` and never give it to anyone. After editing it run `chmod 600 config.toml`. `./ssp-channel-maker doctor` shows whether it is set, never its value.

Do not put symbolic links in this folder: the program refuses them. Check the download from this folder with `sha256sum -c docs/ssp-channel-maker.sha256`.

## Italiano

Questa cartella è il tuo spazio di lavoro. Lavori qui dentro; oltre a ffmpeg (passo 1) non serve installare altro.

```
ssp-channel-maker      il programma (binario statico, Ubuntu 24.04, x86_64)
install-ffmpeg-nvenc.sh  compila sul tuo PC ffmpeg con NVIDIA NVENC (una volta) e lo mette in bin/
bin/       ffmpeg e ffprobe (creati dallo script qui sopra)
config.toml  già presente, modificalo: la tua chiave TMDB (facoltativa) e, solo se serve, i percorsi ffmpeg (`doctor --save`): `tmdb_key = "..."` (personale, non condividere questo file)
in/        qui metti i film già puliti (.mkv chiamati (Titolo)-(Anno).mkv)
out/       qui compaiono le cartelle finite, pronte da caricare con SFTP
logos/     il logo del tuo canale (png)
docs/      GUIDE.md (come pulire, nominare e codificare i film), NAMING.md, QUICKSTART.md, ssp-channel-maker.sha256
```

1. **ffmpeg (una volta).** Con una scheda NVIDIA e il driver installato: `./install-ffmpeg-nvenc.sh --yes`
   (leggi `--help`; la compilazione richiede alcuni minuti e i pacchetti del compilatore indicati lì). Vengono installati solo
   `ffmpeg` e `ffprobe`, dentro `bin/` di questa cartella; non va nient'altro da nessuna parte.
   Hai già un tuo ffmpeg 8.1? Salta questo passo: copia i due programmi in `bin/`, oppure usa `--ffmpeg` / `--ffprobe`
   (con `doctor --ffmpeg ... --ffprobe ... --save` li ricordi in `config.toml`).
2. **Controlla l'ambiente.** `./ssp-channel-maker doctor`. Codice di uscita 2 = manca qualcosa; il messaggio dice cosa.
3. **Controlla i nomi.** `./ssp-channel-maker check --rename` (legge `in/`; poi `--rename --apply` per rinominare).
4. **Plan, build, verify.**
   ```
   ./ssp-channel-maker plan   --name "Il mio cinema"
   ./ssp-channel-maker build  --name "Il mio cinema" --folder-name il_mio_cinema --logo logos/logo.png
   ./ssp-channel-maker verify --folder-name il_mio_cinema
   ```
   (i film si leggono da `in/`, il risultato va in `out/`; altre cartelle: `--input DIR`, `--output DIR`)
5. **Carica** la cartella `out/il_mio_cinema` sul nodo con SFTP. Il pannello la mostra come Ready.

TMDB (facoltativo, trova titoli e anni): la chiave è solo tua, mettila in `config.toml` come `tmdb_key = "..."` e non darla a nessuno. Dopo averlo modificato esegui `chmod 600 config.toml`. `./ssp-channel-maker doctor` dice se è impostata, senza mai mostrarla.

Non mettere link simbolici in questa cartella: il programma li rifiuta. Controlla il download da questa cartella con `sha256sum -c docs/ssp-channel-maker.sha256`.
