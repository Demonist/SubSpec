local L = {}
local locale = GetLocale()

L["new"] = "[New profile]"
L["rename"] = "Rename"
L["save"] = "Save"
L["remove"] = "Remove"
L["moveLeft"] = "Move left"
L["moveRight"] = "Move right"
L["renameText"] = "Input new profile name"
L["cancel"] = "Cancel"
L["versionError"] = "It's a Legion version of the addon. It doesn't working in early patches"

--------------------------------   ruRU:   -------------------------------------

if locale == "ruRU" then
	L["new"] = "[Новый профиль]"
	L["rename"] = "Переименовать"
	L["save"] = "Сохранить"
	L["remove"] = "Удалить"
	L["moveLeft"] = "Переместить влево"
	L["moveRight"] = "Переместить вправо"
	L["renameText"] = "Введите новое имя профиля"
	L["cancel"] = "Отмена"
	L["versionError"] = "Это версия аддона для Легиона или более поздних патчей. Она не работает в более ранних патчах"
end

--------------------------------   deDE:   -------------------------------------

if locale == "deDE" then
	L["new"] = "[Neues Profil]"
	L["rename"] = "Umbenennen"
	L["save"] = "Speichern"
	L["remove"] = "Entfernen"
	L["moveLeft"] = "Nach links verschieben"
	L["moveRight"] = "Nach rechts verschieben"
	L["renameText"] = "Geben Sie den neuen Profilnamen"
	L["cancel"] = "Stornieren"
end

--------------------------------   esES:   -------------------------------------

if locale == "esES" then
	L["new"] = "[Nuevo perfil]"
	L["rename"] = "Renombrar"
	L["save"] = "Guardar"
	L["remove"] = "Eliminar"
	L["moveLeft"] = "Mover a la izquierda"
	L["moveRight"] = "Mover a la derecha"
	L["renameText"] = "Introduce un nuevo nombre de perfil:"
	L["cancel"] = "Cancelar"
end

--------------------------------   frFR:   -------------------------------------

if locale == "frFR" then
	L["new"] = "[Nouveau profil]"
	L["rename"] = "Renommer"
	L["save"] = "Sauvegarder"
	L["remove"] = "Supprimer"
	L["moveLeft"] = "Déplacer à gauche"
	L["moveRight"] = "Déplacer à droite"
	L["renameText"] = "Entrer le nouveau nom du profil"
	L["cancel"] = "Annuler"
end

--------------------------------   itIT:   -------------------------------------

if locale == "itIT" then
	L["new"] = "[Nuovo profilo]"
	L["rename"] = "Rinominare"
	L["save"] = "Salvare"
	L["remove"] = "Rimuovere"
	L["moveLeft"] = "Muovere a sinistra"
	L["moveRight"] = "Vai a destra"
	L["renameText"] = "Ingresso nome del nuovo profilo"
	L["cancel"] = "Annulla"
end

--------------------------------   ptBR:   -------------------------------------

if locale == "ptBR" then
	L["new"] = "[Novo perfil]"
	L["rename"] = "Rebatizar"
	L["save"] = "Salvar"
	L["remove"] = "Remover"
	L["moveLeft"] = "Mova para a esquerda"
	L["moveRight"] = "Mover para a Direita"
	L["renameText"] = "Entrada nome do perfil novo"
	L["cancel"] = "Cancelar"
end

--------------------------------   zhCN:   -------------------------------------

if locale == "zhCN" then
	L["new"] = "[新的配置文件]"
	L["rename"] = "重命名"
	L["save"] = "保存"
	L["remove"] = "去掉"
	L["moveLeft"] = "向左移动"
	L["moveRight"] = "向右移"
	L["renameText"] = "输入新的配置文件名称"
	L["cancel"] = "取消"
end

--------------------------------   zhTW:   -------------------------------------

if locale == "zhTW" then
	L["new"] = "[新的配置文件]"
	L["rename"] = "重命名"
	L["save"] = "保存"
	L["remove"] = "去掉"
	L["moveLeft"] = "向左移動"
	L["moveRight"] = "向右移"
	L["renameText"] = "輸入新的配置文件名稱"
	L["cancel"] = "取消"
end

--------------------------------   koKR:   -------------------------------------

if locale == "koKR" then
	L["new"] = "[새 프로필]"
	L["rename"] = "이름 바꾸기"
	L["save"] = "구하다"
	L["remove"] = "없애다"
	L["moveLeft"] = "이동 왼쪽"
	L["moveRight"] = "오른쪽으로 이동"
	L["renameText"] = "입력 새 프로파일 이름"
	L["cancel"] = "취소하다"
end

SubSpecGlobal = {}
SubSpecGlobal.L = L
