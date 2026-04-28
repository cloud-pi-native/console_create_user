#!/usr/bin/env bash
set -euo pipefail

# Tracking arrays
ADDED=()
UNKNOWN_EMAILS=()
UNKNOWN_GROUPS=()

get_user_id() {
  local email="$1"
  echo "  → Recherche utilisateur pour : $email" 1>&2
  local response
  response=$(curl -k -s --request GET \
    --header "PRIVATE-TOKEN: $MAINT_GITLAB_TOKEN" \
    --url "$MAINT_GITLAB_URL/api/v4/users?search=$email")

  local user_id
  user_id=$(echo "$response" | jq -r '.[0].id // empty')

  if [[ -z "$user_id" || "$user_id" == "null" ]]; then
    echo "  ✗ Aucun utilisateur trouvé pour $email" 1>&2
    return 1
  fi

  echo "  ✓ Utilisateur trouvé (id: $user_id)" 1>&2
  echo "$user_id"
}

update_user_access_level() {
  local user_id="$1"
  local group_id="$2"
  local email="$3"

  echo "  → Ajout du droit maintainer (user: $user_id, group: $group_id)" 1>&2
  local response
  response=$(curl -k -s --request PUT \
    --header "PRIVATE-TOKEN: $MAINT_GITLAB_TOKEN" \
    --url "$MAINT_GITLAB_URL/api/v4/groups/$group_id/members/$user_id?access_level=40")

  # Détection d'erreur dans la réponse GitLab
  local error_msg
  error_msg=$(echo "$response" | jq -r '.message // empty')

  if [[ -n "$error_msg" ]]; then
    echo "  ✗ Erreur GitLab : $error_msg" 1>&2
    # Distinguer groupe introuvable vs autre erreur
    if echo "$error_msg" | grep -qi "not found\|404\|doesn't exist"; then
      UNKNOWN_GROUPS+=("$group_id")
    else
      # Erreur inattendue : on la logue mais on ne l'ignore pas silencieusement
      echo "  ⚠ Erreur inattendue pour $email / group $group_id : $error_msg" 1>&2
    fi
    return 1
  fi

  echo "  ✓ Droit maintainer ajouté pour $email sur le groupe $group_id" 1>&2
  ADDED+=("$email → group $group_id")
}

get_group_name() {
  local group_id="$1"
  local response
  response=$(curl -k -s --request GET \
    --header "PRIVATE-TOKEN: $MAINT_GITLAB_TOKEN" \
    --url "$MAINT_GITLAB_URL/api/v4/groups/$group_id")
  echo "$response" | jq -r '.name // "nom inconnu"'
}

# Lecture du CSV et traitement
while IFS=, read -r email group_id; do

  if [[ -z "$email" ]]; then
    echo "Ligne ignorée (email vide)" 1>&2
    continue
  fi

  # Nettoyage des espaces éventuels
  email=$(echo "$email" | tr -d '\r' | xargs)
  group_id=$(echo "$group_id" | tr -d '\r' | xargs)

  echo "――――――――――――――――――――――――――――――――――" 1>&2
  echo "Traitement : $email / group $group_id" 1>&2

  user_id=$(get_user_id "$email" || true)

  if [[ -z "$user_id" ]]; then
    UNKNOWN_EMAILS+=("$email")
    continue
  fi

  update_user_access_level "$user_id" "$group_id" "$email" || true

done < <(echo "$USERS" | tr -d '\r' | sed '1s/^\xEF\xBB\xBF//')

# ══════════════════════════════════════════
# RÉCAPITULATIF
# ══════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════"
echo "RÉCAPITULATIF"
echo "══════════════════════════════════════════"
echo ""
echo "✓ Droits maintainer ajoutés : ${#ADDED[@]}"
for entry in "${ADDED[@]}"; do
  echo "    $entry"
done

# Déduplication
if [[ ${#UNKNOWN_EMAILS[@]} -gt 0 ]]; then
  readarray -t UNIQUE_UNKNOWN_EMAILS < <(printf '%s\n' "${UNKNOWN_EMAILS[@]}" | sort -u)
else
  UNIQUE_UNKNOWN_EMAILS=()
fi
if [[ ${#UNKNOWN_GROUPS[@]} -gt 0 ]]; then
  readarray -t UNIQUE_UNKNOWN_GROUPS < <(printf '%s\n' "${UNKNOWN_GROUPS[@]}" | sort -u)
else
  UNIQUE_UNKNOWN_GROUPS=()
fi

echo ""
echo "✗ Emails introuvables : ${#UNIQUE_UNKNOWN_EMAILS[@]}"
for email in "${UNIQUE_UNKNOWN_EMAILS[@]}"; do
  echo "    $email"
done

echo ""
echo "✗ Group IDs introuvables : ${#UNIQUE_UNKNOWN_GROUPS[@]}"
for gid in "${UNIQUE_UNKNOWN_GROUPS[@]}"; do
  group_name=$(get_group_name "$gid")
  echo "    $gid ($group_name)"
done
echo ""
