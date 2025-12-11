module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1'
  },
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      useESM: true,
      diagnostics: {
        ignoreCodes: [151002]
      }
    }]
  },
  extensionsToTreatAsEsm: ['.ts']
};
