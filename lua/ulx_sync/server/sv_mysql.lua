if not SERVER then return end

module("ULX_SYNC", package.seeall)

require("mysqloo")

local queue = {}

local db = mysqloo.connect(ULX_SYNC_DATA.config.MySQL.HOST, ULX_SYNC_DATA.config.MySQL.USERNAME, ULX_SYNC_DATA.config.MySQL.PASSWORD, ULX_SYNC_DATA.config.MySQL.DATABASE, ULX_SYNC_DATA.config.MySQL.PORT)

local function query( str, callback, wait_finish )
	local q = db:query( str )

	if wait_finish then
		q:wait(true)
	end

	function q:onSuccess( data )
		if callback then
			callback( data )
		end
	end

	function q:onError( err )
		if db:status() == mysqloo.DATABASE_NOT_CONNECTED then
			table.insert( queue, { str, callback } )
			db:connect()
		return end

		print( "ULX_SYNC > Failed to connect to the database!" )
		print( "ULX_SYNC > The error returned was: " .. err )
	end

	q:start()

end

function db:onConnected()
	print( "ULX_SYNC > Sucessfully connected to database!" )

	for k, v in pairs( queue ) do
		query( v[ 1 ], v[ 2 ] )
	end

	queue = {}

  ULX_SYNC_DATA.mysql:PullPermissions()
end

function db:onConnectionFailed( err )
	print( "ULX_SYNC > Failed to connect to the database!" )
	print( "ULX_SYNC > The error returned was: " .. err )
end

db:connect()

table.insert( queue, { "SHOW TABLES LIKE 'ulx_sync'", function( data )
	if table.Count( data ) < 1 then -- the table doesn't exist
		query( "CREATE TABLE ulx_sync (id int, lastedit BIGINT, perms longtext)", function( data )
			print( "ULX_SYNC > Sucessfully created table!" )
		end )
	end
end } )


function ULX_SYNC_DATA.mysql:SavePermissions()
  local groupsFile = file.Read("ulib/groups.txt", "DATA")
  if not groupsFile then return end

  query("SELECT perms FROM ulx_sync WHERE id=1", function(data)
    if table.Count(data) < 1 then
      query("INSERT INTO ulx_sync (id, lastedit, perms) VALUES (1 ," .. os.time() .. ", '" .. groupsFile .."')", nil)
      return
    end
    query("UPDATE ulx_sync SET perms='".. groupsFile .. "' WHERE id=1", nil)
    query("UPDATE ulx_sync SET lastedit='".. os.time() .. "' WHERE id=1", nil)
  end)


end

function ULX_SYNC_DATA.mysql:PullPermissions()
  timer.Simple(1, function()
    query("SELECT perms FROM ulx_sync WHERE id=1", function(data)
			if table.Count(data) < 1 then return end
      local groupFileString = data[1].perms
      if not groupFileString then return end

      file.Write("ulib/groups.txt", groupFileString)

    end)
  end)
end
