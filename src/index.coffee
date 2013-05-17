domain = require 'domain'

exports.context = (context, domain = require('domain').active) ->
  throw new Error('no active domain') unless domain?
  domain.__context__ = if context? then context() else {}

exports.cleanup = (cleanup, domain = require('domain').active) ->
  throw new Error('no active domain') unless domain?
  cleanup(domain.__context__) if cleanup? and domain.__context__?
  domain.__context__ = null

exports.onError = (onError, context = null, domain = require('domain').active) ->
  onError(context or domain.__context__) if onError?
  domain.__context__ = null

exports.get = (key, domain = require('domain').active) ->
  throw new Error('no active domain') unless domain?
  domain.__context__[key]

exports.run = (options, func) ->
  func = options if not func
  {context, cleanup, onError} = options
  domain = options.domain or require('domain').active
  domain.on 'dispose', -> exports.cleanup(cleanup, domain)
  domain.on 'error', -> exports.onError(onError, null, domain)
  exports.context(context, domain)
  try
    domain.bind(func, true)()
  catch err
    domain.emit 'error', err
  domain

exports.runInNewDomain = (func, options) ->
  currentDomain = require('domain').active
  options.domain = require('domain').create()
  if not options.detach and currentDomain
    currentDomain.add(options.domain)
  exports.run(func, options)

exports.middleware = (context, cleanup) ->
  (req, res, next) ->
    {context, cleanup} = context if typeof context != 'function'
    domain = require('domain').active
    exports.context(context, domain)
    res.on 'finish', -> exports.cleanup(cleanup, domain)
    req.__context__ = domain.__context__
    next()

exports.middlewareOnError = (onError) ->
  (err, req, res, next) ->
    {onError} = onError if typeof onError != 'function'
    exports.onError(onError, req.__context__)
    req.__context__ = null
    next(err)
