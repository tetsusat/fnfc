{Config} = require './config'

class TemplateDao
  _cache = {}
  constructor: (db) ->
    @config = Config.get()
    @collection = db.collection(@config.mongodb.collection.template)    
  put: (template) ->
    @collection.save template, (err, result) ->
      throw err if err
      _cache[template._id] = template
  get: (id, callback) ->
    template = _cache[id]
    if typeof(template) == "undefined"
      @collection.findOne {_id:id}, (err, result) ->
        if err
          callback err
        else
          if result
            _cache[id] = result
            callback null, result
          else
            # update later
    else callback null, template
        
module.exports = {TemplateDao}