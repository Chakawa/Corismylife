const axios = require('axios');
const crypto = require('crypto');

class WaveCheckoutService {
  constructor() {
    this.baseURL = process.env.WAVE_API_BASE_URL || 'https://api.wave.com';
    this.apiKey = process.env.WAVE_API_KEY || '';
    this.checkoutPath = process.env.WAVE_CHECKOUT_PATH || '/v1/checkout/sessions';
    this.sessionStatusPath = process.env.WAVE_SESSION_STATUS_PATH || '/v1/checkout/sessions/{sessionId}';
    this.webhookSecret = process.env.WAVE_WEBHOOK_SECRET || '';

    this.defaultCurrency = process.env.WAVE_DEFAULT_CURRENCY || 'XOF';
    this.defaultSuccessUrl = process.env.WAVE_SUCCESS_URL || 'https://example.com/wave-success';
    this.defaultErrorUrl = process.env.WAVE_ERROR_URL || 'https://example.com/wave-error';
    this.defaultWebhookUrl = process.env.WAVE_WEBHOOK_URL || 'https://example.com/api/payment/wave/webhook';

    this.devMode = process.env.WAVE_DEV_MODE !== 'false';

    if (this.devMode) {
      console.log('🧪 WAVE DEV MODE ACTIVÉ (simulation checkout)');
    } else {
      console.log('💳 WAVE PRODUCTION MODE ACTIVÉ');
      console.log('🔗 Wave API:', this.baseURL);
    }
  }

  // Vérifie qu'une URL est bien en HTTPS (exigence Wave pour success/error URL).
  _isHttpsUrl(value) {
    if (!value || typeof value !== 'string') return false;
    try {
      const parsed = new URL(value);
      return parsed.protocol === 'https:';
    } catch (_) {
      return false;
    }
  }

  // Retourne une URL HTTPS valide. Si invalide, bascule vers un fallback sûr.
  _resolveRequiredHttpsUrl(value, fallbackPath) {
    if (this._isHttpsUrl(value)) return value;
    return `https://example.com${fallbackPath}`;
  }

  // Contrôle des credentials Wave en mode production.
  _checkCredentials() {
    if (this.devMode) return;
    if (!this.apiKey) {
      throw new Error('WAVE_API_KEY non configurée. Ajoutez-la dans le fichier .env');
    }
  }

  // Construit l'URL provider complète à partir d'un path relatif ou absolu.
  _buildUrl(path) {
    if (!path) return this.baseURL;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return `${this.baseURL}${path}`;
  }

  // Extrait sessionId depuis plusieurs formats possibles de réponse Wave.
  _extractSessionId(payload = {}) {
    return (
      payload.id ||
      payload.sessionId ||
      payload.checkout_session_id ||
      payload.session_id ||
      payload.reference ||
      payload.checkout_session?.id ||
      payload.session?.id ||
      payload.data?.id ||
      payload.data?.session_id ||
      payload.data?.checkout_session_id ||
      payload.transaction_id ||
      null
    );
  }

  // Extrait sessionId à partir de l'URL Wave (ex: /c/cos-xxxx) en fallback.
  _extractSessionIdFromUrl(url) {
    if (!url || typeof url !== 'string') return null;
    const match = url.match(/\/c\/(cos-[a-z0-9]+)/i);
    return match ? match[1] : null;
  }

  // Récupère la première valeur non-vide dans une liste de chemins JSON.
  _pick(payload, paths = []) {
    for (const path of paths) {
      const parts = path.split('.');
      let current = payload;
      let found = true;
      for (const key of parts) {
        if (current && Object.prototype.hasOwnProperty.call(current, key)) {
          current = current[key];
        } else {
          found = false;
          break;
        }
      }
      if (found && current !== undefined && current !== null && `${current}` !== '') {
        return current;
      }
    }
    return null;
  }

  async createCheckoutSession({
    amount,
    currency,
    clientReference,
    successUrl,
    errorUrl,
    webhookUrl,
    description,
    customerPhone,
    metadata = {},
  }) {
    this._checkCredentials();

    const normalizedAmount = Number(amount);
    const normalizedCurrency = currency || this.defaultCurrency;
    const zeroDecimalCurrencies = new Set(['XOF']);
    const currencyCode = String(normalizedCurrency).toUpperCase();
    const amountForProvider = zeroDecimalCurrencies.has(currencyCode)
      ? Math.round(normalizedAmount)
      : normalizedAmount;
    const resolvedSuccessUrl = this._resolveRequiredHttpsUrl(
      successUrl || this.defaultSuccessUrl,
      '/wave-success'
    );
    const resolvedErrorUrl = this._resolveRequiredHttpsUrl(
      errorUrl || this.defaultErrorUrl,
      '/wave-error'
    );

    if (!Number.isFinite(amountForProvider) || amountForProvider <= 0) {
      return {
        success: false,
        message: 'Montant invalide pour la session Wave',
      };
    }

    if (this.devMode) {
      const fakeSessionId = `WAVE-DEV-${Date.now()}`;
      return {
        success: true,
        sessionId: fakeSessionId,
        launchUrl: `https://wave.com/checkout/${fakeSessionId}`,
        status: 'pending',
        data: {
          id: fakeSessionId,
          amount: amountForProvider,
          currency: normalizedCurrency,
          status: 'pending',
          wave_launch_url: `https://wave.com/checkout/${fakeSessionId}`,
          success_url: resolvedSuccessUrl,
          error_url: resolvedErrorUrl,
          customer_phone: customerPhone || null,
          description: description || 'Paiement assurance CORIS',
          metadata,
          created_at: new Date().toISOString(),
          simulated: true,
        },
      };
    }

    // Payload de création session: mode polling par défaut (webhook optionnel explicite).
    const payload = {
      amount: amountForProvider,
      currency: normalizedCurrency,
      client_reference: clientReference || `REF-${Date.now()}`,
      success_url: resolvedSuccessUrl,
      error_url: resolvedErrorUrl,
    };

    // Ajouter webhook uniquement si explicitement demandé.
    if (webhookUrl) {
      payload.webhook_url = webhookUrl;
    }

    // Ajouter customer uniquement si numéro fourni.
    if (customerPhone) {
      payload.customer = {
        phone_number: customerPhone,
      };
    }

    try {
      const response = await axios.post(
        this._buildUrl(this.checkoutPath),
        payload,
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 20000,
        }
      );

      const data = response.data || {};
      let sessionId = this._extractSessionId(data);
      const launchUrl = this._pick(data, [
        'wave_launch_url',
        'launch_url',
        'checkout_url',
        'url',
        'payment_url',
        'checkout_session.wave_launch_url',
        'checkout_session.launch_url',
        'checkout_session.checkout_url',
        'checkout_session.url',
        'data.wave_launch_url',
        'data.launch_url',
        'data.checkout_url',
        'data.url',
      ]);

      if (!sessionId && launchUrl) {
        sessionId = this._extractSessionIdFromUrl(launchUrl);
      }

      const resolvedLaunchUrl =
        launchUrl || (sessionId ? `https://pay.wave.com/c/${sessionId}` : null);

      if (!sessionId || !resolvedLaunchUrl) {
        return {
          success: false,
          message: 'Réponse Wave incomplète: sessionId ou URL de lancement manquant',
          error: data,
        };
      }

      return {
        success: true,
        sessionId,
        launchUrl: resolvedLaunchUrl,
        status: data.status || 'pending',
        data,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || 'Erreur lors de la création de la session Wave',
        error: error.response?.data || error.message,
      };
    }
  }

  async getCheckoutSession(sessionId) {
    if (!sessionId) {
      return {
        success: false,
        message: 'sessionId Wave requis',
      };
    }

    this._checkCredentials();

    if (this.devMode) {
      const lower = sessionId.toLowerCase();
      const status = lower.includes('fail')
        ? 'failed'
        : lower.includes('cancel')
            ? 'cancelled'
            : 'completed';

      return {
        success: true,
        sessionId,
        status,
        data: {
          id: sessionId,
          status,
          wave_launch_url: `https://wave.com/checkout/${sessionId}`,
          simulated: true,
          updated_at: new Date().toISOString(),
        },
      };
    }

    const statusPath = this.sessionStatusPath.replace('{sessionId}', encodeURIComponent(sessionId));

    try {
      const response = await axios.get(this._buildUrl(statusPath), {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
      });

      const data = response.data || {};
      const resolvedStatus = this._pick(data, [
        'status',
        'payment_status',
        'checkout_status',
        'checkout_session.status',
        'session.status',
        'data.status',
      ]) || 'pending';

      return {
        success: true,
        sessionId: this._extractSessionId(data) || sessionId,
        status: resolvedStatus,
        data,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || 'Erreur lors de la récupération du statut Wave',
        error: error.response?.data || error.message,
      };
    }
  }

  verifyWebhookSignature({ signature, rawBody }) {
    if (!this.webhookSecret) {
      return true;
    }

    if (!signature || !rawBody) {
      return false;
    }

    try {
      // Wave-Signature header format: "t=<timestamp>,v1=<hex_signature>[,v1=<hex_signature2>]"
      const parts = String(signature).trim().split(',');

      const timestampPart = parts.find(p => p.startsWith('t='));
      if (!timestampPart) return false;
      const timestamp = timestampPart.split('=')[1];

      const v1Signatures = parts
        .filter(p => p.startsWith('v1='))
        .map(p => p.slice(3)); // remove "v1=" prefix

      if (v1Signatures.length === 0) return false;

      // Per Wave docs: HMAC-SHA256 of (timestamp + rawBody) using the webhook secret
      const computedHmac = crypto
        .createHmac('sha256', this.webhookSecret)
        .update(timestamp + rawBody, 'utf8')
        .digest('hex');

      // Compare against all provided v1 signatures (supports key rotation)
      return v1Signatures.some(sig => {
        try {
          const sigBuf = Buffer.from(sig, 'utf8');
          const hmacBuf = Buffer.from(computedHmac, 'utf8');
          return sigBuf.length === hmacBuf.length &&
            crypto.timingSafeEqual(sigBuf, hmacBuf);
        } catch {
          return false;
        }
      });
    } catch (error) {
      return false;
    }
  }
}

module.exports = new WaveCheckoutService();