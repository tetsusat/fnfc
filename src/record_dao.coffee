{Config} = require './config'

class RecordDao
  constructor: (db) ->
    @config = Config.get()
    @collection = db.collection(@config.mongodb.collection.records)
  insert: (records) ->
    @collection.insert records, (err, result) ->
      throw err if err
        
module.exports = {RecordDao}