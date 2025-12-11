import typescriptEslint from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import stylistic from '@stylistic/eslint-plugin';
import unicorn from 'eslint-plugin-unicorn';
import nodePlugin from 'eslint-plugin-n';
import importPlugin from 'eslint-plugin-import';
import eslint from '@eslint/js';

export default [
  eslint.configs.recommended,
  {
    ignores: ['dist/*', 'node_modules/*']
  },
  {
    files: ['**/*.ts'],
    languageOptions: {
      parser: tsParser,
      ecmaVersion: 2022,
      sourceType: 'module',
      parserOptions: {
        project: ['./tsconfig.json']
      },
      globals: {
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        module: 'readonly',
        require: 'readonly',
        exports: 'writable',
        setTimeout: 'readonly',
        setInterval: 'readonly',
        clearTimeout: 'readonly',
        clearInterval: 'readonly'
      }
    },
    plugins: {
      '@typescript-eslint': typescriptEslint,
      '@stylistic': stylistic,
      unicorn,
      n: nodePlugin,
      import: importPlugin
    },
    settings: {
      'import/extensions': ['.ts']
    },
    rules: {
      '@typescript-eslint/prefer-optional-chain': 'error',
      '@stylistic/brace-style': 'error',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', {
        args: 'none',
        varsIgnorePattern: '^_',
        caughtErrorsIgnorePattern: '^_'
      }],
      'no-redeclare': 'off',
      'no-constant-condition': 'error',
      '@typescript-eslint/no-redeclare': 'error',
      'no-use-before-define': 'off',
      '@typescript-eslint/no-use-before-define': ['error', { enums: false, functions: false }],
      '@stylistic/type-annotation-spacing': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unsafe-argument': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',
      'import/extensions': ['error', 'always', { ignorePackages: true }],
      'array-bracket-spacing': 1,
      'arrow-spacing': ['error', { before: true, after: true }],
      'brace-style': 'error',
      camelcase: 'off',
      'comma-dangle': ['error', 'never'],
      'comma-spacing': ['error', { before: false, after: true }],
      'consistent-return': 'off',
      curly: 'error',
      'default-case': 'off',
      'eol-last': ['error', 'always'],
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'func-names': 'off',
      'func-style': ['error', 'declaration'],
      'guard-for-in': 'error',
      'id-length': ['error', {
        min: 3,
        exceptions: ['i', 'a', 'b', '_', 'fs', 'rp', '$', 'db', 'iv', 'to', 'qs', 'io', 'id', 'os', 't', 'p', 'rl'],
        properties: 'never'
      }],
      '@stylistic/indent': ['error', 2, { SwitchCase: 1 }],
      'key-spacing': ['error', { beforeColon: false, afterColon: true }],
      'keyword-spacing': ['error', { before: true, after: true }],
      'max-len': ['error', 120, {
        ignoreStrings: true,
        ignoreTemplateLiterals: true,
        ignoreComments: true
      }],
      'new-cap': ['error', {
        capIsNewExceptions: ['ObjectId']
      }],
      'no-undef': 'error',
      'no-async-promise-executor': 'error',
      'no-bitwise': 'off',
      'no-caller': 'error',
      'no-case-declarations': 'off',
      'no-console': 'off',
      'no-const-assign': 'error',
      'no-control-regex': 'off',
      'no-dupe-keys': 'error',
      'no-else-return': 'off',
      'no-empty-class': 'off',
      'no-empty': ['error', { allowEmptyCatch: true }],
      'no-extra-semi': 'error',
      'no-fallthrough': 'error',
      'no-multi-spaces': 'error',
      'no-multiple-empty-lines': ['error', { max: 2, maxBOF: 0 }],
      'no-param-reassign': 'off',
      'no-process-exit': 'off',
      'no-prototype-builtins': 'off',
      'no-self-compare': 'error',
      'no-shadow': 'off',
      'no-spaced-func': 'error',
      'no-throw-literal': 'error',
      'no-trailing-spaces': 'error',
      'no-underscore-dangle': 'off',
      'no-unneeded-ternary': ['error', { defaultAssignment: false }],
      'no-unreachable': 'error',
      'no-unused-expressions': 'off',
      'no-useless-rename': 'error',
      'no-var': ['error'],
      'no-whitespace-before-property': 'error',
      'n/exports-style': ['error', 'module.exports'],
      'n/handle-callback-err': 'error',
      'n/no-extraneous-import': 'off',
      'n/no-sync': 'off', // We use sync operations for CLI
      'n/no-unpublished-import': 'off',
      'n/prefer-global/buffer': 'error',
      'n/prefer-global/console': 'error',
      'n/prefer-global/process': 'error',
      'n/prefer-promises/dns': 'error',
      'n/prefer-promises/fs': 'off', // We use sync fs operations
      'n/no-path-concat': 'error',
      'n/no-missing-import': 'off',
      'n/no-unsupported-features/es-syntax': 'off',
      'object-curly-spacing': 'off',
      '@stylistic/object-curly-spacing': ['error', 'always'],
      'object-shorthand': 'error',
      'one-var-declaration-per-line': ['error', 'always'],
      'one-var': ['error', 'never'],
      'padded-blocks': 'off',
      'prefer-const': ['error', { destructuring: 'all' }],
      'prefer-destructuring': ['error', {
        VariableDeclarator: { array: true, object: true },
        AssignmentExpression: { array: true, object: false }
      }],
      'prefer-template': 'error',
      'quote-props': ['error', 'as-needed'],
      quotes: ['error', 'single'],
      'require-await': 'error',
      'semi-spacing': 'error',
      semi: 'error',
      'space-before-blocks': ['error', 'always'],
      '@stylistic/space-before-blocks': ['error', 'always'],
      'space-in-parens': ['error', 'never'],
      '@stylistic/space-in-parens': ['error', 'never'],
      '@stylistic/space-before-function-paren': ['error', { anonymous: 'never', named: 'never', asyncArrow: 'never' }],
      '@stylistic/space-infix-ops': 'error',
      'spaced-comment': ['error', 'always'],
      strict: 'off',
      'template-curly-spacing': ['error', 'never'],
      'unicorn/numeric-separators-style': 'error',
      'unicorn/prefer-module': 'error',
      'unicorn/no-useless-undefined': 'error',
      'unicorn/consistent-function-scoping': 'error',
      'unicorn/prefer-node-protocol': 'error',
      'wrap-iife': ['error', 'outside'],
      'n/no-process-env': 'off', // We need process.env for CLI
      'import/no-unresolved': 'off',
      'no-dupe-class-members': 'off',
      '@typescript-eslint/no-dupe-class-members': ['error']
    }
  },
  {
    files: ['**/*.test.ts'],
    languageOptions: {
      globals: {
        describe: 'readonly',
        it: 'readonly',
        test: 'readonly',
        expect: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly'
      }
    }
  },
  {
    files: ['*.js', '*.mjs', '*.cjs'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        require: 'readonly',
        module: 'writable'
      }
    }
  }
];
