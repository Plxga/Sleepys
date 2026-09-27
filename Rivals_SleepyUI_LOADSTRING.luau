--[[
  SLEEPY UI LOADER - Versión resistente
  Pegá TODO este código en el executor.
]]

local url = "https://raw.githubusercontent.com/betsabetmatus-bit/RivalsMP/main/Rivals_SleepyUI_LOADSTRING.luau"

local loadFunc = loadstring or load or (getfenv and getfenv().loadstring) or (getgenv and getgenv().loadstring)

if not loadFunc then
    error("[SleepyUI] Este executor no tiene loadstring/load.")
end

print("[SleepyUI] Descargando desde GitHub...")

local body
local okGet = pcall(function()
    body = game:HttpGet(url)
end)

if not okGet or not body or #body < 200 then
    local requestFunc = (syn and syn.request) or http_request or request or (http and http.request)
    if requestFunc then
        print("[SleepyUI] HttpGet falló, probando request alternativo...")
        local okReq, resp = pcall(function()
            return requestFunc({Url = url, Method = "GET"})
        end)
        if okReq and resp then
            body = resp.Body or resp.body
        end
    end
end

if not body or #body < 200 then
    error("[SleepyUI] NO SE PUDO DESCARGAR. ¿Subiste el archivo a GitHub?\nURL: " .. url)
end

print("[SleepyUI] Descargado (" .. #body .. " bytes). Ejecutando...")

local fn, err = loadFunc(body)
if not fn then
    error("[SleepyUI] Error al compilar:\n" .. tostring(err))
end

local ok, runErr = pcall(fn)
if not ok then
    warn("[SleepyUI] Error al ejecutar:", runErr)
else
    print("[SleepyUI] Cargado correctamente.")
end
