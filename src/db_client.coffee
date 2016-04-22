{MongoClient} = require 'mongodb'
{Config} = require './config'

class DbClient
  constructor: (callback) ->
    @config = Config.get()
    MongoClient.connect "mongodb://#{@config.mongodb.ip}:#{@config.mongodb.port}/#{@config.mongodb.db}", (err, db) =>
      if err
        callback err
      else
        callback null, db

module.exports = {DbClient}