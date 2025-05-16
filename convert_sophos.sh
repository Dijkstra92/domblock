#!/bin/bash

# Demande source : fichier local ou URL
read -rp "Souhaitez-vous utiliser un fichier local ou une URL ? (local/url) : " SOURCE_TYPE

# Déterminer le fichier brut
if [[ "$SOURCE_TYPE" == "url" ]]; then
    read -rp "Entrez l'URL du fichier à télécharger : " URL
    RAW_FILE=$(mktemp)
    echo "Téléchargement depuis $URL..."
    curl -s "$URL" -o "$RAW_FILE"
    if [[ ! -s "$RAW_FILE" ]]; then
        echo "Erreur : le fichier n'a pas pu être téléchargé ou est vide."
        exit 1
    fi
elif [[ "$SOURCE_TYPE" == "local" ]]; then
    read -rp "Entrez le chemin complet du fichier local : " RAW_FILE
    if [[ ! -f "$RAW_FILE" || ! -s "$RAW_FILE" ]]; then
        echo "Erreur : le fichier est introuvable ou vide."
        exit 1
    fi
else
    echo "Entrée invalide. Veuillez taper 'local' ou 'url'."
    exit 1
fi

# Demander où enregistrer le fichier formaté
read -rp "Chemin complet du fichier de sortie (ex: /tmp/sophos_phishing_domains.txt) : " OUTPUT_FILE

# Traitement du fichier :
# - Ignore les commentaires (#)
# - Extrait les domaines depuis :
#     * lignes de type "0.0.0.0 domaine.com"
#     * lignes de type "||domaine.com^"
echo "Traitement du fichier..."
awk '
  /^[ \t]*#/ { next }                    # Ignorer les commentaires
  /^[ \t]*$/ { next }                    # Ignorer les lignes vides
  $1 ~ /^0\.0\.0\.0$/ || $1 ~ /^127\.0\.0\.1$/ { print $2; next }  # Format hosts
  $0 ~ /^\|\|.*\^$/ {
    gsub(/^\|\|/, "", $0); gsub(/\^$/, "", $0); print $0; next    # Format adblock
  }
' "$RAW_FILE" | sort -u > "$OUTPUT_FILE"

# Affichage du résultat
DOMAIN_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "Fichier formaté créé : $OUTPUT_FILE avec $DOMAIN_COUNT domaines."

# Nettoyage si fichier temporaire
if [[ "$SOURCE_TYPE" == "url" ]]; then
    rm -f "$RAW_FILE"
fi

