const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const kyc = require('../controllers/kycController');

router.get('/requirements', verifyToken, kyc.listRequired);
router.get('/documents', verifyToken, kyc.listDocuments);
router.post('/upload', verifyToken, kyc.uploadMiddleware, kyc.uploadDocument);

module.exports = router;








