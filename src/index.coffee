domain = require 'domain'

exports.requestContext = (init, cleanup) ->
  (req, res, next) ->
    domain = require('domain').active
    throw new Error('no active domain') unless domain?
    {init, cleanup} = init if typeof init != 'function'
    domain.__context__ = req.__context__ = init()
    res.on 'finish', ->
      cleanup(domain.__context__) if cleanup? and domain.__context__?
      domain.__context__ = null
    next()

exports.requestContextOnError = (cleanup) ->
  (err, req, res, next) ->
    {cleanup} = cleanup if typeof cleanup != 'function'
    cleanup(req.__context__) if cleanup?
    domain.__context__ = req.__context__ = null
    next(err)

exports.get = (key) ->
  domain = require('domain').active
  throw new Error('no active domain') unless domain?
  domain.__context__[key]
