/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Couleurs CORIS (même que l'app mobile)
        'coris-blue': '#002B6B',
        'coris-red': '#E30613',
        'coris-blue-light': '#003A85',
        'coris-gray': '#F0F4F8',
        'coris-green': '#10B981',
        'coris-orange': '#F59E0B',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
