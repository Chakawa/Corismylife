const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/upload');


const {
  createSubscription,
  updateSubscriptionStatus,
  updatePaymentStatus,
  uploadDocument,
  getUserPropositions,   
  getUserContracts,
  getSubscriptionWithUserDetails,
  getSubscriptionPDF,
  attachProposal
} = require('../controllers/subscriptionController');

// Routes
router.post('/create', verifyToken, createSubscription);
router.put('/:id/status', verifyToken, updateSubscriptionStatus);
router.put('/:id/payment-status', verifyToken, updatePaymentStatus);
router.post('/:id/upload-document', verifyToken, upload.single('document'), uploadDocument);
router.get('/user/propositions', verifyToken, getUserPropositions);
router.get('/user/contrats', verifyToken, getUserContracts);
router.get('/:id', verifyToken, getSubscriptionWithUserDetails);
router.get('/:id/pdf', verifyToken, getSubscriptionPDF);
router.post('/attach', verifyToken, attachProposal);
module.exports = router;