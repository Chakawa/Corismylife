import React, { useState } from 'react';
import './CorisMoneyPaymentModal.css';
import API_URL from '../config';

const CorisMoneyPaymentModal = ({ isOpen, onClose, onPaymentSuccess, montant, subscriptionId, description }) => {
  const [step, setStep] = useState(1); // 1: Formulaire, 2: OTP envoyé, 3: Paiement en cours
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const [formData, setFormData] = useState({
    codePays: '225', // Côte d'Ivoire par défaut
    telephone: '',
    codeOTP: '',
  });

  const [transactionResult, setTransactionResult] = useState(null);

  // Réinitialiser le formulaire
  const resetForm = () => {
    setStep(1);
    setFormData({ codePays: '225', telephone: '', codeOTP: '' });
    setError('');
    setSuccess(false);
    setTransactionResult(null);
  };

  // Fermer la modal
  const handleClose = () => {
    resetForm();
    onClose();
  };

  // Gérer les changements de formulaire
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setError(''); // Effacer l'erreur lors de la saisie
  };

  // Étape 1: Envoyer le code OTP
  const handleSendOTP = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (!formData.telephone || formData.telephone.length < 8) {
      setError('Veuillez entrer un numéro de téléphone valide');
      setLoading(false);
      return;
    }

    try {
      const token = localStorage.getItem('adminToken');
      const response = await fetch(`${API_URL}/payment/send-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          codePays: formData.codePays,
          telephone: formData.telephone
        })
      });

      const data = await response.json();

      if (data.success) {
        setStep(2);
        setError('');
      } else {
        setError(data.message || 'Erreur lors de l\'envoi du code OTP');
      }
    } catch (err) {
      console.error('Erreur:', err);
      setError('Erreur de connexion au serveur');
    } finally {
      setLoading(false);
    }
  };

  // Étape 2: Traiter le paiement avec OTP
  const handleProcessPayment = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setStep(3);

    // Validation
    if (!formData.codeOTP || formData.codeOTP.length < 4) {
      setError('Veuillez entrer le code OTP reçu');
      setLoading(false);
      setStep(2);
      return;
    }

    try {
      const token = localStorage.getItem('adminToken');
      const response = await fetch(`${API_URL}/payment/process-payment`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          codePays: formData.codePays,
          telephone: formData.telephone,
          montant: montant,
          codeOTP: formData.codeOTP,
          subscriptionId: subscriptionId,
          description: description || 'Paiement de prime d\'assurance'
        })
      });

      const data = await response.json();

      if (data.success) {
        setSuccess(true);
        setTransactionResult(data);
        
        // Appeler le callback de succès
        if (onPaymentSuccess) {
          onPaymentSuccess(data);
        }

        // Fermer automatiquement après 3 secondes
        setTimeout(() => {
          handleClose();
        }, 3000);
      } else {
        setError(data.message || 'Erreur lors du paiement');
        setStep(2); // Retourner à l'étape OTP pour réessayer
      }
    } catch (err) {
      console.error('Erreur:', err);
      setError('Erreur de connexion au serveur');
      setStep(2);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="corismoney-modal-overlay" onClick={handleClose}>
      <div className="corismoney-modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="corismoney-modal-header">
          <h2>
            <span className="payment-icon">💳</span>
            Paiement CorisMoney
          </h2>
          <button className="close-btn" onClick={handleClose}>×</button>
        </div>

        <div className="corismoney-modal-body">
          {/* Affichage du montant */}
          <div className="payment-amount-display">
            <span>Montant à payer:</span>
            <strong>{parseFloat(montant).toLocaleString('fr-FR')} FCFA</strong>
          </div>

          {/* Étape 1: Formulaire téléphone */}
          {step === 1 && (
            <form onSubmit={handleSendOTP} className="payment-form">
              <div className="form-group">
                <label htmlFor="codePays">Code Pays</label>
                <select
                  id="codePays"
                  name="codePays"
                  value={formData.codePays}
                  onChange={handleChange}
                  disabled={loading}
                >
                  <option value="225">🇨🇮 Côte d'Ivoire (+225)</option>
                  <option value="226">🇧🇫 Burkina Faso (+226)</option>
                  <option value="223">🇲🇱 Mali (+223)</option>
                  <option value="227">🇳🇪 Niger (+227)</option>
                </select>
              </div>

              <div className="form-group">
                <label htmlFor="telephone">Numéro de téléphone CorisMoney</label>
                <input
                  type="tel"
                  id="telephone"
                  name="telephone"
                  placeholder="Ex: 0102030405"
                  value={formData.telephone}
                  onChange={handleChange}
                  disabled={loading}
                  required
                />
                <small>Entrez le numéro associé à votre compte CorisMoney</small>
              </div>

              {error && <div className="error-message">{error}</div>}

              <div className="form-actions">
                <button type="button" onClick={handleClose} className="btn-secondary" disabled={loading}>
                  Annuler
                </button>
                <button type="submit" className="btn-primary" disabled={loading}>
                  {loading ? 'Envoi...' : 'Recevoir le code OTP'}
                </button>
              </div>
            </form>
          )}

          {/* Étape 2: Saisie du code OTP */}
          {step === 2 && (
            <form onSubmit={handleProcessPayment} className="payment-form">
              <div className="otp-info">
                <p>✅ Un code OTP a été envoyé au <strong>+{formData.codePays} {formData.telephone}</strong></p>
                <p>Veuillez entrer le code reçu pour confirmer le paiement.</p>
              </div>

              <div className="form-group">
                <label htmlFor="codeOTP">Code OTP</label>
                <input
                  type="text"
                  id="codeOTP"
                  name="codeOTP"
                  placeholder="Entrez le code reçu"
                  value={formData.codeOTP}
                  onChange={handleChange}
                  disabled={loading}
                  required
                  maxLength="6"
                  className="otp-input"
                />
              </div>

              {error && <div className="error-message">{error}</div>}

              <div className="form-actions">
                <button 
                  type="button" 
                  onClick={() => setStep(1)} 
                  className="btn-secondary" 
                  disabled={loading}
                >
                  Retour
                </button>
                <button type="submit" className="btn-primary" disabled={loading}>
                  {loading ? 'Traitement...' : 'Confirmer le paiement'}
                </button>
              </div>
            </form>
          )}

          {/* Étape 3: Paiement en cours / Succès */}
          {step === 3 && (
            <div className="payment-status">
              {loading && (
                <div className="loading-spinner">
                  <div className="spinner"></div>
                  <p>Traitement du paiement en cours...</p>
                </div>
              )}

              {success && transactionResult && (
                <div className="success-message">
                  <div className="success-icon">✅</div>
                  <h3>Paiement réussi !</h3>
                  <div className="transaction-details">
                    <p><strong>ID Transaction:</strong> {transactionResult.transactionId}</p>
                    <p><strong>Montant:</strong> {parseFloat(transactionResult.montant).toLocaleString('fr-FR')} FCFA</p>
                  </div>
                  <p className="auto-close-message">Cette fenêtre se fermera automatiquement...</p>
                </div>
              )}

              {error && !loading && (
                <div className="error-message">
                  <p>{error}</p>
                  <button onClick={() => setStep(2)} className="btn-primary">
                    Réessayer
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default CorisMoneyPaymentModal;
