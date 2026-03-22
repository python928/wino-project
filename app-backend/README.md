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
- `users`: Unified user/store profile + registration + JWT endpoints.
- `catalog`: Categories, products, images, packs, reviews, promotions.
- `notifications`: Persistent notifications + FCM device endpoints.
- `subscriptions`: Subscription plans and subscriptions.
- `wallet`: Coin balances, transactions ledger, and coin purchase/grant endpoints.

## API entrypoints
- Auth: `/api/auth/token/`, `/api/auth/token/refresh/`, `/api/users/register/`
- Routers: `/api/users/`, `/api/catalog/`, `/api/notifications/`, `/api/subscriptions/`, `/api/wallet/`

## Monetization (Coins)
- Post Coins are consumed when publishing products/packs/promotions.
- Ad View Coins are consumed per delivered ad view; campaigns pause when balance reaches 0.
- Wallet endpoints live under `/api/wallet/`.
- `POST /api/wallet/buy/` creates a **pending** purchase request (coins are not granted immediately).
- Admin approval credits coins:
   - API: `POST /api/wallet/purchases/<purchase_id>/approve/`
   - Admin panel: `Wallet > Coin Purchases > Approve selected pending purchases`
- Wallet snapshot now includes both `recent_transactions` and `recent_purchases`.

## Notifications
 Notifications use FCM (fcm-django). Register devices via `/api/notifications/devices/` and ensure `FCM_SERVER_KEY` is set.

## Media & static
 Media is served at `/media/` when `DEBUG=True`.

## Environment
- Copy `./.env.example` to `./.env` and fill in values as needed.
- Defaults to SQLite; set `POSTGRES_*` env vars for Postgres (see `docker-compose.yml`).
- Redis/Celery are optional and only required if background jobs are enabled.
- `GOOGLE_APPLICATION_CREDENTIALS` should point to your Firebase Admin SDK JSON (kept out of git).

## Notes
- Remember to configure admin user: `/usr/bin/python3 manage.py createsuperuser`.
