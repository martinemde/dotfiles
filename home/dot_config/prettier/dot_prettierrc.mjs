/**
 * @see https://prettier.io/docs/configuration
 * @type {import("prettier").Config}
 */

// Dynamically load plugins that are available
const plugins = [];

const optionalPlugins = ['prettier-plugin-toml', 'prettier-plugin-tailwindcss'];

for (const plugin of optionalPlugins) {
  try {
    await import(plugin);
    plugins.push(plugin);
  } catch {
    // Plugin not installed, skip it
  }
}

const config = {
  printWidth: 80,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  quoteProps: 'as-needed',
  trailingComma: 'es5',
  singleQuote: true,
  bracketSpacing: true,
  arrowParens: 'always',
  proseWrap: 'preserve',
  endOfLine: 'lf',
  plugins,
  overrides: [
    {
      files: ['*.json', '*.jsonc'],
      options: {
        singleQuote: false,
        trailingComma: 'none',
      },
    },
  ],
};

export default config;
