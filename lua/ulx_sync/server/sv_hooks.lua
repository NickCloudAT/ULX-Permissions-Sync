hook.Add(ULib.HOOK_GROUP_ACCESS_CHANGE, "ULX_SYNC_PERMS_CHANGED", function()
  ULX_SYNC_DATA.mysql:SavePermissions()
end)
