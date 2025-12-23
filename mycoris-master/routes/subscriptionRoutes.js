const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../config/multer');


const {
  createSubscription,
  updateSubscription,
  updateSubscriptionStatus,
  updatePaymentStatus,
  uploadDocument,
  getUserPropositions,   
  getUserContracts,
  getSubscriptionWithUserDetails,
  getSubscriptionPDF,
  attachProposal,
  getDocument,
  getQuestionsQuestionnaireMedical,
  saveQuestionnaireMedical,
  getQuestionnaireMedical
} = require('../controllers/subscriptionController');

// Routes
router.post('/create', verifyToken, createSubscription);
router.put('/:id/update', verifyToken, updateSubscription);
router.put('/:id/status', verifyToken, updateSubscriptionStatus);
router.put('/:id/payment-status', verifyToken, updatePaymentStatus);
router.post('/:id/upload-document', verifyToken, upload.single('document'), uploadDocument);
router.get('/user/propositions', verifyToken, getUserPropositions);
router.get('/user/contrats', verifyToken, getUserContracts);
// Routes spécifiques AVANT les routes génériques
// Endpoint public pour les questions du questionnaire médical
router.get('/questionnaire-medical/questions', getQuestionsQuestionnaireMedical);
router.get('/:id/pdf', verifyToken, getSubscriptionPDF);
router.get('/:id/document/:filename', verifyToken, getDocument);
router.post('/:id/questionnaire-medical', verifyToken, saveQuestionnaireMedical);
router.get('/:id/questionnaire-medical', verifyToken, getQuestionnaireMedical);
// Route générique /:id EN DERNIER
router.get('/:id', verifyToken, getSubscriptionWithUserDetails);
router.post('/attach', verifyToken, attachProposal);
module.exports = router;