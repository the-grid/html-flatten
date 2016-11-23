chai = require 'chai'
path = require 'path'
tv4 = require 'tv4'
apiDocs = require 'thegrid-apidocs'

exports.before = ->
  # Load all API docs schemas into tv4
  apiDocs.listSchemas().forEach (schemaName) ->
    schemaDef = apiDocs.getSchema schemaName
    tv4.addSchema schemaDef.id, schemaDef

exports.validate = (entry, type, callback) ->
  unless path.extname type
    type = "#{type}.json"
  schemaDef = tv4.getSchema type
  unless schemaDef
    return new Error "Schema #{type} not found"
  result = tv4.validateMultiple entry, type
  return callback null unless result
  return callback null if result.valid and not result.missing?.length
  try
    chai.expect(result.errors).to.eql []
  catch e
    return callback e
  return callback new Error "Missing schemas #{result.missing.join(', ')}" if result.missing?.length
  return callback result

exports.after = ->
  do tv4.dropSchemas
