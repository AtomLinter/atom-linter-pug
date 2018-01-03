'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';
import path from 'path';

// Dependencies
let bundledPugLint;
let objectAssign;
let configFile;
let helpers;
let resolve;

const pugLints = new Map();

const resolvePath = (name, basedir) =>
  new Promise(((res, reject) =>
    resolve(name, { basedir }, (err, modulePath) => {
      if (err != null) {
        reject(err);
      }
      return res(modulePath);
    })
  ));

const getPugLint = async (baseDir) => {
  if (pugLints.has(baseDir)) {
    return pugLints.get(baseDir);
  }

  try {
    const pugLintPath = await resolvePath('pug-lint', baseDir);
    // eslint-disable-next-line import/no-dynamic-require
    pugLints.set(baseDir, require(pugLintPath));
  } catch (e) {
    pugLints.set(baseDir, bundledPugLint);
  }

  return pugLints.get(baseDir);
};

const loadDeps = () => {
  if (!bundledPugLint) {
    bundledPugLint = require('pug-lint');
  }
  if (!objectAssign) {
    objectAssign = require('object-assign');
  }
  if (!configFile) {
    configFile = require('pug-lint/lib/config-file');
  }
  if (!helpers) {
    helpers = require('atom-linter');
  }
  if (!resolve) {
    resolve = require('resolve');
  }
};

module.exports = {
  activate() {
    this.idleCallbacks = new Set();
    let depsCallbackID;
    const installLinterJSHintDeps = () => {
      this.idleCallbacks.delete(depsCallbackID);
      loadDeps();
    };
    depsCallbackID = window.requestIdleCallback(installLinterJSHintDeps);
    this.idleCallbacks.add(depsCallbackID);

    if (atom.config.get('linter-pug.executablePath')) {
      atom.notifications.addWarning(
        'Removing custom pug-lint path',
        {
          detail: 'linter-pug has moved to the Node.js API for pug-lint and ' +
            "will now use a project's local instance where possible, falling " +
            'back to a bundled version of pug-lint where none is found.',
        },
      );
      atom.config.unset('linter-pug.executablePath');
    }

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(atom.config.observe(
      'linter-pug.projectConfigFile',
      (value) => { this.projectConfigFile = value; },
    ));
    this.subscriptions.add(atom.config.observe(
      'linter-pug.onlyRunWhenConfig',
      (value) => { this.onlyRunWhenConfig = value; },
    ));
  },

  deactivate() {
    this.idleCallbacks.forEach(callbackID => window.cancelIdleCallback(callbackID));
    this.idleCallbacks.clear();
    this.subscriptions.dispose();
  },

  getConfig(filePath) {
    let config;
    if (path.isAbsolute(this.projectConfigFile)) {
      config = configFile.load(false, this.projectConfigFile);
    } else {
      config = configFile.load(false, path.join(path.dirname(filePath), this.projectConfigFile));
    }
    if (!config && this.onlyRunWhenConfig) {
      return undefined;
    }

    const options = {};
    const newConfig = objectAssign(options, config);

    if (!newConfig.configPath && config && config.configPath) {
      newConfig.configPath = config.configPath;
    }
    return newConfig;
  },

  provideLinter() {
    return {
      name: 'pug-lint',
      grammarScopes: ['source.jade', 'source.pug'],
      scope: 'file',
      lintOnFly: true,

      lint: async (textEditor) => {
        if (!atom.workspace.isTextEditor(textEditor)) {
          // Somehow, called with an invalid TextEditor instance
          return null;
        }

        const filePath = textEditor.getPath();
        if (!filePath) {
          // File somehow has no path
          return null;
        }

        const fileText = textEditor.getText();
        if (!fileText) {
          // Nothing in the file
          return null;
        }

        // Load the dependencies if they aren't already
        loadDeps();

        const projectConfig = this.getConfig(filePath);
        if (!projectConfig || !projectConfig.configPath) {
          if (this.onlyRunWhenConfig) {
            atom.notifications.addError('Pug-lint config not found');
            return null;
          }
        }

        let rules = [];
        if (this.onlyRunWhenConfig || projectConfig) {
          rules = projectConfig;
        }

        // Use Atom's project root folder
        let projectDir = atom.project.relativizePath(filePath)[0];
        if ((projectDir == null)) {
          // Fall back to the file directory
          projectDir = path.dirname(filePath);
        }

        const linter = new (await getPugLint(projectDir))();
        linter.configure(rules);
        const results = linter.checkString(fileText, filePath);
        return results.map(res => ({
          severity: 'error',
          location: {
            file: res.filename,
            position: helpers.generateRange(textEditor, res.line - 1, res.column - 1),
          },
          excerpt: res.msg,
        }));
      },
    };
  },
};
