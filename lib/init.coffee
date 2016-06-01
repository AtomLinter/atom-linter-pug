{CompositeDisposable} = require('atom')
path = require('path')

module.exports =
  config:
    executablePath:
      type: 'string'
      default: path.join __dirname, '..', 'node_modules', 'pug-lint', 'bin', 'pug-lint'
      description: 'Full path to the `pug-lint` executable node script file (e.g. /usr/local/bin/pug-lint)'

    projectConfigFile:
      type: 'string'
      default: '.pug-lintrc'
      description: 'Relative path from project to config file'

    onlyRunWhenConfig:
      default: false
      title: 'Run Pug-lint only if config is found'
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

  provideLinter: ->
    helpers = require('atom-linter')
    provider =
      grammarScopes: ['source.jade', 'source.pug']
      scope: 'file'
      lintOnFly: true

      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()

        if !fileText
          return Promise.resolve([])

        projectConfigPath = helpers.find(filePath, @projectConfigFile)

        parameters = [filePath]

        if(@onlyRunWhenConfig && !projectConfigPath)
          atom.notifications.addError 'Pug-lint config no found'
          return Promise.resolve([])

        if(@onlyRunWhenConfig || !@runWithStrictMode && projectConfigPath)
          parameters.push('-c', projectConfigPath)

        parameters.push('-r', 'inline')


        return helpers.execNode(@executablePath, parameters, stdin: fileText, throwOnStdErr: false, ignoreExitCode: true).then (result) ->
          regex = /(Warning|Error)?(.*)\:(\d*)\:(\d*)\s(.*)/g
          messages = []

          while (match = regex.exec(result)) != null
            messages.push
              type: if match[1] then match[1] else 'Error'
              text: match[5]
              filePath: match[2]
              range: helpers.rangeFromLineNumber(textEditor, match[3] - 1, match[4] - 1)
          return messages
