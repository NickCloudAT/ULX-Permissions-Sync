if not SERVER then return end

ULX_SYNC_DATA.config.MySQL = {
  HOST = "localhost",
  PORT = "3306",
  USERNAME = "dbuser",
  PASSWORD = "dbpassword",
  DATABASE = "db"
}

if not file.Exists("ulx_sync/config.json", "DATA") then
  file.CreateDir("ulx_sync")
  file.Write("ulx_sync/config.json", util.TableToJSON(ULX_SYNC_DATA.config, true))
else
  local configFile = file.Read("ulx_sync/config.json", "DATA")
  if not configFile then return end

  ULX_SYNC_DATA.config = util.JSONToTable(configFile)
end
