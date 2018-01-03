'use babel';

// eslint-disable-next-line no-unused-vars
import { it, fit, wait, beforeEach, afterEach } from 'jasmine-fix';
import path from 'path';

const { lint } = require('../lib/init').provideLinter();

const goodPug = path.join(__dirname, 'fixtures', 'config', 'good.pug');
const badPug = path.join(__dirname, 'fixtures', 'config', 'bad.pug');
const noConfigRule = path.join(__dirname, 'fixtures', 'noConfig', 'badRule.pug');
const noConfigSyntax = path.join(__dirname, 'fixtures', 'noConfig', 'badSyntax.pug');

describe('The pug-lint provider for Linter', () => {
  beforeEach(async () => {
    atom.workspace.destroyActivePaneItem();
    await atom.packages.activatePackage('linter-pug');
  });

  it('should be in the packages list', () =>
    expect(atom.packages.isPackageLoaded('linter-pug')).toBe(true));

  it('should be an active package', () =>
    expect(atom.packages.isPackageActive('linter-pug')).toBe(true));

  describe('works with a configuration', () => {
    it('finds nothing wrong with valid file', async () => {
      const editor = await atom.workspace.open(goodPug);
      const messages = await lint(editor);
      expect(messages.length).toBe(0);
    });

    it('finds something wrong with invalid file', async () => {
      const errMsg = 'Attribute interpolation operators must not be used';
      const editor = await atom.workspace.open(badPug);
      const messages = await lint(editor);

      expect(messages.length).toEqual(1);
      expect(messages[0].html).not.toBeDefined();
      expect(messages[0].text).toBe(errMsg);
      expect(messages[0].filePath).toBe(badPug);
      expect(messages[0].range).toEqual([[0, 13], [0, 20]]);
    });
  });

  describe('works without a configuration', () => {
    it('finds nothing wrong with a "bad" file', async () => {
      const editor = await atom.workspace.open(noConfigRule);
      const messages = await lint(editor);
      expect(messages.length).toBe(0);
    });

    it('finds syntax errors without a configuration', async () => {
      const errMsg = 'The end of the string reached with no closing bracket ) found.';
      const editor = await atom.workspace.open(noConfigSyntax);
      const messages = await lint(editor);

      expect(messages.length).toEqual(1);
      expect(messages[0].html).not.toBeDefined();
      expect(messages[0].text).toBe(errMsg);
      expect(messages[0].filePath).toBe(noConfigSyntax);
      expect(messages[0].range).toEqual([[1, 0], [1, 0]]);
    });
  });
});
