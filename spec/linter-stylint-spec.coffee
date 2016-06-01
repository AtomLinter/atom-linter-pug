path = require('path')

describe 'The pug-lint provider for Linter', ->
  lint = require('../lib/init.coffee').provideLinter().lint

  beforeEach ->
    atom.workspace.destroyActivePaneItem()
    waitsForPromise ->
       atom.packages.activatePackage('linter-pug')


  it 'should be in the packages list', ->
     expect(atom.packages.isPackageLoaded('linter-pug')).toBe true

  it 'should be an active package', ->
     expect(atom.packages.isPackageActive('linter-pug')).toBe true

  it 'finds nothing wrong with valid file', ->
    waitsForPromise ->
      atom.workspace.open(path.join(__dirname, 'fixtures', 'good.pug')).then (editor) ->
        lint(editor).then (messages) ->
          expect(messages.length).toEqual 0

  it 'finds something wrong with invalid file', ->
    waitsForPromise ->
      atom.workspace.open(path.join(__dirname, 'fixtures', 'bad.pug')).then (editor) ->
        lint(editor).then (messages) ->
          expect(messages.length).toEqual 1
          expect(messages[0].text).toBeDefined()
          expect(messages[0].text).toEqual 'Attribute interpolation operators must not be used'
          expect(messages[0].filePath).toBeDefined()
          expect(messages[0].filePath).toMatch(/.+bad\.pug$/)
          expect(messages[0].range).toBeDefined()
          expect(messages[0].range.length).toBeDefined()
          expect(messages[0].range.length).toEqual(2)
          expect(messages[0].range).toEqual([[0, 13], [0, 28]])
