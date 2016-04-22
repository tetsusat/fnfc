dgram = require 'dgram'

{Config} = require './config'
{Logger} = require './logger'
# {V5Parser} = require './v5_parser'
{V9Parser} = require './v9_parser'
# {V10Parser} = require './v10_parser'
{DbClient} = require './db_client'
{RecordDao} = require './record_dao'
{TemplateDao} = require './template_dao'

class Fnfc
  constructor: ->
    @config = Config.get()
    @port = @config.fnfc.port
    @server = dgram.createSocket('udp4')
    @logger = Logger.get(@config.logger.level)
    new DbClient (err, db) =>
      throw err if err
      dao = new RecordDao(db)
      @v9_parser = new V9Parser(dao)

  run: ->
    @server.on 'message', (msg, rinfo) =>
      sender = rinfo.address
      port = rinfo.port
      @logger.verbose "server got message from #{sender}:#{port}"
      nf_data = new Buffer(msg)
      version = nf_data.readUInt16BE(0)
      switch version
        when 10
          @logger.warn "IPFIX has not been supported yet"
        when 9
          @v9_parser.parse(sender, nf_data)
        when 5
          @logger.warn "Netflow V5 has not been supported yet"
        else
          @logger.warn "unsuppoted Netflow version #{version}"

    @server.on 'listening', () =>
      address = @server.address()
      @logger.info "server listening #{address.address}:#{address.port}"

    @server.bind(@port)

fnfc = new Fnfc()
fnfc.run()
