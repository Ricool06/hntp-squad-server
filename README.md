# hntp-squad-server
Config and other guff that needs to be stored remotely so we can run administer the Squad server with Pterodactyl Panel

# How to use
1. [Make a Github app](https://docs.github.com/en/developers/apps) with the permissions scope set to a single file: `backup/squadserverbackup.tar.gz.gpg`

1. Create and download a private key for you github app.

1. Install the Github app in your chosen repo.

1. Your Github app RSA private key (usually a .pem file) should be stored in `./secrets/<private-key-file>.pem`

1. The following env vars need to be set for `./backup.sh` to run:
    - SERVERCONFIG_FOLDER: the location of the Squad `ServerConfig` folder (usually something like `/home/steam/squad-dedicated/SquadGame/SquadServer`)
    - GITHUB_APP_KEY_FILENAME: the path to the github app RSA private key (e.g. `./secrets/hntp-config-manager.pem`)
    - BACKUP_ENCRYPTION_PASSPHRASE: the passphrase with which to encrypt the backup `.tar.gz` file that stores the contents of the `ServerConfig` folder (make it a strong password if you can)

1. Once these variables have been set, you should be able to run `./backup.sh` and the download url and instructions for decryption will be displayed.

# Requirements
- `base64url` (can be installed with `sudo apt install basez`)
- `jq` (can be installed with `sudo apt install jq`)
- `openssl`
- `curl`
- `gpg`
