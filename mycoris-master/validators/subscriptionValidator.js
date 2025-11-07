const { body } = require('express-validator');

exports.validateSubscription = (req, res, next) => {
  const productType = req.body.product_type;
  
  let validations = [
    body('product_type').notEmpty().isIn([
      'coris_retraite', 'coris_etude', 'coris_serenite', 
      'coris_familis', 'coris_epargne_bonus', 'flex_emprunteur'
    ]),
    body('beneficiaire.nom').notEmpty(),
    body('beneficiaire.contact').notEmpty(),
    body('contact_urgence.nom').notEmpty(),
    body('contact_urgence.contact').notEmpty(),
    body('piece_identite').notEmpty()
  ];

  // Validations spécifiques selon le produit
  switch (productType) {
    case 'coris_retraite':
    case 'coris_serenite':
    case 'coris_familis':
      validations.push(
        body('prime').isNumeric(),
        body('capital').isNumeric(),
        body('duree').isInt(),
        body('periodicite').notEmpty()
      );
      break;
      
    case 'coris_etude':
      validations.push(
        body('duree_mois').isInt(),
        body('montant').isNumeric(),
        body('periodicite').notEmpty(),
        body('prime_calculee').isNumeric(),
        body('rente_calculee').isNumeric()
      );
      break;
      
    case 'coris_epargne_bonus':
      validations.push(
        body('capital').isNumeric(),
        body('prime_mensuelle').isNumeric(),
        body('duree_mois').isInt()
      );
      break;
      
    case 'flex_emprunteur':
      validations.push(
        body('type_pret').notEmpty(),
        body('capital').isNumeric(),
        body('duree').isInt(),
        body('prime_annuelle').isNumeric(),
        body('capital_garanti').isNumeric()
      );
      break;
  }

  return validations;
};