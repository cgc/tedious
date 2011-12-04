Connection = require('../../lib/connection')
Request = require('../../lib/request')
fs = require('fs')

config = JSON.parse(fs.readFileSync(process.env.HOME + '/.tedious/test-connection.json', 'utf8'))
config.options.debug =
  data: true
  payload: true
  token: true

exports.connect = (test) ->
  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(!err)
    test.ok(loggedIn)
    test.strictEqual(connection.database(), config.options.database)

    test.done()
  )

  connection.on('databaseChange', (database) ->
    test.strictEqual(database, config.options.database)
  )

  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.execSimpleSql = (test) ->
  test.expect(9)

  request = new Request('select 8 as C1', (err, rowCount) ->
    test.ok(!err)
    test.strictEqual(rowCount, 1)
    test.done()
  )

  request.on('columnMetadata', (columnsMetadata) ->
    test.strictEqual(columnsMetadata.length, 1)
  )
  
  request.on('row', (columns) ->
    test.strictEqual(columns.length, 1)

    test.strictEqual(columns[0].value, 8)

    test.strictEqual(columns[0].isNull, false)
    
    byName = columns.byName()
    test.strictEqual(byName.C1.value, 8)
  )

  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(!err)
    test.ok(loggedIn)

    connection.execSql(request)
  )
  
  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.execSqlWithLotsOfRowsReturned = (test) ->
  numberOfRows = 1000
  rowsReceived = 0

  test.expect(6)

  request = new Request("select top #{numberOfRows} object_id, name from sys.all_columns", (err, rowCount) ->
    test.ok(!err)
    test.strictEqual(rowCount, numberOfRows)
    test.strictEqual(rowsReceived, numberOfRows)
    test.done()
  )

  request.on('columnMetadata', (columnsMetadata) ->
    test.strictEqual(columnsMetadata.length, 2)
  )
  
  request.on('row', (columns) ->
    rowsReceived++
  )

  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(!err)
    test.ok(loggedIn)
    
    connection.execSql(request)
  )
  
  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.execBadSql = (test) ->
  test.expect(6)

  request = new Request('select bad syntax here', (err, rowCount) ->
    test.ok(err)
    test.strictEqual(rowCount, undefined)
    test.done()
  )

  request.on('row', (columns) ->
    test.ok(false)
  )

  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(!err)
    test.ok(loggedIn)
    
    connection.execSql(request)
  )
  
  connection.on('errorMessage', (error) ->
    test.ok(error.message.indexOf('syntax'))
    test.strictEqual(error.number, 102)
  )

  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.execSqlProc = (test) ->
  rows = 0

  request = new Request('exec sp_who2', (err, returnStatus) ->
    test.ok(!err)
    test.strictEqual(returnStatus, 0)
    test.ok(rows > 0)
    test.done()
  )

  request.on('columnMetadata', (columnsMetadata) ->
    test.strictEqual(columnsMetadata.length, 13)
  )

  request.on('row', (columns) ->
    rows++
    test.strictEqual(columns.length, 13)
  )
  
  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(!err)
    test.ok(loggedIn)
    
    connection.execSql(request)
  )
  
  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.badCredentials = (test) ->
  test.expect(4)

  connection = new Connection(config.server, config.userName, 'bad-password', config.options, (err, loggedIn) ->
    test.ok(err)
    test.ok(!loggedIn)

    test.done()
  )

  connection.on('errorMessage', (error) ->
    test.ok(error.message.indexOf('failed'))
    test.strictEqual(error.number, 18456)
  )

  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.badServer = (test) ->
  connection = new Connection('bad-server', config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(false)
  )

  connection.on('fatal', (error) ->
    test.done()
  )

  connection.on('debug', (message) ->
    #console.log(message)
  )

exports.badPort = (test) ->
  config.options.port = -1
  connection = new Connection(config.server, config.userName, config.password, config.options, (err, loggedIn) ->
    test.ok(false)
  )

  connection.on('fatal', (error) ->
    test.done()
  )

  connection.on('debug', (message) ->
    #console.log(message)
  )
