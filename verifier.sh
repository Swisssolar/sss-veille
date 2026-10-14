#!/usr/bin/env bash
# Sentinelle Swiss Solar System : vérifie que les services utilisés par les
# régies (portail) et par les collaborateurs (SSS OS) restent joignables.
# Lecture seule : aucune écriture nulle part. Sortie != 0 = alerte.
set -u

PORTAIL_HOST="monitor.swisssolarsystem.ch"
PORTAIL_CIBLE="82a4a7a8a157371f.vercel-dns-017.com."   # cible CNAME exigée par Vercel
URLS=(
  "https://monitor.swisssolarsystem.ch/login|Swiss Solar System|Portail des régies"
  "https://swisssolar.github.io/|SSS|SSS OS (collaborateurs)"
  "https://www.swisssolarsystem.ch/||Site web"
)

problemes=()
note() { echo "$1"; }

# 1. DNS chez le fournisseur qui fait foi (détecte une migration DNS tout de suite,
#    avant même que les caches d'Internet ne l'oublient), puis chez deux DNS publics.
ns=$(dig +short NS swisssolarsystem.ch @1.1.1.1 | head -1)
for serveur in "$ns" 1.1.1.1 8.8.8.8; do
  [ -z "$serveur" ] && continue
  vu=$(dig +short CNAME "$PORTAIL_HOST" @"$serveur" | head -1)
  if [ "$vu" = "$PORTAIL_CIBLE" ]; then
    note "OK   DNS $PORTAIL_HOST chez $serveur"
  else
    problemes+=("DNS : $PORTAIL_HOST n'a plus la bonne adresse chez $serveur (vu : '${vu:-aucune}', attendu : $PORTAIL_CIBLE). À recréer dans la zone DNS de swisssolarsystem.ch (fournisseur actuel : ${ns:-inconnu}) : CNAME monitor → $PORTAIL_CIBLE")
  fi
done

# 2. Les pages répondent (3 essais espacés pour éviter les fausses alertes).
for ligne in "${URLS[@]}"; do
  IFS='|' read -r url attendu nom <<< "$ligne"
  ok=0
  for essai in 1 2 3; do
    corps=$(curl -sS -L --max-time 20 -w '\n%{http_code}' "$url" 2>/dev/null) || corps=$'\n000'
    code=$(printf '%s' "$corps" | tail -n1)
    if [ "$code" = "200" ] && { [ -z "$attendu" ] || printf '%s' "$corps" | grep -q "$attendu"; }; then ok=1; break; fi
    sleep 20
  done
  if [ $ok = 1 ]; then note "OK   $nom ($url)"; else problemes+=("$nom injoignable : $url (dernier code HTTP : $code)"); fi
done

# 3. Certificat HTTPS du portail : alerte 14 jours avant expiration.
fin=$(echo | openssl s_client -servername "$PORTAIL_HOST" -connect "$PORTAIL_HOST:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$fin" ]; then
  jours=$(( ( $(date -d "$fin" +%s) - $(date +%s) ) / 86400 ))
  if [ "$jours" -lt 14 ]; then problemes+=("Certificat HTTPS du portail : expire dans $jours jour(s)"); else note "OK   Certificat HTTPS du portail ($jours jours restants)"; fi
else
  problemes+=("Certificat HTTPS du portail illisible")
fi

if [ ${#problemes[@]} -gt 0 ]; then
  printf '%s\n' "${problemes[@]}" > problemes.txt
  echo; echo "PANNE :"; printf ' - %s\n' "${problemes[@]}"
  exit 1
fi
echo; echo "Tout fonctionne."
