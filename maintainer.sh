#!/usr/bin/env bash
set -euo pipefail

get_user_id() {
  echo "getting user id for email: $USER_EMAIL" 1>&2
  response=$(curl -k -s --request GET --header "PRIVATE-TOKEN: $MAINT_GITLAB_TOKEN" --url "$MAINT_GITLAB_URL/api/v4/users?search=$USER_EMAIL")
  echo "user response: $response" 1>&2
  user_id=$(echo "$response" | jq -r '.[0].id // empty')
  echo "user id: ${user_id:-<none>}" 1>&2
  if [[ -z "$user_id" || "$user_id" == "null" ]]; then
    return 1
  fi
  echo "$user_id"
}


update_user_access_level() {
  echo "updating user access level for user id: $USER_ID and group id: $GROUP_ID"
  response=$(curl -k -s --request PUT --header "PRIVATE-TOKEN: $MAINT_GITLAB_TOKEN" --url "$MAINT_GITLAB_URL/api/v4/groups/$GROUP_ID/members/$USER_ID?access_level=40")
  echo "group response: $response"
}

#Read csv env variable and update user access level
while IFS=, read -r email group_id; do
  # if email is empty, skip
  if [[ -z "$email" ]]; then
    echo "Email is empty, skipping" 1>&2
    continue
  fi
  echo "Email: $email, Group ID: $group_id"
  USER_EMAIL=$email
  USER_ID=$(get_user_id || true)
  if [[ -z "$USER_ID" ]]; then
    echo "No user found for $USER_EMAIL, skipping" 1>&2
    continue
  fi
  GROUP_ID=$group_id
  update_user_access_level
done < <(echo "$USERS" | tail -n +2)