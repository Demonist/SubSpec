local L = {}
local locale = GetLocale()

L["settings"] = "Settings"
L["new"] = "[New profile]"
L["rename"] = "Rename"
L["save"] = "Save"
L["remove"] = "Remove"

--------------------------------   ruRU:   -------------------------------------

if locale == "ruRU" then
	L["settings"] = "Настройка"
	L["new"] = "[Новый профиль]"
	L["rename"] = "Переименовать"
	L["save"] = "Сохранить"
	L["remove"] = "Удалить"
end

--------------------------------   deDE:   -------------------------------------

if locale == "deDE" then
	L["settings"] = "Einstellungen"
	L["profile"] = "Profil"
	L["commonProfile"] = "[Gemeinsam]"
	L["load"] = "Belastung"
	L["save"] = "Sparen"
	L["remove"] = "Entfernen"
end

--------------------------------   esES:   -------------------------------------

if locale == "esES" then
	L["settings"] = "Ajustes"
	L["profile"] = "Perfil"
	L["commonProfile"] = "[Común]"
	L["load"] = "Carga"
	L["save"] = "Ahorrar"
	L["remove"] = "Eliminar"
end

--------------------------------   frFR:   -------------------------------------

if locale == "frFR" then
	L["settings"] = "Paramètres"
	L["profile"] = "Profil"
	L["commonProfile"] = "[Commun]"
	L["load"] = "Charge"
	L["save"] = "Sauvegarder"
	L["remove"] = "Retirer"
end

--------------------------------   itIT:   -------------------------------------

if locale == "itIT" then
	L["settings"] = "Impostazioni"
	L["profile"] = "Profilo"
	L["commonProfile"] = "[Comune]"
	L["load"] = "Caricare"
	L["save"] = "Salvare"
	L["remove"] = "Rimuovere"
end

--------------------------------   ptBR:   -------------------------------------

if locale == "ptBR" then
	L["settings"] = "Configurações"
	L["profile"] = "Perfil"
	L["commonProfile"] = "[Comum]"
	L["load"] = "Carregar"
	L["save"] = "Guardar"
	L["remove"] = "Remover"
end

--------------------------------   zhCN:   -------------------------------------

if locale == "zhCN" then
	L["settings"] = "设置"
	L["profile"] = "简介"
	L["commonProfile"] = "[共同]"
	L["load"] = "加载"
	L["save"] = "保存"
	L["remove"] = "删除"
end

--------------------------------   zhTW:   -------------------------------------

if locale == "zhTW" then
	L["settings"] = "設置"
	L["profile"] = "簡介"
	L["commonProfile"] = "[共同]"
	L["load"] = "加載"
	L["save"] = "保存"
	L["remove"] = "刪除"
end

--------------------------------   koKR:   -------------------------------------

if locale == "koKR" then
	L["settings"] = "설정"
	L["profile"] = "윤곽"
	L["commonProfile"] = "[공유지]"
	L["load"] = "하중"
	L["save"] = "구하다"
	L["remove"] = "풀다"
end

SubSpecGlobal = {}
SubSpecGlobal.L = L
