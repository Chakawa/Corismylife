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

  _checkCredentials() {
    if (this.devMode) return;
    if (!this.apiKey) {
      throw new Error('WAVE_API_KEY non configurée. Ajoutez-la dans le fichier .env');
    }
  }

  _buildUrl(path) {
    if (!path) return this.baseURL;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return `${this.baseURL}${path}`;
  }

  _extractSessionId(payload = {}) {
    return (
      payload.id ||
      payload.sessionId ||
      payload.checkout_session_id ||
      payload.session_id ||
      payload.reference ||
      payload.transaction_id ||
      null
    );
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
    const resolvedSuccessUrl = successUrl || this.defaultSuccessUrl;
    const resolvedErrorUrl = errorUrl || this.defaultErrorUrl;

    if (!Number.isFinite(normalizedAmount) || normalizedAmount <= 0) {
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
          amount: normalizedAmount,
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

    // ✅ Payload SANS webhook (mode polling uniquement)
    const payload = {
      amount: normalizedAmount,
      currency: normalizedCurrency,
      client_reference: clientReference || `REF-${Date.now()}`,
      success_url: resolvedSuccessUrl,
      error_url: resolvedErrorUrl,
      description: description || 'Paiement assurance CORIS',
      metadata,
    };

    // Ajouter webhook SEULEMENT s'il est explicitement fourni
    if (webhookUrl) {
      payload.webhook_url = webhookUrl;
    }

    // Ajouter customer SEULEMENT si numéro fourni
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
      const sessionId = this._extractSessionId(data);

      return {
        success: true,
        sessionId,
        launchUrl: data.wave_launch_url || data.launch_url || data.checkout_url || null,
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
      return {
        success: true,
        sessionId: this._extractSessionId(data) || sessionId,
        status: data.status || data.payment_status || 'pending',
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

    const expected = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(rawBody, 'utf8')
      .digest('hex');

    try {
      return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
    } catch (error) {
      return false;
    }
  }
}

module.exports = new WaveCheckoutService();