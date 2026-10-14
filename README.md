# Veille des services Swiss Solar System

Toutes les 10 minutes, GitHub vérifie (lecture seule) :

- que `monitor.swisssolarsystem.ch` (portail des régies) existe toujours dans le DNS, chez le
  fournisseur DNS lui-même puis chez les DNS publics, et pointe vers le portail ;
- que le portail, SSS OS (`swisssolar.github.io`) et le site `www.swisssolarsystem.ch` répondent ;
- que le certificat HTTPS du portail n'expire pas dans les 14 jours.

En cas de problème, un **incident** (« PANNE ») est ouvert ici : GitHub l'envoie par e-mail. Il se
referme tout seul quand tout répond de nouveau.

**Règle DNS à ne jamais oublier** — si le DNS de `swisssolarsystem.ch` change de fournisseur ou est
réinitialisé, recréer :

| Type | Nom | Valeur |
|---|---|---|
| CNAME | `monitor` | `82a4a7a8a157371f.vercel-dns-017.com` |

Secours pendant une panne DNS : https://sss-monitor-hub.vercel.app (mêmes identifiants).
