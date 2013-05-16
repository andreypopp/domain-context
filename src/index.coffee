domain = require 'domain'

exports.requestContext = (init, cleanup) ->
  (req, res, next) ->
    throw new Error('no active domain') unless domain.active?
    domain.active.__context__ = init()
    res.on 'finish', ->
      cleanup(domain.active.__context__) if cleanup?
      domain.active.__context__ = null
    next()

exports.requestContextOnError = (cleanup) ->
  (err, req, res, next) ->
    throw new Error('no active domain') unless domain.active?
    clean(domain.active.__context__) if cleanup?
    domain.active.__context__ = null
    next()
