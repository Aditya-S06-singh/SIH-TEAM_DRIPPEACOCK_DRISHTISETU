/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gov: {
          navy: '#0B2545',
          blue: '#134074',
          light: '#EEF4F8',
          accent: '#1D4ED8',
          gold: '#B45309'
        },
        risk: {
          green: '#15803D',
          amber: '#D97706',
          red: '#DC2626'
        }
      }
    },
  },
  plugins: [],
}
