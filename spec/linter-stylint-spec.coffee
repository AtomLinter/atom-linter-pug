path = require 'path'

goodPug = path.join(__dirname, 'fixtures', 'config', 'good.pug')
badPug = path.join(__dirname, 'fixtures', 'config', 'bad.pug')
noConfigRule = path.join(__dirname, 'fixtures', 'noConfig', 'badRule.pug')
noConfigSyntax = path.join(__dirname, 'fixtures', 'noConfig', 'badSyntax.pug')

describe 'The pug-lint provider for Linter', ->
  lint = require('../lib/init.coffee').provideLinter().lint

  beforeEach ->
    atom.workspace.destroyActivePaneItem()
    waitsForPromise ->
      atom.packages.activatePackage 'linter-pug'


  it 'should be in the packages list', ->
    expect(atom.packages.isPackageLoaded('linter-pug')).toBe true

  it 'should be an active package', ->
    expect(atom.packages.isPackageActive('linter-pug')).toBe true

  describe 'works with a configuration', ->
    it 'finds nothing wrong with valid file', ->
      waitsForPromise ->
        atom.workspace.open(goodPug).then (editor) ->
          lint(editor).then (messages) ->
            expect(messages.length).toBe 0

    it 'finds something wrong with invalid file', ->
      errMsg = 'Attribute interpolation operators must not be used'
      waitsForPromise ->
        atom.workspace.open(badPug).then (editor) ->
          lint(editor).then (messages) ->
            expect(messages.length).toEqual 1
            expect(messages[0].html).not.toBeDefined()
            expect(messages[0].text).toBe errMsg
            expect(messages[0].filePath).toBe badPug
            expect(messages[0].range).toEqual [[0, 13], [0, 20]]

  describe 'works without a configuration', ->
    it 'finds nothing wrong with a "bad" file', ->
      waitsForPromise ->
        atom.workspace.open(noConfigRule).then (editor) ->
          lint(editor).then (messages) ->
            expect(messages.length).toBe 0

    it 'finds syntax errors without a configuration', ->
      errMsg = 'The end of the string reached with no closing bracket ) found.'
      waitsForPromise ->
        atom.workspace.open(noConfigSyntax).then (editor) ->
          lint(editor).then (messages) ->
            expect(messages.length).toEqual 1
            expect(messages[0].html).not.toBeDefined()
            expect(messages[0].text).toBe errMsg
            expect(messages[0].filePath).toBe noConfigSyntax
            expect(messages[0].range).toEqual [[1, 0], [1, 0]]
