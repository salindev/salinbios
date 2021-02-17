local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local serialization = require("serialization")

local eeprom = component.eeprom
local freespace = eeprom.getDataSize() - 38
local users, readOnly = false, false

local function read(hint)
    return io.read() or os.exit()
end

local function QA(text)
    io.write(("%s [Y/n] "):format(text))
    local input = unicode.lower(read())

    if input == "y" or input == "" then
        return true
    end
end

if QA("Создать белый список для доступа к загрузчику?") then
    repeat
        io.write('Пример белого списка: {"hohserg", "Fingercomp", "Saghetti"}\nWhitelist: ')
        users = read()
        local err = select(2, require("serialization").unserialize(users))

        if err then
            io.stderr:write(err .. "\n")
        else
            if #users > freespace then
                io.stderr:write(("\nМаксимальный размер белого списка составляет %s, и вы использовали %s\n"):format(freespace, #users))
            elseif #users > 0 then
                users = ("#%s#%s"):format(users, QA("Запросить нажатие пользователем при загрузке?") and "*" or "")
            end
        end
    until users and #users > 0 and not err
end

readOnly = QA("Сделать EEPROM только для чтения?")
os.execute("wget -f https://github.com/salindev/salinbios/blob/main/cyan.comp /tmp/cyan.comp")
local file = io.open("/tmp/cyan.comp", "r")
local data = file:read("*a")
file:close()
print("Записываю...")
eeprom.set(data)
eeprom.setData((eeprom.getData():match("[a-f-0-9]+") or eeprom.getData()) .. (users or ""), true)
eeprom.setLabel("Mythic BIOS")
if readOnly then
    print("Готово...")
    eeprom.makeReadonly(eeprom.getChecksum())
end
computer.shutdown(true)