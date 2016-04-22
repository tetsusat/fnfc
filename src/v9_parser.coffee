{Logger} = require './logger'
{Config} = require './config'
{Record} = require './record'
FIELD_TYPE = require './field_type'
APPLICATION_ID = require './application_id'

class V9Parser
  constructor: (dao) ->
    @_templates = {}
    @config = Config.get()
    @logger = Logger.get(@config.logger.level)
    @dao = dao

  parse: (sender, nf_data) ->
    flowsets = @parse_flowset(nf_data)
    for flowset in flowsets
      flowset_id = flowset.readUInt16BE(0)
      if flowset_id == 0  # template flowset!
        @logger.verbose "template flowset was recieved!"
        templates = @parse_template_flowset(flowset)
        for raw_template in templates
          template = @parse_template(sender, raw_template)
          @_templates[template.sender] ?= {}
          @_templates[template.sender][template.id] = template
      else if flowset_id == 1  # option template flowset!
        @logger.verbose "option template flowset was recieved!"
      else if flowset_id >= 256 # data flowset!
        @logger.verbose "data flowset recieved!"
        @parse_data_flowset(sender, flowset)
      else  # reserved?
        @logger.verbose "reserved flowset id #{flowset_id} was recieved!"

  parse_flowset: (nf_data) ->
    flowsets = []
    nf_data_len = nf_data.length
    current = 20
    while current < nf_data_len
      flowset_id = nf_data.readUInt16BE(current)
      flowset_len = nf_data.readUInt16BE(current + 2)
      flowsets.push(nf_data.slice(current, current + flowset_len))
      current += flowset_len
    return flowsets

  parse_template_flowset: (flowset) ->
    templates = []
    flowset_len = flowset.readUInt16BE(2)
    current = 4
    while current < flowset_len
      template_id = flowset.readUInt16BE(current)
      field_num = flowset.readUInt16BE(current + 2)
      templates.push(flowset.slice(current, current + 4 + field_num * 4))
      current = current + 4 + field_num * 4
    return templates

  parse_template: (sender, raw_template) ->
    template_id = raw_template.readUInt16BE(0)
    field_num = raw_template.readUInt16BE(2)
    template = {sender: sender, id: template_id, flowset_id: 0, field_num: field_num, total_length: 0, fields: []}
    current = 4
    for i in [1 .. field_num]
      type = raw_template.readUInt16BE(current)
      current += 2
      length = raw_template.readUInt16BE(current)
      current += 2
      template.total_length += length
      template.fields.push({type: type, length: length})
    return template

  parse_data_flowset: (sender, flowset) ->
    template_id = flowset.readUInt16BE(0)
    if @_templates[sender] && @_templates[sender][template_id]?
      template = @_templates[sender][template_id]
      @logger.debug "Template:", template
      switch template.flowset_id
        when 0  #
          @parse_data_flowset_internal(sender, flowset, template)
        when 1  # option
          @logger.info "option data flowset has not been supported yet!"
    else
      @logger.warn "template does not exist"

  parse_data_flowset_internal: (sender, flowset, template) ->
    records = []
    template_id = flowset.readUInt16BE(0)
    flowset_len = flowset.readUInt16BE(2)
    padding = (flowset_len - 4) % template.total_length
    current = 4     # template_id(2) + flowset_len(2)
    @logger.debug "padding: #{padding}"
    while current < flowset_len - padding
      record = new Record()
      record.exporter = sender
      record.template_id = template_id
      for field in template.fields
        switch field.length
          when 1
            value = flowset.readUInt8(current)
            record.record[FIELD_TYPE[field.type]] = value
            current += 1
          when 2
            value = flowset.readUInt16BE(current)
            record.record[FIELD_TYPE[field.type]] = value
            current += 2
          when 3
            value1 = flowset.readUInt16BE(current)
            value2 = flowset.readUInt8(current + 2)
            value = (value1 << 8) + value2
            record.record[FIELD_TYPE[field.type]] = value
            current += 3
          when 4
            if field.type == 8 || field.type == 12 # ipv4_addr
              value = @readByteArray(flowset, field.length, current)
              ip = "#{value[0]}.#{value[1]}.#{value[2]}.#{value[3]}"
              record.record[FIELD_TYPE[field.type]] = ip
            else if field.type == 95 # application id
              engine_id = flowset.readUInt8(current)
              value1 = flowset.readUInt16BE(current + 1)
              value2 = flowset.readUInt8(current + 3)
              selector_id = (value1 << 8) + value2
              value = "#{engine_id}:#{selector_id}"
              record.record[FIELD_TYPE[field.type]] = value
              if APPLICATION_ID[value]?
                record.record["applicatoin_name"] = APPLICATION_ID[value]
            else
              value = flowset.readUInt32BE(current)
              record.record[FIELD_TYPE[field.type]] = value
            current += 4
          else
            value = @readByteArray(flowset, field.length, current)
            if field.type == 152 || field.type == 153 # absolute timestamp
              epoch = value[2] * 1099511627776 + value[3] * 4294967296 + value[4] * 16777216 + value[5] * 65536 + value[6] * 256 + value[7]
              record.record[FIELD_TYPE[field.type]] = new Date(epoch)
            else
              record.record[FIELD_TYPE[field.type]] = value
            current += field.length
      records.push(record)
    @logger.debug "Records:", records
    @dao.insert(records)
    #console.log(records)

  readByteArray: (flowset, length, current) ->
    byte_array = []
    for i in [0 .. length - 1]
      byte_array.push flowset.readUInt8(current+i)
    return byte_array

module.exports = {V9Parser}
