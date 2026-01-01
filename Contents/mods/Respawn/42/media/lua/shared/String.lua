String = String or {};

function String:Split(inputstr, sep)
    sep = sep or '%s'

    local t = {}

    for field, s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
        table.insert(t, field);

        if s == "" then
            return t
        end
    end
end

function String:StartsWith(str, start)
    if type(str) ~= "string" or type(start) ~= "string" then
        return false;
    end

   return string.sub(str, 1, string.len(start)) == start
end

