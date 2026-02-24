const waveCheckoutService = require('./waveCheckoutService');

class PaymentService {
  constructor(paymentMethod = '') {
    this.paymentMethod = String(paymentMethod || '').toLowerCase();
  }

  async createPaymentSession({
    transactionId,
    contractId,
    amount,
    description,
    customerPhone,
  }) {
    if (this.paymentMethod === 'wave') {
      const waveResult = await waveCheckoutService.createCheckoutSession({
        amount,
        customerPhone,
        description,
        clientReference: `CONTRACT-${contractId || 'N/A'}-TX-${transactionId || Date.now()}`,
        metadata: {
          transactionId: transactionId || null,
          contractId: contractId || null,
          scope: 'contract-premium',
        },
      });

      if (!waveResult.success) {
        return {
          success: false,
          message: waveResult.message || 'Impossible de créer la session Wave',
          error: waveResult.error,
        };
      }

      return {
        success: true,
        data: {
          provider: 'Wave',
          transactionId,
          sessionId: waveResult.sessionId,
          launchUrl: waveResult.launchUrl,
          status: waveResult.status || 'pending',
          raw: waveResult.data,
        },
      };
    }

    if (this.paymentMethod === 'corismoney' || this.paymentMethod === 'orange money' || this.paymentMethod === 'orangemoney') {
      return {
        success: true,
        data: {
          provider: this.paymentMethod.includes('orange') ? 'Orange Money' : 'CORIS Money',
          transactionId,
          status: 'pending',
          message: 'Session créée. Confirmation manuelle requise pour cette méthode.',
        },
      };
    }

    return {
      success: false,
      message: `Méthode de paiement non supportée: ${this.paymentMethod}`,
    };
  }

  async verifyPayment(paymentSession) {
    if (this.paymentMethod === 'wave') {
      const sessionId = this._extractSessionId(paymentSession);

      if (!sessionId) {
        return {
          success: false,
          data: { status: 'failed' },
          message: 'sessionId Wave introuvable pour la vérification',
        };
      }

      const statusResult = await waveCheckoutService.getCheckoutSession(sessionId);
      if (!statusResult.success) {
        return {
          success: false,
          data: { status: 'pending' },
          message: statusResult.message || 'Impossible de vérifier le statut Wave',
          error: statusResult.error,
        };
      }

      return {
        success: true,
        data: {
          status: this._mapWaveStatus(statusResult.status),
          providerStatus: statusResult.status,
          sessionId: statusResult.sessionId || sessionId,
          raw: statusResult.data,
        },
      };
    }

    if (this.paymentMethod === 'corismoney' || this.paymentMethod === 'orange money' || this.paymentMethod === 'orangemoney') {
      return {
        success: true,
        data: {
          status: 'pending',
          message: 'Vérification provider non implémentée sur cette route pour cette méthode.',
        },
      };
    }

    return {
      success: false,
      data: { status: 'failed' },
      message: `Méthode de paiement non supportée: ${this.paymentMethod}`,
    };
  }

  _extractSessionId(paymentSession) {
    if (!paymentSession) return null;

    if (typeof paymentSession === 'string') {
      return paymentSession;
    }

    return (
      paymentSession.sessionId ||
      paymentSession.id ||
      paymentSession.waveSessionId ||
      paymentSession.checkoutSessionId ||
      null
    );
  }

  _mapWaveStatus(providerStatus = '') {
    const normalized = String(providerStatus).toLowerCase();

    if (['complete', 'completed', 'paid', 'success', 'successful'].includes(normalized)) {
      return 'completed';
    }

    if (['failed', 'failure', 'cancelled', 'canceled', 'expired'].includes(normalized)) {
      return 'failed';
    }

    return 'pending';
  }
}

module.exports = PaymentService;
