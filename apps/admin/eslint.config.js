import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
    rules: {
      // Pages load data by calling a fetch function from a mount effect; that function sets
      // loading/error state. This is the established pattern until a data-fetching layer is
      // introduced (see docs/TASKS.md P2-06 / P2-07), so it is reported as a warning, not an error.
      'react-hooks/set-state-in-effect': 'warn',
    },
  },
])
