# Setup rapide Wave (backend)

## 1) Bloc `.env` prêt à coller

Copiez ce bloc dans `.env` puis adaptez les valeurs:

```env
# ============================================
# Configuration WAVE CHECKOUT
# ============================================
WAVE_DEV_MODE=true
WAVE_API_BASE_URL=https://api.wave.com
WAVE_API_KEY=VOTRE_CLE_API_WAVE_ICI
WAVE_CHECKOUT_PATH=/v1/checkout/sessions
WAVE_SESSION_STATUS_PATH=/v1/checkout/sessions/{sessionId}
WAVE_WEBHOOK_SECRET=VOTRE_WEBHOOK_SECRET_WAVE_ICI
WAVE_SUCCESS_URL=https://votre-domaine.com/wave-success
WAVE_ERROR_URL=https://votre-domaine.com/wave-error
WAVE_WEBHOOK_URL=https://votre-domaine.com/api/payment/wave/webhook
WAVE_DEFAULT_CURRENCY=XOF
```

## 2) Test rapide API locale

Script fourni: `test-wave-checkout.js`

### PowerShell

```powershell
cd d:\CORIS\app_coris\mycoris-master
$env:JWT_TOKEN="<votre_jwt>"
$env:SUBSCRIPTION_ID="123"
$env:AMOUNT="100"
node test-wave-checkout.js
```

## 3) Mode réel Wave

Pour basculer en réel:

- `WAVE_DEV_MODE=false`
- renseigner `WAVE_API_KEY`
- renseigner `WAVE_WEBHOOK_SECRET`
- mettre une URL publique valide dans `WAVE_WEBHOOK_URL`

## 4) Endpoints backend Wave

- `POST /api/payment/wave/create-session`
- `GET /api/payment/wave/status/:sessionId`
- `POST /api/payment/wave/webhook`
