// En local, utiliser /api pour passer par le proxy Vite et éviter les soucis CORS.
const API_URL = import.meta.env.VITE_API_URL || '/api'

export default API_URL
