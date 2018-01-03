{CompositeDisposable} = require('atom')
bundledPugLint = require('pug-lint')
path = require('path')
objectAssign = require('object-assign')
configFile = require('pug-lint/lib/config-file')
reqResolve = require('resolve')

pugLints = new Map()

resolvePath = (name, baseDir) ->
  return new Promise (resolve, reject) ->
    reqResolve name, { basedir: baseDir }, (err, res) ->
      reject(err) if err?
      resolve(res)

getPugLint = (baseDir) ->
  if pugLints.has(baseDir)
    return Promise.resolve pugLints.get(baseDir)

  resolvePath('pug-lint', baseDir)
    .then (pugLintPath) ->
      pugLints.set(baseDir, require(pugLintPath))
      return Promise.resolve pugLints.get(baseDir)
    .catch () ->
      pugLints.set(baseDir, bundledPugLint)
      return Promise.resolve pugLints.get(baseDir)

module.exports =
  config:
    projectConfigFile:
      type: 'string'
      default: ''
      description: 'Relative path from project to config file'

    onlyRunWhenConfig:
      default: false
      title: 'Run Pug-lint only if config is found'
      description: 'Disable linter if there is no config file found for the linter.',
      type: 'boolean'

  activate: ->
    require('atom-package-deps').install('linter-pug')

    if atom.config.get('linter-pug.executablePath')?
      atom.notifications.addWarning('Removing custom pug-lint path', {
        detail: "linter-pug has moved to the Node.js API for pug-lint and " +
          "will now use a project's local instance where possible, falling " +
          "back to a bundled version of pug-lint where none is found."
        })
      atom.config.unset('linter-pug.executablePath')

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-pug.executablePath',
      (executablePath) =>
        @executablePath = executablePath
    @subscriptions.add atom.config.observe 'linter-pug.projectConfigFile',
      (projectConfigFile) =>
        @projectConfigFile = projectConfigFile
    @subscriptions.add atom.config.observe 'linter-pug.onlyRunWhenConfig',
      (onlyRunWhenConfig) =>
        @onlyRunWhenConfig = onlyRunWhenConfig

  getConfig: (filePath) ->
    config = undefined
    if path.isAbsolute(@projectConfigFile)
      config = configFile.load(false, @projectConfigFile)
    else
      config = configFile.load(false, path.join(path.dirname(filePath), @projectConfigFile))
    if !config and @onlyRunWhenConfig
      return undefined

    options = {}
    newConfig = objectAssign(options, config)

    if !newConfig.configPath and config and config.configPath
      newConfig.configPath = config.configPath
    return newConfig

  provideLinter: ->
    helpers = require('atom-linter')
    provider =
      name: 'pug-lint'
      grammarScopes: ['source.jade', 'source.pug']
      scope: 'file'
      lintOnFly: true

      lint: (textEditor) =>
        rules = []
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        projectConfig = @getConfig(filePath)

        # Use Atom's project root folder
        projectDir = atom.project.relativizePath(filePath)[0]
        if !projectDir?
          # Fall back to the file directory
          projectDir = path.dirname(filePath)

        if !fileText
          return Promise.resolve([])

        if !projectConfig || !projectConfig.configPath
          if @onlyRunWhenConfig
            atom.notifications.addError 'Pug-lint config not found'
            return Promise.resolve([])

        if(@onlyRunWhenConfig || projectConfig)
          rules = projectConfig

        return new Promise (resolve) ->
          getPugLint(projectDir).then (pugLint) ->
            linter = new pugLint()
            linter.configure rules

            results = linter.checkString fileText

            resolve results.map (res) -> {
              type: res.name
              filePath: filePath
              range: helpers.generateRange textEditor,  res.line - 1, res.column - 1
              text: res.msg
            }
