# OPERATOR_HANDOFF.md

## Section One: Pre-Launch Manual Steps
Before pointing real traffic at the system, the operator must verify the following items:

1.  **Twilio Physical Verification**: Run the following command with a physical phone number you control to ensure SMS delivery works end-to-end.
    ```bash
    docker exec alzai-backend python -c "from app.services.twilio_service import send_sms; import asyncio; asyncio.run(send_sms('+91YOUR_REAL_NUMBER', 'Alz-AI final production verification'))"
    ```
2.  **Database Connection Check**: Confirm only your authorized users (Currently: 2) are present.
    ```bash
    docker exec alzai-db psql -U alzai -d alzai -c "SELECT id, email, role FROM users;"
    ```
3.  **Port 443 Accessibility**: Ensure your firewall permits inbound traffic on port 443.

## Section Two: Credentials Location
The production passwords for Redis, Neo4j, and Minio have been generated and stored in:
`PRODUCTION_SECRETS.txt` (Project Root)

> [!CAUTION]
> Back up this file to a secure off-site password manager immediately. It is in `.gitignore` and will not be committed to version control.

## Section Three: SSL Certificate Upgrade
The system is currently running on a self-signed certificate for internal network compatibility. Once you have a domain name (e.g., `app.alz-ai.org`), replace the self-signed cert with a valid Let's Encrypt certificate using these commands:

1.  Install Certbot and run basic certificate generation (assumes port 80 is open and DNS is set):
    ```bash
    # (On the host)
    docker run -it --rm --name certbot \
      -v "$(pwd)/certs:/etc/letsencrypt" \
      certbot/certbot certonly --standalone -d app.alz-ai.org
    ```
2.  Update Nginx to point to the new files by updating paths in `nginx.conf` and running:
    ```bash
    docker exec alzai-nginx nginx -s reload
    ```

## Section Four: Mobile Release Build
To generate the final production APK for distribution:

1.  **Update Environment**: Open `mobile/assets/.env.production` and replace the placeholder `YOUR_SERVER_IP_OR_DOMAIN` with the actual server IP or domain name.
2.  **Build Release APK**: Run the following from the `mobile` directory:
    ```ps1
    flutter build apk --release --dart-define-from-file=assets/.env.production
    ```
    *Note: The signing keystore `upload-keystore.jks` and `key.properties` have already been initialized in the `mobile/android` structure.*

3.  **Keystore Details**:
    - **Alias**: `upload`
    - **Password**: `alzai_deploy_secret` (Stored in `mobile/android/key.properties`)
    - **Location**: `mobile/android/app/upload-keystore.jks`
