# Backend (Django + DRF)

## Quick start
1. Install dependencies (system Python):
   ```bash
   pip3 install -r requirements.txt --break-system-packages --default-timeout 300
   ```
2. Apply migrations:
   ```bash
   /usr/bin/python3 manage.py migrate
   ```
3. Run the server:
   ```bash
   /usr/bin/python3 manage.py runserver 0.0.0.0:8000
   ```

## Apps
- `users`: Custom `User` with roles, registration, JWT endpoints.
- `stores`: Store CRUD, followers with signals to notify owners.
- `catalog`: Categories, products, images, packs, reviews.
- `promotions`: Promotions with images; signals notify followers.
- `messaging`: Direct messages; signals push chat + notifications via FCM.
- `notifications`: Persistent notifications + FCM device endpoints.
- `subscriptions`: Subscription plans and merchant subscriptions.

## API entrypoints
- Auth: `/api/auth/token/`, `/api/auth/token/refresh/`, `/api/users/register/`
- Routers: `/api/users/`, `/api/stores/`, `/api/catalog/`, `/api/promotions/`, `/api/messaging/`, `/api/notifications/`, `/api/subscriptions/`

## Notifications
 Notifications use FCM (fcm-django). Register devices via `/api/notifications/devices/` and ensure `FCM_SERVER_KEY` is set.

## Media & static
 Set `FCM_SERVER_KEY` to your Firebase server key for push notifications.
## Environment
- Defaults to SQLite; set `POSTGRES_*` env vars for Postgres (see `docker-compose.yml`).
- Redis is not required.

## Notes
- Remember to configure admin user: `/usr/bin/python3 manage.py createsuperuser`.
