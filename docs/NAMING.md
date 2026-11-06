# Naming the source files / Come chiamare i file

English first, Italian below. `check <movies>` shows how every name is read; `check --rename` proposes names in this scheme.

## English

### The rule

Every part of the name is in round brackets, joined by a hyphen:

```
(Title)-(Year)-(Resolution)-(Language)-(genre)-(fps)-(tmdbid.ID).mkv
```

Series put the episode right after the title and use the id of the show:

```
(Show)-(S01E03)-(Year)-(1080p)-(iTA)-(drama)-(25)-(tmdbid.1399).mkv
```

| Part | Required | What it is | Example |
|---|---|---|---|
| Title | yes | the title as it should appear; accents and apostrophes are welcome | `(L'uomo dalla pistola d'oro)` |
| SxxEyy | series only | season and episode | `(S01E03)` |
| Year | no (warning) | year of the movie; without it the spot shows only the title, and the play order by year cannot be used | `(1974)` |
| Resolution | no | `2160p`, `1080p`, `720p`, below that the picture height (`576p`); the tool measures it, the measure wins | `(1080p)` |
| Language | no | audio language label, free text | `(iTA)` |
| genre | no | free text | `(azione)` |
| fps | no | `23` (23.976), `24`, `25`, `29` (29.97), `30`, `50`, `59` (59.94), `60`; measured, the measure wins | `(23)` |
| tmdbid | no (warning; error with `--tmdb-strict`) | the TMDB number of the movie or show | `(tmdbid.682)` |

Leave out parts you do not know. The title must come first. Year, resolution, fps, `S01E03` and `tmdbid.ID` are recognised by their shape
in any position; language and genre are plain words and are told apart by position: the first plain word after the title is the language,
the second the genre. So keep language before genre (or write only the language).

Good: `(Alien)-(1979)-(1080p)-(iTA)-(fantascienza)-(23)-(tmdbid.348).mkv`, `(Heat)-(1995).mkv`, `(007.06 Al servizio segreto di Sua Maestà)-(1969).mkv`
(a leading movie number stays in the title).

Bad: `alien.mkv` (no year: warning only), `(Show)-(2011).mkv` in a series folder (no `S01E03`: error), `-(1979).mkv` (no title: error).

Old names ending in `-(sub)` or `-(nosub)` are still read; `check` says so and proposes the new name.

### What check says

- **error**: must be fixed before a build (no title, series without SxxEyy, the same tmdbid on two movies, `--tmdb-strict` without an id).
- **warning**: the build works, but look at it (no year, no tmdbid, the resolution or fps written in the name differs from the file).
- **notice**: information only (old ending, name not yet in the scheme, what TMDB found).

`check --rename` shows the proposed names, nothing changes. `check --rename --apply` really renames; it never overwrites a file, never touches a
file with an error, and moves the `.title` file with its movie. Proposed names put dots between the words and keep apostrophes and accents
(`(L'uomo.dalla.pistola.d'oro)-(1974).mkv`); a title a file name cannot hold (`:` `?` `/`, a real dot, or longer than 200 bytes) is
written first to the movie's `<new name>.title` file, so the spot keeps the exact title. `check --tmdb` (needs your TMDB key: `tmdb_key` in `config.toml` or `TMDB_API_KEY`) finds the
missing tmdbid only when exactly one TMDB result has the same title and year (accents, apostrophes, case and punctuation do not count).
Anything less sure is never chosen by itself: on a keyboard it asks you (the number you pick must not belong to another movie), and with
`--yes` or without a keyboard it lists the candidates, does not rename those files and exits with code 3.

### Titles

The title comes from the name. Other sources, strongest first: `--title "..."` (one movie only, kept exactly as typed),
a `<movie name without extension>.title` file (one line), then with `--title-source tmdb` the official TMDB title, then the name.

## Italiano

### La regola

Ogni parte del nome sta tra parentesi tonde, unite da un trattino:

```
(Titolo)-(Anno)-(Risoluzione)-(Lingua)-(genere)-(fps)-(tmdbid.ID).mkv
```

Le serie mettono l'episodio subito dopo il titolo e usano l'id della serie:

```
(Serie)-(S01E03)-(Anno)-(1080p)-(iTA)-(drama)-(25)-(tmdbid.1399).mkv
```

| Parte | Obbligatoria | Cos'è | Esempio |
|---|---|---|---|
| Titolo | sì | il titolo come deve apparire; accenti e apostrofi vanno bene | `(L'uomo dalla pistola d'oro)` |
| SxxEyy | solo serie | stagione ed episodio | `(S01E03)` |
| Anno | no (avviso) | anno del film; senza, lo spot mostra solo il titolo e l'ordine per anno non si può usare | `(1974)` |
| Risoluzione | no | `2160p`, `1080p`, `720p`, sotto l'altezza dell'immagine (`576p`); lo strumento la misura e vale la misura | `(1080p)` |
| Lingua | no | etichetta della lingua audio, testo libero | `(iTA)` |
| genere | no | testo libero | `(azione)` |
| fps | no | `23` (23.976), `24`, `25`, `29` (29.97), `30`, `50`, `59` (59.94), `60`; misurato, vale la misura | `(23)` |
| tmdbid | no (avviso; errore con `--tmdb-strict`) | il numero TMDB del film o della serie | `(tmdbid.682)` |

Le parti che non conosci si tolgono. Il titolo deve essere il primo. Anno, risoluzione, fps, `S01E03` e `tmdbid.ID` si riconoscono dalla forma
in qualsiasi posizione; lingua e genere sono parole semplici e si distinguono dalla posizione: la prima parola semplice dopo il titolo è la
lingua, la seconda il genere. Quindi metti la lingua prima del genere (oppure scrivi solo la lingua).

Giusti: `(Alien)-(1979)-(1080p)-(iTA)-(fantascienza)-(23)-(tmdbid.348).mkv`, `(Heat)-(1995).mkv`,
`(007.06 Al servizio segreto di Sua Maestà)-(1969).mkv` (il numero del film davanti resta nel titolo).

Sbagliati: `alien.mkv` (senza anno: solo avviso), `(Serie)-(2011).mkv` in una cartella di serie (manca `S01E03`: errore), `-(1979).mkv` (senza titolo: errore).

I nomi vecchi che finiscono con `-(sub)` o `-(nosub)` si leggono ancora; `check` lo segnala e propone il nome nuovo.

### Cosa dice check

- **error**: va corretto prima di un build (senza titolo, serie senza SxxEyy, lo stesso tmdbid su due film, `--tmdb-strict` senza id).
- **warning**: il build funziona, ma controlla (senza anno, senza tmdbid, risoluzione o fps scritti nel nome diversi dal file).
- **notice**: solo informazione (finale vecchio, nome non ancora nello schema, cosa ha trovato TMDB).

`check --rename` mostra i nomi proposti e non cambia niente. `check --rename --apply` rinomina davvero: non sovrascrive mai un file, non tocca
i file con un errore e sposta il file `.title` insieme al suo film. I nomi proposti mettono i punti tra le parole e tengono apostrofi e accenti
(`(L'uomo.dalla.pistola.d'oro)-(1974).mkv`); un titolo che un nome di file non può contenere (`:` `?` `/`, un punto vero, o più di 200 byte)
viene scritto prima nel file `<nuovo nome>.title` del film, così lo spot tiene il titolo esatto. `check --tmdb` (serve la tua chiave TMDB: `tmdb_key` in `config.toml` o `TMDB_API_KEY`) trova
il tmdbid mancante solo quando esattamente un risultato TMDB ha lo stesso titolo e lo stesso anno (accenti, apostrofi, maiuscole e punteggiatura
non contano). Tutto ciò che è meno sicuro non viene mai scelto da solo: da tastiera te lo chiede (il numero scelto non deve appartenere a un altro
movie), con `--yes` o senza tastiera elenca i candidati, non rinomina quei file ed esce con codice 3.

### Titoli

Il titolo viene dal nome. Altre fonti, dalla più forte: `--title "..."` (un solo film, tenuto esattamente come scritto),
un file `<nome del film senza estensione>.title` (una riga), poi con `--title-source tmdb` il titolo ufficiale TMDB, poi il nome.
