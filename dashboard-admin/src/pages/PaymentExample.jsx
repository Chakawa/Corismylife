import React, { useState } from 'react';
import CorisMoneyPaymentModal from '../components/CorisMoneyPaymentModal';

/**
 * Exemple d'utilisation du composant CorisMoneyPaymentModal
 * Ce fichier montre comment intégrer le paiement CorisMoney dans vos pages
 */
const PaymentExample = () => {
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentData, setPaymentData] = useState({
    montant: 50000, // Exemple: 50,000 FCFA
    subscriptionId: null,
    description: 'Paiement de prime d\'assurance'
  });

  // Gérer le succès du paiement
  const handlePaymentSuccess = (result) => {
    console.log('✅ Paiement réussi !', result);
    
    // Afficher une notification
    alert(`Paiement réussi !\nTransaction ID: ${result.transactionId}\nMontant: ${result.montant} FCFA`);
    
    // Rafraîchir les données ou rediriger l'utilisateur
    // window.location.reload();
    // navigate('/confirmation');
  };

  // Ouvrir la modal de paiement
  const openPaymentModal = () => {
    setIsPaymentModalOpen(true);
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>Exemple de Paiement CorisMoney</h1>
      
      <div style={{ marginTop: '20px', padding: '20px', border: '1px solid #ddd', borderRadius: '8px' }}>
        <h3>Détails du paiement</h3>
        <p><strong>Montant:</strong> {paymentData.montant.toLocaleString('fr-FR')} FCFA</p>
        <p><strong>Description:</strong> {paymentData.description}</p>
        
        <button 
          onClick={openPaymentModal}
          style={{
            marginTop: '15px',
            padding: '12px 24px',
            background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            fontSize: '1rem',
            cursor: 'pointer'
          }}
        >
          💳 Payer avec CorisMoney
        </button>
      </div>

      {/* Modal de paiement CorisMoney */}
      <CorisMoneyPaymentModal
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
        onPaymentSuccess={handlePaymentSuccess}
        montant={paymentData.montant}
        subscriptionId={paymentData.subscriptionId}
        description={paymentData.description}
      />

      {/* Instructions d'utilisation */}
      <div style={{ marginTop: '40px', padding: '20px', background: '#f8f9fa', borderRadius: '8px' }}>
        <h3>📚 Comment utiliser ce composant dans vos pages:</h3>
        
        <pre style={{ background: 'white', padding: '15px', borderRadius: '8px', overflow: 'auto' }}>
{`// 1. Importer le composant
import CorisMoneyPaymentModal from '../components/CorisMoneyPaymentModal';

// 2. Ajouter l'état pour gérer l'ouverture de la modal
const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);

// 3. Définir les données de paiement
const paymentData = {
  montant: 50000,
  subscriptionId: 123, // Optionnel
  description: 'Paiement de prime d\'assurance'
};

// 4. Créer la fonction de callback pour le succès
const handlePaymentSuccess = (result) => {
  console.log('Paiement réussi !', result);
  // Faire quelque chose après le paiement
};

// 5. Ajouter le composant dans votre JSX
<CorisMoneyPaymentModal
  isOpen={isPaymentModalOpen}
  onClose={() => setIsPaymentModalOpen(false)}
  onPaymentSuccess={handlePaymentSuccess}
  montant={paymentData.montant}
  subscriptionId={paymentData.subscriptionId}
  description={paymentData.description}
/>`}
        </pre>

        <h4>Props du composant:</h4>
        <ul>
          <li><strong>isOpen</strong> (boolean): Contrôle l'affichage de la modal</li>
          <li><strong>onClose</strong> (function): Fonction appelée lors de la fermeture</li>
          <li><strong>onPaymentSuccess</strong> (function): Callback appelé après un paiement réussi</li>
          <li><strong>montant</strong> (number): Montant à payer en FCFA</li>
          <li><strong>subscriptionId</strong> (number, optionnel): ID de la souscription associée</li>
          <li><strong>description</strong> (string, optionnel): Description du paiement</li>
        </ul>

        <h4>Flux de paiement:</h4>
        <ol>
          <li>L'utilisateur saisit son numéro CorisMoney</li>
          <li>Un code OTP est envoyé à son téléphone</li>
          <li>L'utilisateur entre le code OTP reçu</li>
          <li>Le paiement est traité</li>
          <li>Confirmation avec l'ID de transaction</li>
        </ol>
      </div>
    </div>
  );
};

export default PaymentExample;
