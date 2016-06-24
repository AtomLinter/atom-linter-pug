path = require 'path'

goodPug = path.join(__dirname, 'fixtures', 'good.pug')
badPug = path.join(__dirname, 'fixtures', 'bad.pug')

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
