fs = require 'fs'

class Config
  _config = undefined
  @get: () ->
    _config ?= JSON.parse(fs.readFileSync(__dirname + '/../config/fnfc.json'))

module.exports = {Config}
