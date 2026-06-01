import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'Monaco', 'monospace'],
      },
      colors: {
        panel: {
          bg: '#f8f8f7',
          surface: '#ffffff',
          border: '#e8e6e3',
          muted: '#f3f2f0',
        },
        accent: {
          purple: '#7c3aed',
          blue: '#2563eb',
          amber: '#d97706',
          red: '#dc2626',
          green: '#059669',
          teal: '#0d9488',
        },
      },
    },
  },
  plugins: [],
};
export default config;
