/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      backgroundImage: {
        'grid-primary': 'linear-gradient(0deg, rgba(59, 130, 246, 0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(59, 130, 246, 0.05) 1px, transparent 1px)',
      },
      fontFamily: {
        'web3': ['Orbitron', 'ui-sans-serif', 'system-ui', '-apple-system', 'BlinkMacSystemFont', "Segoe UI", 'Roboto', "Helvetica Neue", 'Arial', "Noto Sans", 'sans-serif'],
      },
      fontSize: {
        'web3-xs': ['0.75rem', { lineHeight: '1rem', letterSpacing: '0.05em' }],
        'web3-sm': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.04em' }],
        'web3-base': ['1rem', { lineHeight: '1.5rem', letterSpacing: '0.03em' }],
        'web3-lg': ['1.25rem', { lineHeight: '1.75rem', letterSpacing: '0.02em' }],
        'web3-xl': ['1.5rem', { lineHeight: '2rem', letterSpacing: '0.01em' }],
        'web3-2xl': ['2rem', { lineHeight: '2.5rem', letterSpacing: '0em' }],
        'web3-3xl': ['2.5rem', { lineHeight: '3rem', letterSpacing: '-0.01em' }],
        'web3-4xl': ['3rem', { lineHeight: '3.5rem', letterSpacing: '-0.02em' }],
        'web3-5xl': ['4rem', { lineHeight: '4.5rem', letterSpacing: '-0.03em' }],
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'shimmer': 'shimmer 2s infinite linear',
        'blob': 'blob 7s infinite',
        'float': 'float 6s ease-in-out infinite',
        'float-slow': 'float 10s ease-in-out infinite',
      },
      keyframes: {
        shimmer: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(100%)' },
        },
        blob: {
          '0%, 100%': { transform: 'translate(0, 0) scale(1)' },
          '33%': { transform: 'translate(30px, -50px) scale(1.1)' },
          '66%': { transform: 'translate(-20px, 20px) scale(0.9)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-20px)' },
        }
      },
      transitionDelay: {
        '2000': '2000ms',
      },
    },
  },
  plugins: [],
}
