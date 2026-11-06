# Guide: how to prepare your movies / Guida: come preparare i tuoi film

English first, Italian below. Both parts say the same thing.
Facts about `mkvmerge` were checked against its manual page (MKVToolNix); facts about `ssp-channel-maker` against its code (0.1.0-dev).

## English

### 1. The big picture

```
your rip (.mkv)  ->  clean copy (mkvmerge)  ->  right name  ->  check  ->  plan  ->  build  ->  verify  ->  upload (SFTP)
```

1. **Clean** each movie so the file holds one video track and one audio track (no extra languages, subtitles, chapters).
2. **Name** it in the scheme `(Title)-(Year)-...mkv` (full rules: `NAMING.md`).
3. **Check** the names, **plan** (a dry run), **build** (the real encode), **verify**, then upload the finished folder to your node.

The tool re-encodes every movie to one uniform format (1080p H.264 + AAC, same profile for the whole folder) and adds a countdown spot
before each movie. You do not have to prepare the picture: only choose *what* goes in (which tracks) and *how* it is named.
Your sources are never changed: the tool only reads them.

### 2. Look at what you have

```bash
mkvmerge -i "Alien.1979.mkv"
```

`mkvmerge -i` (`--identify`) lists the tracks with their **track IDs**. The wording changes with the version and the language of your system, so
read it like this (example, yours will differ):

```
File 'Alien.1979.mkv': container: Matroska
Track ID 0: video (V_MPEG4/ISO/AVC)
Track ID 1: audio (A_AC3)         <- Italian 5.1
Track ID 2: audio (A_DTS)         <- English 5.1
Track ID 3: subtitles (S_TEXT/UTF8)
```

Note which ID is the video and which audio you want. IDs are track IDs, not "first, second, third": always read them from this list.
The tool can also show what it sees: `ssp-channel-maker probe ~/movies`.

### 3. Make a clean copy with mkvmerge

Keep **one video track and one audio track**. Example: keep video ID 0 and audio ID 1, drop subtitles, chapters, attachments and tags:

```bash
mkvmerge -o "clean/Alien.1979.mkv" \
  --video-tracks 0 --audio-tracks 1 \
  --no-subtitles --no-chapters --no-attachments --no-global-tags \
  "Alien.1979.mkv"
```

What each option does (from the manual): `--video-tracks` / `--audio-tracks` copy only the listed track IDs; `--no-subtitles` (`-S`),
`--no-attachments` (`-M`), `--no-chapters`, `--no-global-tags` leave those parts out. A `!` before the list reverses it
(`--audio-tracks '!2'` = every audio track except ID 2). Instead of an ID you can write the ISO 639-2 language, for example
`--audio-tracks ita`, but only if the file carries language tags for its tracks.

Many files with the same layout (Italian audio tagged `ita`), in one go:

```bash
mkdir -p clean
for f in *.mkv; do
  mkvmerge -o "clean/$f" --video-tracks 0 --audio-tracks ita \
    --no-subtitles --no-chapters --no-attachments --no-global-tags "$f"
done
```

Afterwards **check the result** with `mkvmerge -i "clean/Alien.1979.mkv"`: it must show one video and one audio track. If a file has the
video on another ID, the loop above is wrong for that file: do it by hand.

Why this matters: if a file keeps several audio tracks and you do not choose, the tool takes the one with the most channels (or the language you
set with `--audio-lang`, e.g. `--audio-lang ita,eng`). A clean copy removes the guesswork. Subtitles are not used in this version.

No lossless step is needed: `mkvmerge` only copies the tracks, it does not re-encode. The tool re-encodes later.

### 4. Name the files

Format: `(Title)-(Year)-(Resolution)-(Language)-(genre)-(fps)-(tmdbid.ID).mkv`. Only the title is required; the year is strongly advised.

| You have | Name it |
|---|---|
| A movie, nothing else known | `(Heat)-(1995).mkv` |
| A movie, everything known | `(Alien)-(1979)-(1080p)-(iTA)-(fantascienza)-(23)-(tmdbid.348).mkv` |
| A movie with a number in the title | `(007.06 Al servizio segreto di Sua Maestà)-(1969).mkv` |
| A series episode | `(Show)-(S01E03)-(2011)-(1080p)-(iTA)-(drama)-(25)-(tmdbid.1399).mkv` |

Rules in short: the title comes first; keep the language before the genre; leave out what you do not know; for a series put `(S01E03)` right
after the title and use the id of the **show**. Resolution and fps are measured on the file, so if you write them wrongly the tool tells you.
The `tmdbid` is the number in the address of the movie on themoviedb.org; with it the tool can use the official title.

You do not need to rename by hand. Let the tool propose names, look at them, then apply:

```bash
ssp-channel-maker check ~/movies --rename             # shows proposed names, changes nothing
ssp-channel-maker check ~/movies --rename --apply     # really renames (never overwrites)
```

With your TMDB key set (see "Your TMDB key" below), add `--tmdb` to find the missing ids; the tool only picks a match when exactly one result has the same title and year,
otherwise it asks you (or lists the candidates when it cannot ask). Details and edge cases: `NAMING.md`.

#### Your TMDB key (optional)

TMDB is optional. It only helps to find titles and years. The key is **yours and personal**: you get it free from your own TMDB account
(themoviedb.org, Settings, API). Do not share it and do not send it to anyone, not even to support.

Where it goes: the file `config.toml` is already in your workspace folder, next to the program (not hidden). Open it and fill in the line:

```
tmdb_key = "your_key_here"
```

- The file is made readable by you only (mode 0600) when `doctor --save` writes it; `doctor --save` keeps your key. If you create or edit it by hand, run `chmod 600 config.toml`; `doctor` warns you when other users can read it.
- The tool uses the key only to ask TMDB for titles and years (read only). It never prints it, never writes it in logs or in your channel folder.
- `./ssp-channel-maker doctor` tells you if a key is set and where it comes from, without showing it.
- The environment variable `TMDB_API_KEY` also works and wins over the file (handy for one run).
- If you copy the workspace folder to someone else, or send `config.toml` for help, take the key line out first.

### 5. Series

Put all episodes of one show in **one folder**, name them with `(S01E03)` and run the tool with `--series`. The spot can appear before every
episode (default), only at the first episode of a season, or never: `--spot-frequency every_episode | first_of_season | none`. A series file
without `SxxEyy` is an error.

### 6. Choose the bit rate

The video bit rate (`--video-kbps`) is **one value for the whole folder**: the panel accepts only files with the same profile, so you cannot give
different rates to different movies. Default 4000 kb/s; the tool warns outside the usual range 1500 - 20000 kb/s. Audio (`--audio-kbps`) defaults to
192 kb/s, usual range 64 - 320.

File size is easy to estimate: **size = (video + audio kb/s) x seconds / 8**. For a 2-hour movie (7200 s):

| Video kb/s | Audio kb/s | About | Use it when |
|---|---|---|---|
| 2000 | 192 | 2.0 GB | small disk, many viewers on slow lines |
| 4000 (default) | 192 | 3.8 GB | good quality for HD live viewing |
| 6000 | 192 | 5.6 GB | cleaner picture on big screens |
| 8000 | 192 | 7.4 GB | very high quality; needs fast lines and disks |

Remember: this is also the rate that every viewer of the channel downloads, and a live channel streams a whole folder over time. When in doubt
keep 4000. A measured example (lab, one sample): a 2 h 16 movie at 4000 kb/s gave 4.26 GB.

#### Spot background

`--background NAME` picks the picture behind the spot text. List them with `ssp-channel-maker spot --list-backgrounds`; a ready sample of each
is in the `example-spots/` folder of the public repo (stills in its README). The nine: `smoke1-3` (slow drifting cloud), `black`, `silk` (golden satin folds),
`dust` (warm motes rising), `film` (grain, flicker, scratches; slower to render) `rays` (beams of light) and `matrix` (falling green letters). You can also give `#RRGGBB` or your own picture file.
Names of 0.1.2-dev and earlier that were removed (`gradient-*`, `velvet-*`, `bokeh-*`, `smoke-<colour>`, `grain`) still work: they render as `smoke1` and the tool warns.
Try one first: `ssp-channel-maker spot --title "Test" --background silk -o out/test.mp4`.

#### Plot, genre, runtime and poster on the spot

With TMDB on (`--tmdb`, or `--tmdb-id N` for the `spot` command) the spot shows the TMDB poster on the left and, on the right, title and year, one line
"Genres  -  136 min" and the plot (`--plot-lines N`, default 6, 0 drops it; a longer plot ends with "..."). `--spot-info` chooses the parts
(default `title,year,genre,runtime,plot,cover`). Without TMDB data only title and year appear, centered as before; if the poster cannot be fetched the spot is
made without it and the build prints a notice. Example: `ssp-channel-maker spot --title "The Matrix" --year 1999 --tmdb --background matrix -o out/matrix.mp4`.

#### Box behind the text

Over a busy background (the `matrix` letter rain, for example) a long plot is hard to read. `--text-box on` puts a black box behind every text line and the
countdown; `--text-box-opacity N` (1-100 percent, default 45) sets how dark it is. The box is **off by default** (since 0.1.7-dev, earlier versions always drew a
45 % box). Try: `ssp-channel-maker spot --title "The Matrix" --year 1999 --tmdb --background matrix --text-box on --text-box-opacity 60 -o out/matrix.mp4`.

### 7. Check, plan, build, verify

```bash
ssp-channel-maker doctor                              # once: finds ffmpeg (in bin/), checks GPU and encoders
ssp-channel-maker check                               # how every name is read: errors, warnings, notices
ssp-channel-maker plan  --name "My Cinema"            # dry run: what will be done to each movie
ssp-channel-maker build --name "My Cinema" --folder-name my_cinema --logo logos/logo.png
ssp-channel-maker verify --folder-name my_cinema      # re-measures the result like the panel does
```

Folders: the movies are read from `in/` and the channel folder is written into `out/` (both next to the program). You can point the tool somewhere
else with `--input ~/movies` and `--output ~/out` (short forms `-i`, `-o`); an option you do not write keeps its default. `--folder-name` is the name of
the channel folder inside the output (default: made from `--name`). The older form `check ~/movies`, `build ~/movies -o ~/out` still works.

What the tool checks for you:

- **Names** (`check`): no title or a series without `SxxEyy` is an **error** and stops the build; no year or no tmdbid is a **warning**.
- **File contents** (`plan`): a file without video is refused; movies with different frame rates in one folder are reported (build one group with
  `--fps`, or split the folder); the plan lists what will be done to each movie (crop of black bars, deinterlace, HDR to SDR, scaling to 1080p with
  black bars, audio down-mix).
- **Bit rates** (`plan`): a warning when video or audio kb/s is outside the usual range.
- **Result** (`verify`): the finished folder is measured again and judged like the panel judges it, so a folder that passes is expected to be shown as
  Ready by the panel.

Exit codes: 0 ok, 1 wrong usage, 2 something missing in the environment, 3 input refused, 4 encode failed, 5 verification failed, 130 interrupted.
The build writes into `<out>/<folder>.partial` and renames it when finished, with `manifest.json` last, so an interrupted run never leaves a
half-finished folder looking complete; run the same command again and finished files are kept.

Speed: about 7 times real time on an RTX 3080 (lab sample). Without a GPU use `--encoder libx264`; it is slower.

### 8. Upload

Upload the whole finished folder (movies, spots, `manifest.json`) to the node with SFTP, into the node's Create channel inbox. The panel scans
it and shows **Ready** when everything matches. Then confirm the profile and activate the channel in the panel (see the Help topic
"Create channel").

### 9. Common problems

| Message or symptom | What to do |
|---|---|
| `symbolic link refused` | The tool does not follow symbolic links. Use the real path of the folder, not a path that goes through a link. |
| Error: series file without `SxxEyy` | Add `(S01E03)` after the title, or run without `--series` if it is a movie folder. |
| Frame rates mixed | `plan` lists the groups. Build one with `--fps 25` (the others are left out), or put each frame rate in its own folder. |
| The spot has no year | The name has no year. Add it: `(Heat)-(1995).mkv`. |
| The movie plays in the wrong audio language | Make a clean copy with only the track you want (section 3), or set `--audio-lang`. |
| `check --tmdb` lists candidates and exits 3 | It was not sure which movie is yours. Run it on a keyboard and pick the number, or write the `(tmdbid.ID)` yourself. |
| `doctor` exit 2 | ffmpeg/ffprobe, an encoder or a filter is missing; the message says which. |

---

## Italiano

### 1. Il quadro

```
il tuo rip (.mkv)  ->  copia pulita (mkvmerge)  ->  nome giusto  ->  check  ->  plan  ->  build  ->  verify  ->  upload (SFTP)
```

1. **Pulisci** ogni film: il file deve avere una traccia video e una traccia audio (niente lingue extra, sottotitoli, capitoli).
2. **Dai il nome** nello schema `(Titolo)-(Anno)-...mkv` (regole complete: `NAMING.md`).
3. **Check** dei nomi, **plan** (prova a vuoto), **build** (la codifica vera), **verify**, poi carichi la cartella finita sul nodo.

Lo strumento ricodifica ogni film in un formato unico (1080p H.264 + AAC, stesso profilo per tutta la cartella) e aggiunge uno spot con
conto alla rovescia prima di ogni film. Non devi preparare l'immagine: scegli solo *cosa* entra (quali tracce) e *come* si chiama.
I tuoi originali non vengono mai modificati: lo strumento li legge soltanto.

### 2. Guarda cosa hai

```bash
mkvmerge -i "Alien.1979.mkv"
```

`mkvmerge -i` (`--identify`) elenca le tracce con i loro **track ID**. Le parole cambiano con la versione e con la lingua del sistema: leggilo così
(esempio, il tuo sarà diverso):

```
File 'Alien.1979.mkv': container: Matroska
Track ID 0: video (V_MPEG4/ISO/AVC)
Track ID 1: audio (A_AC3)         <- italiano 5.1
Track ID 2: audio (A_DTS)         <- inglese 5.1
Track ID 3: subtitles (S_TEXT/UTF8)
```

Segna quale ID è il video e quale l'audio che vuoi. Sono track ID, non "prima, seconda, terza": leggili sempre da questo elenco.
Lo strumento può mostrare cosa vede: `ssp-channel-maker probe ~/films`.

### 3. Fai una copia pulita con mkvmerge

Tieni **una traccia video e una traccia audio**. Esempio: tieni il video ID 0 e l'audio ID 1, togli sottotitoli, capitoli, allegati e tag:

```bash
mkvmerge -o "clean/Alien.1979.mkv" \
  --video-tracks 0 --audio-tracks 1 \
  --no-subtitles --no-chapters --no-attachments --no-global-tags \
  "Alien.1979.mkv"
```

Cosa fa ogni opzione (dal manuale): `--video-tracks` / `--audio-tracks` copiano solo i track ID elencati; `--no-subtitles` (`-S`),
`--no-attachments` (`-M`), `--no-chapters`, `--no-global-tags` lasciano fuori quelle parti. Un `!` davanti all'elenco lo inverte
(`--audio-tracks '!2'` = tutte le tracce audio tranne l'ID 2). Al posto dell'ID puoi scrivere la lingua ISO 639-2, per esempio
`--audio-tracks ita`, ma solo se il file ha le etichette di lingua sulle tracce.

Tanti file con la stessa struttura (audio italiano etichettato `ita`), in un colpo solo:

```bash
mkdir -p clean
for f in *.mkv; do
  mkvmerge -o "clean/$f" --video-tracks 0 --audio-tracks ita \
    --no-subtitles --no-chapters --no-attachments --no-global-tags "$f"
done
```

Dopo, **controlla il risultato** con `mkvmerge -i "clean/Alien.1979.mkv"`: deve mostrare una traccia video e una audio. Se in un file il video ha
un altro ID, il ciclo sopra è sbagliato per quel file: fallo a mano.

Perché serve: se un file tiene più tracce audio e tu non scegli, lo strumento prende quella con più canali (o la lingua che imposti con
`--audio-lang`, per esempio `--audio-lang ita,eng`). Una copia pulita toglie l'incertezza. I sottotitoli in questa versione non si usano.

Non serve nessun passaggio senza perdita: `mkvmerge` copia soltanto le tracce, non ricodifica. La ricodifica la fa lo strumento dopo.

### 4. Dai il nome ai file

Formato: `(Titolo)-(Anno)-(Risoluzione)-(Lingua)-(genere)-(fps)-(tmdbid.ID).mkv`. Solo il titolo è obbligatorio; l'anno è molto consigliato.

| Cosa hai | Come chiamarlo |
|---|---|
| Un film, non sai altro | `(Heat)-(1995).mkv` |
| Un film, sai tutto | `(Alien)-(1979)-(1080p)-(iTA)-(fantascienza)-(23)-(tmdbid.348).mkv` |
| Un film con un numero nel titolo | `(007.06 Al servizio segreto di Sua Maestà)-(1969).mkv` |
| Un episodio di serie | `(Show)-(S01E03)-(2011)-(1080p)-(iTA)-(drama)-(25)-(tmdbid.1399).mkv` |

Regole in breve: il titolo viene per primo; la lingua prima del genere; togli ciò che non sai; per una serie metti `(S01E03)` subito dopo il
titolo e usa l'id della **serie**. Risoluzione e fps vengono misurati sul file: se li scrivi sbagliati lo strumento te lo dice.
Il `tmdbid` è il numero nell'indirizzo del film su themoviedb.org; con quello lo strumento può usare il titolo ufficiale.

Non devi rinominare a mano. Lascia che lo strumento proponga i nomi, guardali, poi applica:

```bash
ssp-channel-maker check ~/films --rename             # mostra i nomi proposti, non cambia niente
ssp-channel-maker check ~/films --rename --apply     # rinomina davvero (non sovrascrive mai)
```

Con la tua chiave TMDB impostata (vedi «La tua chiave TMDB» sotto) aggiungi `--tmdb` per trovare gli id mancanti; lo strumento sceglie da solo solo quando esattamente un risultato ha lo
stesso titolo e lo stesso anno, altrimenti te lo chiede (o elenca i candidati se non può chiedere). Dettagli e casi limite: `NAMING.md`.

#### La tua chiave TMDB (facoltativa)

TMDB è facoltativo: serve solo a trovare titoli e anni. La chiave è **tua e personale**: la ottieni gratis dal tuo account TMDB
(themoviedb.org, Impostazioni, API). Non condividerla e non mandarla a nessuno, nemmeno all'assistenza.

Dove si mette: il file `config.toml` c'è già nella tua cartella di lavoro, accanto al programma (non è nascosto). Aprilo e compila la riga:

```
tmdb_key = "la_tua_chiave"
```

- Quando `doctor --save` scrive il file lo rende leggibile solo da te (permessi 0600); `doctor --save` conserva la tua chiave. Se lo crei o lo modifichi a mano, esegui `chmod 600 config.toml`; `doctor` ti avvisa se altri utenti possono leggerlo.
- Lo strumento usa la chiave solo per chiedere a TMDB titoli e anni (sola lettura). Non la stampa mai, non la scrive nei log né nella cartella del canale.
- `./ssp-channel-maker doctor` ti dice se una chiave è impostata e da dove viene, senza mostrarla.
- Funziona anche la variabile `TMDB_API_KEY` e ha la precedenza sul file (comoda per una sola esecuzione).
- Se copi la cartella di lavoro a qualcuno, o mandi `config.toml` per farti aiutare, togli prima la riga della chiave.

### 5. Serie

Metti tutti gli episodi di una serie in **una cartella**, chiamali con `(S01E03)` e lancia lo strumento con `--series`. Lo spot può comparire
prima di ogni episodio (predefinito), solo al primo episodio di ogni stagione, o mai: `--spot-frequency every_episode | first_of_season | none`.
Un file di serie senza `SxxEyy` è un errore.

### 6. Scegli il bitrate

Il bitrate video (`--video-kbps`) è **un solo valore per tutta la cartella**: il pannello accetta solo file con lo stesso profilo, quindi non puoi
dare bitrate diversi a film diversi. Predefinito 4000 kb/s; lo strumento avvisa fuori dall'intervallo usuale 1500 - 20000 kb/s. L'audio
(`--audio-kbps`) è 192 kb/s di base, intervallo usuale 64 - 320.

La dimensione si stima facilmente: **dimensione = (video + audio kb/s) x secondi / 8**. Per un film di 2 ore (7200 s):

| Video kb/s | Audio kb/s | Circa | Quando usarlo |
|---|---|---|---|
| 2000 | 192 | 2,0 GB | disco piccolo, molti spettatori con linee lente |
| 4000 (predefinito) | 192 | 3,8 GB | buona qualità per la visione live in HD |
| 6000 | 192 | 5,6 GB | immagine più pulita su schermi grandi |
| 8000 | 192 | 7,4 GB | qualità molto alta; servono linee e dischi veloci |

Ricorda: è anche il bitrate che scarica ogni spettatore del canale. Nel dubbio resta a 4000. Un esempio misurato (laboratorio, un solo campione):
un film di 2 h 16 a 4000 kb/s è venuto 4,26 GB.

#### Sfondo dello spot

`--background NOME` sceglie l'immagine dietro il testo dello spot. L'elenco: `ssp-channel-maker spot --list-backgrounds`; un esempio pronto di ognuno
è nella cartella `example-spots/` del repo pubblico (anteprime nel suo README). I nove: `smoke1-3` (nuvola lenta in movimento), `black`, `silk` (pieghe di raso dorato),
`dust` (granelli caldi che salgono), `film` (grana, sfarfallio, graffi; più lento da generare), `rays` (raggi di luce) e `matrix` (lettere verdi che scendono). Puoi dare anche `#RRGGBB` o una tua immagine.
I nomi tolti dopo la 0.1.2-dev (`gradient-*`, `velvet-*`, `bokeh-*`, `smoke-<colore>`, `grain`) funzionano ancora: diventano `smoke1` e il programma avvisa.
Provane uno prima: `ssp-channel-maker spot --title "Prova" --background silk -o out/prova.mp4`.

#### Trama, generi, durata e locandina sullo spot

Con TMDB attivo (`--tmdb`, oppure `--tmdb-id N` per il comando `spot`) lo spot mostra a sinistra la locandina TMDB e a destra titolo e anno, una riga
"Generi  -  136 min" e la trama (`--plot-lines N`, predefinito 6, 0 la toglie; una trama lunga finisce con "..."). `--spot-info` sceglie le parti
(predefinito `title,year,genre,runtime,plot,cover`). Senza dati TMDB compaiono solo titolo e anno, centrati come prima; se la locandina non si scarica lo spot
viene fatto senza e la build stampa un avviso. Esempio: `ssp-channel-maker spot --title "The Matrix" --year 1999 --tmdb --background matrix -o out/matrix.mp4`.

#### Riquadro dietro il testo

Su uno sfondo movimentato (per esempio le lettere di `matrix`) una trama lunga si legge male. `--text-box on` mette un riquadro nero dietro ogni riga di testo e dietro il
conto alla rovescia; `--text-box-opacity N` (1-100 per cento, predefinito 45) decide quanto è scuro. Il riquadro è **spento di default** (dalla 0.1.7-dev; le versioni
precedenti disegnavano sempre un riquadro al 45 %). Prova: `ssp-channel-maker spot --title "The Matrix" --year 1999 --tmdb --background matrix --text-box on --text-box-opacity 60 -o out/matrix.mp4`.

### 7. Check, plan, build, verify

```bash
ssp-channel-maker doctor                              # una volta: trova ffmpeg (in bin/), controlla GPU e codificatori
ssp-channel-maker check                               # come viene letto ogni nome: errori, avvisi, note
ssp-channel-maker plan  --name "Il mio cinema"        # prova a vuoto: cosa si farà a ogni film
ssp-channel-maker build --name "Il mio cinema" --folder-name il_mio_cinema --logo logos/logo.png
ssp-channel-maker verify --folder-name il_mio_cinema  # rimisura il risultato come fa il pannello
```

Cartelle: i film si leggono da `in/` e la cartella del canale si scrive in `out/` (entrambe accanto al programma). Per usare altre cartelle:
`--input ~/films` e `--output ~/out` (forme corte `-i`, `-o`); un'opzione che non scrivi tiene il suo valore predefinito. `--folder-name` è il nome della
cartella del canale dentro l'output (predefinito: ricavato da `--name`). La forma vecchia `check ~/films`, `build ~/films -o ~/out` funziona ancora.

Cosa controlla lo strumento per te:

- **Nomi** (`check`): senza titolo, o una serie senza `SxxEyy`, è un **errore** e ferma il build; senza anno o senza tmdbid è un **avviso**.
- **Contenuto dei file** (`plan`): un file senza video viene rifiutato; film con frame rate diversi nella stessa cartella vengono segnalati (costruisci
  un gruppo con `--fps`, o dividi la cartella); il piano elenca cosa si farà a ogni film (taglio delle barre nere, deinterlacciamento, HDR a SDR,
  scala a 1080p con barre nere, riduzione dei canali audio).
- **Bitrate** (`plan`): avviso se i kb/s di video o audio sono fuori dall'intervallo usuale.
- **Risultato** (`verify`): la cartella finita viene rimisurata e giudicata come la giudica il pannello, quindi una cartella che passa dovrebbe
  comparire come Ready nel pannello.

Codici di uscita: 0 ok, 1 uso errato, 2 manca qualcosa nell'ambiente, 3 input rifiutato, 4 codifica fallita, 5 verifica fallita, 130 interrotto.
Il build scrive in `<out>/<cartella>.partial` e rinomina a lavoro finito, con `manifest.json` per ultimo, quindi una corsa interrotta non lascia
mai una cartella a metà che sembra completa; rilanci lo stesso comando e i file già finiti restano.

Velocità: circa 7 volte il tempo reale su una RTX 3080 (campione di laboratorio). Senza GPU usa `--encoder libx264`; è più lento.

### 8. Caricamento

Carica con SFTP tutta la cartella finita (film, spot, `manifest.json`) sul nodo, nella casella di ingresso di Create channel. Il pannello la scansiona
e mostra **Ready** quando tutto corrisponde. Poi conferma il profilo e attiva il canale nel pannello (argomento di aiuto "Create channel").

### 9. Problemi comuni

| Messaggio o sintomo | Cosa fare |
|---|---|
| `symbolic link refused` | Lo strumento non segue i link simbolici. Usa il percorso reale della cartella, non uno che passa da un link. |
| Errore: file di serie senza `SxxEyy` | Aggiungi `(S01E03)` dopo il titolo, oppure lancia senza `--series` se è una cartella di film. |
| Frame rate misti | `plan` elenca i gruppi. Costruisci un gruppo con `--fps 25` (gli altri restano fuori), o metti ogni frame rate in una cartella a parte. |
| Lo spot non ha l'anno | Il nome non ha l'anno. Aggiungilo: `(Heat)-(1995).mkv`. |
| Il film va in onda con la lingua audio sbagliata | Fai una copia pulita con la sola traccia voluta (sezione 3), oppure imposta `--audio-lang`. |
| `check --tmdb` elenca candidati ed esce con 3 | Non era sicuro di quale film sia il tuo. Lancialo da tastiera e scegli il numero, o scrivi tu `(tmdbid.ID)`. |
| `doctor` esce con 2 | Mancano ffmpeg/ffprobe, un codificatore o un filtro; il messaggio dice quale. |
