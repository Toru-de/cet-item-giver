# CET Item Giver

Мод на выдачу предметов в Cyberpunk 2077 **2.5**. Оружие, киберимпланты, чертежи, материалы, патроны и деньги выдаются через инвентарь игры. Единственная зависимость — Cyber Engine Tweaks.

## Установка

1. Закройте игру. Установите CET 1.38.1 для патча 2.5. [Скачать CET](https://github.com/maximegmd/CyberEngineTweaks/releases/tag/v1.38.1)
2. Распакуйте `CETItemGiver-v0.1.0.zip` в корень `Cyberpunk 2077`, объединив папки `bin`. Файл мода должен оказаться по пути `bin/x64/plugins/cyber_engine_tweaks/mods/CETItemGiver/init.lua`. [Скачать ZIP мода](https://github.com/Toru-de/cet-item-giver/releases/download/v0.1.0/CETItemGiver-v0.1.0.zip)
3. Запустите игру, загрузите сейв и откройте окно **CET Item Giver** в оверлее CET.

## Выдача

- Выберите предмет в **Quick picks** или введите свой **Item ID**. Короткий ID получает префикс `Items.`. Для патронов и других пространств имён вводите полный ID, например `Ammo.RifleAmmo`.
- Укажите **Quantity** и нажмите **Give Item**. Сообщение под кнопкой покажет результат. Лимит за одну выдачу составляет 1 000 000 для складываемых предметов и 50 для остальных. Игра применяет свои ограничения на количество.
- Для готовой кибердеки выберите **Militech Canto Mk.6 (Tier 5)**. Для изготовления выберите **Militech Canto Mk.6 crafting spec**, **Decoded Cerberus component** и нужные материалы. Чертёж проверяйте в меню изготовления.

Быстрый выбор заполняет поля. Выдача происходит только после нажатия **Give Item** и проходит через штатный инвентарь. Для предметов Phantom Liberty требуется это дополнение. [Список и поиск ID предметов](https://wiki.redmodding.org/cyberpunk-2077-modding/for-mod-creators-theory/references-lists-and-overviews/equipment/spawn-codes-baseids-hashes)

## Проверка

Сигнатура `GiveItemByTDBID` сверена со скриптами версии 2.5. ID быстрых предметов сверены с индексом WolvenKit. Локальные тесты на LuaJIT проверяют выбор, выдачу, валидацию и обработку отказа игры. Прогон внутри игры ещё нужен. [Скрипты 2.5](https://codeberg.org/adamsmasher/cyberpunk/src/commit/17c62d000310f8938beb9593b3892c6c4febeffb), [индекс WolvenKit](https://github.com/WolvenKit/WolvenKit/blob/95074158ed971aea39fc8abc50c2574381f4aad2/WolvenKit.Common/Resources/tweakdbstr.kark), [команды инвентаря CET](https://wiki.redmodding.org/cyber-engine-tweaks/console/console/how-do-i)

```text
lua tests/smoke.lua
```
