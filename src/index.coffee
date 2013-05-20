domain = require 'domain'

exports.context = (context, domain = require('domain').active) ->
  throw new Error('no active domain') unless domain?
  domain.__context__ = if context? then context() else {}

exports.cleanup = (cleanup, context = null, domain = require('domain').active) ->
  context = context or domain.__context__
  cleanup(context) if cleanup? and context?
  domain.__context__ = null if domain?

exports.onError = (err, onError, context = null, domain = require('domain').active) ->
  context = context or domain.__context__
  onError(err, context) if onError?
  domain.__context__ = null

exports.get = (key, domain = require('domain').active) ->
  throw new Error('no active domain') unless domain?
  domain.__context__[key]

exports.run = (options, func) ->
  if not func
    func = options
    options = {}

  {context, cleanup, onError} = options

  domain = options.domain or require('domain').active
  throw new Error('no active domain') unless domain

  domain.on 'dispose', ->
    exports.cleanup(cleanup, null, domain)

  domain.on 'error', (err) ->
    if onError?
      exports.onError(err, onError, null, domain)
    else
      exports.cleanup(cleanup, null, domain)

  exports.context(context, domain)

  try
    domain.bind(func, true)()
  catch err
    domain.emit 'error', err

  domain

exports.runInNewDomain = (options, func) ->
  if not func
    func = options
    options = {}

  currentDomain = require('domain').active
  options.domain = require('domain').create()

  if not options.detach and currentDomain
    currentDomain.add(options.domain)

    options.domain.on 'error', (err) ->
      currentDomain.emit 'error', err

    currentDomain.on 'dispose', ->
      options.domain.dispose()

  exports.run(options, func)

exports.middleware = (context, cleanup) ->
  (req, res, next) ->
    {context, cleanup} = context if typeof context != 'function'
    domain = require('domain').active

    exports.context(context, domain)

    res.on 'finish', ->
      exports.cleanup(cleanup, null, domain)

    req.__context__ = domain.__context__
    next()

exports.middlewareOnError = (onError) ->
  (err, req, res, next) ->
    {onError} = onError if typeof onError != 'function'
    if onError?
      exports.onError(err, onError, req.__context__)
    else
      exports.cleanup(onError, req.__context__)

    req.__context__ = null
    next(err)
