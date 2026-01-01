local json = require("json");

Respawn.File = {};

function Respawn.File.Save(path, table)
    local file = getFileWriter(path, true, false);
    
    file:write(json.Encode(table));
    file:close();
end

function Respawn.File.Load(path)
    local file = getFileReader(path, false);

    if file == nil then
        return nil;
    end

    local content = "";
    local line = file:readLine();
    while line ~= nil do
        content = content..line;
        line = file:readLine();
    end

    file:close();
    return content ~=  "" and json.Decode(content) or nil;
end