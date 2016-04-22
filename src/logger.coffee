winston = require 'winston'

class Logger
  _instance = undefined
  @get: (level) ->
    _instance ?= new (winston.Logger)(
      transports: [
        new (winston.transports.Console)(
          timestamp: true
          colorize : true
          level    : level
        )
      ]
    )

module.exports = {Logger}
