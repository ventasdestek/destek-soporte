import { defineConfig, globalIgnores } from 'eslint/config'
import nextVitals from 'eslint-config-next/core-web-vitals'
import tseslint from '@typescript-eslint/eslint-plugin'

export default defineConfig([
  ...nextVitals,
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'react/no-unescaped-entities': 'off',
    },
  },
  globalIgnores(['node_modules/', '.next/', 'out/', '*.config.js', '*.config.mjs', 'next-env.d.ts']),
])