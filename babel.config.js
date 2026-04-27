// Minimal Babel config for Sprockets ES5/ES6 assets and for @babel/eslint-parser (Phase 2).
module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      [
        '@babel/preset-env',
        {
          modules: false,
        },
      ],
    ],
  };
};
