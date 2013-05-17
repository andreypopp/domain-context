{equal, ok} = require 'assert'
{run, runInNewDomain, get} = require './src/index'

describe 'run()', ->

  it 'runs a func in an active domain if no domain is provided', ->
    domain = require('domain').create()
    domain.run ->
      run ->
        equal require('domain').active, domain
    domain.dispose()

  it 'runs a func in a provided domain', ->
    domain = require('domain').create()
    anotherDomain = require('domain').create()
    domain.run ->
      run {domain: anotherDomain}, ->
        equal require('domain').active, anotherDomain
    domain.dispose()

  it 'allows setting a context with init callback and getting values with get()', ->
    domain = require('domain').create()
    domain.run ->
      run {context: -> {a: 1, b: 2}}, ->
        equal get('a'), 1
        equal get('b'), 2
        equal get('c'), undefined
    domain.dispose()

  it 'calls cleanup callback on dispose', ->
    cleanupCalled = false
    domain = require('domain').create()
    domain.run ->
      run {cleanup: -> cleanupCalled = true}, ->
    domain.dispose()
    ok cleanupCalled

  describe 'onError callback', ->

    it 'calls onError on sync throw', ->

      onErrorCalled = false
      domain = require('domain').create()
      domain.run ->
        run {onError: -> onErrorCalled = true}, ->
          throw new Error('x')
      domain.dispose()
      ok onErrorCalled

    it 'calls onError on async throw', (done) ->
      onErrorCalled = false
      domain = require('domain').create()
      domain.run ->
        run {onError: -> onErrorCalled = true}, ->
          require('fs').readFile 'non-existent', (err, result) ->
            throw err
      setTimeout (->
        ok onErrorCalled
        done()
        ), 20

describe 'runInNewDomain()', ->

  it 'runs a func in a new domain', ->
    domain = runInNewDomain ->
      equal require('domain').active, domain
    domain.dispose()

  it 'nestes a new domain to a current one if latter is present', ->
    parentDomain = require('domain').create()

    disposed = false
    errorCalled = false

    parentDomain.on 'error', ->
      errorCalled = true

    parentDomain.run ->
      domain = runInNewDomain ->
        throw new Error('x')
      domain.on 'dispose', ->
        disposed = true
      ok errorCalled
    parentDomain.dispose()
    ok disposed

  it 'does not nest domain if detach option is provided', ->
    parentDomain = require('domain').create()

    disposed = false
    errorCalled = false

    parentDomain.on 'error', ->
      errorCalled = true

    parentDomain.run ->
      domain = runInNewDomain {detach: true}, ->
        throw new Error('x')
      domain.on 'dispose', ->
        disposed = true
      ok not errorCalled
    parentDomain.dispose()
    ok not disposed

describe.skip 'middleware()', ->
describe.skip 'middleware() with middlewareOnError()', ->
