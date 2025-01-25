
-- A reasonably secure storage user database.
-- Module returns function rwdb(db)
-- Usage:
--   rwdb(lua-table) Encode, encrypt, and write encrypted DB
--   rwdb() Read encrypted DB, decrypt, decode, and return Lua table

local io = ba.openio"home" or ba.openio"disk" -- mako or xedge
local rw=require"rwfile"

local dbEncKey=esp32.mac()
dbEncKey=ba.crypto.hash("sha256")(ba.tpm.uniquekey(dbEncKey,#dbEncKey))(true,"binary")

-- Read/write encrypted db. Write if 'db' provided
local function rwdb(db)
   if db then
      local iv=ba.rndbs(12)
      local gcmEnc=ba.crypto.symmetric("GCM",dbEncKey,iv)
      local cipher,tag=gcmEnc:encrypt(ba.json.encode(db),"PKCS7")
      return rw.file(io,"mydb.encrypted",iv..tag..cipher)
   end
   local data=rw.file(io,"mydb.encrypted")
   if data then
      if  #data > 30 then
	 local iv=data:sub(1,12)
	 local tag=data:sub(13,28)
	 local gcmDec=ba.crypto.symmetric("GCM",dbEncKey,iv)
	 local db
	 pcall(function() db=ba.json.decode(gcmDec:decrypt(data:sub(29,-1),tag,"PKCS7")) end)
	 if db then return db end
	 return nil,"Data corrupt"
      end
   end
   return nil,"No DB"
end

return rwdb
