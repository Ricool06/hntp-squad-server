#!/usr/bin/bash

set -euo pipefail

test -d ${SERVERCONFIG_FOLDER} || { echo "ServerConfig folder not found. (try setting env var SERVERCONFIG_FOLDER)"; exit 1; }
test -f ${GITHUB_APP_KEY_FILENAME} || { echo "Github app key file not found. Could not backup server config. (try setting env var GITHUB_APP_KEY_FILENAME)"; exit 1; }
test -n ${BACKUP_ENCRYPTION_PASSPHRASE} || { echo "Passphrase not set for backup file. (try setting env var BACKUP_ENCRYPTION_PASSPHRASE)"; exit 1; }

backup_content=$(tar -C ${SERVERCONFIG_FOLDER} -czf - ./ | gpg --symmetric --cipher-algo aes256 --batch --passphrase ${BACKUP_ENCRYPTION_PASSPHRASE} | base64 -w 0)

# Backup via github API
now=$(date +%s)

jwt_header=$(cat <<EOF |
{
  "alg": "RS256",
  "typ": "JWT"
}
EOF
jq -Mcj '.' | base64 - | tr -d '=')

jwt_claims=$(cat <<EOF |
{
  "iat": $((${now} - 60)),
  "exp": $((${now} + (60 * 10))),
  "iss": "222321"
}
EOF
jq -Mcj '.' | base64 - | tr -d '=')

jwt_payload=${jwt_header}.${jwt_claims}

jwt_signature=$(printf '%s' "${jwt_payload}" | openssl dgst -sha256 -sign "${GITHUB_APP_KEY_FILENAME}" -binary | base64url -w 0 - | tr -d '=')

jwt=${jwt_header}.${jwt_claims}.${jwt_signature}

echo "Fetching Github app installation ID"
installation_id=$(curl -s -H "Authorization: Bearer ${jwt}" -H "Accept: application/vnd.github+json" https://api.github.com/app/installations | \
jq -c '.[] | select(.app_slug | contains("hntp-squad-server-config-manager")) | .id')

echo "Fetching Github app installation auth token"
installation_auth_token=$(curl -s -X POST \
-H "Authorization: Bearer ${jwt}" \
-H "Accept: application/vnd.github+json" \
"https://api.github.com/app/installations/${installation_id}/access_tokens" | jq -cr '.token')

echo "Fetching existing backup sha"
existing_backup_sha=$(curl -s \
  -X GET \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token ${installation_auth_token}" \
  https://api.github.com/repos/Ricool06/hntp-squad-server/contents/backup/squadserverbackup.tar.gz.gpg | jq -cr '.sha')

echo "Pushing backup to repo"
backup_response=$(curl \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token ${installation_auth_token}" \
  https://api.github.com/repos/Ricool06/hntp-squad-server/contents/backup/squadserverbackup.tar.gz.gpg \
  -d @- <<- EOF
{
  "message":"my commit message",
  "committer": {
    "name":"Brick",
    "email":"brick@ricool.uk"
  },
  "content":"${backup_content}",
  "sha":"${existing_backup_sha}"
}
EOF
)

download_url=$(echo ${backup_response} | jq -c '.content.download_url')

echo "Backup created. Download from ${download_url}"
echo 'Then decrypt the backup file with: gpg --batch --passphrase ${BACKUP_ENCRYPTION_PASSPHRASE} -d ./squadserverbackup.tar.gz.gpg | tar xzf -'
