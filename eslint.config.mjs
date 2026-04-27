import js from '@eslint/js';
import babelParser from '@babel/eslint-parser';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default [
  {
    ignores: [
      'node_modules/**',
      'vendor/**',
      'public/assets/**',
      'tmp/**',
      'log/**',
    ],
  },
  js.configs.recommended,
  {
    files: ['app/assets/javascripts/**/*.js'],
    languageOptions: {
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        babelOptions: {
          configFile: './babel.config.js',
        },
      },
      globals: {
        ...globals.browser,
        $: 'readonly',
        jQuery: 'readonly',
        ActionCable: 'readonly',
        App: 'writable',
      },
    },
  },
  prettier,
];
