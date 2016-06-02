{CompositeDisposable} = require('atom')
path = require('path')
objectAssign = require('object-assign')
configFile = require('pug-lint/lib/config-file')

module.exports =
  config:
    executablePath:
      type: 'string'
      default: path.join __dirname, '..', 'node_modules', 'pug-lint', 'bin', 'pug-lint'
      description: 'Full path to the `pug-lint` executable node script file (e.g. /usr/local/bin/pug-lint)'

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
    require('atom-package-deps').install()
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
      grammarScopes: ['source.jade', 'source.pug']
      scope: 'file'
      lintOnFly: true

      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        projectConfigPath = @getConfig(filePath)

        if !fileText
          return Promise.resolve([])

        parameters = [filePath]

        if !projectConfigPath || !projectConfigPath.configPath
          if !@onlyRunWhenConfig
            atom.notifications.addError 'Pug-lint config not found'
          return Promise.resolve([])

        if(@onlyRunWhenConfig || projectConfigPath)
          parameters.push('-c', projectConfigPath.configPath)

        parameters.push('-r', 'inline')

        return helpers.execNode(@executablePath, parameters, stdin: fileText, allowEmptyStderr: true, stream: 'stderr')
          .then (result) ->
            regex = /(Warning|Error)?(.*)\:(\d*)\:(\d*)\s(.*)/g
            messages = []

            while (match = regex.exec(result)) != null
              messages.push
                type: if match[1] then match[1] else 'Error'
                text: match[5]
                filePath: match[2]
                range: helpers.rangeFromLineNumber(textEditor, match[3] - 1, match[4] - 1)
            return messages
