module.exports = (schema) => (req, res, next) => {
  if (!schema) return next();
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation échouée',
      details: error.details.map(d => ({ message: d.message, path: d.path }))
    });
  }
  req.body = value;
  next();
};