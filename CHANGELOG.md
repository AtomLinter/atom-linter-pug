<a name="2.0.2"></a>
## [2.0.2](https://github.com/AtomLinter/atom-linter-pug/compare/v2.0.1...v2.0.2) (2018-01-11)


### Bug Fixes

* **package:** pin pug-lint to version 2.5.0 ([ab08afe](https://github.com/AtomLinter/atom-linter-pug/commit/ab08afe)), closes [#2](https://github.com/AtomLinter/atom-linter-pug/issues/2) [#8](https://github.com/AtomLinter/atom-linter-pug/issues/8)

<a name="2.0.1"></a>
## [2.0.1](https://github.com/AtomLinter/atom-linter-pug/compare/v2.0.0...v2.0.1) (2018-01-05)


### Bug Fixes

* correctly declare the provider for v2 API ([09a8909](https://github.com/AtomLinter/atom-linter-pug/commit/09a8909)), closes [#23](https://github.com/AtomLinter/atom-linter-pug/issues/23) [#24](https://github.com/AtomLinter/atom-linter-pug/issues/24)

<a name="2.0.0"></a>
# [2.0.0](https://github.com/AtomLinter/atom-linter-pug/compare/v1.3.1...v2.0.0) (2018-01-04)


### Bug Fixes

* **package:** update atom-linter to version 10.0.0 ([#13](https://github.com/AtomLinter/atom-linter-pug/issues/13)) ([d23391a](https://github.com/AtomLinter/atom-linter-pug/commit/d23391a))
* slight grammar fix in warning message ([5702ee3](https://github.com/AtomLinter/atom-linter-pug/commit/5702ee3))


### Features

* update to Linter v2 API ([2d9798a](https://github.com/AtomLinter/atom-linter-pug/commit/2d9798a))


### Performance Improvements

* decaffeinate the provider and defer dependencies ([3f607fc](https://github.com/AtomLinter/atom-linter-pug/commit/3f607fc))


### BREAKING CHANGES

* The `executablePath` setting has been removed and is no longer
available. `linter-pug` will now use your project's local `pug-lint`
when one can be found using the standard `require.resolve`
implementation. If one can't be found local to your project then the
bundled one will be used as a fallback.
