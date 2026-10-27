# ing-03 — Réparer le backend

Niveau 3 — 15 minutes

Contexte : namespace `ckad-ing-03`.

`./init.sh` une fois, puis `./lab.sh start ing-03`.

L'Ingress `app` (hôte `app.ckad.local`, classe `ckad`) pointe vers un
Service qui n'existe pas. Le Service réel s'appelle `web` et écoute sur le
port `80`.

Corrigez le backend. Conservez le nom de l'Ingress, la classe, l'hôte, le
chemin `/` et `pathType: Prefix`.
