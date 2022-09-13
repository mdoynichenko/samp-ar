/*
===================================
|                                  |
|             -•<(¤)>•-            |
|                                  |
|         ГОНКА ВООРУЖЕНИЙ         |
|                                  |
|             -•<(¤)>•-            |
|                                  |
===================================


Игровой мод "Гонка Вооружений"
Жанр: Team Deathmatch (TDM)
Версия: v1.0
Дата выхода: 10.02.2016 г.
Поддерживаемые версии: GTA SA:MP 0.3.7 и новее
GitHub: https://github.com/mdoynichenko

*================================*

Кредиты:

+ The SAMP Team - базовые инклюды
+ Incognito - плагин streamer
+ Y_less - плагин sscanf2, цикл foreach
+ Daniel_Cortez - командный процессор dc_cmd
+ BlueG - плагин MySQL R7
+ Kazoox - идея и базовая реализация
+ MaDoy - данный игровой мод

*================================*

Разработчики:

+ Скриптер: MaDoy
+ Бета-тестеры: steadY., Mystery., _Flomka_

*================================*

Немного о моде:

Данный игровой мод представляет собой реализацию модификации GunGame для Counter Strike: Source в SA:MP. 
Игроку предлагается на выбор две команды. По 4 скина в каждой. После этого он попадает на одну из 20 карт, выбранную заранее. 
Убивая игроков он получает очки, повышает свой уровень. 
Так же присутствуют различные бонусы, позволяющие получить больше очков. Игрок, первым достигший последнего уровня, является победителем. 
В сочетании с различными дополнениями, в виде чата команды и общего, аптечек и тому подобного, играть не надоедает даже при небольшом онлайне.
Так же на сервере присутствует система званий, рейтинга игроков.
Все системы, представленные в данном моде писались с 0 и являются уникальными.

*================================*

От разработчика:

-

*================================*

Лог изменений:


v1.0 (10.02.2016):

+ Первый релиз игрового мода



*================================*

(c) 2014-2016, MaDoy

*================================*

*/

// Инклуды
#include <a_samp> // базовые функции SAMP
#include <streamer> // плагин Streamer
#include <objects_gg> // объекты для карт
#include <dc_cmd> // командный процессор DC_CMD
#include <a_mysql> // плагин MySQL R7
#include <sscanf2> // плагин sscanf2
#include <foreach> // быстрый цикл перебора игроков в сети - foreach
#include <a_deamx> // защита от декомпиляции amx-файла
#include <mxdate> // unix timestamp
#pragma dynamic 10000 // кол-во выделяемой серверу оперативной памяти

main() // Автовызываемая функция при старте сервера
{
new year;
getdate(year);
printf("<¤>========================================<¤>");
printf("||                                          ||");
printf("||                - <(¤)> -                 ||");
printf("||              ГОНКА ВООРУЖЕНИЙ            ||");
printf("||            (c) 2014-%d, MaDoy          ||",year);
printf("||                - <(¤)> -                 ||");
printf("||                                          ||");
printf("<¤>========================================<¤>");
}



// Дата начала разработки
#define START_SECOND 0
#define START_MINUTE 21
#define START_HOUR 13
#define START_DAY 7
#define START_MONTH 12
#define START_YEAR 2014

// Дата выхода текущей версии
#define RELEASE_DAY 10
#define RELEASE_MONTH 2
#define RELEASE_YEAR 2016
#define ANNOUNCE_IF_OLD 1


// Цвета
#define COL_RED					0xFF0000AA
#define COL_RED_DEAD			0xAA0000AA
#define COL_RED_INVIS			0xFF000000
#define COL_YELLOW 				0xFFFF00AA
#define COL_GREEN 				0x66CC00FF
#define COL_GREEN_INVIS 		0x66CC0000
#define COL_WHITE 				0xFFFFFFAA
#define COLOR_BLUE 				0x0000FFAA
#define COLOR_BLUE_DEAD 		0x0000AAAA
#define COLOR_BLUE_INVIS 		0x0000FF00
#define COLOR_WHITE 			0xFFFFFFFF
#define COL_GREEN 				0x66CC00FF
#define COL_ORANGE 				0xFF9900AA
#define COLOR_LIGHTRED 			0xFF6347AA

// Псевдофункции
#define GetName(%0) PlayerInfo[%0][pName] // Ник игрока по ID
#define GetGunName(%0) WeapNames[%0] // Название оружия по ID
#define GetAdminRank(%0) AdminRanks[%0] // Название уровня администированния в им.падеже (по ID уровня, а не игрока!)
#define GetAdminRankEx(%0) AdminRanksEx[%0] // Название уровня администированния в тв.падеже (по ID уровня, а не игрока!)
#define GetAdminRankEx2(%0) AdminRanksEx2[%0] // Название уровня администированния в род.падеже (по ID уровня, а не игрока!)
#define GetMonthNameRus(%0) MonthNamesRus[%0-1] // Название месяца
#define GiveLevelWeapon(%0) GivePlayerWeapon(%0,LevelWeapons[GunLevel[%0]],9999) // Выдача игроку оружия его уровня
#define GetPlayerLevelGunName(%0) WeapNames[PlayerLevel[GunLevel[%0]][0]] // Название уровнегого оружия игрока
#define GetGunTD(%0) WeapTD[%0-22]
#define ReloadWeapons(%0) ResetPlayerWeapons(%0), GivePlayerWeapon(%0,LevelWeapons[GunLevel[%0]],9999) // Перезагрузка оружия игрока
#define SendErrorMessage(%0,%1) SendClientMessage(%0,0xFFFFFFFF,"{ff0000}Ошибка {ffffff}> "%1) // Отправка оформленного сообщения об ошибке


// Макросы для системы мониторинга HP, для отката в односекундном таймере (Не изменяйте, если не понимаете значение данных макросов)
#define HideMinusHPTD 0
#define HidePlusHPTD 1

// =======
#undef MAX_PLAYERS
#define MAX_PLAYERS 20
// =======

// MySQL Settings (Home PC)
#define mysql_host "localhost" //Хост БД
#define mysql_db "gungame" // Название БД
#define mysql_user "root" //Пользователь БД
#define mysql_pass "" // Пароль БД
// ===============


new connectionHandle; // ID соединения MySQL
new Text: FirstTextDraw; // Для исправления рассинхрона textdraw, textdraw-пустышка
new Text:TimeDisp; // Textdraw с монмторингом веремени
new Text:DateDisp; // Textdraw с мониторингом даты
new Text:URL; // Textdraw для сайта, форума или группы в соц.сетм
new Skinah[MAX_PLAYERS]; // ID скина игрока
new ChangingVar[MAX_PLAYERS]; // Используется в панели конфигурации сервера как ID изменяемого параметра
new ChangingLevel[MAX_PLAYERS];
new ostimer,infotimer; // переменные для хранения ID таймеров - односекундного и информационного соответственно

enum pInfo // Информация об игроке
{
	pCash, // Донат (пока не используется)
	pAdmin, // Уровень администированния
	pVip, // VIP (время в секундах, 0 - нет)
	pMute, // время заглушки в секундах
	pWarn, // кол-во предупреждений
	pKills, // убийства
	pDeaths, // смерти
	pWins, // выигранные игры
	pGames, // сыгранные игры
	pLevels, // сумма всех уровней (для вычисления среднего уровня в играх)
	pBestSeries, // лучшая серия убийств
	pRank, // Звание
	pLeaves, // Покинутые игры
	pName[MAX_PLAYER_NAME], // Хранение имени игрока
	pRating, // рейтинг ARR
	pRankProgress, // Прогресс по званию
	pLGID, // ID последней игры (для системы быстрого восстановления)
	pLGlevel, // Уже не используется
	pLGexp, // Уже не используется
	pBanned, // Забанен ли игрок
	pBanInfo[128], // Информация о бане
	pCTime, // Время онлайн (в минутах)
	pRegTime, // Дата регистрации (UNIX TIMESTAMP)
	pID, // ID в базе данных
	pShots, // Выстрелы
	pGoodShots, // Попадания
	pDamageTaken, // Урона получено
	pDamageGiven, // Урона нанесено
};
enum dInfo // Информация о нанесенном уроне между игроками (Выводится во время смерти)
{
	Float:gTaken, // Кол-во урона
	gShots, // Выстрелы
	gKills, // Убийства
};
enum dsInfo // Информация о сериях нанесенного урона между игроками (используется в системе DamageInformer'а)
{
	Float:dsDamage, // Коо-во урона
	dsCombo, // Кол-во выстрелов
	dsWeapon, // ID оружия
	dsHideTimeTake, // Скрытие красного textdraw DamageInformer'а и обновление 3D-текста над головой
	dsHideTimeGive, // Скрытие зеленого textdraw DamageInformer'а
};
new DamageSeries[MAX_PLAYERS][MAX_PLAYERS][dsInfo]; // массив для системы DamageInformer'а
new AllShots; // Все выстрелы
new AllGoodShots; // Все попадания
new Map; // ID карты
new PlayerShots[MAX_PLAYERS];
new PlayerGoodShots[MAX_PLAYERS];
new DamageGiven[MAX_PLAYERS];
new DamageTaken[MAX_PLAYERS];
new HealTimes[MAX_PLAYERS];
new PlayerGiveDamage[MAX_PLAYERS];
new PlayerTakeDamage[MAX_PLAYERS];

// Система "Место Вашей последней смерти"
new bool:LDIOn[MAX_PLAYERS]; // Отображается ли место последней смерти игрока
new PlayerText3D:LDI3DText[MAX_PLAYERS]; // 3D-текст "Место Вашей последней смерти. Расстояние: xx метров"
// ======

new PlayerInfo[MAX_PLAYERS][pInfo]; // массив с информацией об игроках
new Damage[MAX_PLAYERS][MAX_PLAYERS][dInfo]; // массив с информацией о нанесенном уроне с иомента последнего спавна
new bool:Blocked[MAX_PLAYERS][MAX_PLAYERS]; // Заблокировал ли один игрок другого (/block)

//===
new Text:TKPlus1[2]; // Всплывающее уведомление +1 убийство у команды
new TKPlus1_Time[2]; // скрытие данного уведомления
//====

enum pSettings // персональные настройки игрока
{
bool:psDInfoOff, // DamageInformer (true - выкл, false - вкл)
bool:psDeathStatOff,  // информация о нанесенном уроне с момента посл.спавна. Показывается во время смерти игрока (true - выкл, false - вкл)
bool:psLDInfoOff, // Место последней смерти (true - выкл, false - вкл)
bool:psMonHPOff, // HP в цифрах, отображается на прогрессбаое HP (true - выкл, false - вкл)
bool:psPMOff, // Личные сообщения (true - выкл, false - вкл)
bool:psOChatOff, // Общий чат  (true - выкл, false - вкл)
bool:psTChatOff, // Командный чат  (true - выкл, false - вкл)
bool:psVIPChatOff, // Чат VIP  (true - выкл, false - вкл)
bool:psAChatOff, // Чат администрации  (true - выкл, false - вкл)
bool:psSInterface, // Тип интерфейса (true - простой, false - продвинутый)
psInterfaceColor, // Цвет интерфейса (0 - черный, 1 - красный, 2 - зеленый, 3 - синий)
bool:psDateTDOff, // Отображение даты (true - выкл, false - вкл)
bool:psTimeTDOff, // Отображение времени (true - выкл, false - вкл)
}

new PlayerSettings[MAX_PLAYERS][pSettings]; // массив для перс.настроек игроков

enum dCoords // координаты места последней смепти
{
Float:posX, // Координата X
Float:posY, // Координата Y
Float:posZ, // Координата Z
}

new DeathCoords[MAX_PLAYERS][dCoords]; // массив с координатами мест последней смерти игроков

enum sSettings // настройки сервеоа
{
ssGameMode, // игровой режим
// Настройки режима GunGame
ssExpNeed, // EXP для повышения уровня
ssLevels, // Кол-во уровней (на 1 меньше, чем отображаемое игроку)
ssAssists, // Ассисты для повышения уровня
bool:ssHeadshots, // Двойной урон в голову
bool:ssTeamfire, // Огонь по своим
ssAutoteambalance, // Допустимый перевес игроков. 0 - отключить автобаланс
bool:ssAntiCheat, // Античит
ssWeather, // ID погоды (пока не используется)
bool:ssAntiAFK, // Анти-АФК
bool:ssLevelCompensation, // Компенсация уровня, если игра уже начата
bool:ssProgressBackup, // Восстановление прогресса при реконнекте в ту же игру
bool:ssOChat, // Общий чат
bool:ssVIPChat, // Чат VIP
bool:ssTeamChat, // Командные чаты
bool:ssPM, // Личные сообщения
// CS Settings (для последующих версий)
ssBuyTime,
ssRoundTime,
ssMaxMoney,
ssStartMoney,
}

new ServerSettings[sSettings]; // массив для настроек сервера

enum hptdInfo // Система могиторинга HP
{
	Text:MonitoringHPTD, // Кол-во HP
	Text:PlusHPTD,// Всплывающее уведомление +HP
	Text:MinusHPTD, // Всплывающее уведомление -HP
}

new HPTD[MAX_PLAYERS][hptdInfo]; // массив текстдраврв системы мониторинга HP
new HideHPTD[MAX_PLAYERS][2]; // Скрытие всплывающих уведомлений систеиы мониторинга HP



enum lutdInfo
{
	Text:BackgroundLUTD[4],
	Text:TopicLUTD,
	Text:TextLUTD[MAX_PLAYERS],
	Text:ModelLUTD[13],
	HideLUTD[MAX_PLAYERS],

}

new LevelUpTD[lutdInfo];
//====



//new gChat,gVip,gTeam; // Переключатели для вкл/выкл чаты
new Vubor[MAX_PLAYERS];
new bool:GameStarted; // Начата ли игра
new GameID; // ID игры
new GameMinutes, GameSeconds; // Время, прошедшее с момента начала игры
new SK[MAX_PLAYERS]; // Задержка респавна
new InformerUpdate[MAX_PLAYERS]; // Обновление информера над головой игрока
new Float:P[3];
new Text: leaderTD; // текстдрав для лидера игры
new Text: leaderTeamT; // текстдрав для лидера команды террористов
new Text: leaderTeamCT; // текстдрав для лидера команды спецназа
new Text: TeamScore; // мониторинг счета вверху посередине

new TeamKills[3]; // Командный счетчик убийств

// ====
new Text: leaderBG[4];
new Text: lvlexpBG[4];
new Text3D:PlayerInformer[MAX_PLAYERS];
new Text3D:PlayerStatus[MAX_PLAYERS];
// ====

new Healings[MAX_PLAYERS];
new GunCheatWarns[MAX_PLAYERS];
new bool:LevelUpDelay[MAX_PLAYERS];

// Anti AFK
new Float:PlayerAFKCoords[MAX_PLAYERS][6];
new PlayerAFKTime[MAX_PLAYERS];

// === DamageInformer Server System

new Text:HealthTD_G[MAX_PLAYERS];
new Text:HealthTD_R[MAX_PLAYERS];
new Float:ComboDamage[MAX_PLAYERS];
new ComboX[MAX_PLAYERS];
new ShowingTD_G[MAX_PLAYERS];
new ShowingTD_R[MAX_PLAYERS];
new OldID[MAX_PLAYERS];

// ===

new Text:RDTD[6];
new Text:RDTimeTD[MAX_PLAYERS];

new Text:HealTD[5];
new Text:HealAmountTD[MAX_PLAYERS];
new HideHealTD[MAX_PLAYERS];

//new Text:LevelUpTD[16];


//====

new bool:PlayerSpawned[MAX_PLAYERS];
new bool:FirstSpawn[MAX_PLAYERS];
new bool:WatchTime[MAX_PLAYERS];
new AntiFlood[MAX_PLAYERS];
new ReportChat[MAX_PLAYERS];
new KillScore[MAX_PLAYERS];
new GunLevel[MAX_PLAYERS];
new Assists[MAX_PLAYERS];
new PlayerTeam[MAX_PLAYERS];
new PlayerTarget[MAX_PLAYERS];
new PlayerSpectating[MAX_PLAYERS];
new Text:leader;
new Text:leaderT;
new Text:leaderCT;

// ====
new Text:exp[MAX_PLAYERS];
new Text:level[MAX_PLAYERS];
// ====

new KillSeries[MAX_PLAYERS];
new BestKillSeries[MAX_PLAYERS];
new KillsInGame[MAX_PLAYERS];
new DeathsInGame[MAX_PLAYERS];

// ===
new BestScore, BestScoreT, BestScoreCT;
new LeaderID, LeaderTID, LeaderCTID;
// ===

new LevelWeapons[14] = {23, 22,24,25,26,27,28,32,29,30,31,33,34,2};
new DefaultLevelWeapons[14] = {23, 22,24,25,26,27,28,32,29,30,31,33,34,2};
//new TeamSkins[8] = {21,179,123,298,287,285,165,191}; // 1-4 - Т, 5-8 - КТ
new RankNames[26][] = // Названия званий
{
	{"Нет"},
	{"Bronze I"},
	{"Bronze II"},
	{"Bronze III"},
	{"Bronze IV"},
	{"Bronze Master"},
	{"Silver I"},
	{"Silver II"},
	{"Silver III"},
	{"Silver IV"},
	{"Silver Elite"},
	{"Gold Nova I"},
	{"Gold Nova II"},
	{"Gold Nova III"},
	{"Gold Nova IV"},
	{"Gold Nova Master"},
	{"Master Guardian I"},
	{"Master Guardian II"},
	{"Master Guardian III"},
	{"Master Guardian IV"},
	{"Master Guardian Elite"},
	{"Distinguished Master Guardian"},
	{"Legendary Eagle"},
	{"Legendary Eagle Master"},
	{"Supreme Master First Class"},
	{"The Global Elite"}
};

new MapNames[20][] = // Названия карт
{
	{"LVA"},
	{"Ocean Boxes"},
	{"Roofs Near Town-Hall"},
	{"Advanced Battlefield"},
	{"Ruins On Roofs"},
	{"Hawai"},
	{"Two Islands"},
	{"Ruins of Ghetto"},
	{"Ruins"},
	{"Port"},
	{"Bandits' Town"},
	{"Jail"},
	{"Island Near LS"},
	{"Warehouse"},
	{"Ship SF"},
	{"Ship LS"},
	{"Caligulas"},
	{"Four Dragons"},
	{"Atrium"},
	{"Jizzy's"}
};

new WeapNames[][] = {
	{"Кулак"}, // 0
	{"Кастет"}, // 1
	{"Golf Club"}, // 2
	{"Night Stick"}, // 3
	{"Нож"}, // 4
	{"Baseball Bat"}, // 5
	{"Shovel"}, // 6
	{"Pool Cue"}, // 7
	{"Katana"}, // 8
	{"Chainsaw"}, // 9
	{"Purple Dildo"}, // 10
	{"Big White Vibrator"}, // 11
	{"Medium White Vibrator"}, // 12
	{"Small White Vibrator"}, // 13
	{"Flowers"}, // 14
	{"Cane"}, // 15
	{"Grenade"}, // 16
	{"Teargas"}, // 17
	{"Molotov"}, // 18
	{" "}, // 19
	{" "}, // 20
	{" "}, // 21
	{"Dual Pistols"}, // 22
	{"Silenced Pistol"}, // 23
	{"Desert Eagle"}, // 24
	{"Shotgun"}, // 25
	{"Sawnoff Shotgun"}, // 26
	{"Combat Shotgun"}, // 27
	{"Micro SMG"}, // 28
	{"MP5"}, // 29
	{"AK-47"}, // 30
	{"M4A1"}, // 31
	{"Tec-9"}, // 32
	{"Country Rifle"}, // 33
	{"Sniper Rifle"}, // 34
	{"Rocket Launcher"}, // 35
	{"Heat-Seeking Rocket Launcher"}, // 36
	{"Flamethrower"}, // 37
	{"Minigun"}, // 38
	{"Satchel Charge"}, // 39
	{"Detonator"}, // 40
	{"Spray Can"}, // 41
	{"Fire Extinguisher"}, // 42
	{"Camera"}, // 43
	{"Night Vision Goggles"}, // 44
	{"Infrared Vision Goggles"}, // 45
	{"Parachute"}, // 46
	{"Fake Pistol"}, // 47
	{" "}, // 48
	{" Vehicle "}, // 49
	{" Helicopter Blades "}, // 50
	{" Explosion "}, // 51
	{" "}, // 52
	{" Drowned "}, // 53
	{" Splat "} // 54
};

new AdminRanks[8][] =
{
	{"Нет"},
	{"Модератор 1 уровня"},
	{"Модератор 2 уровня"},
	{"Модератор 3 уровня"},
	{"Гл.Модератор"},
	{"Администратор"},
	{"Гл.Администратор"},
	{"Основатель"}
};

new AdminRanksEx[8][] =
{
    {"Нет"},
	{"Модератором 1 уровня"},
	{"Модератором 2 уровня"},
	{"Модератором 3 уровня"},
	{"Гл.Модератором"},
	{"Администратором"},
	{"Гл.Администратором"},
	{"Основателем"}
};

new AdminRanksEx2[8][] =
{
    {"Нет"},
	{"Модератора 1 уровня"},
	{"Модератора 2 уровня"},
	{"Модератора 3 уровня"},
	{"Гл.Модератора"},
	{"Администратора"},
	{"Гл.Администратора"},
	{"Основателя"}
};

new MonthNamesRus[12][] =
{
    {"января"},
	{"февраля"},
	{"марта"},
	{"апреля"},
	{"мая"},
	{"июня"},
	{"июля"},
	{"августа"},
	{"сентября"},
	{"октября"},
	{"ноября"},
	{"декабря"}
};

new WeapTD[13] = {
/*	{"?????"}, // 0
	{"??????"}, // 1
	{"Golf Club"}, // 2
	{"Night Stick"}, // 3
	{"???"}, // 4
	{"Baseball Bat"}, // 5
	{"Shovel"}, // 6
	{"Pool Cue"}, // 7
	{"Katana"}, // 8
	{"Chainsaw"}, // 9
	{"Purple Dildo"}, // 10
	{"Big White Vibrator"}, // 11
	{"Medium White Vibrator"}, // 12
	{"Small White Vibrator"}, // 13
	{"Flowers"}, // 14
	{"Cane"}, // 15
	{"Grenade"}, // 16
	{"Teargas"}, // 17
	{"Molotov"}, // 18
	{" "}, // 19
	{" "}, // 20
	{" "}, // 21*/
	1, // 22
	0, // 23
	2, // 24
	3, // 25
	4, // 26
	5, // 27
	6, // 28
	8, // 29
	9, // 30
	10, // 31
	7, // 32
	11, // 33
	12//, // 34
/*	{"Rocket Launcher"}, // 35
	{"Heat-Seeking Rocket Launcher"}, // 36
	{"Flamethrower"}, // 37
	{"Minigun"}, // 38
	{"Satchel Charge"}, // 39
	{"Detonator"}, // 40
	{"Spray Can"}, // 41
	{"Fire Extinguisher"}, // 42
	{"Camera"}, // 43
	{"Night Vision Goggles"}, // 44
	{"Infrared Vision Goggles"}, // 45
	{"Parachute"}, // 46
	{"Fake Pistol"}, // 47
	{" "}, // 48
	{" Vehicle "}, // 49
	{" Helicopter Blades "}, // 50
	{" Explosion "}, // 51
	{" "}, // 52
	{" Drowned "}, // 53
	{" Splat "} // 54*/
};

// Коордмнаты респавнов террористов
new Float:gTeam1Spawns[7][4] = {{165.439468,1850.395019,25.498508,340.908874},{270.674896,1892.079223,25.500000,175.780807},{224.285385,1931.419921,17.640625,263.828247},{155.196548,1903.258789,18.700893,265.684997},{209.133255,1841.347045,17.640625,358.537017},{242.670776,1860.905761,17.928026,117.541275},{189.828308,1931.338134,17.640625,86.393249}};
new Float:g2Team1Spawns[2][3] = {{-1463.4968,3973.1499,100.8846},{-1443.0544,3968.0269,92.9005}};
new Float:g3Team1Spawns[2][3] = {{1545.4878,-1570.0004,67.2109},{1456.5684,-1558.2682,67.2109}};
new Float:g4Team1Spawns[2][3] = {{-975.2363,1089.9001,1344.9727},{-973.4219,1061.1956,1345.6715}};
new Float:g5Team1Spawns[2][3] = {{1587.2426,-1258.8999,277.8810},{1589.9684,-1232.7505,277.8746}};
new Float:g6Team1Spawns[2][3] = {{-2099.8933,2151.8086,5.9000},{-2155.1675,2064.1995,5.0000}};
new Float:g7Team1Spawns[2][3] = {{3087.8079,-1544.4242,2.6422},{3540.7451,-1531.2885,8.5199}};
new Float:g8Team1Spawns[2][3] = {{2576.8555,-2095.4270,2.2069},{2608.5923,-2048.6531,3.8594}};
new Float:g9Team1Spawns[2][3] = {{4231.0508,-1846.7003,3.1844},{4182.9292,-1861.5004,3.1766}};
new Float:g10Team1Spawns[2][3] = {{-3030.4675,-2706.9055,1.9134},{-3173.3750,-2741.8113,1.9134}};
new Float:g11Team1Spawns[2][3] = {{461.9254,-913.2509,63.2485},{457.9684,-914.7695,63.2250}};
new Float:g12Team1Spawns[2][3] = {{1365.3179,-8.3230,1000.9219},{1370.0417,-2.7448,1004.3973}};
new Float:g13Team1Spawns[2][3] = {{516.3882,-2070.7771,8.8053},{542.4733,-2091.8020,11.0407}};
new Float:g14Team1Spawns[2][3] = {{4191.0254,-1609.9421,9.4215},{4167.8574,-1636.1426,9.1575}};
new Float:g15Team1Spawns[2][3]=
{
{-2366.1394,1536.0835,2.1172},
{-2366.0908,1542.4854,2.1172}
};
new Float:g16Team1Spawns[2][3]=
{
{-1435.5262,1480.1664,1.8672},
{-1439.2717,1491.3358,1.8672}
};
new Float:g17Team1Spawns[2][3]=
{
{2232.3325,1677.9073,1008.3594},
{2240.6733,1678.3192,1008.3594}
};
new Float:g18Team1Spawns[2][3]=
{
{1927.0093,1012.4525,994.4688},
{1927.2509,1025.3694,994.4688}
};
new Float:g19Team1Spawns[2][3]=
{
{1723.4520,-1640.2926,27.2035},
{1729.2224,-1639.9808,27.2464}
};
new Float:g20Team1Spawns[2][3]=
{
{-2660.0093,1428.1246,912.4114},
{-2670.1052,1428.7080,912.4063}
};
// Координаты респавнов спецназа
new Float:gTeam2Spawns[7][4] = {{211.069198,1808.600097,21.867187,87.607421},{245.675125,1859.658813,14.084012,1.029075},{259.606048,1870.162963,8.757812,89.157775},{241.982009,1845.786499,8.757812,272.540588},{254.260482,1802.218505,7.418661,91.014541},{241.495422,1831.202636,4.710937,270.428436},{240.115341,1878.761962,11.460937,179.897201}};
new Float:g2Team2Spawns[2][3] = {{-1375.3667,3969.8770,92.9005},{-1403.9269,3994.3337,92.9005}};
new Float:g3Team2Spawns[2][3] = {{1502.9543,-1518.9641,67.2072},{1528.8739,-1521.2714,67.2072}};
new Float:g4Team2Spawns[2][3] = {{-1131.1349,1029.1449,1345.7279},{-1131.3365,1057.9196,1346.4174}};
new Float:g5Team2Spawns[2][3] = {{1555.7014,-1246.4132,279.3455},{1552.0570,-1234.3361,277.8823}};
new Float:g6Team2Spawns[2][3] = {{-2213.8977,2087.4932,6.1000},{-2198.9097,2142.3862,3.9691}};
new Float:g7Team2Spawns[2][3] = {{3621.5984,-1514.6577,7.8483},{3100.1887,-1480.4529,2.7105}};
new Float:g8Team2Spawns[2][3] = {{2560.7583,-2065.0183,3.8594},{2560.5061,-2005.0332,3.8594}};
new Float:g9Team2Spawns[2][3] = {{4118.5815,-1823.9496,4.1563},{4166.0776,-1769.1033,3.1844}};
new Float:g10Team2Spawns[2][3] = {{-3159.9895,-2871.8372,1.9134},{-3035.9722,-2863.8281,1.9134}};
new Float:g11Team2Spawns[2][3] = {{424.3949,-857.2176,27.7998},{416.2459,-865.8541,27.2238}};
new Float:g12Team2Spawns[2][3] = {{1409.9056,-19.7939,1000.9230},{1381.0240,-30.1236,1004.3973}};
new Float:g13Team2Spawns[2][3] = {{596.1398,-2088.4343,11.0407},{612.1158,-2060.6692,11.0385}};
new Float:g14Team2Spawns[2][3] = {{4071.0803,-1633.8101,9.5777},{4103.1934,-1672.0254,9.5777}};
new Float:g15Team2Spawns[2][3] =
{
{-2439.8330,1554.9635,2.1231},
{-2432.8467,1542.0372,2.1172}
};
new Float:g16Team2Spawns[2][3] =
{
{-1370.5560,1486.4387,3.6641},
{-1372.6964,1486.9093,3.6641}
};
new Float:g17Team2Spawns[2][3] =
{
{2141.7769,1638.5546,993.5761},
{2145.9812,1638.1970,993.5761}
};
new Float:g18Team2Spawns[2][3] =
{
{2007.4491,1013.8793,994.4688},
{2008.5409,1021.5811,994.4688}
};
new Float:g19Team2Spawns[2][3] =
{
{1701.7133,-1649.9515,20.2195},
{1701.5601,-1661.6443,20.2194}
};
new Float:g20Team2Spawns[2][3] =
{
{-2636.4766,1408.7834,906.4609},
{-2636.6016,1404.3606,906.4609}
};

stock ConnectToMySQL()
{
	connectionHandle = mysql_connect(mysql_host, mysql_user, mysql_db, mysql_pass);
	switch(mysql_ping())
	{
		case 1: printf("MySQL > Соединение с базой данных '%s' успешно установлено", mysql_db);
		default: printf("MySQL | Ошибка > Не удалось соединиться с базой данных '%s'", mysql_db);
	}
	mysql_query("SET NAMES cp1251", -1, 0, connectionHandle);
	mysql_query("set character_set_client=\'cp1251\'", -1, 0, connectionHandle);
	mysql_query("set character_set_results=\'cp1251\'", -1, 0, connectionHandle);
	mysql_query("set collation_connection=\'cp1251_general_ci\'", -1, 0, connectionHandle);
	mysql_debug(0);
}
public OnGameModeInit()
{
	new ServerCount = GetTickCount();
	new year, month, day, hour, minute,second;
	new string[128];
	getdate(year,month,day);
	gettime(hour,minute,second);
	ResetServerSettings();
	ConnectToMySQL();
	UsePlayerPedAnims();
	ObjectLoad();
	GoMap();
	SetWeather(11);
	ShowPlayerMarkers(1);
	ShowNameTags(0);
	DisableInteriorEnterExits();
	SendRconCommand("hostname Гонка Вооружений | GTA SAMP 0.3.7");
	SendRconCommand("weburl https://github.com/MaDoyScripts");
	SendRconCommand("language Русский (Russian)");
	SetGameModeText("Гонка Вооружений | Версия 1.0");
	ostimer = SetTimer("OneSecondTimer",1000,true);
	infotimer = SetTimer("InfoTimer",10*60*1000,true);
	// Скины террористов
	AddPlayerClass(21,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(179,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(123,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(298,0,0,0,0,0,0,0,0,0,0);
	// Скины спецназа
	AddPlayerClass(287,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(285,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(165,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(191,0,0,0,0,0,0,0,0,0,0);
	//Скины VIP
	AddPlayerClass(111,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(113,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(294,0,0,0,0,0,0,0,0,0,0);
	AddPlayerClass(90,0,0,0,0,0,0,0,0,0,0);
	FirstTextDraw = TextDrawCreate(306.000000, 63.000000, "Error! Report to admin!");
	TextDrawAlignment(FirstTextDraw, 2);
	TextDrawBackgroundColor(FirstTextDraw, 255);
	TextDrawFont(FirstTextDraw, 3);
	TextDrawLetterSize(FirstTextDraw, 0.509998, 2.299998);
	TextDrawColor(FirstTextDraw, -1);
	TextDrawSetOutline(FirstTextDraw, 1);
	TextDrawSetProportional(FirstTextDraw, 1);
	
	leaderTD = TextDrawCreate(312.000000, 419.000000, "You are Game Leader");
	TextDrawAlignment(leaderTD, 2);
	TextDrawBackgroundColor(leaderTD, 255);
	TextDrawFont(leaderTD, 1);
	TextDrawLetterSize(leaderTD, 0.340000, 1.799999);
	TextDrawColor(leaderTD, -65281);
	TextDrawSetOutline(leaderTD, 0);
	TextDrawSetProportional(leaderTD, 1);
	TextDrawSetShadow(leaderTD, 1);
	
	leaderTeamT = TextDrawCreate(311.000000, 401.000000, "You are Team Leader");
	TextDrawAlignment(leaderTeamT, 2);
	TextDrawBackgroundColor(leaderTeamT, 255);
	TextDrawFont(leaderTeamT, 1);
	TextDrawLetterSize(leaderTeamT, 0.340000, 1.799999);
	TextDrawColor(leaderTeamT, -16776961);
	TextDrawSetOutline(leaderTeamT, 0);
	TextDrawSetProportional(leaderTeamT, 1);
	TextDrawSetShadow(leaderTeamT, 1);
	
	leaderTeamCT = TextDrawCreate(311.000000, 401.000000, "You are Team Leader");
	TextDrawAlignment(leaderTeamCT, 2);
	TextDrawBackgroundColor(leaderTeamCT, 255);
	TextDrawFont(leaderTeamCT, 1);
	TextDrawLetterSize(leaderTeamCT, 0.340000, 1.799999);
	TextDrawColor(leaderTeamCT, 65535);
	TextDrawSetOutline(leaderTeamCT, 0);
	TextDrawSetProportional(leaderTeamCT, 1);
	TextDrawSetShadow(leaderTeamCT, 1);
	
	leader = TextDrawCreate(312.000000, 419.000000, "Game Leader: None");
	TextDrawAlignment(leader, 2);
	TextDrawBackgroundColor(leader, 255);
	TextDrawFont(leader, 1);
	TextDrawLetterSize(leader, 0.340000, 1.800000);
	TextDrawColor(leader, -65281);
	TextDrawSetOutline(leader, 0);
	TextDrawSetProportional(leader, 1);
	TextDrawSetShadow(leader, 1);
	
	leaderT = TextDrawCreate(311.000000, 401.000000, "Team Leader: None");
	TextDrawAlignment(leaderT, 2);
	TextDrawBackgroundColor(leaderT, 255);
	TextDrawFont(leaderT, 1);
	TextDrawLetterSize(leaderT, 0.340000, 1.799999);
	TextDrawColor(leaderT, -16776961);
	TextDrawSetOutline(leaderT, 0);
	TextDrawSetProportional(leaderT, 1);
	TextDrawSetShadow(leaderT, 1);
	
	leaderCT = TextDrawCreate(311.000000, 401.000000, "Team Leader: None");
	TextDrawAlignment(leaderCT, 2);
	TextDrawBackgroundColor(leaderCT, 255);
	TextDrawFont(leaderCT, 1);
	TextDrawLetterSize(leaderCT, 0.340000, 1.799999);
	TextDrawColor(leaderCT, 65535);
	TextDrawSetOutline(leaderCT, 0);
	TextDrawSetProportional(leaderCT, 1);
	TextDrawSetShadow(leaderCT, 1);
	
	lvlexpBG[0] = TextDrawCreate(190.000000, 267.000000, "   ");
	TextDrawBackgroundColor(lvlexpBG[0], 255);
	TextDrawFont(lvlexpBG[0], 1);
	TextDrawLetterSize(lvlexpBG[0], 0.659999, 2.400000);
	TextDrawColor(lvlexpBG[0], -1);
	TextDrawSetOutline(lvlexpBG[0], 0);
	TextDrawSetProportional(lvlexpBG[0], 1);
	TextDrawSetShadow(lvlexpBG[0], 1);
	TextDrawUseBox(lvlexpBG[0], 1);
	TextDrawBoxColor(lvlexpBG[0], 102);
	TextDrawTextSize(lvlexpBG[0], 3.000000, -4.000000);
	
	lvlexpBG[1] = TextDrawCreate(190.000000, 267.000000, "   ");
	TextDrawBackgroundColor(lvlexpBG[1], 255);
	TextDrawFont(lvlexpBG[1], 1);
	TextDrawLetterSize(lvlexpBG[1], 0.659999, 2.400000);
	TextDrawColor(lvlexpBG[1], -1);
	TextDrawSetOutline(lvlexpBG[1], 0);
	TextDrawSetProportional(lvlexpBG[1], 1);
	TextDrawSetShadow(lvlexpBG[1], 1);
	TextDrawUseBox(lvlexpBG[1], 1);
	TextDrawBoxColor(lvlexpBG[1], 520093798);
	TextDrawTextSize(lvlexpBG[1], 3.000000, -4.000000);

	lvlexpBG[2] = TextDrawCreate(190.000000, 267.000000, "   ");
	TextDrawBackgroundColor(lvlexpBG[2], 255);
	TextDrawFont(lvlexpBG[2], 1);
	TextDrawLetterSize(lvlexpBG[2], 0.659999, 2.400000);
	TextDrawColor(lvlexpBG[2], -1);
	TextDrawSetOutline(lvlexpBG[2], 0);
	TextDrawSetProportional(lvlexpBG[2], 1);
	TextDrawSetShadow(lvlexpBG[2], 1);
	TextDrawUseBox(lvlexpBG[2], 1);
	TextDrawBoxColor(lvlexpBG[2], 52363366);
	TextDrawTextSize(lvlexpBG[2], 3.000000, -4.000000);
	
	lvlexpBG[3] = TextDrawCreate(190.000000, 267.000000, "   ");
	TextDrawBackgroundColor(lvlexpBG[3], 255);
	TextDrawFont(lvlexpBG[3], 1);
	TextDrawLetterSize(lvlexpBG[3], 0.659999, 2.400000);
	TextDrawColor(lvlexpBG[3], -1);
	TextDrawSetOutline(lvlexpBG[3], 0);
	TextDrawSetProportional(lvlexpBG[3], 1);
	TextDrawSetShadow(lvlexpBG[3], 1);
	TextDrawUseBox(lvlexpBG[3], 1);
	TextDrawBoxColor(lvlexpBG[3], 204646);
	TextDrawTextSize(lvlexpBG[3], 3.000000, -4.000000);

	leaderBG[0] = TextDrawCreate(452.000000, 400.000000, "   ");
	TextDrawBackgroundColor(leaderBG[0], 255);
	TextDrawFont(leaderBG[0], 1);
	TextDrawLetterSize(leaderBG[0], 0.300000, 2.200000);
	TextDrawColor(leaderBG[0], 13311);
	TextDrawSetOutline(leaderBG[0], 0);
	TextDrawSetProportional(leaderBG[0], 1);
	TextDrawSetShadow(leaderBG[0], 1);
	TextDrawUseBox(leaderBG[0], 1);
	TextDrawBoxColor(leaderBG[0], 102);
	TextDrawTextSize(leaderBG[0], 179.000000, 50.000000);
	
	leaderBG[1] = TextDrawCreate(452.000000, 400.000000, "   ");
	TextDrawBackgroundColor(leaderBG[1], 255);
	TextDrawFont(leaderBG[1], 1);
	TextDrawLetterSize(leaderBG[1], 0.300000, 2.200000);
	TextDrawColor(leaderBG[1], 13311);
	TextDrawSetOutline(leaderBG[1], 0);
	TextDrawSetProportional(leaderBG[1], 1);
	TextDrawSetShadow(leaderBG[1], 1);
	TextDrawUseBox(leaderBG[1], 1);
	TextDrawBoxColor(leaderBG[1], 520093798);
	TextDrawTextSize(leaderBG[1], 179.000000, 50.000000);
	
	leaderBG[2] = TextDrawCreate(452.000000, 400.000000, "   ");
	TextDrawBackgroundColor(leaderBG[2], 255);
	TextDrawFont(leaderBG[2], 1);
	TextDrawLetterSize(leaderBG[2], 0.300000, 2.200000);
	TextDrawColor(leaderBG[2], 13311);
	TextDrawSetOutline(leaderBG[2], 0);
	TextDrawSetProportional(leaderBG[2], 1);
	TextDrawSetShadow(leaderBG[2], 1);
	TextDrawUseBox(leaderBG[2], 1);
	TextDrawBoxColor(leaderBG[2], 52363366);
	TextDrawTextSize(leaderBG[2], 179.000000, 50.000000);
	
	leaderBG[3] = TextDrawCreate(452.000000, 400.000000, "   ");
	TextDrawBackgroundColor(leaderBG[3], 255);
	TextDrawFont(leaderBG[3], 1);
	TextDrawLetterSize(leaderBG[3], 0.300000, 2.200000);
	TextDrawColor(leaderBG[3], 13311);
	TextDrawSetOutline(leaderBG[3], 0);
	TextDrawSetProportional(leaderBG[3], 1);
	TextDrawSetShadow(leaderBG[3], 1);
	TextDrawUseBox(leaderBG[3], 1);
	TextDrawBoxColor(leaderBG[3], 204646);
	TextDrawTextSize(leaderBG[3], 179.000000, 50.000000);
	
	URL = TextDrawCreate(21.000000, 426.000000, "github.com/MaDoyScripts");
	TextDrawBackgroundColor(URL, 255);
	TextDrawFont(URL, 1);
	TextDrawLetterSize(URL, 0.349999, 1.800000);
	TextDrawColor(URL, -1);
	TextDrawSetOutline(URL, 1);
	TextDrawSetProportional(URL, 1);
	
	LevelUpTD[TopicLUTD] = TextDrawCreate(581.904663, 278.399902, "Level Up");
	TextDrawLetterSize(LevelUpTD[TopicLUTD], 0.402379, 1.471999);
	TextDrawAlignment(LevelUpTD[TopicLUTD], 2);
	TextDrawColor(LevelUpTD[TopicLUTD], -1);
	TextDrawSetShadow(LevelUpTD[TopicLUTD], 2);
	TextDrawSetOutline(LevelUpTD[TopicLUTD], 0);
	TextDrawBackgroundColor(LevelUpTD[TopicLUTD], 51);
	TextDrawFont(LevelUpTD[TopicLUTD], 1);
	TextDrawSetProportional(LevelUpTD[TopicLUTD], 1);
	
    LevelUpTD[BackgroundLUTD][0] = TextDrawCreate(620.094909, 277.766662, "usebox");
	TextDrawLetterSize(LevelUpTD[BackgroundLUTD][0], 0.000000, 10.029367);
	TextDrawTextSize(LevelUpTD[BackgroundLUTD][0], 546.095397, 0.000000);
	TextDrawAlignment(LevelUpTD[BackgroundLUTD][0], 1);
	TextDrawColor(LevelUpTD[BackgroundLUTD][0], 0);
	TextDrawUseBox(LevelUpTD[BackgroundLUTD][0], true);
	TextDrawBoxColor(LevelUpTD[BackgroundLUTD][0], 102);
	TextDrawSetShadow(LevelUpTD[BackgroundLUTD][0], 0);
	TextDrawSetOutline(LevelUpTD[BackgroundLUTD][0], 0);
	TextDrawFont(LevelUpTD[BackgroundLUTD][0], 0);

    LevelUpTD[BackgroundLUTD][1] = TextDrawCreate(620.094909, 277.766662, "usebox");
	TextDrawLetterSize(LevelUpTD[BackgroundLUTD][1], 0.000000, 10.029367);
	TextDrawTextSize(LevelUpTD[BackgroundLUTD][1], 546.095397, 0.000000);
	TextDrawAlignment(LevelUpTD[BackgroundLUTD][1], 1);
	TextDrawColor(LevelUpTD[BackgroundLUTD][1], 0);
	TextDrawUseBox(LevelUpTD[BackgroundLUTD][1], true);
	TextDrawBoxColor(LevelUpTD[BackgroundLUTD][1], 520093798);
	TextDrawSetShadow(LevelUpTD[BackgroundLUTD][1], 0);
	TextDrawSetOutline(LevelUpTD[BackgroundLUTD][1], 0);
	TextDrawFont(LevelUpTD[BackgroundLUTD][1], 0);

    LevelUpTD[BackgroundLUTD][2] = TextDrawCreate(620.094909, 277.766662, "usebox");
	TextDrawLetterSize(LevelUpTD[BackgroundLUTD][2], 0.000000, 10.029367);
	TextDrawTextSize(LevelUpTD[BackgroundLUTD][2], 546.095397, 0.000000);
	TextDrawAlignment(LevelUpTD[BackgroundLUTD][2], 1);
	TextDrawColor(LevelUpTD[BackgroundLUTD][2], 0);
	TextDrawUseBox(LevelUpTD[BackgroundLUTD][2], true);
	TextDrawBoxColor(LevelUpTD[BackgroundLUTD][2], 52363366);
	TextDrawSetShadow(LevelUpTD[BackgroundLUTD][2], 0);
	TextDrawSetOutline(LevelUpTD[BackgroundLUTD][2], 0);
	TextDrawFont(LevelUpTD[BackgroundLUTD][2], 0);

    LevelUpTD[BackgroundLUTD][3] = TextDrawCreate(620.094909, 277.766662, "usebox");
	TextDrawLetterSize(LevelUpTD[BackgroundLUTD][3], 0.000000, 10.029367);
	TextDrawTextSize(LevelUpTD[BackgroundLUTD][3], 546.095397, 0.000000);
	TextDrawAlignment(LevelUpTD[BackgroundLUTD][3], 1);
	TextDrawColor(LevelUpTD[BackgroundLUTD][3], 0);
	TextDrawUseBox(LevelUpTD[BackgroundLUTD][3], true);
	TextDrawBoxColor(LevelUpTD[BackgroundLUTD][3], 204646);
	TextDrawSetShadow(LevelUpTD[BackgroundLUTD][3], 0);
	TextDrawSetOutline(LevelUpTD[BackgroundLUTD][3], 0);
	TextDrawFont(LevelUpTD[BackgroundLUTD][3], 0);

// модели оружий

	LevelUpTD[ModelLUTD][0] = TextDrawCreate(556.190490, 280.533416, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][0], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][0], 0.460000, 3.400000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][0], 94.761932, 94.400024);
	TextDrawAlignment(LevelUpTD[ModelLUTD][0], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][0], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][0], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][0], 255);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][0], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][0], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][0], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][0], 347);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][0], 0.000000, 0.000000, 0.000000, 1.000000);
	
	LevelUpTD[ModelLUTD][1] = TextDrawCreate(546.190673, 285.333129, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][1], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][1], 0.000000, -0.303999);
	TextDrawTextSize(LevelUpTD[ModelLUTD][1], 109.999961, 78.933349);
	TextDrawAlignment(LevelUpTD[ModelLUTD][1], 2);
	TextDrawColor(LevelUpTD[ModelLUTD][1], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][1], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][1], 255);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][1], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][1], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][1], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][1], 346);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][1], 0.000000, 0.000000, 0.000000, 1.000000);
	
	LevelUpTD[ModelLUTD][2] = TextDrawCreate(556.666931, 277.333343, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][2], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][2], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][2], 109.999984, 97.066650);
	TextDrawAlignment(LevelUpTD[ModelLUTD][2], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][2], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][2], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][2], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][2], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][2], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][2], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][2], 348);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][2], 0.000000, 351.000000, 0.000000, 1.000000);
	
    LevelUpTD[ModelLUTD][3] = TextDrawCreate(539.523925, 270.399902, " ");
    TextDrawBackgroundColor(LevelUpTD[ModelLUTD][3], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][3], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][3], 114.285682, 103.466674);
	TextDrawAlignment(LevelUpTD[ModelLUTD][3], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][3], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][3], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][3], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][3], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][3], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][3], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][3], 349);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][3], 0.000000, 0.000000, 0.000000, 3.000000);
	
	LevelUpTD[ModelLUTD][4] = TextDrawCreate(550.476257, 273.066650, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][4], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][4], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][4], 108.095245, 101.333312);
	TextDrawAlignment(LevelUpTD[ModelLUTD][4], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][4], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][4], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][4], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][4], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][4], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][4], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][4], 350);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][4], 1.000000, 0.000000, 0.000000, 2.000000);
	
	LevelUpTD[ModelLUTD][5] = TextDrawCreate(549.047607, 274.133300, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][5], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][5], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][5], 136.190444, 110.399993);
	TextDrawAlignment(LevelUpTD[ModelLUTD][5], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][5], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][5], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][5], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][5], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][5], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][5], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][5], 351);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][5], 0.000000, 0.000000, 0.000000, 2.000000);
	
	LevelUpTD[ModelLUTD][6] = TextDrawCreate(532.857360, 259.199920, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][6], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][6], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][6], 112.857139, 113.066650);
	TextDrawAlignment(LevelUpTD[ModelLUTD][6], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][6], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][6], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][6], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][6], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][6], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][6], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][6], 352);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][6], 0.000000, 0.000000, 0.000000, 2.000000);
	
	LevelUpTD[ModelLUTD][7] = TextDrawCreate(540.000183, 262.933258, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][7], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][7], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][7], 119.047576, 108.799987);
	TextDrawAlignment(LevelUpTD[ModelLUTD][7], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][7], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][7], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][7], 255);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][7], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][7], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][7], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][7], 372);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][7], 0.000000, 0.000000, 0.000000, 2.000000);
	
	LevelUpTD[ModelLUTD][8] = TextDrawCreate(539.523864, 272.533233, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][8], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][8], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][8], 115.714279, 111.466644);
	TextDrawAlignment(LevelUpTD[ModelLUTD][8], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][8], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][8], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][8], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][8], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][8], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][8], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][8], 353);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][8], 0.000000, 0.000000, 0.000000, 2.000000);

    LevelUpTD[ModelLUTD][9] = TextDrawCreate(527.142761, 263.999969, " ");
    TextDrawBackgroundColor(LevelUpTD[ModelLUTD][9], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][9], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][9], 131.904724, 114.133331);
	TextDrawAlignment(LevelUpTD[ModelLUTD][9], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][9], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][9], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][9], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][9], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][9], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][9], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][9], 355);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][9], 0.000000, 0.000000, 0.000000, 4.000000);
	
	LevelUpTD[ModelLUTD][10] = TextDrawCreate(533.333557, 267.733337, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][10], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][10], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][10], 124.761924, 108.266662);
	TextDrawAlignment(LevelUpTD[ModelLUTD][10], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][10], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][10], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][10], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][10], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][10], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][10], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][10], 356);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][10], 0.000000, 0.000000, 0.000000, 3.000000);
	
	LevelUpTD[ModelLUTD][11] = TextDrawCreate(534.285766, 269.333251, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][11], 0);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][11], 0.000000, 0.000000);
	TextDrawTextSize(LevelUpTD[ModelLUTD][11], 128.095260, 108.799987);
	TextDrawAlignment(LevelUpTD[ModelLUTD][11], 1);
	TextDrawColor(LevelUpTD[ModelLUTD][11], -1);
	TextDrawUseBox(LevelUpTD[ModelLUTD][11], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][11], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][11], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][11], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][11], 5);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][11], 357);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][11], 0.000000, 0.000000, 0.000000, 3.000000);
	
	LevelUpTD[ModelLUTD][12] = TextDrawCreate(534.285766, 267.733184, " ");
	TextDrawBackgroundColor(LevelUpTD[ModelLUTD][12], 0);
	TextDrawFont(LevelUpTD[ModelLUTD][12], 5);
	TextDrawLetterSize(LevelUpTD[ModelLUTD][12], 1.000000, 1.000000);
	TextDrawColor(LevelUpTD[ModelLUTD][12], -1);
	TextDrawTextSize(LevelUpTD[ModelLUTD][12], 121.904769, 115.199981);
	TextDrawAlignment(LevelUpTD[ModelLUTD][12], 2);
	TextDrawUseBox(LevelUpTD[ModelLUTD][12], true);
	TextDrawBoxColor(LevelUpTD[ModelLUTD][12], 0);
	TextDrawSetShadow(LevelUpTD[ModelLUTD][12], 0);
	TextDrawSetOutline(LevelUpTD[ModelLUTD][12], 0);
	TextDrawSetPreviewModel(LevelUpTD[ModelLUTD][12], 358);
	TextDrawSetPreviewRot(LevelUpTD[ModelLUTD][12], 0.000000, 0.000000, 0.000000, 3.000000);


	
/*	LevelUpTD[14] = TextDrawCreate(620.000000, 271.000000, "   ");
	TextDrawBackgroundColor(LevelUpTD[14], 255);
	TextDrawFont(LevelUpTD[14], 1);
	TextDrawLetterSize(LevelUpTD[14], 0.500000, 4.099999);
	TextDrawColor(LevelUpTD[14], -1);
	TextDrawSetOutline(LevelUpTD[14], 0);
	TextDrawSetProportional(LevelUpTD[14], 1);
	TextDrawSetShadow(LevelUpTD[14], 1);
	TextDrawUseBox(LevelUpTD[14], 1);
	TextDrawBoxColor(LevelUpTD[14], 102);
	TextDrawTextSize(LevelUpTD[14], 546.000000, 0.000000);
	
	LevelUpTD[15] = TextDrawCreate(562.000000, 332.000000, "New Level");
	TextDrawBackgroundColor(LevelUpTD[15], 255);
	TextDrawFont(LevelUpTD[15], 1);
	TextDrawLetterSize(LevelUpTD[15], 0.260000, 1.000000);
	TextDrawColor(LevelUpTD[15], -1);
	TextDrawSetOutline(LevelUpTD[15], 0);
	TextDrawSetProportional(LevelUpTD[15], 1);
	TextDrawSetShadow(LevelUpTD[15], 1);
	
	
	LevelUpTD[1] = TextDrawCreate(520.000000, 225.000000, "Colt45");
	TextDrawBackgroundColor(LevelUpTD[1], 0);
	TextDrawFont(LevelUpTD[1], 5);
	TextDrawLetterSize(LevelUpTD[1], 0.500000, 1.000000);
	TextDrawColor(LevelUpTD[1], -1);
	TextDrawSetOutline(LevelUpTD[1], 0);
	TextDrawSetProportional(LevelUpTD[1], 1);
	TextDrawSetShadow(LevelUpTD[1], 0);
	TextDrawTextSize(LevelUpTD[1], 164.000000, 155.000000);
	TextDrawSetPreviewModel(LevelUpTD[1], 346);
	TextDrawSetPreviewRot(LevelUpTD[1], 0.000000, 0.000000, 60.000000, 1.500000);
	
	LevelUpTD[2] = TextDrawCreate(520.000000, 225.000000, "Deagle");
	TextDrawBackgroundColor(LevelUpTD[2], 0);
	TextDrawFont(LevelUpTD[2], 5);
	TextDrawLetterSize(LevelUpTD[2], 0.500000, 1.000000);
	TextDrawColor(LevelUpTD[2], -1);
	TextDrawSetOutline(LevelUpTD[2], 0);
	TextDrawSetProportional(LevelUpTD[2], 1);
	TextDrawSetShadow(LevelUpTD[2], 0);
	TextDrawTextSize(LevelUpTD[2], 164.000000, 155.000000);
	TextDrawSetPreviewModel(LevelUpTD[2], 348);
	TextDrawSetPreviewRot(LevelUpTD[2], 0.000000, 0.000000, 60.000000, 1.500000);*/

 	RDTD[5] = TextDrawCreate(440.000000, 160.000000, "   ");
	TextDrawBackgroundColor(RDTD[5], 255);
	TextDrawFont(RDTD[5], 1);
	TextDrawLetterSize(RDTD[5], 1.300000, 8.100000);
	TextDrawColor(RDTD[5], -1);
	TextDrawSetOutline(RDTD[5], 0);
	TextDrawSetProportional(RDTD[5], 1);
	TextDrawSetShadow(RDTD[5], 1);
	TextDrawUseBox(RDTD[5], 1);
	TextDrawBoxColor(RDTD[5], 204646);
	TextDrawTextSize(RDTD[5], 200.000000, 0.000000);

 	RDTD[4] = TextDrawCreate(440.000000, 160.000000, "   ");
	TextDrawBackgroundColor(RDTD[4], 255);
	TextDrawFont(RDTD[4], 1);
	TextDrawLetterSize(RDTD[4], 1.300000, 8.100000);
	TextDrawColor(RDTD[4], -1);
	TextDrawSetOutline(RDTD[4], 0);
	TextDrawSetProportional(RDTD[4], 1);
	TextDrawSetShadow(RDTD[4], 1);
	TextDrawUseBox(RDTD[4], 1);
	TextDrawBoxColor(RDTD[4], 52363366);
	TextDrawTextSize(RDTD[4], 200.000000, 0.000000);

 	RDTD[3] = TextDrawCreate(440.000000, 160.000000, "   ");
	TextDrawBackgroundColor(RDTD[3], 255);
	TextDrawFont(RDTD[3], 1);
	TextDrawLetterSize(RDTD[3], 1.300000, 8.100000);
	TextDrawColor(RDTD[3], -1);
	TextDrawSetOutline(RDTD[3], 0);
	TextDrawSetProportional(RDTD[3], 1);
	TextDrawSetShadow(RDTD[3], 1);
	TextDrawUseBox(RDTD[3], 1);
	TextDrawBoxColor(RDTD[3], 520093798);
	TextDrawTextSize(RDTD[3], 200.000000, 0.000000);
	
 	RDTD[2] = TextDrawCreate(440.000000, 160.000000, "   ");
	TextDrawBackgroundColor(RDTD[2], 255);
	TextDrawFont(RDTD[2], 1);
	TextDrawLetterSize(RDTD[2], 1.300000, 8.100000);
	TextDrawColor(RDTD[2], -1);
	TextDrawSetOutline(RDTD[2], 0);
	TextDrawSetProportional(RDTD[2], 1);
	TextDrawSetShadow(RDTD[2], 1);
	TextDrawUseBox(RDTD[2], 1);
	TextDrawBoxColor(RDTD[2], 102);
	TextDrawTextSize(RDTD[2], 200.000000, 0.000000);
	
	RDTD[1] = TextDrawCreate(242.000000, 144.000000, "Respawn Delay");
	TextDrawBackgroundColor(RDTD[1], 255);
	TextDrawFont(RDTD[1], 0);
	TextDrawLetterSize(RDTD[1], 0.900000, 3.000000);
	TextDrawColor(RDTD[1], -1);
	TextDrawSetOutline(RDTD[1], 0);
	TextDrawSetProportional(RDTD[1], 1);
	TextDrawSetShadow(RDTD[1], 1);
	
	RDTD[0] = TextDrawCreate(322.000000, 179.000000, "You will return in ~n~~n~~n~~n~~n~seconds");
	TextDrawAlignment(RDTD[0], 2);
	TextDrawBackgroundColor(RDTD[0], 255);
	TextDrawFont(RDTD[0], 1);
	TextDrawLetterSize(RDTD[0], 0.500000, 2.000000);
	TextDrawColor(RDTD[0], -1);
	TextDrawSetOutline(RDTD[0], 0);
	TextDrawSetProportional(RDTD[0], 1);
	TextDrawSetShadow(RDTD[0], 1);

	HealTD[4] = TextDrawCreate(620.000000, 201.000000, "   ");
	TextDrawBackgroundColor(HealTD[4], 255);
	TextDrawFont(HealTD[4], 1);
	TextDrawLetterSize(HealTD[4], 0.460000, 3.499999);
	TextDrawColor(HealTD[4], 102);
	TextDrawSetOutline(HealTD[4], 0);
	TextDrawSetProportional(HealTD[4], 1);
	TextDrawSetShadow(HealTD[4], 1);
	TextDrawUseBox(HealTD[4], 1);
	TextDrawBoxColor(HealTD[4], 204646);
	TextDrawTextSize(HealTD[4], 546.000000, 60.000000);

	HealTD[3] = TextDrawCreate(620.000000, 201.000000, "   ");
	TextDrawBackgroundColor(HealTD[3], 255);
	TextDrawFont(HealTD[3], 1);
	TextDrawLetterSize(HealTD[3], 0.460000, 3.499999);
	TextDrawColor(HealTD[3], 102);
	TextDrawSetOutline(HealTD[3], 0);
	TextDrawSetProportional(HealTD[3], 1);
	TextDrawSetShadow(HealTD[3], 1);
	TextDrawUseBox(HealTD[3], 1);
	TextDrawBoxColor(HealTD[3], 52363366);
	TextDrawTextSize(HealTD[3], 546.000000, 60.000000);

	HealTD[2] = TextDrawCreate(620.000000, 201.000000, "   ");
	TextDrawBackgroundColor(HealTD[2], 255);
	TextDrawFont(HealTD[2], 1);
	TextDrawLetterSize(HealTD[2], 0.460000, 3.499999);
	TextDrawColor(HealTD[2], 102);
	TextDrawSetOutline(HealTD[2], 0);
	TextDrawSetProportional(HealTD[2], 1);
	TextDrawSetShadow(HealTD[2], 1);
	TextDrawUseBox(HealTD[2], 1);
	TextDrawBoxColor(HealTD[2], 520093798);
	TextDrawTextSize(HealTD[2], 546.000000, 60.000000);
	
	HealTD[1] = TextDrawCreate(620.000000, 201.000000, "   ");
	TextDrawBackgroundColor(HealTD[1], 255);
	TextDrawFont(HealTD[1], 1);
	TextDrawLetterSize(HealTD[1], 0.460000, 3.499999);
	TextDrawColor(HealTD[1], 102);
	TextDrawSetOutline(HealTD[1], 0);
	TextDrawSetProportional(HealTD[1], 1);
	TextDrawSetShadow(HealTD[1], 1);
	TextDrawUseBox(HealTD[1], 1);
	TextDrawBoxColor(HealTD[1], 102);
	TextDrawTextSize(HealTD[1], 546.000000, 60.000000);
	
	HealTD[0] = TextDrawCreate(585.000000, 202.000000, "Medecine Chest ~n~used");
	TextDrawAlignment(HealTD[0], 2);
	TextDrawBackgroundColor(HealTD[0], 255);
	TextDrawFont(HealTD[0], 1);
	TextDrawLetterSize(HealTD[0], 0.160000, 1.000000);
	TextDrawColor(HealTD[0], -1);
	TextDrawSetOutline(HealTD[0], 0);
	TextDrawSetProportional(HealTD[0], 1);
	TextDrawSetShadow(HealTD[0], 1);
	
	TKPlus1[0] = TextDrawCreate(263.000000, 23.000000, "+1");
	TextDrawBackgroundColor(TKPlus1[0], 255);
	TextDrawFont(TKPlus1[0], 1);
	TextDrawLetterSize(TKPlus1[0], 0.500000, 2.199999);
	TextDrawColor(TKPlus1[0], -16776961);
	TextDrawSetOutline(TKPlus1[0], 0);
	TextDrawSetProportional(TKPlus1[0], 1);
	TextDrawSetShadow(TKPlus1[0], 1);
	
	TKPlus1[1] = TextDrawCreate(312.000000, 23.000000, "+1");
	TextDrawBackgroundColor(TKPlus1[1], 255);
	TextDrawFont(TKPlus1[1], 1);
	TextDrawLetterSize(TKPlus1[1], 0.500000, 2.199999);
	TextDrawColor(TKPlus1[1], 65535);
	TextDrawSetOutline(TKPlus1[1], 0);
	TextDrawSetProportional(TKPlus1[1], 1);
	TextDrawSetShadow(TKPlus1[1], 1);
	
	TeamScore = TextDrawCreate(332.000000, 1.000000, "~r~Terrorists ~w~[~y~0~w~] - [~y~0~w~] ~b~Counter Terrorists");
	TextDrawAlignment(TeamScore, 2);
	TextDrawBackgroundColor(TeamScore, 255);
	TextDrawFont(TeamScore, 3);
	TextDrawLetterSize(TeamScore, 0.400000, 2.100000);
	TextDrawColor(TeamScore, -1);
	TextDrawSetOutline(TeamScore, 0);
	TextDrawSetProportional(TeamScore, 1);
	TextDrawSetShadow(TeamScore, 1);
	//
	TimeDisp = TextDrawCreate(576.666931, 24.000015, "00:00");
	TextDrawLetterSize(TimeDisp, 0.476666, 1.802666);
	TextDrawAlignment(TimeDisp, 2);
	TextDrawColor(TimeDisp, -1);
	TextDrawSetShadow(TimeDisp, 0);
	TextDrawSetOutline(TimeDisp, 1);
	TextDrawBackgroundColor(TimeDisp, 51);
	TextDrawFont(TimeDisp, 1);
	TextDrawSetProportional(TimeDisp, 1);
	//
	UpdateTime();
	SetTimer("UpdateTime",1000*60,true);
	//
	format(string,sizeof(string),"%02d.%02d.%d",day,month,year);
	DateDisp = TextDrawCreate(577.143432, 41.066722, string);
	TextDrawLetterSize(DateDisp, 0.300952, 1.743999);
	TextDrawTextSize(DateDisp, -1.904762, -0.533333);
	TextDrawAlignment(DateDisp, 2);
	TextDrawColor(DateDisp, -1);
	TextDrawSetShadow(DateDisp, 0);
	TextDrawSetOutline(DateDisp, 1);
	TextDrawBackgroundColor(DateDisp, 51);
	TextDrawFont(DateDisp, 1);
	TextDrawSetProportional(DateDisp, 1);
	//
	printf("Version > MaDoy's ArmRace Engine v1.0 (10.02.2016)");
	printf("Info > На сервере установлено %d дополнительных объектов", CountDynamicObjects());
	printf("Info > Игровой мод запущен %d %s %d года в %d:%02d:%02d по МСК", day,GetMonthNameRus(month),year,hour,minute,second);
	string = "Info > ";
	second-=START_SECOND;
	minute-=START_MINUTE;
	hour-=START_HOUR;
	day-=START_DAY;
	month-=START_MONTH;
	year-=START_YEAR;
	if(second < 0)
	{
		second+=60;
		minute--;
	}
	if(minute < 0)
	{
		minute+=60;
		hour--;
	}
	if(hour < 0)
	{
		hour+=24;
		day--;
	}
	if(day < 0)
	{
		day+=31; //day+=GetDayCount(START_MONTH);
		month--;
	}
	if(month < 0)
	{
		month+=12;
		year--;
	}
	if(year > 0)
	{
		if(year < 11 || year > 20)
		{
			switch(year % 10)
			{
				case 1: format(string,sizeof(string),"%s%d год ",string,year);
				case 2..4: format(string,sizeof(string),"%s%d года ",string,year);
				default: format(string,sizeof(string),"%s%d лет ",string,year);
			}
		}
		else format(string,sizeof(string),"%s%d лет ",year);
	}
	switch(month)
	{
		case 1: strcat(string,"1 месяц ");
		case 2..4: format(string,sizeof(string),"%s%d месяца ",string,month);
		case 5..12: format(string,sizeof(string),"%s%d месяцев ",string,month);
	}
	switch(day)
	{
		case 1: strcat(string,"1 день ");
		case 2..4: format(string,sizeof(string),"%s%d дня ",string,day);
		case 5..20: format(string,sizeof(string),"%s%d дней ",string,day);
		case 21: strcat(string,"21 день ");
		case 22..24: format(string,sizeof(string),"%s%d дня ",string,day);
		case 25..30: format(string,sizeof(string),"%s%d дней ",string,day);
		case 31: strcat(string,"31 дннь ");
	}
	switch(hour)
	{
		case 1: strcat(string,"1 час ");
		case 2..4: format(string,sizeof(string),"%s%d часа ",string,hour);
		case 5..20: format(string,sizeof(string),"%s%d часов ",string,hour);
		case 21: strcat(string,"21 час ");
		case 22..24: format(string,sizeof(string),"%s%d часа ",string,hour);
	}
	if(minute > 0)
	{
		if(minute < 11 || minute > 20)
		{
			switch(minute % 10)
			{
				case 1: format(string,sizeof(string),"%s%d минута ",string,minute);
				case 2..4: format(string,sizeof(string),"%s%d минуты ",string,minute);
				default: format(string,sizeof(string),"%s%d минут ",string,minute);
			}
		}
		else format(string,sizeof(string),"%s%d минут ",string,minute);
	}
	if(second > 0)
	{
		if(second < 11 || second > 20)
		{
			switch(second % 10)
			{
			case 1: format(string,sizeof(string),"%s%d секунда ",string,second);
			case 2..4: format(string,sizeof(string),"%s%d секунды ",string,second);
			default: format(string,sizeof(string),"%s%d секунд ",string,second);
			}
		}
		else format(string,sizeof(string),"%s%d секунд ",string,second);
	}
	strcat(string,"с момента начала разработки");
	printf(string);
	if(ANNOUNCE_IF_OLD) SetTimer("CheckForUpdates",1000,false);
	printf("Info > На загрузку мода потрачено %d миллисекунд(ы)", GetTickCount() - ServerCount);
	return true;
}
public OnGameModeExit()
{
	mysql_close(connectionHandle);
	TextDrawDestroy(FirstTextDraw);
	TextDrawDestroy(leaderTD);
	TextDrawDestroy(leaderTeamT);
	TextDrawDestroy(leaderTeamCT);
	TextDrawDestroy(leader);
	TextDrawDestroy(leaderT);
	TextDrawDestroy(leaderCT);
//	TextDrawDestroy(lvlexpBG);
//	TextDrawDestroy(leaderBG);
	TextDrawDestroy(URL);
	TextDrawDestroy(RDTD[0]);
	TextDrawDestroy(RDTD[1]);
	TextDrawDestroy(RDTD[2]);
	TextDrawDestroy(HealTD[0]);
	TextDrawDestroy(HealTD[1]);
	TextDrawDestroy(TKPlus1[0]);
	TextDrawDestroy(TKPlus1[1]);
	TextDrawDestroy(TeamScore);
	TextDrawDestroy(TimeDisp);
	TextDrawDestroy(DateDisp);
	KillTimer(ostimer);
	KillTimer(infotimer);
	return true;
}
public OnPlayerRequestSpawn(playerid)
{
	if(!GetPVarInt(playerid, "Logged")) return false;
	if(GetPlayerSkin(playerid) == 111 && PlayerInfo[playerid][pVip] == 0) return false;
	if(GetPlayerSkin(playerid) == 113 && PlayerInfo[playerid][pVip] == 0) return false;
	if(GetPlayerSkin(playerid) == 294 && PlayerInfo[playerid][pVip] == 0) return false;
	if(GetPlayerSkin(playerid) == 90 && PlayerInfo[playerid][pVip] == 0) return false;
	if(PlayerTeam[playerid] == 1 && GetTeamOnline(1)-GetTeamOnline(2) > ServerSettings[ssAutoteambalance]) return false;
	if(PlayerTeam[playerid] == 2 && GetTeamOnline(2)-GetTeamOnline(1) > ServerSettings[ssAutoteambalance]) return false;
	if(PlayerTeam[playerid] == 3)
	{
	    ForceClassSelection(playerid);
	    return false;
 	}
	Vubor[playerid] = 0;
	Skinah[playerid] = GetPlayerSkin(playerid);
	return true;
}
public OnPlayerRequestClass(playerid, classid)
{
	if(classid >= 0 && classid < 4)
	{
		PlayerTeam[playerid] = 1;
		GameTextForPlayer(playerid, "~y~> ~r~Terrorist ~y~<", 3500,6);
		if(GetTeamOnline(1)-GetTeamOnline(2) > ServerSettings[ssAutoteambalance])
		{
			SendClientMessage(playerid,COLOR_WHITE,"{ff0000} Ошибка {ffffff}> Терроисты имеют численный перевес! Выберите команду спецназа!");
			ForceClassSelection(playerid);
		}
	}
	else if(classid >= 4 && classid < 8)
	{
		PlayerTeam[playerid] = 2;
		GameTextForPlayer(playerid, "~y~> ~b~Counter-Terrorist ~y~<", 3500, 6);
		if(GetTeamOnline(2)-GetTeamOnline(1) > ServerSettings[ssAutoteambalance])
		{
			SendClientMessage(playerid,COLOR_WHITE,"{ff0000} Ошибка {ffffff}> Спецназ имеет численный перевес! Выбрите команду террористов!");
			ForceClassSelection(playerid);
		}
	}
	else if(classid >= 8 && classid < 12)
	{
		if(PlayerInfo[playerid][pVip] == 0)
		{
			GameTextForPlayer(playerid, "~r~> ~y~Vip ~r~<", 3500, 6);
			SendClientMessage(playerid,COLOR_WHITE,"{ff0000} Ошибка {ffffff}> Данный персонаж доступен только VIP игрокам!");
			ForceClassSelection(playerid);
		}
		else 
		{
			GameTextForPlayer(playerid, "~r~> ~y~Vip ~r~<", 3500, 6);
			ShowPlayerDialog(playerid,3,0,"Выбор команды","Выбери команду, за которую будешь играть:\n\nT - Террористы\nCT - Спецназ","T","CT");
		}
	}
	SetPlayerVirtualWorld(playerid, 1);
	SetPlayerPos(playerid, 211.5, 1811.6, 21.86);
	SetPlayerFacingAngle(playerid, 180);
	SetPlayerColor(playerid, 0xFFFFFF00);
	SetPlayerCameraPos(playerid, 211.1, 1808.6, 22.0);
	SetPlayerCameraLookAt(playerid, 211.5, 1811.6, 21.86);
	if(Vubor[playerid] == 0)
	{
		SetSpawnInfo(playerid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) ;
		SpawnPlayer(playerid);
		return true;
	}
	return true;
}
public OnPlayerDisconnect(playerid,reason)
{
	TextDrawDestroy(HealAmountTD[playerid]);
	TextDrawDestroy(RDTimeTD[playerid]);
	TextDrawDestroy(level[playerid]);
	TextDrawDestroy(exp[playerid]);
	TextDrawDestroy(HealthTD_G[playerid]);
	TextDrawDestroy(HealthTD_R[playerid]);
	TextDrawDestroy(LevelUpTD[TextLUTD][playerid]);
	Delete3DTextLabel(PlayerInformer[playerid]);
	Delete3DTextLabel(PlayerStatus[playerid]);
	if(GetPVarInt(playerid,"Logged") == 0) return 1;
	UpdateScore();
	new string[400], playerip[32],currtimestamp;
	new year,month,day,hour,minute;
	getdate(year,month,day);
	gettime(hour,minute);
	currtimestamp = date_to_timestamp(year,month,day,hour,minute);
	GetPlayerIp(playerid,playerip,sizeof(playerip));
	mysql_format(connectionHandle, string,"UPDATE `accounts` SET `LastConnection` = '%d' WHERE `Name` = '%s'",currtimestamp,GetName(playerid));
	mysql_query(string, -1, 0, connectionHandle);
	mysql_format(connectionHandle, string, "INSERT INTO `connectlog` (`PlayerName`, `PlayerID`, `ConnectType`, `PlayerALevel`,`PlayerIP`,`Time`) VALUES ('%s', '%d', '%d', '%d', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],reason,PlayerInfo[playerid][pAdmin],playerip,currtimestamp);
	mysql_query(string, -1, 0, connectionHandle);
	if(GameStarted == true)
	{
		PlayerInfo[playerid][pLeaves]++;
		PlayerInfo[playerid][pRating]-=5;
		PlayerInfo[playerid][pRankProgress]-=200;
	}
	//PlayerInfo[playerid][pLGlevel] = GunLevel[playerid];
	//PlayerInfo[playerid][pLGexp] = KillScore[playerid];
	if(reason != 2)
	{
	    PlayerInfo[playerid][pLGID] = GameID;
		mysql_format(connectionHandle, string,"UPDATE `accounts` SET `LGInfo` = '%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d' WHERE `Name` = '%s'",currtimestamp,GunLevel[playerid],KillScore[playerid],Assists[playerid],KillsInGame[playerid],DeathsInGame[playerid],PlayerShots[playerid],PlayerGoodShots[playerid],HealTimes[playerid],DamageGiven[playerid],DamageTaken[playerid],BestKillSeries[playerid],GetName(playerid));
		mysql_query(string, -1, 0, connectionHandle);
	}
	SavePlayer(playerid);
//	GetPlayerName(playerid, PlayerName, sizeof(PlayerName));
	switch(reason)
	{
		case 0: format(string,sizeof(string),"{B7FF00}%s {00FFEE}покинул сервер (Потеря связи)",GetName(playerid));
		case 1: format(string,sizeof(string),"{B7FF00}%s {00FFEE}покинул сервер (Выход)",GetName(playerid));
		case 2: format(string,sizeof(string),"{B7FF00}%s {00FFEE}покинул сервер (Кик/Бан)",GetName(playerid));
	}
	SendClientMessageToAll(-1,string);
	//log("Logged",string);
	if(LeaderID == playerid)
	{
		LeaderID = 999;
		BestScore = 0;
		foreach(Player,i)
		{
			if(BestScore < GunLevel[i])
			{
				BestScore = GunLevel[i];
				LeaderID = i;
			}
		}
		TextDrawSetString(leader,"Game Leader: None");
		TextDrawHideForAll(leaderTD);
		if(LeaderID != 999)
		{
			format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderID),GunLevel[LeaderID]+1);
			TextDrawSetString(leader,string);
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {00ff00}игры{ffffff}!",GetName(LeaderID));
			SendClientMessageToAll(COLOR_WHITE, string);
			TextDrawShowForPlayer(LeaderID,leaderTD);
			TextDrawHideForPlayer(LeaderID,leader);
		}
	}
	if(LeaderTID == playerid)
	{
		LeaderTID = 999;
		BestScoreT = 0;
		foreach(Player,i)
		{
			if(BestScoreT < GunLevel[i] && PlayerTeam[i] == 1)
			{
				BestScoreT = GunLevel[i];
				LeaderTID = i;
			}
		}
		TextDrawHideForAll(leaderTeamT);
		if(LeaderTID != 999)
		{
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {ff0000}террористов{ffffff}!",GetName(LeaderTID));
			SendClientMessageToAll(COLOR_WHITE,string);
			TextDrawShowForPlayer(LeaderTID,leaderTeamT);
			TextDrawHideForPlayer(LeaderTID,leaderT);
			format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderTID), GunLevel[LeaderTID]+1);
			TextDrawSetString(leaderT,string);
		}
	}
	if(LeaderCTID == playerid)
	{
		LeaderCTID = 999;
		BestScoreCT = 0;
		foreach(Player,i)
		{
			if(BestScoreCT < GunLevel[i] && PlayerTeam[i] == 2)
			{
				BestScoreCT = GunLevel[i];
				LeaderCTID = i;
			}
		}
		TextDrawHideForAll(leaderTeamCT);
		if(LeaderCTID != 999)
		{
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {0000ff}спецназа{ffffff}!",GetName(LeaderCTID));
			SendClientMessageToAll(COLOR_WHITE,string);
			TextDrawShowForPlayer(LeaderCTID,leaderTeamCT);
			TextDrawHideForPlayer(LeaderCTID,leaderCT);
			format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderCTID), GunLevel[LeaderCTID]+1);
			TextDrawSetString(leaderCT,string);
		}
	}
	PlayerTeam[playerid] = 0;
	foreach(Player,i)
	{
		if(PlayerSpectating[playerid] == i && PlayerTeam[i] == 3)
		{
			ClearPlayerVars(i);
			PlayerTeam[i] = 3;
			ForceClassSelection(i);
			TogglePlayerSpectating(i,0);
		}
	}
	return true;
}
stock TpPlayer(playerid, Float:x, Float:y, Float:z)
{
	SK[playerid] = 5;
	SetPlayerHealth(playerid,100);
	SendClientMessage(playerid,COL_GREEN,"Подождите! Через 5 секунд вы будете возвращены в игру!");
	SetPlayerPos(playerid, Float:x, Float:y, Float:z);
	PlayerSpawned[playerid] = false;
	if(PlayerSettings[playerid][psSInterface] == false)
	{
		TextDrawShowForPlayer(playerid,RDTD[0]);
		TextDrawShowForPlayer(playerid,RDTD[1]);
		TextDrawShowForPlayer(playerid,RDTD[PlayerSettings[playerid][psInterfaceColor]+2]);
		TextDrawSetString(RDTimeTD[playerid],"5");
		TextDrawShowForPlayer(playerid,RDTimeTD[playerid]);
	}
	TextDrawSetString(HPTD[playerid][MonitoringHPTD],"100 HP");
	return true;
}
public OnPlayerEnterCheckpoint(playerid)
{
	if(LDIOn[playerid] == true && PlayerSpawned[playerid] == true)
	{
	    DeletePlayer3DTextLabel(playerid,LDI3DText[playerid]);
	    DisablePlayerCheckpoint(playerid);
	}
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	new string[144];
	new tmpassist = 999, Float:maxdamage;
	new Float:x, Float:y, Float:z;
	new Float:camposx, Float:camposy, Float:camposz;
	new Float:camvecx, Float:camvecy, Float:camvecz;
    GetPlayerPos(playerid,x,y,z);
    GetPlayerCameraPos(playerid,camposx,camposy,camposz);
    GetPlayerCameraFrontVector(playerid,camvecx,camvecy,camvecz);
    if(ServerSettings[ssAssists] > 0)
    {
		foreach(Player,i)
		{
			if(Damage[playerid][i][gTaken] > maxdamage && i != killerid && i != playerid && Damage[playerid][i][gTaken] > 50.0)
			{
			tmpassist = i;
			maxdamage = Damage[playerid][i][gTaken];
			}
		}
		if(tmpassist != 999)
		{
			Assists[tmpassist]++;
			if(Assists[tmpassist] >= ServerSettings[ssAssists])
			{
				Assists[tmpassist] -= ServerSettings[ssAssists];
				if(KillScore[tmpassist] < ServerSettings[ssExpNeed]-1)
				{
					KillScore[tmpassist]++;
				}
				else
				{
					KillScore[tmpassist]-=ServerSettings[ssAssists]-1;
					LevelUp(tmpassist);
				}
			}
			UpdateExpTD(tmpassist);
			GameTextForPlayer(tmpassist,"~g~+1 assist",3000,5);
			format(string,sizeof(string),"За помощь в убийстве {ffff99}%s {ffffff}Вы получаете {00ff00}+1 assist",GetName(playerid));
			SendClientMessage(tmpassist,COLOR_WHITE,string);
			if(killerid != INVALID_PLAYER_ID) format(string,sizeof(string),"> {ffff99}%s {ffffff}помог {ffff99}%s {ffffff}убить {ffff99}%s",GetName(tmpassist), GetName(killerid),GetName(playerid));
			else format(string,sizeof(string),"> {ffff99}%s {ffffff}помог {ffff99}%s {ffffff}совершить самоубийство",GetName(tmpassist),GetName(playerid));
			PlayerInfo[tmpassist][pRankProgress] += 20;
			SendClientMessageToAll(COLOR_WHITE,string);
		}
	}
	if(PlayerSettings[playerid][psDeathStatOff] == false)
	{
		SendClientMessage(playerid,COL_RED,"> {ffffff}Урон, нанесенный другим игрокам:");
		foreach(Player,i)
		{
		    if(Damage[i][playerid][gTaken] > 0.0)
		    {
		        format(string,sizeof(string),"+ {ffffff}%s - {ffff99}%.0f {ffffff}HP - {ffff99}%d {ffffff}попаданий",GetName(i),Damage[i][playerid][gTaken],Damage[i][playerid][gShots]);
		        SendClientMessage(playerid,COL_RED,string);
		    }
		}
		SendClientMessage(playerid,COL_RED,"----------");
		SendClientMessage(playerid,COL_RED,"> {ffffff}Урон, полученный от других игроков:");
		foreach(Player,i)
		{
		    if(Damage[playerid][i][gTaken] > 0.0)
		    {
		        format(string,sizeof(string),"+ {ffffff}%s - {ffff99}%.0f {ffffff}HP - {ffff99}%d {ffffff}попаданий",GetName(i),Damage[playerid][i][gTaken],Damage[playerid][i][gShots]);
		        SendClientMessage(playerid,COL_RED,string);
		        Damage[playerid][i][gTaken] = 0.0;
		        Damage[playerid][i][gShots] = 0;
		    }
		}
		SendClientMessage(playerid,COL_RED,"----------");
		SendClientMessage(playerid,COL_RED,"> {ffffff}Убитые игроки:");
		foreach(Player,i)
		{
		    if(Damage[playerid][i][gKills] > 0)
		    {
		        if(Damage[playerid][i][gKills] == 1) format(string,sizeof(string),"+ {ffffff}%s",GetName(i));
		        else format(string,sizeof(string),"+ {ffffff}%s ({ffff99}x%d{ffffff})",GetName(i),Damage[playerid][i][gKills]);
		        SendClientMessage(playerid,COL_RED,string);
		        Damage[playerid][i][gKills] = 0;
		    }
		}
		SendClientMessage(playerid,COL_RED,"----------");
	}
	else
	{
		foreach(Player,i)
		{
	        Damage[playerid][i][gTaken] = 0.0;
	        Damage[playerid][i][gShots] = 0;
	        Damage[playerid][i][gKills] = 0;
		}
	}
	SendDeathMessage(killerid,playerid,reason);
	PlayerSpawned[playerid] = false;
	switch(PlayerTeam[playerid])
	{
		case 1: SetPlayerColor(playerid,COL_RED_DEAD);
		case 2: SetPlayerColor(playerid,COLOR_BLUE_DEAD);
	}
 	GetPlayerPos(playerid,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ]);
	if(LDIOn[playerid] == true) DeletePlayer3DTextLabel(playerid,LDI3DText[playerid]);
	InformerUpdate[playerid] = 0;
	TextDrawSetString(HPTD[playerid][MonitoringHPTD],"0 HP");
	TextDrawHideForPlayer(playerid,HPTD[playerid][MinusHPTD]);
	TextDrawHideForPlayer(playerid,HPTD[playerid][PlusHPTD]);
	HideHPTD[playerid][HideMinusHPTD] = 0;
	HideHPTD[playerid][HidePlusHPTD] = 0;
	if(killerid == INVALID_PLAYER_ID)
	{
		if(reason == 54 || reason == 53)
		{
 			foreach(Player,i)
			{
			    if(PlayerSpectating[i] == playerid && PlayerTeam[i] == 3)
			    {
					SetPlayerCameraPos(i,x,y,z+5);
					SetPlayerCameraLookAt(i,x,y,z);
			    }
			}
			//InterpolateCameraPos(playerid,camposx,camposy,camposz,x,y,z+5,3000,CAMERA_CUT);
			InterpolateCameraLookAt(playerid, camvecx, camvecy, camvecz, x, y, z, 3000, CAMERA_CUT);
			format(string,sizeof(string),"> {ffff99}%s {ffffff}совершил {ff0000}самоубийство",GetName(playerid));
			SendClientMessageToAll(COLOR_WHITE, string);
			GameTextForPlayer(playerid,"~r~You killed yourself",3000,5);
			PlayerInfo[playerid][pRating]-=2;
			PlayerInfo[playerid][pRankProgress]-=80;
			DeathsInGame[playerid]++;
			PlayerInfo[playerid][pDeaths]++;
			if(PlayerTeam[playerid] == 1) format(string,sizeof(string), "{FF0000}%s - Террорист\n\n{FFFFFF}Погиб, совершив {ff0000}самоубийство",GetName(playerid));
			else if(PlayerTeam[playerid] == 2) format(string,sizeof(string), "{0000FF}%s - Спецназовец\n\n{FFFFFF}Погиб, совершив {ff0000}самоубийство",GetName(playerid));
			Update3DTextLabelText(PlayerStatus[playerid],COLOR_WHITE,string);
			Update3DTextLabelText(PlayerInformer[playerid],COLOR_WHITE,"");
			//SendDeathMessage(killerid,playerid,reason);
			return true;
		}
		return 1;
	}
	//SendDeathMessage(killerid,playerid,reason);
	new Float:healths;
	GetPlayerHealth(killerid,healths);
/*	if(reason != PlayerWeapon[GunLevel[killerid]][0] && reason != 4 && reason != 1 && PlayerTeam[killerid] != 3 && PlayerTeam[killerid] != 0 && reason != 51)
	{
		format(string, sizeof(string), "[Античит] %s (ID: %d) , возможно, использует чит на оружие (LvL: %d | Оружие: %s)",GetName(killerid),killerid,GunLevel[killerid]+1,GetGunName(GetPlayerWeapon(killerid)));
		SendAdminMessage(COL_RED,string);
		GunCheatWarns[killerid]++;
		if(GunCheatWarns[killerid] >= 3)
		{
		    SendClientMessage(killerid,COL_RED,"Вы были кикнуты за использованние чита на оружие!");
		    format(string, sizeof(string), "[Античит] %s (ID: %d) был кикнут по подозрению в читерстве!",GetName(killerid),killerid);
   			SendClientMessageToAll(COL_RED,string);
   			Kick(killerid);
		}
	}
 */
	new updater[400];
	if(PlayerTeam[playerid] == 1) format(updater,sizeof(updater), "{FF0000}%s - Террорист\n\n{FFFFFF}Убит игроком {FFFF99}%s {FFFFFF}из оружия {FFFF99}%s {ffffff}с {ffff99}%.0f {ffffff}метров",GetName(playerid),  GetName(killerid),GetGunName(reason),GetDistanceBetweenPlayers(playerid, killerid));
	else if(PlayerTeam[playerid] == 2) format(updater,sizeof(updater), "{0000FF}%s - Спецназовец\n\n{FFFFFF}Убит игроком {FFFF99}%s {FFFFFF}из оружия {FFFF99}%s {ffffff}с {ffff99}%.0f {ffffff}метров",GetName(playerid), GetName(killerid),GetGunName(reason), GetDistanceBetweenPlayers(playerid,killerid));
	Update3DTextLabelText(PlayerInformer[playerid],COLOR_WHITE,"");
	Update3DTextLabelText(PlayerStatus[playerid],COLOR_WHITE,updater);
	Damage[killerid][playerid][gKills]++;
 	new Float:kx, Float:ky, Float:kz;
    GetPlayerPos(killerid,kx,ky,kz);
    InterpolateCameraPos(playerid,camposx,camposy,camposz,x,y,z+3,3000,CAMERA_CUT);
    InterpolateCameraLookAt(playerid,camvecx,camvecy,camvecz,kx,ky,kz,3000,CAMERA_CUT);
	foreach(Player,i)
	{
	    if(PlayerSpectating[i] == playerid && PlayerTeam[i] == 3)
	    {
			SetPlayerCameraPos(i,x,y,z);
			SetPlayerCameraLookAt(i,kx,ky,kz);
	    }
	}
	if(PlayerTeam[killerid] == PlayerTeam[playerid])
	{
		if(GunLevel[killerid] != 0)
		{
			GunLevel[killerid]--;
		}
		UpdateLevelTD(killerid);
		UpdateExpTD(killerid);
		KillScore[killerid] = 0;
		Assists[killerid] = 0;
		PlayerInfo[killerid][pRating]-=3;
		PlayerInfo[killerid][pRankProgress]-=100;
		ReloadWeapons(killerid);
		format(string, sizeof(string),"> {FFFF99}%s {FFFFFF}убил товарища по команде и был понижен до {FFFF99}%d {FFFFFF}уровня ({FFFF99}%s{FFFFFF})",GetName(killerid), GunLevel[killerid]+1,GetGunName(LevelWeapons[GunLevel[killerid]]));
		SendClientMessageToAll(COLOR_WHITE, string);
	 	GameTextForPlayer(killerid, "~r~TEAMKILL", 1500, 5);
	 	GameTextForPlayer(playerid, "~r~KILLED BY TEAMMATE", 1500, 5);
		switch(PlayerTeam[playerid])
		{
			case 1: format(string,sizeof(string), "{FF0000}%s - Террорист{ffffff}\n\n{ff0000}Убил товарища по команде",GetName(killerid));
			case 2: format(string,sizeof(string), "{0000FF}%s - Спецназовец{ffffff}\n\n{ff0000}Убил товарища по команде",GetName(killerid));
		}
		Update3DTextLabelText(PlayerStatus[killerid],COLOR_WHITE,string);
		Update3DTextLabelText(PlayerInformer[killerid],COLOR_WHITE,"");
		InformerUpdate[killerid] = 3;
		return true;
	}
	if(TeamKills[1] == 0 && TeamKills[2] == 0)
	{
		format(string,sizeof(string),"> {ff0000}%s {ffffff}пролил первую кровь, убив {ff0000}%s",GetName(killerid),GetName(playerid));
		SendClientMessageToAll(COLOR_WHITE, string);
		GameTextForAll("~r~FIRSTBLOOD!",3000,6);
		PlayerInfo[killerid][pRating]++;
		PlayerInfo[killerid][pRankProgress]++;
	}
	TeamKills[PlayerTeam[killerid]]++;
	foreach(Player,i)
	{
	    if(PlayerSettings[playerid][psSInterface] == false)
		{
			TextDrawShowForPlayer(i,TKPlus1[PlayerTeam[killerid]-1]);
		}
	}
	TKPlus1_Time[PlayerTeam[killerid]-1] = 3;
    UpdateScore();
	format(string, sizeof(string),"Вы убили {00ff00}%s {ffffff}с {00ff00}%s {ffffff}на расстоянии {00ff00}%.0f {ffffff}метров",GetName(playerid),GetGunName(reason),GetDistanceBetweenPlayers(playerid,killerid));
	SendClientMessage(killerid,COLOR_WHITE,string);
	PlayerInfo[playerid][pDeaths]++;
	PlayerInfo[killerid][pKills]++;
	KillSeries[killerid]++;
	KillsInGame[killerid]++;
	DeathsInGame[playerid]++;
	PlayerInfo[killerid][pRating]+=2;
	PlayerInfo[playerid][pRating]--;
	PlayerInfo[killerid][pRankProgress]+=30;
	PlayerInfo[killerid][pRankProgress]+=KillSeries[killerid];
	PlayerInfo[killerid][pRankProgress]-=PlayerInfo[killerid][pRank];
	PlayerInfo[killerid][pRankProgress]+=PlayerInfo[playerid][pRank];
	PlayerInfo[playerid][pRankProgress]-=30;
	PlayerInfo[playerid][pRankProgress]+=KillSeries[playerid];
	PlayerInfo[playerid][pRankProgress]+=PlayerInfo[killerid][pRank];
	PlayerInfo[playerid][pRankProgress]-=PlayerInfo[playerid][pRank];
	if(KillSeries[killerid] > BestKillSeries[killerid])
	{
		BestKillSeries[killerid] = KillSeries[killerid];
	}
	if(KillSeries[killerid] > PlayerInfo[killerid][pBestSeries])
	{
		PlayerInfo[killerid][pBestSeries] = KillSeries[killerid];
	}
	if(KillSeries[killerid] >= 3)
	{
		format(string,sizeof(string),"{ff0000}%s {ffffff}совершил серию из {ff0000}%d {ffffff}убийств!",GetName(killerid),KillSeries[killerid]);
		SendClientMessageToAll(COLOR_WHITE,string);
		if(KillSeries[killerid] % 5 == 0)
		{
			format(string,sizeof(string),"За серию из {ff0000}%d {ffffff}убийств Вы получаете +1 Exp!",KillSeries[killerid]);
			SendClientMessage(killerid,COLOR_WHITE,string);
			KillScore[killerid]++;
		}
	}
	if(KillSeries[killerid] == 1)
	{
		switch(PlayerTeam[playerid])
		{
			case 1: format(string,sizeof(string), "{FF0000}%s - Террорист{ffffff}\n\nУбил {ffff99}%s",GetName(killerid),GetName(playerid));
			case 2: format(string,sizeof(string), "{0000FF}%s - Спецназовец{ffffff}\n\nУбил {ffff99}%s",GetName(killerid),GetName(playerid));
		}
		Update3DTextLabelText(PlayerStatus[killerid],COLOR_WHITE,string);
		Update3DTextLabelText(PlayerInformer[killerid],COLOR_WHITE,"");
		InformerUpdate[killerid] = 3;
	}
	else
	{
		switch(PlayerTeam[playerid])
		{
			case 1: format(string,sizeof(string), "{FF0000}%s - Террорист{ffffff}\n\nУбил {ffff99}%s\n(COMBO x%d)",GetName(killerid),GetName(playerid),KillSeries[killerid]);
			case 2: format(string,sizeof(string), "{0000FF}%s - Спецназовец{ffffff}\n\nУбил {ffff99}%s\n(COMBO x%d)",GetName(killerid),GetName(playerid),KillSeries[killerid]);
		}
		Update3DTextLabelText(PlayerStatus[killerid],COLOR_WHITE,string);
		Update3DTextLabelText(PlayerInformer[killerid],COLOR_WHITE,"");
		InformerUpdate[killerid] = 3;
    }
	if(reason == 0)
	{
		if(GunLevel[playerid] != 0)
		{ 
			GunLevel[playerid]--;
		}
		UpdateLevelTD(playerid);
		UpdateExpTD(playerid);
		KillScore[playerid] = 0;
		Assists[playerid] = 0;
		LevelUp(killerid);
		Healings[killerid]++;
		PlayerInfo[killerid][pRating]+=3;
		GameTextForPlayer(playerid, "~r~KILLED WITHOUT ANY WEAPON", 1500, 5);
		if(healths <= 70)
		{
			SetPlayerHealth(killerid, healths+30);
			if(PlayerSettings[killerid][psMonHPOff] == false)
			{
				TextDrawSetString(HPTD[killerid][PlusHPTD],"+30");
				TextDrawShowForPlayer(killerid,HPTD[killerid][PlusHPTD]);
				HideHPTD[killerid][HidePlusHPTD] = 3;
				format(string,sizeof(string),"%d HP",floatround(healths+30,floatround_ceil));
				TextDrawSetString(HPTD[killerid][MonitoringHPTD],string);
			}
		}
		format(string, sizeof(string),"> {FFFF99}%s {FFFFFF}убил голыми руками {FFFF99}%s {FFFFFF}и повысился до {FFFF99}%d уровня {FFFFFF}({FFFF99}%s{FFFFFF})", GetName(killerid), GetName(playerid), GunLevel[killerid]+1, GetGunName(LevelWeapons[GunLevel[killerid]]));
		SendClientMessageToAll(COLOR_WHITE,string);
		SendClientMessage(killerid,COL_YELLOW,"Вы убили противника голыми руками! Вы получаете: +1 lvl, +30 hp, +1 аптечка!");
		UpdateLevelTD(killerid);
		UpdateInformer(killerid);
		PlayerInfo[killerid][pRating]++;
		return 1;
	}
	else if(healths <= 85)
	{
		SetPlayerHealth(killerid,healths + 15);
		if(PlayerSettings[killerid][psMonHPOff] == false)
		{
			TextDrawSetString(HPTD[killerid][PlusHPTD],"+15");
			TextDrawShowForPlayer(killerid,HPTD[killerid][PlusHPTD]);
			HideHPTD[killerid][HidePlusHPTD] = 3;
			format(string,sizeof(string),"%d HP",floatround(healths+15,floatround_ceil));
			TextDrawSetString(HPTD[killerid][MonitoringHPTD],string);
		}
	}
	if(KillScore[killerid] < ServerSettings[ssExpNeed]-1)
	{
		KillScore[killerid]++;
		format(string, sizeof(string), "~g~%d/%d", KillScore[killerid],ServerSettings[ssExpNeed]);
		GameTextForPlayer(killerid, string, 1500, 5);
		PlayerPlaySound(killerid, 1056, 0.0, 0.0, 0.0);
		UpdateExpTD(killerid);
	}
	else
	{
		KillScore[killerid]-=ServerSettings[ssExpNeed]-1;
		Assists[killerid] = 0;
		LevelUp(killerid);
		UpdateExpTD(killerid);
	}
	format(string,sizeof(string),"~r~KILLED BY %s",GetName(killerid));
	GameTextForPlayer(playerid, string, 1500, 5);
	UpdateInformer(killerid);
    GetPlayerHealth(playerid,healths);
	format(string, sizeof(string),"{ff0000}%s {ffffff}({ff0000}%.0f {ffffff}HP) убил вас с {ff0000}%s {ffffff}на расстоянии {ff0000}%.0f {ffffff}метров",GetName(killerid),healths,  GetGunName(reason),GetDistanceBetweenPlayers(playerid,killerid));
	SendClientMessage(playerid,COLOR_WHITE,string);
	//SetPlayerChatBubble(playerid,"",COLOR_WHITE,30.0,3000);
	return true;
}
stock LevelUp(playerid)
{
	new string[144];
	GunLevel[playerid]++;
	LevelUpDelay[playerid] = true;
	PlayerPlaySound(playerid,1057,0,0,0);
	SetPlayerScore(playerid, GunLevel[playerid]+1);
	if(GunLevel[playerid] >= ServerSettings[ssLevels])
	{
		OnPlayerWinGame(playerid);
		return true;
	}
	ReloadWeapons(playerid);
	if(PlayerSettings[playerid][psSInterface] == false)
	{
	    if(LevelUpTD[HideLUTD][playerid] > 0) TextDrawHideForPlayer(playerid,LevelUpTD[ModelLUTD][GetGunTD(LevelWeapons[GunLevel[playerid]-1])]);
	    LevelUpTD[HideLUTD][playerid] = 3;
   		format(string,sizeof(string),"%s~n~%d level",GetGunName(LevelWeapons[GunLevel[playerid]]),GunLevel[playerid]+1);
   		TextDrawSetString(LevelUpTD[TextLUTD][playerid],string);
 		TextDrawShowForPlayer(playerid,LevelUpTD[ModelLUTD][GetGunTD(LevelWeapons[GunLevel[playerid]])]);
	    TextDrawShowForPlayer(playerid,LevelUpTD[TextLUTD][playerid]);
	    TextDrawShowForPlayer(playerid,LevelUpTD[TopicLUTD]);
	    TextDrawShowForPlayer(playerid,LevelUpTD[BackgroundLUTD][PlayerSettings[playerid][psInterfaceColor]]);
	    
	}
	else
	{
		format(string,sizeof(string),"~g~Level Up!~n~%d level - %s",GunLevel[playerid]+1,GetGunName(LevelWeapons[GunLevel[playerid]]));
		GameTextForPlayer(playerid, string, 3000, 5);
	}
	if(PlayerTeam[playerid] == 1 && BestScoreT < GunLevel[playerid])
	{
		if(LeaderTID != playerid)
		{
		    TextDrawShowForPlayer(LeaderTID,leaderT);
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер команды {ff0000}террористов{ffffff}!",GetName(playerid));
			SendClientMessageToAll(COLOR_WHITE, string);
		}
		LeaderTID = playerid;
		BestScoreT = GunLevel[playerid];
		TextDrawHideForAll(leaderTeamT);
		TextDrawShowForPlayer(playerid,leaderTeamT);
		TextDrawHideForPlayer(playerid,leaderT);
		format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(playerid), GunLevel[playerid]+1);
		TextDrawSetString(leaderT,string);
	}
	if(PlayerTeam[playerid] == 2 && BestScoreCT < GunLevel[playerid])
	{
		if(LeaderCTID != playerid)
		{
		    TextDrawShowForPlayer(LeaderTID,leaderT);
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер команды {0000ff}спецназа{ffffff}!",GetName(playerid));
			SendClientMessageToAll(COLOR_WHITE, string);
		}
		LeaderCTID = playerid;
		BestScoreCT = GunLevel[playerid];
		TextDrawHideForAll(leaderTeamCT);
		TextDrawShowForPlayer(playerid,leaderTeamCT);
		TextDrawHideForPlayer(playerid,leaderCT);
		format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(playerid), GunLevel[playerid]+1);
		TextDrawSetString(leaderCT,string);
	}
	if(BestScore < GunLevel[playerid])
	{
		if(LeaderID != playerid)
		{
			format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {00ff00}игры{ffffff}!",GetName(playerid));
			SendClientMessageToAll(COLOR_WHITE, string);
			TextDrawShowForPlayer(LeaderID,leader);
			LeaderID = playerid;
		}
		BestScore = GunLevel[playerid];
		TextDrawHideForAll(leaderTD);
		TextDrawShowForPlayer(LeaderID,leaderTD);
		TextDrawHideForPlayer(LeaderID,leader);
		format(string,sizeof(string),"> {FFFF99}%s {FFFFFF}лидирует с {FFFF99}%d {FFFFFF}уровнем ({FFFF99}%s{FFFFFF})", GetName(playerid), GunLevel[playerid]+1, GetGunName(LevelWeapons[GunLevel[playerid]]));
		SendClientMessageToAll(COLOR_WHITE,string);
		format(string,sizeof(string),"Game Leader: %s (%d Level)", GetName(playerid), GunLevel[playerid]+1);
		TextDrawSetString(leader,string);
		UpdateLevelTD(playerid);
	}
	else
	{
		format(string,sizeof(string),"> {FFFF99}%s {FFFFFF}перешел на {FFFF99}%d {FFFFFF}уровень ({FFFF99}%s{FFFFFF})", GetName(playerid), GunLevel[playerid]+1, GetGunName(LevelWeapons[GunLevel[playerid]]));
		SendClientMessageToAll(COLOR_WHITE,string);
		UpdateLevelTD(playerid);
	}
	return true;
}
forward OnPlayerWinGame(winnerid);
public OnPlayerWinGame(winnerid)
{
	new allstring[2000];
	new string[180];
	new BestRatio;
	new BestRatioID;
	new BestKills;
	new BestKillerID;
	new BestDeaths;
	new BestDeathsID;
	new BestSeries;
	new BestSeriesID;
	new BestHeals;
	new BestHealsID;
	new Float:BestKD;
	new BestKDID;
	new RCtype = 0;
//	new NewPlayerRank;
	GameTextForPlayer(winnerid,"~g~You won The Game!",3000,6);
	PlayerInfo[winnerid][pRankProgress]+=250;
	foreach(Player,i)
	{
		if(GetPlayerShotQuallity(i) > BestRatio)
		{
			BestRatio = GetPlayerShotQuallity(i);
			BestRatioID = i;
		}
		if(KillsInGame[i] > BestKills)
		{
			BestKills = KillsInGame[i];
			BestKillerID = i;
		}
		if(DeathsInGame[i] > BestDeaths)
		{
			BestDeaths = DeathsInGame[i];
			BestDeathsID = i;
		}
		if(BestKillSeries[i] > BestSeries)
		{
			BestSeries = BestKillSeries[i];
			BestSeriesID = i;
		}
		if(HealTimes[i] > BestHeals)
		{
			BestHeals = HealTimes[i];
			BestHealsID = i;
		}
		if(float(KillsInGame[i]) / float(DeathsInGame[i]) > BestKD)
		{
		BestKD = float(KillsInGame[i]) / float(DeathsInGame[i]);
		BestKDID = i;
		}
	}
	SendClientMessageToAll(COLOR_WHITE,"\n");
	format(string,sizeof(string),"> {ffff99}%s {ffffff}достиг максимального уровня и победил!", GetName(winnerid));
	SendClientMessageToAll(COLOR_WHITE,string);
	foreach(Player,i)
	{
		if(IsPlayerConnected(i)) Vubor[i] = 1;
		TogglePlayerControllable(i, 0);
	}
	GameStarted = false;
	GameID = 0-random(9999);
	SetTimer("GoMap",10000,false);
	foreach(Player,i)
	{
		TogglePlayerControllable(i,0);
		PlayerInfo[i][pGames]++;
		PlayerInfo[i][pLevels] += GunLevel[i];
		PlayerInfo[i][pRating]+=10;
		if(PlayerTeam[i] == PlayerTeam[winnerid]) PlayerInfo[i][pRankProgress]+=250;
		RCtype = 0;
		if(PlayerInfo[i][pGames] == 3) OnPlayerRankChange(i, GetPlayerRank(i)), RCtype = 3;
		if(PlayerInfo[i][pGames] > 3)
		{
			if(PlayerInfo[i][pRankProgress] >= 1000 && PlayerInfo[i][pRank] < 25)
			{
		 		OnPlayerRankChange(i, PlayerInfo[i][pRank]+1);
		 		RCtype = 1;
			}
			if(PlayerInfo[i][pRankProgress] <= -1000 && PlayerInfo[i][pRank] > 1)
			{
		 		OnPlayerRankChange(i, PlayerInfo[i][pRank]-1);
		 		RCtype = 2;
			}
		}
		allstring = "";
		if(i == winnerid) format(allstring,sizeof(allstring),"Поздравляем! Вы победили в этой игре!\n\n\nВаша статистика в этой игре:\n\n");
		else format(allstring,sizeof(allstring),"%s победил в этой игре!\n\n\nВаша статистика в этой игре:\n\n",GetName(winnerid));
		format(string,sizeof(string),"* Убийств: %d\n* Смертей: %d\n* Коэффициент У/С: %.2f\n* Выстрелов: %d\n* Попаданий: %d\n* Меткость: %d%%\n",KillsInGame[i],DeathsInGame[i],float(KillsInGame[i]) / float(DeathsInGame[i]),PlayerShots[i],PlayerGoodShots[i],GetPlayerShotQuallity(i));
		strcat(allstring,string);
		format(string,sizeof(string),"* Лучшая серия убтйств: %d подряд\n* Аптечек использовано: %d\n\nОбщая статистика:\n\n",BestKillSeries[i],HealTimes[i]);
		strcat(allstring,string);
		format(string,sizeof(string),"* Всего выстрелов: %d\n* Всего попаданий: %d\n* Лучшая меткость - %s (%d%%)\n* Лучший коэффициент У/С - %s (%.2f)",AllShots,AllGoodShots,GetName(BestRatioID),BestRatio, GetName(BestKDID),BestKD);
		strcat(allstring,string);
		format(string,sizeof(string),"\n* Наибольшее число убийств - %s (%d убийств(а))\n* Наибольшее число смертей - %s (%d смертей)",GetName(BestKillerID),BestKills,GetName(BestDeathsID),BestDeaths);
		strcat(allstring,string);
		format(string,sizeof(string),"\n* Наибольшее число убийств подряд - %s (%d подряд)\n* Самый осторожный - %s (%d аптечек использовано)",GetName(BestSeriesID),BestSeries, GetName(BestHealsID),BestHeals);
		strcat(allstring,string);
		format(string,sizeof(string),"\n* Всего убийств - %d (T: %d | CT: %d)",TeamKills[1]+TeamKills[2],TeamKills[1],TeamKills[2]);
		strcat(allstring,string);
		switch(RCtype)
		{
		case 1: format(string,sizeof(string),"\n\n\nВас повысили в звании!\nВаше текущее звание: %s\nРейтинг ARR: %d очков", RankNames[PlayerInfo[i][pRank]], PlayerInfo[i][pRating]);
		case 2: format(string,sizeof(string),"\n\n\nВас понизили в звании!\nВаше текущее звание: %s\nРейтинг ARR: %d очков", RankNames[PlayerInfo[i][pRank]], PlayerInfo[i][pRating]);
		case 3: format(string,sizeof(string),"\n\n\nВаше звание определено!\nВаше текущее звание: %s\nРейтинг ARR: %d очков", RankNames[PlayerInfo[i][pRank]], PlayerInfo[i][pRating]);
		default: format(string,sizeof(string),"\n\n\nВаше текущее звание: %s\nРейтинг ARR: %d очков", RankNames[PlayerInfo[i][pRank]], PlayerInfo[i][pRating]);
		}
		strcat(allstring,string);
		ShowPlayerDialog(i,1337,DIALOG_STYLE_MSGBOX,"Гонка Вооружений",allstring,"Закрыть","");
	}
	SendClientMessageToAll(COLOR_WHITE,"Внимание! Через {ffff99}10 {ffffff}секунд начнется новая игра!");
	PlayerInfo[winnerid][pWins]++;
	PlayerInfo[winnerid][pRating]+=10;
	new year,month,day,hour,minute, timestamp, query[1024];
	getdate(year,month,day);
	gettime(hour,minute);
	timestamp = date_to_timestamp(year,month,day,hour,minute,0);
	mysql_format(connectionHandle, query, "INSERT INTO `games` (`Winner`, `KillsT`, `KillsCT`,`Date`,`Code`,`Map`, `Shots`, `GoodShots`, `Time`, `BestShotQuallityName`, `BestShotQuallity`, `BestKDName`, `BestKD`, `BestKillerName`, `BestKills`, `BestSeriesName`, `BestSeries`, `BestDeathsName`, `BestDeaths`, `BestHealingsName`, `BestHealings`) VALUES ('%s', '%d', '%d', '%d', '%d','%s', '%d', '%d', '%d', '%s', '%d', '%s','%f', '%s','%d', '%s','%d', '%s','%d', '%s', '%d')",
	 GetName(winnerid), TeamKills[1], TeamKills[2], timestamp,GameID,MapNames[Map],AllShots,AllGoodShots,GameMinutes*60 + GameSeconds, GetName(BestRatioID), BestRatio, GetName(BestKDID),BestKD, GetName(BestKillerID),BestKills, GetName(BestSeriesID),BestSeries, GetName(BestDeathsID),BestDeaths, GetName(BestHealsID),BestHeals);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}

// Отладочные команды
/*CMD:wingame(playerid,params[])
{
	OnPlayerWinGame(playerid);
	return 1;
}

CMD:levelup(playerid,params[])
{
	LevelUp(playerid);
	return 1;
}*/

forward GoMap();
public GoMap()
{
	new rand = random(20);
	Map = rand;
	UpdateMap(Map);
	ClearGameVars();
	GameStarted = true;
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			TogglePlayerControllable(i, 1);
			ForceClassSelection(i);
			SetPlayerHealth(i,0);
			TextDrawsHide(i);
		}
	}
}
public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	if(GetPVarInt(playerid,"Logged") == 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы еще не авторизовались!");
	new text[300],string[64];
    PlayerTarget[playerid] = clickedplayerid;
	format(string, sizeof(string), "Профиль игрока %s", GetName(clickedplayerid));
	if(Blocked[clickedplayerid][playerid] == true)
	{
	    ShowPlayerDialog(playerid,1337, DIALOG_STYLE_MSGBOX, string, "Данный игрок заблокировал Вас!\nИнформация недоступна!", "Закрыть","");
	    return 1;
	}
	if(GetPVarInt(clickedplayerid,"Logged") == 0)
	{
	    ShowPlayerDialog(playerid,1337, DIALOG_STYLE_MSGBOX, string, "Данный игрок еще не авторизовался!\nИнформация о нем недоступна!", "Закрыть","");
	    return 1;
	}
	if(PlayerTeam[clickedplayerid] == 1)
	{
		format(text, sizeof(text), "Команда: Террористы\nЗвание: %s\nРейтинг ARR: %d\n\nУровень: %d\nОружие: %s\nОчки: %d/2\n\nУбийств: %d\nСмертей: %d\nКоэффициент У/С: %.2f\n\nВыстрелов: %d\nПопаданий: %d\nМеткость: %d%%\n\nНанесено урона: %d\nПолучено урона: %d\n\nЛучшая серия убийств: %d\nАптечек использовано: %d", RankNames[PlayerInfo[clickedplayerid][pRank]],PlayerInfo[clickedplayerid][pRating],
		GunLevel[clickedplayerid]+1, GetGunName(LevelWeapons[GunLevel[clickedplayerid]]),KillScore[clickedplayerid], KillsInGame[clickedplayerid],DeathsInGame[clickedplayerid],float(KillsInGame[clickedplayerid]) / float(DeathsInGame[clickedplayerid]),
		PlayerShots[clickedplayerid],PlayerGoodShots[clickedplayerid],GetPlayerShotQuallity(clickedplayerid),DamageGiven[clickedplayerid],DamageTaken[clickedplayerid],BestKillSeries[clickedplayerid], HealTimes[clickedplayerid]);
        ShowPlayerDialog(playerid,7, DIALOG_STYLE_MSGBOX, string, text, "Наблюдать","Закрыть");
	}
	else if(PlayerTeam[clickedplayerid] == 2)
	{
		format(text, sizeof(text), "Команда: Спецназ\nЗвание: %s\nРейтинг ARR: %d\n\nУровень: %d\nОружие: %s\nОчки: %d/2\n\nУбийств: %d\nСмертей: %d\nКоэффициент У/С: %.2f\n\nВыстрелов: %d\nПопаданий: %d\nМеткость: %d%%\n\nНанесено урона: %d\nПолучено урона: %d\n\nЛучшая серия убийств: %d\nАптечек использовано: %d", RankNames[PlayerInfo[clickedplayerid][pRank]],PlayerInfo[clickedplayerid][pRating],
		GunLevel[clickedplayerid]+1, GetGunName(LevelWeapons[GunLevel[clickedplayerid]]),KillScore[clickedplayerid], KillsInGame[clickedplayerid],DeathsInGame[clickedplayerid],float(KillsInGame[clickedplayerid]) / float(DeathsInGame[clickedplayerid]),
		PlayerShots[clickedplayerid],PlayerGoodShots[clickedplayerid],GetPlayerShotQuallity(clickedplayerid),DamageGiven[clickedplayerid],DamageTaken[clickedplayerid],BestKillSeries[clickedplayerid], HealTimes[clickedplayerid]);
        ShowPlayerDialog(playerid,7, DIALOG_STYLE_MSGBOX, string, text, "Наблюдать","Закрыть");
	}
	else if(PlayerTeam[clickedplayerid] == 3)
	{
        format(text, sizeof(text), "Команда: Наблюдатели\nЗвание: %s\nРейтинг ARR: %d", RankNames[PlayerInfo[clickedplayerid][pRank]],PlayerInfo[clickedplayerid][pRating]);
        ShowPlayerDialog(playerid,1337, DIALOG_STYLE_MSGBOX, string, text, "Закрыть","");
	}
	return true;
}
public OnPlayerConnect(playerid)
{
	if(playerid >= 20)
	{
		Kick(playerid);
		return true;
	}
	ClearRelogPlayerVars(playerid);
	Vubor[playerid] = 1;
	TogglePlayerSpectating(playerid, 1);
	InterpolateCameraPos(playerid, 3149.595703, -1453.849975, 47.205917, 3616.294677, -1572.166625, 53.614048, 3000);
	InterpolateCameraLookAt(playerid, 3145.683593, -1456.275024, 45.252746, 3612.889648, -1569.440307, 51.170127, 3000);
 	GetPlayerName(playerid,PlayerInfo[playerid][pName],MAX_PLAYER_NAME);
	new ip[MAX_PLAYER_NAME];
	GetPlayerIp(playerid, ip, sizeof(ip));
 	new logstr[128];
	mysql_real_escape_string(GetName(playerid), GetName(playerid));
	format(logstr, sizeof(logstr),"SELECT `Name` FROM `accounts` WHERE `Name` = '%s'", GetName(playerid));
	mysql_function_query(connectionHandle, logstr, true, "OnPlayerRegCheck","d", playerid);
	RemoveBuildingForPlayer(playerid, 1231, 2932.5078, -1566.4688, 13.0313, 0.25);
	RemoveBuildingForPlayer(playerid, 621, 2916.6406, -1482.1563, 8.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1290, 2914.8906, -1474.4922, 15.6719, 0.25);
	RemoveBuildingForPlayer(playerid, 621, 2917.8203, -1468.8125, 7.3594, 0.25);
	RemoveBuildingForPlayer(playerid, 621, 2915.3750, -1464.3125, 8.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 2954.6094, -1461.8750, 12.9453, 0.25);
	PlayerInformer[playerid] = Create3DTextLabel("Loading...", GetPlayerColor(playerid), 0.00, 0.00, 10000.0, 10, -1, 1);
	Attach3DTextLabelToPlayer(PlayerInformer[playerid], playerid, 0.0, 0.0, 0.3);
	PlayerStatus[playerid] = Create3DTextLabel("", GetPlayerColor(playerid), 0.00, 0.00, 10000.0, 50, -1, 0);
	Attach3DTextLabelToPlayer(PlayerStatus[playerid], playerid, 0.0, 0.0, 0.3);
	ClearRelogPlayerVars(playerid);
	
	level[playerid] = TextDrawCreate(10.000000, 270.000000, "Level: 0/14 (None)");
	TextDrawBackgroundColor(level[playerid], 255);
	TextDrawFont(level[playerid], 1);
	TextDrawLetterSize(level[playerid], 0.340000, 1.800000);
	TextDrawColor(level[playerid], 16711935);
	TextDrawSetOutline(level[playerid], 0);
	TextDrawSetProportional(level[playerid], 1);
	TextDrawSetShadow(level[playerid], 1);
	
	exp[playerid] = TextDrawCreate(11.000000, 288.000000, "Exp: 0/2 (0 assist)");
	TextDrawBackgroundColor(exp[playerid], 255);
	TextDrawFont(exp[playerid], 1);
	TextDrawLetterSize(exp[playerid], 0.340000, 1.800000);
	TextDrawColor(exp[playerid], 16711935);
	TextDrawSetOutline(exp[playerid], 0);
	TextDrawSetProportional(exp[playerid], 1);
	TextDrawSetShadow(exp[playerid], 1);
	
	LevelUpTD[TextLUTD][playerid] = TextDrawCreate(583.809448, 343.999877, "Dual Pistols ~n~2 level");
	TextDrawLetterSize(LevelUpTD[TextLUTD][playerid], 0.210475, 1.135999);
	TextDrawAlignment(LevelUpTD[TextLUTD][playerid], 2);
	TextDrawColor(LevelUpTD[TextLUTD][playerid], -1);
	TextDrawSetShadow(LevelUpTD[TextLUTD][playerid], 0);
	TextDrawSetOutline(LevelUpTD[TextLUTD][playerid], 1);
	TextDrawBackgroundColor(LevelUpTD[TextLUTD][playerid], 51);
	TextDrawFont(LevelUpTD[TextLUTD][playerid], 1);
	TextDrawSetProportional(LevelUpTD[TextLUTD][playerid], 1);

/*	HealthTD_G[playerid] = TextDrawCreate(250.000000, 310.000000, "_");
	TextDrawBackgroundColor(HealthTD_G[playerid], 255);
	TextDrawFont(HealthTD_G[playerid], 1);
	TextDrawLetterSize(HealthTD_G[playerid], 0.190000, 0.799999);
	TextDrawColor(HealthTD_G[playerid], 15597823);
	TextDrawSetOutline(HealthTD_G[playerid], 0);
	TextDrawSetProportional(HealthTD_G[playerid], 1);
	TextDrawSetShadow(HealthTD_G[playerid], 1);
 	TextDrawHideForPlayer(playerid,HealthTD_G[playerid]);

 	HealthTD_R[playerid] = TextDrawCreate(250.000000, 329.000000, "_");
	TextDrawBackgroundColor(HealthTD_R[playerid], 255);
	TextDrawFont(HealthTD_R[playerid], 1);
	TextDrawLetterSize(HealthTD_R[playerid], 0.190000, 0.799999);
	TextDrawColor(HealthTD_R[playerid], -871300865);
	TextDrawSetOutline(HealthTD_R[playerid], 0);
	TextDrawSetProportional(HealthTD_R[playerid], 1);
	TextDrawSetShadow(HealthTD_R[playerid], 1);
 	TextDrawHideForPlayer(playerid,HealthTD_R[playerid]);*/
 	
	HealthTD_R[playerid] = TextDrawCreate(221.000000, 316.000000, "_");
	TextDrawAlignment(HealthTD_R[playerid], 2);
	TextDrawBackgroundColor(HealthTD_R[playerid], 255);
	TextDrawFont(HealthTD_R[playerid], 1);
	TextDrawLetterSize(HealthTD_R[playerid], 0.180000, 1.000000);
	TextDrawColor(HealthTD_R[playerid], -16776961);
	TextDrawSetOutline(HealthTD_R[playerid], 1);
	TextDrawSetProportional(HealthTD_R[playerid], 1);

	HealthTD_G[playerid] = TextDrawCreate(453.000000, 316.000000, "_");
	TextDrawAlignment(HealthTD_G[playerid], 2);
	TextDrawBackgroundColor(HealthTD_G[playerid], 255);
	TextDrawFont(HealthTD_G[playerid], 1);
	TextDrawLetterSize(HealthTD_G[playerid], 0.180000, 1.000000);
	TextDrawColor(HealthTD_G[playerid], 16711935);
	TextDrawSetOutline(HealthTD_G[playerid], 1);
	TextDrawSetProportional(HealthTD_G[playerid], 1);
 	
 	RDTimeTD[playerid] = TextDrawCreate(323.000000, 206.000000, "0");
	TextDrawAlignment(RDTimeTD[playerid], 2);
	TextDrawBackgroundColor(RDTimeTD[playerid], 255);
	TextDrawFont(RDTimeTD[playerid], 3);
	TextDrawLetterSize(RDTimeTD[playerid], 1.200000, 6.000000);
	TextDrawColor(RDTimeTD[playerid], -1);
	TextDrawSetOutline(RDTimeTD[playerid], 0);
	TextDrawSetProportional(RDTimeTD[playerid], 1);
	TextDrawSetShadow(RDTimeTD[playerid], 1);
 	
 	HealAmountTD[playerid] = TextDrawCreate(580.000000, 220.000000, "+0 HP");
	TextDrawAlignment(HealAmountTD[playerid], 2);
	TextDrawBackgroundColor(HealAmountTD[playerid], 255);
	TextDrawFont(HealAmountTD[playerid], 3);
	TextDrawLetterSize(HealAmountTD[playerid], 0.480000, 4.000000);
	TextDrawColor(HealAmountTD[playerid], 16711935);
	TextDrawSetOutline(HealAmountTD[playerid], 0);
	TextDrawSetProportional(HealAmountTD[playerid], 1);
	TextDrawSetShadow(HealAmountTD[playerid], 1);
	
	HPTD[playerid][MinusHPTD] = TextDrawCreate(558.000000, 67.000000, "-3");
	TextDrawAlignment(HPTD[playerid][MinusHPTD], 2);
	TextDrawBackgroundColor(HPTD[playerid][MinusHPTD], 255);
	TextDrawFont(HPTD[playerid][MinusHPTD], 1);
	TextDrawLetterSize(HPTD[playerid][MinusHPTD], 0.130000, 0.799999);
	TextDrawColor(HPTD[playerid][MinusHPTD], -16776961);
	TextDrawSetOutline(HPTD[playerid][MinusHPTD], 1);
	TextDrawSetProportional(HPTD[playerid][MinusHPTD], 1);
	
	HPTD[playerid][MonitoringHPTD] = TextDrawCreate(576.000000, 67.000000, "100 HP");
	TextDrawAlignment(HPTD[playerid][MonitoringHPTD], 2);
	TextDrawBackgroundColor(HPTD[playerid][MonitoringHPTD], 255);
	TextDrawFont(HPTD[playerid][MonitoringHPTD], 1);
	TextDrawLetterSize(HPTD[playerid][MonitoringHPTD], 0.120000, 0.800000);
	TextDrawColor(HPTD[playerid][MonitoringHPTD], -1);
	TextDrawSetOutline(HPTD[playerid][MonitoringHPTD], 1);
	TextDrawSetProportional(HPTD[playerid][MonitoringHPTD], 1);
	
	HPTD[playerid][PlusHPTD] = TextDrawCreate(596.000000, 67.000000, "+5");
	TextDrawAlignment(HPTD[playerid][PlusHPTD], 2);
	TextDrawBackgroundColor(HPTD[playerid][PlusHPTD], 255);
	TextDrawFont(HPTD[playerid][PlusHPTD], 1);
	TextDrawLetterSize(HPTD[playerid][PlusHPTD], 0.130000, 0.799999);
	TextDrawColor(HPTD[playerid][PlusHPTD], 16711935);
	TextDrawSetOutline(HPTD[playerid][PlusHPTD], 1);
	TextDrawSetProportional(HPTD[playerid][PlusHPTD], 1);
 	
	return true;
}
/*stock ReloadWeapons(playerid)
{
	ResetPlayerWeapons(playerid);
	new weapon = LevelWeapons[GunLevel[playerid]];
	//new ammo = LevelWeapons[GunLevel[playerid]][1];
	//GivePlayerWeapon(playerid, 1, 1);
	//GivePlayerWeapon(playerid, 4, 1);
	GivePlayerWeapon(playerid, weapon, 9999);
	return true;
}*/
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ){if(PlayerInfo[playerid][pAdmin] > 2) return SetPlayerPosFindZ(playerid, fX, fY, fZ);return true;}
public OnPlayerSpawn(playerid)
{
	if(PlayerTeam[playerid] == 3)
	{
		SetPlayerHealth(playerid,0);
		ForceClassSelection(playerid);
		return 1;
	}
	new string[128];
	SetPlayerInterior(playerid,0);
	TogglePlayerControllable(playerid, 0);
	//PlayAudioStreamForPlayer(playerid,"http://stream.get-tune.net/listen/5254760/-646862/1299811049/04b50d893bbf10c6/Go-Go-Go_-_Counter-Strike_(get-tune.net).mp3");
	SetSpawnInfo (playerid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
	SetPlayerSkin(playerid,Skinah[playerid]);
	if(PlayerTeam[playerid] == 1)
	{
	    switch(Map)
	 	{
			case 0: {new rand = random(sizeof(gTeam1Spawns));TpPlayer(playerid, gTeam1Spawns[rand][0], gTeam1Spawns[rand][1], gTeam1Spawns[rand][2]);}
			case 1: {new rand = random(sizeof(g2Team1Spawns));TpPlayer(playerid, g2Team1Spawns[rand][0], g2Team1Spawns[rand][1], g2Team1Spawns[rand][2]);}
			case 2: {new rand = random(sizeof(g3Team1Spawns));TpPlayer(playerid, g3Team1Spawns[rand][0], g3Team1Spawns[rand][1], g3Team1Spawns[rand][2]);}
			case 3: {new rand = random(sizeof(g4Team1Spawns));TpPlayer(playerid, g4Team1Spawns[rand][0], g4Team1Spawns[rand][1], g4Team1Spawns[rand][2]);SetPlayerInterior(playerid,10);}
			case 4: {new rand = random(sizeof(g5Team1Spawns));TpPlayer(playerid, g5Team1Spawns[rand][0], g5Team1Spawns[rand][1], g5Team1Spawns[rand][2]);}
			case 5: {new rand = random(sizeof(g6Team1Spawns));TpPlayer(playerid, g6Team1Spawns[rand][0], g6Team1Spawns[rand][1], g6Team1Spawns[rand][2]);}
			case 6: {new rand = random(sizeof(g7Team1Spawns));TpPlayer(playerid, g7Team1Spawns[rand][0], g7Team1Spawns[rand][1], g7Team1Spawns[rand][2]);}
			case 7: {new rand = random(sizeof(g8Team1Spawns));TpPlayer(playerid, g8Team1Spawns[rand][0], g8Team1Spawns[rand][1], g8Team1Spawns[rand][2]);}
			case 8: {new rand = random(sizeof(g9Team1Spawns));TpPlayer(playerid, g9Team1Spawns[rand][0], g9Team1Spawns[rand][1], g9Team1Spawns[rand][2]);}
			case 9: {new rand = random(sizeof(g10Team1Spawns));TpPlayer(playerid, g10Team1Spawns[rand][0], g10Team1Spawns[rand][1], g10Team1Spawns[rand][2]);}
			case 10: {new rand = random(sizeof(g11Team1Spawns));TpPlayer(playerid, g11Team1Spawns[rand][0], g11Team1Spawns[rand][1], g11Team1Spawns[rand][2]);}
			case 11: {new rand = random(sizeof(g12Team1Spawns));TpPlayer(playerid, g12Team1Spawns[rand][0], g12Team1Spawns[rand][1], g12Team1Spawns[rand][2]);SetPlayerInterior(playerid,1);}
			case 12: {new rand = random(sizeof(g13Team1Spawns));TpPlayer(playerid, g13Team1Spawns[rand][0], g13Team1Spawns[rand][1], g13Team1Spawns[rand][2]);}
			case 13: {new rand = random(sizeof(g14Team1Spawns));TpPlayer(playerid, g14Team1Spawns[rand][0], g14Team1Spawns[rand][1], g14Team1Spawns[rand][2]);}
			case 14: {new rand = random(sizeof(g15Team1Spawns));TpPlayer(playerid, g15Team1Spawns[rand][0], g15Team1Spawns[rand][1], g15Team1Spawns[rand][2]);}
			case 15: {new rand = random(sizeof(g16Team1Spawns));TpPlayer(playerid, g16Team1Spawns[rand][0], g16Team1Spawns[rand][1], g16Team1Spawns[rand][2]);}
			case 16: {new rand = random(sizeof(g17Team1Spawns));TpPlayer(playerid, g17Team1Spawns[rand][0], g17Team1Spawns[rand][1], g17Team1Spawns[rand][2]);SetPlayerInterior(playerid,1);}
			case 17: {new rand = random(sizeof(g18Team1Spawns));TpPlayer(playerid, g18Team1Spawns[rand][0], g18Team1Spawns[rand][1], g18Team1Spawns[rand][2]);SetPlayerInterior(playerid,10);}
			case 18: {new rand = random(sizeof(g19Team1Spawns));TpPlayer(playerid, g19Team1Spawns[rand][0], g19Team1Spawns[rand][1], g19Team1Spawns[rand][2]);SetPlayerInterior(playerid,18);}
			case 19: {new rand = random(sizeof(g20Team1Spawns));TpPlayer(playerid, g20Team1Spawns[rand][0], g20Team1Spawns[rand][1], g20Team1Spawns[rand][2]);SetPlayerInterior(playerid,3);}
		}
		//SetPlayerColor(playerid, COL_RED);
	}
	else if(PlayerTeam[playerid] == 2)
	{
	    switch(Map)
		{
			case 0: {new rand = random(sizeof(gTeam2Spawns));TpPlayer(playerid, gTeam2Spawns[rand][0], gTeam2Spawns[rand][1], gTeam2Spawns[rand][2]);}
			case 1: {new rand = random(sizeof(g2Team2Spawns));TpPlayer(playerid, g2Team2Spawns[rand][0], g2Team2Spawns[rand][1], g2Team2Spawns[rand][2]);}
			case 2: {new rand = random(sizeof(g3Team2Spawns));TpPlayer(playerid, g3Team2Spawns[rand][0], g3Team2Spawns[rand][1], g3Team2Spawns[rand][2]);}
			case 3: {new rand = random(sizeof(g4Team2Spawns));TpPlayer(playerid, g4Team2Spawns[rand][0], g4Team2Spawns[rand][1], g4Team2Spawns[rand][2]);SetPlayerInterior(playerid,10);}
			case 4: {new rand = random(sizeof(g5Team2Spawns));TpPlayer(playerid, g5Team2Spawns[rand][0], g5Team2Spawns[rand][1], g5Team2Spawns[rand][2]);}
			case 5: {new rand = random(sizeof(g6Team2Spawns));TpPlayer(playerid, g6Team2Spawns[rand][0], g6Team2Spawns[rand][1], g6Team2Spawns[rand][2]);}
			case 6: {new rand = random(sizeof(g7Team2Spawns));TpPlayer(playerid, g7Team2Spawns[rand][0], g7Team2Spawns[rand][1], g7Team2Spawns[rand][2]);}
			case 7: {new rand = random(sizeof(g8Team2Spawns));TpPlayer(playerid, g8Team2Spawns[rand][0], g8Team2Spawns[rand][1], g8Team2Spawns[rand][2]);}
			case 8: {new rand = random(sizeof(g9Team2Spawns));TpPlayer(playerid, g9Team2Spawns[rand][0], g9Team2Spawns[rand][1], g9Team2Spawns[rand][2]);}
			case 9: {new rand = random(sizeof(g10Team2Spawns));TpPlayer(playerid, g10Team2Spawns[rand][0], g10Team2Spawns[rand][1], g10Team2Spawns[rand][2]);}
			case 10: {new rand = random(sizeof(g11Team2Spawns));TpPlayer(playerid, g11Team2Spawns[rand][0], g11Team2Spawns[rand][1], g11Team2Spawns[rand][2]);}
			case 11: {new rand = random(sizeof(g12Team2Spawns));TpPlayer(playerid, g12Team2Spawns[rand][0], g12Team2Spawns[rand][1], g12Team2Spawns[rand][2]);SetPlayerInterior(playerid,1);}
			case 12: {new rand = random(sizeof(g13Team2Spawns));TpPlayer(playerid, g13Team2Spawns[rand][0], g13Team2Spawns[rand][1], g13Team2Spawns[rand][2]);}
			case 13: {new rand = random(sizeof(g14Team2Spawns));TpPlayer(playerid, g14Team2Spawns[rand][0], g14Team2Spawns[rand][1], g14Team2Spawns[rand][2]);}
			case 14: {new rand = random(sizeof(g15Team2Spawns));TpPlayer(playerid, g15Team2Spawns[rand][0], g15Team2Spawns[rand][1], g15Team2Spawns[rand][2]);}
			case 15: {new rand = random(sizeof(g16Team2Spawns));TpPlayer(playerid, g16Team2Spawns[rand][0], g16Team2Spawns[rand][1], g16Team2Spawns[rand][2]);}
			case 16: {new rand = random(sizeof(g17Team2Spawns));TpPlayer(playerid, g17Team2Spawns[rand][0], g17Team2Spawns[rand][1], g17Team2Spawns[rand][2]);SetPlayerInterior(playerid,1);}
			case 17: {new rand = random(sizeof(g18Team2Spawns));TpPlayer(playerid, g18Team2Spawns[rand][0], g18Team2Spawns[rand][1], g18Team2Spawns[rand][2]);SetPlayerInterior(playerid,10);}
			case 18: {new rand = random(sizeof(g19Team2Spawns));TpPlayer(playerid, g19Team2Spawns[rand][0], g19Team2Spawns[rand][1], g19Team2Spawns[rand][2]);SetPlayerInterior(playerid,18);}
			case 19: {new rand = random(sizeof(g20Team2Spawns));TpPlayer(playerid, g20Team2Spawns[rand][0], g20Team2Spawns[rand][1], g20Team2Spawns[rand][2]);SetPlayerInterior(playerid,3);}
		}
		//SetPlayerColor(playerid, COLOR_BLUE);
	}
	SetPlayerVirtualWorld(playerid, 2);
	SetCameraBehindPlayer(playerid);
	ReloadWeapons(playerid);
	SetPlayerScore(playerid,GunLevel[playerid]+1);
	Healings[playerid] = 1;
	KillSeries[playerid] = 0;
	UpdateInformer(playerid);
	Update3DTextLabelText(PlayerStatus[playerid],COLOR_WHITE,"");
	if(ServerSettings[ssTeamfire] == false) SetPlayerTeam(playerid,PlayerTeam[playerid]);
	else SetPlayerTeam(playerid,NO_TEAM);
	if(DeathCoords[playerid][posX] != 0.0 && DeathCoords[playerid][posY] != 0.0 && DeathCoords[playerid][posZ] != 0.0 && PlayerSettings[playerid][psLDInfoOff] == false)
	{
	    if(FirstSpawn[playerid] == false)
	    {
	        DeathCoords[playerid][posX] = 0.0;
	        DeathCoords[playerid][posY] = 0.0;
	        DeathCoords[playerid][posZ] = 0.0;
	    }
	    else
	    {
		    format(string,sizeof(string),"Место Вашей предыдущей смерти\nРасстояние: {ffff99}%.0f {ffffff}метров",GetPlayerDistanceFromPoint(playerid,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ]));
			SetPlayerCheckpoint(playerid,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ],3.0);
	   		LDI3DText[playerid] = CreatePlayer3DTextLabel(playerid,string,COLOR_WHITE,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ],1000.0,-1,-1,0);
		    LDIOn[playerid] = true;
	    }
 	}
	if(FirstSpawn[playerid] == false)
	{
		switch(PlayerTeam[playerid])
		{
		case 1: format(string,sizeof(string),"{ffff99}%s {ffffff}присоединился к команде {ff0000}террористов!",GetName(playerid));
		case 2: format(string,sizeof(string),"{ffff99}%s {ffffff}присоединился к команде {0000ff}спецназа!",GetName(playerid));
		}
		SendClientMessageToAll(COLOR_WHITE,string);
		TextDrawShowForPlayer(playerid,leader);
		TextDrawShowForPlayer(playerid,level[playerid]);
		TextDrawShowForPlayer(playerid,exp[playerid]);
		if(PlayerSettings[playerid][psSInterface] == false)
		{
			TextDrawShowForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
			TextDrawShowForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
		}
		TextDrawShowForPlayer(playerid,leader);
		TextDrawShowForPlayer(playerid,TeamScore);
		if(PlayerSettings[playerid][psTimeTDOff] == false) TextDrawShowForPlayer(playerid,TimeDisp);
		if(PlayerSettings[playerid][psDateTDOff] == false) TextDrawShowForPlayer(playerid,DateDisp);
		TextDrawShowForPlayer(playerid,URL);
		if(PlayerSettings[playerid][psMonHPOff] == false) TextDrawShowForPlayer(playerid,HPTD[playerid][MonitoringHPTD]);
		switch(PlayerTeam[playerid])
		{
			case 1: TextDrawShowForPlayer(playerid,leaderT);
			case 2: TextDrawShowForPlayer(playerid,leaderCT);
		}
		UpdateLevelTD(playerid);
		UpdateExpTD(playerid);
		ShowPlayerDialog(playerid, 1337, DIALOG_STYLE_MSGBOX,"Гонка Вооружений","Добро пожаловать!\n\nЦель данной игры - достигнуть последнего уровня\nУровень повышается при убийстве игроков противоположной команды.\nТак же на сервере присутствует система званий и рейтинга!\nМеню игрока - /menu (Клавиша ALT)\n\nПриятной игры!","Закрыть","");
		UpdateScore();
		if(PlayerInfo[playerid][pLGID] == GameID && ServerSettings[ssProgressBackup] == true)
		{
		    format(string, sizeof(string),"SELECT * FROM `accounts` WHERE `Name` = '%s'", GetName(playerid));
		    mysql_function_query(connectionHandle, string, true, "SetLastGameResults","d", playerid);
		}
		else if(PlayerInfo[playerid][pLGID] != GameID && ServerSettings[ssLevelCompensation] == true)
		{
			new givelevel = GetPlayersMiddleLevel();
			if(givelevel != 0)
			{
				GunLevel[playerid] = givelevel;
				SendClientMessage(playerid,COLOR_WHITE,"");
				SendClientMessage(playerid,COLOR_WHITE,"Данная игра уже началась! ");
				format(string,sizeof(string),"В качестве компенсации вы получаете {ffff99}%d {ffffff}уровень",givelevel+1);
				SendClientMessage(playerid,COLOR_WHITE,string);
				SendClientMessage(playerid,COLOR_WHITE,"");
				ReloadWeapons(playerid);
				UpdateLevelTD(playerid);
				SetPlayerScore(playerid,GunLevel[playerid]+1);
			}
		}
		FirstSpawn[playerid] = true;
	}
	return true;
}
forward SetLastGameResults(playerid);
public SetLastGameResults(playerid)
{
	new string[300];
	new rows, fields, maximum[300];
	cache_get_data(rows, fields);
	cache_get_field_content(0, "LGInfo", maximum), strmid(string,maximum,0,strlen(maximum),255);
    mysql_free_result();
    new lginfo[12][10];
    split(string, lginfo, '|');
    GunLevel[playerid] = strval(lginfo[1]);
    KillScore[playerid] = strval(lginfo[2]);
    Assists[playerid] = strval(lginfo[3]);
    KillsInGame[playerid] = strval(lginfo[4]);
    DeathsInGame[playerid] = strval(lginfo[5]);
    PlayerShots[playerid] = strval(lginfo[6]);
    PlayerGoodShots[playerid] = strval(lginfo[7]);
    HealTimes[playerid] = strval(lginfo[8]);
    DamageGiven[playerid] = strval(lginfo[9]);
    DamageTaken[playerid] = strval(lginfo[10]);
    BestKillSeries[playerid] = strval(lginfo[11]);
	ReloadWeapons(playerid);
	SendClientMessage(playerid,COLOR_WHITE,"\n");
	SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Внимание {ffffff}> Недавно Вы покинули эту игру! Ваш прогресс восстановлен!");
	format(string,sizeof(string),"{ff0000}> {ffffff}Уровень - {ffff99}%d{ffffff}, очки опыта - {ffff99}%d{ffffff}, помощи - {ffff99}%d",GunLevel[playerid]+1,KillScore[playerid],Assists[playerid]);
	SendClientMessage(playerid,COLOR_WHITE,string);
	format(string,sizeof(string),"{ff0000}> {ffffff}Убийств - {ffff99}%d{ffffff}, смертей - {ffff99}%d{ffffff}, наибольшая серия убийств - {ffff99}%d",KillsInGame[playerid],DeathsInGame[playerid],BestKillSeries[playerid]);
	SendClientMessage(playerid,COLOR_WHITE,string);
	format(string,sizeof(string),"{ff0000}> {ffffff}Выстрелов - {ffff99}%d{ffffff}, попаданий - {ffff99}%d{ffffff}, аптечек использовано - {ffff99}%d",PlayerShots[playerid],PlayerGoodShots[playerid],HealTimes[playerid]);
	SendClientMessage(playerid,COLOR_WHITE,string);
	format(string,sizeof(string),"{ff0000}> {ffffff}Урона нанесено - {ffff99}%d HP{ffffff}, урона получено - {ffff99}%d HP",DamageGiven[playerid],DamageTaken[playerid]);
	SendClientMessage(playerid,COLOR_WHITE,string);
	SendClientMessage(playerid,COLOR_WHITE,"\n");
	SetPlayerScore(playerid,GunLevel[playerid]+1);
	UpdateLevelTD(playerid);
	UpdateExpTD(playerid);
	PlayerInfo[playerid][pLeaves]--;
	PlayerInfo[playerid][pRating]+=5;
	PlayerInfo[playerid][pRankProgress]+=200;
	PlayerInfo[playerid][pLGID] = -1;
	if(GunLevel[playerid] > BestScore)
	{
		TextDrawHideForPlayer(LeaderID, leaderTD);
		TextDrawShowForPlayer(LeaderID, leader);
		LeaderID = playerid;
		BestScore = GunLevel[playerid];
		format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderID),GunLevel[LeaderID]+1);
		TextDrawSetString(leader,string);
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {00ff00}игры{ffffff}!",GetName(LeaderID));
		SendClientMessageToAll(COLOR_WHITE, string);
		TextDrawHideForPlayer(LeaderID,leader);
		TextDrawShowForPlayer(LeaderID,leaderTD);
	}
	if(GunLevel[playerid] > BestScoreT && PlayerTeam[playerid] == 1)
	{
		TextDrawHideForPlayer(LeaderTID, leaderTeamT);
		TextDrawShowForPlayer(LeaderTID, leaderT);
		LeaderTID = playerid;
		BestScoreT = GunLevel[playerid];
		format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderTID),GunLevel[LeaderTID]+1);
		TextDrawSetString(leaderT,string);
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {ff0000}террористов{ffffff}!",GetName(LeaderTID));
		SendClientMessageToAll(COLOR_WHITE, string);
		TextDrawHideForPlayer(LeaderTID,leaderT);
		TextDrawShowForPlayer(LeaderTID,leaderTeamT);
	}
	if(GunLevel[playerid] > BestScoreCT && PlayerTeam[playerid] == 2)
	{
		TextDrawHideForPlayer(LeaderCTID, leaderTeamCT);
		TextDrawShowForPlayer(LeaderCTID, leaderCT);
		LeaderCTID = playerid;
		BestScoreCT = GunLevel[playerid];
		format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderCTID),GunLevel[LeaderCTID]+1);
		TextDrawSetString(leaderCT,string);
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {0000ff}спецназа{ffffff}!",GetName(LeaderCTID));
		SendClientMessageToAll(COLOR_WHITE, string);
		TextDrawHideForPlayer(LeaderCTID,leaderCT);
		TextDrawShowForPlayer(LeaderCTID,leaderTeamCT);
	}
	return 1;
}
CMD:tp(playerid, params[]){if(!GetPVarInt(playerid, "Logged")) return true;if(PlayerInfo[playerid][pAdmin] < 2) return true;TpPlayer(playerid,4088.556640625,-1782.2398681641,17.233839988708);return true;}
CMD:vert(playerid, params[]){if(!GetPVarInt(playerid, "Logged")) return true;if(PlayerInfo[playerid][pAdmin] < 2) return true;new Float:x, Float:y, Float:z;GetPlayerPos(playerid, x, y, z);CreateVehicle(487,x,y+2.0,z,0.0,6,1,60000);return true;}
CMD:tp2(playerid, params[]){if(!GetPVarInt(playerid, "Logged")) return true;if(PlayerInfo[playerid][pAdmin] < 2) return true;TpPlayer(playerid,-3042.1426000,-2792.3582000,5.7471000);return true;}
CMD:gomap(playerid, params[])
{
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(PlayerInfo[playerid][pAdmin] < 3) return true;
	GameTextForAll("Administrator has changed the map",7000,5);
	foreach(Player,i)
	{ 
		if(IsPlayerConnected(i)) Vubor[i] = 1;
		TogglePlayerControllable(i, 0); 
	}
	GoMap();
	return true;
}
CMD:changeteam(playerid, params[])
{
	new string[144];
	Vubor[playerid] = 1;
	ForceClassSelection(playerid);
	SetPlayerHealth(playerid,0);
	FirstSpawn[playerid] = false;
	TextDrawsHide(playerid);
	if(LeaderID == playerid)
	{
		LeaderID = 999;
		BestScore = 0;
		foreach(Player,i)
		{
			if(BestScore < GunLevel[i])
			{
				BestScore = GunLevel[i];
				LeaderID = i;
			}
		}
		TextDrawSetString(leader,"Game Leader: None");
		format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderID),GunLevel[LeaderID]+1);
		TextDrawSetString(leader,string);
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {00ff00}игры{ffffff}!",GetName(LeaderID));
		SendClientMessageToAll(COLOR_WHITE, string);
		TextDrawHideForAll(leaderTD);
		TextDrawShowForPlayer(LeaderID,leaderTD);
		TextDrawHideForPlayer(LeaderID,leader);
	}
	if(LeaderTID == playerid)
	{
		LeaderTID = 999;
		BestScoreT = 0;
		foreach(Player,i)
		{
			if(BestScoreT < GunLevel[i] && PlayerTeam[i] == 1)
			{
				BestScoreT = GunLevel[i];
				LeaderTID = i;
			}
		}
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {ff0000}террористов{ffffff}!",GetName(LeaderTID));
		SendClientMessageToAll(COLOR_WHITE,string);
		TextDrawHideForAll(leaderTeamT);
		TextDrawShowForPlayer(LeaderTID,leaderTeamT);
		TextDrawHideForPlayer(LeaderTID,leaderT);
		format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderTID), GunLevel[LeaderTID]+1);
		TextDrawSetString(leaderT,string);
	}
	if(LeaderCTID == playerid)
	{
		LeaderCTID = 999;
		BestScoreCT = 0;
		foreach(Player,i)
		{
			if(BestScoreCT < GunLevel[i] && PlayerTeam[i] == 2)
			{
				BestScoreCT = GunLevel[i];
				LeaderCTID = i;
			}
		}
		format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {0000ff}спецназа{ffffff}!",GetName(LeaderCTID));
		SendClientMessageToAll(COLOR_WHITE,string);
		TextDrawHideForAll(leaderTeamCT);
		TextDrawShowForPlayer(LeaderCTID,leaderTeamCT);
		TextDrawHideForPlayer(LeaderCTID,leaderCT);
		format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderCTID), GunLevel[LeaderCTID]+1);
		TextDrawSetString(leaderCT,string);
	}
	return true;
}
CMD:speed(playerid, params[]){if(!GetPVarInt(playerid, "Logged")) return true;if(PlayerInfo[playerid][pAdmin] < 2) return true;SetPlayerVelocity(playerid, 0.5,0.5,0.5);return true;}
/*CMD:ban(playerid, params[])
{
	new ip[32],string[144];
	if(PlayerInfo[playerid][pAdmin] < 3 || PlayerInfo[params[0]][pAdmin] > 0) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	new result[128];
	if(sscanf(params, "us[128]", params[0], result)) return SendClientMessage(playerid, COL_WHITE, "Введите: /ban [id игрока] [причина]");
	GetPlayerIp(params[0], ip, 32);format(string, sizeof(string), "<< Администратор %s забанил игрока %s. Причина: %s >>", GetName(playerid), GetName(params[0]), result);SendClientMessageToAll(COL_ORANGE,string);
	log("Ban",string);
	//format(string, 100, "Ник: %s IP: %s", GetName(params[0]), ip);SendClientMessage(playerid,COL_RED,string);
	Ban(params[0]);
	return true;
} */
CMD:ban(playerid,params[])
{
	if(PlayerInfo[playerid][pAdmin] == 0) return SendClientMessage(playerid, COLOR_WHITE, "Вы не можете использовать эту команду.");
	new result[128], playeri, day;
	if(sscanf(params,"uis[128]",playeri,day,result)) return SendClientMessage(playerid,COLOR_WHITE, "/ban [ ID игрока / Nick игрока ] [ Срок ] [ Причина ]");
	if(IsPlayerConnected(playerid))
	{
		new y,m,d;
		new hours, minutes, seconds, timestamp;
		if(!IsPlayerConnected(playeri)) return SendClientMessage(playerid,COLOR_WHITE,"Этого игрока нет на сервере.");
		if(day <= 0) return SendClientMessage(playerid,COLOR_WHITE,"Дни бана должны быть больше нуля.");
		if(PlayerInfo[playeri][pAdmin] > 0) return SendClientMessage(playerid, COLOR_WHITE, "Запрещено банить Администратора.");
		getdate(y,m,d);
		gettime(hours, minutes, seconds);
		timestamp = date_to_timestamp(y,m,d,hours,minutes,seconds);
		new string[200];
	    format(string,sizeof(string),"Администратор %s забанил игрока %s сроком на %d дней. Причина: %s",GetName(playerid),GetName(playeri),day,result);
	    SendClientMessageToAll(COLOR_LIGHTRED,string);
		log("Ban", string);
		format(string, sizeof(string), "Аккаунт забанен!\nВаш ник: %s\nЗабанил: %s\nДата бана: (%d.%d.%d)\nДней до разбана: %d\nПричина: %s\n\nЕсли Вы желаете оспорить данное действие, то\n\n ** сделайте Screenshot (Клавиша F8)\n ** и обратитесь к администрации сервера", GetName(playeri), GetName(playerid), d, m, y, day, result);
		ShowPlayerDialog(playeri,1337,DIALOG_STYLE_MSGBOX,"Аккаунт забанен",string,"Закрыть","");
		new dd = d;
		new mm = m;
		new yy = y;
		dd = dd + day;
		while(dd > GetDayMount(m,y))
		{
			mm++;
			if(mm > 12)
			{
				mm=1;
				yy++;
			}
			dd = dd-GetDayMount(mm,yy);
		}
		PlayerInfo[playeri][pBanned] = 1;
//		format(string,sizeof(string),"%d|%d|%d|%s|%s|%d|%d|%d|%d|%d|%d",dd,mm,yy,GetName(playerid), result,hours, minutes, seconds, d,m,y);
		format(string,sizeof(string),"%d|%s|%s|%d",timestamp,GetName(playerid), result,timestamp+day*86400);
		new query[300];
		format(query,sizeof(query),"UPDATE `accounts` SET `BanInfo`='%s' WHERE `Name`='%s'",string,GetName(playeri));
		mysql_function_query(connectionHandle, query, false,"","");
		TogglePlayerControllable(playeri, 0);
		Kick(playeri);
	}
	return true;
}
CMD:id(playerid, params[])
{
	new ip[32],string[144];
//	if(PlayerInfo[playerid][pAdmin] < 3 || PlayerInfo[params[0]][pAdmin] > 0) return true
	if(GetPVarInt(playerid, "Logged") == 0) return true;
//	new result[128];
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COL_WHITE, "Введите: /id [id игрока/Ник]");
	GetPlayerIp(params[0], ip, 32);
	if(PlayerInfo[playerid][pAdmin] > 0) format(string, sizeof(string), "> Ник: {ffff99} %s {ffffff}| ID: {ffff99}%d {ffffff}| IP: {ffff99}%s", GetName(params[0]), params[0], ip);
	else format(string, sizeof(string), "> Ник: {ffff99} %s {ffffff}| ID: {ffff99}%d", GetName(params[0]), params[0]);
	SendClientMessage(playerid,COLOR_WHITE,string);
	//format(string, 100, "Ник: %s IP: %s", GetName(params[0]), ip);SendClientMessage(playerid,COL_RED,string);
//	Ban(params[0]);
	return true;
}
CMD:kick(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1) return true;
	if(GetPVarInt(playerid, "Logged") == 0) return true;
	new result[128], giveid;
	if(sscanf(params, "us[128]", giveid,result)) return SendClientMessage(playerid, COL_WHITE, "Введите: /kick [id игрока] [причина]");
	new string[128];
	format(string, sizeof(string),"%s был(а) кикнут(а) %s %s, Причина: %s", GetName(giveid),GetAdminRankEx(PlayerInfo[playerid][pAdmin]),GetName(playerid),result);
	SendClientMessageToAll(COLOR_LIGHTRED, string);
	log("Kick",string);
	SendClientMessage(giveid, COL_RED, "Вы были кикнуты, соблюдайте правила сервера");
	Kick(giveid);
	return true;
}
CMD:boom(playerid, params[])
{
	new string[128];
	if(PlayerInfo[playerid][pAdmin] < 2) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COL_WHITE, "Введите: /boom [id игрока]");
	format(string, sizeof(string), "<< Администратор %s подорвал %s >>", GetName(playerid), GetName(params[0]));
	SendClientMessageToAll(COL_ORANGE, string);
	GetPlayerPos(params[0],P[0],P[1],P[2]);
	CreateExplosion(P[0],P[1],P[2],0,4.0);
	return true;
}
CMD:slap(playerid, params[])
{
	new string[128];
	if(PlayerInfo[playerid][pAdmin] < 1) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COL_WHITE, "Введите: /slap [id игрока]");
	format(string, sizeof(string), "<< Администратор %s дал пинка %s >>", GetName(playerid), GetName(params[0]));
	SendClientMessageToAll(COL_ORANGE, string);
	GetPlayerPos(params[0],P[0],P[1],P[2]);
	SetPlayerPos(params[0],P[0],P[1],P[2]+10);
	return true;
}
CMD:acmd(playerid, params[])
{
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(PlayerInfo[playerid][pAdmin] < 1) return true;
	SendClientMessage(playerid,COL_YELLOW, "[1]: /kick - кикнуть игрока || /mute - заткнуть игрока || /slap - дать пинка игроку || /полетаем");
	SendClientMessage(playerid,COL_YELLOW, "[2]: /warn - дать варн игроку || /boom - взорвать игрока || /unmute - снять затычку || /vert - получить вертушку");
	SendClientMessage(playerid,COL_YELLOW, "[3]: /ban - забанить игрока || /map - сменить карту || /gomap - сменить карту рандомно");
	SendClientMessage(playerid,COL_YELLOW, "[4]: пока ничего :(");
	SendClientMessage(playerid,COL_YELLOW, "[5]: /unwarn - снять варны с игрока");
	SendClientMessage(playerid,COL_YELLOW, "[6]: /gmx - сделать рестарт сервера || /saveacc- сохранить аккаунты игроков");
	return true;
}
CMD:warn(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 2) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
 	new result[128], giveid;
	if(sscanf(params, "us[128]", giveid, result)) return SendClientMessage(playerid, COL_WHITE, "Введите: /warn [id игрока] [причина]");
	PlayerInfo[giveid][pWarn]++;
	new string[144];
	if(PlayerInfo[giveid][pWarn] < 3)
	{
		format(string, sizeof(string), "<< %s %s выдал предупреждение игроку %s. Причина: %s >>", GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid), GetName(giveid), result);
		SendClientMessageToAll(COL_ORANGE, string);
	}
	else
	{
		PlayerInfo[giveid][pWarn] = 0;
		format(string, sizeof(string), "<< %s забанен (3 варна) %s %s. Причина: %s >>", GetName(giveid),GetAdminRankEx(PlayerInfo[playerid][pAdmin]),GetName(playerid), result);
		SendClientMessageToAll(COL_ORANGE, string);
		Kick(giveid);
	}
	log("Warn",string);
	return true;
}
CMD:unwarn(playerid, params[]){
	new string[80];if(PlayerInfo[playerid][pAdmin] < 5) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COL_WHITE, "Введите: /unwarn [id игрока]");
	PlayerInfo[params[0]][pWarn] = 0;format(string, 100, "<< %s %s снял варны с %s >>", GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetName(params[0]));SendClientMessageToAll(COL_ORANGE,string);return true;}
CMD:mute(playerid, params[])
{
	new string[144];if(PlayerInfo[playerid][pAdmin] < 1) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	new result[128];
	if(sscanf(params, "uds[128]", params[0], params[1], result)) return SendClientMessage(playerid, COL_WHITE, "Введите: /mute [id игрока] [время] [причина]");
	if(PlayerInfo[params[0]][pMute] > 0) return SendClientMessage(playerid, COL_RED, "Игрок уже имеет бан чата");
	if(params[1] > 120 || params[1] < 1) return SendClientMessage(playerid, COL_RED, "Время указывается в минутах! От 1 минуты до 120 минут!");
	PlayerInfo[params[0]][pMute] = params[1]*60;
	format(string, sizeof(string), "<< %s %s выдал мут игроку %s на %d минут(ы).Причина: %s >>",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetName(params[0]),params[1],result);
	SendClientMessageToAll(COL_ORANGE, string);
	log("Mute",string);
	return true;
	}
CMD:unmute(playerid, params[])
{
	new string[80];if(PlayerInfo[playerid][pAdmin] < 2) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COL_WHITE, "Введите: /unmute [id игрока]");
	if(!IsPlayerConnected(params[0])) return true;if(PlayerInfo[params[0]][pMute] == 0) return SendClientMessage(playerid, COL_RED, "У игрока нет мута!");
	PlayerInfo[params[0]][pMute] = 0;
	format(string, 100, "<< Администратор %s снял бан чата у %s >>",GetName(playerid),GetName(params[0]));SendClientMessageToAll(COL_ORANGE, string);
	format(string, 100, "Администратор %s снял вам бан чата", GetName(playerid));
	SendClientMessage(params[0],COL_ORANGE,string);
	return true;
	}
CMD:makeadmin(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 7) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "ud", params[0], params[1])) return SendClientMessage(playerid, COL_WHITE, "/makeadmin [id игрока] [уровень (0-7)]");
	if(params[1] < 0 || params[1] > 7) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Уровень администированния не может быть меньше 0 или больше 7!");
	if(playerid == params[0]) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Нельзя изменить уровень администированиия самому себе!");
	new string[128];
	if(PlayerInfo[params[0]][pAdmin] <= 0 || PlayerInfo[params[0]][pAdmin] == params[1])
	{
		PlayerInfo[params[0]][pAdmin] = params[1];
		format(string,sizeof(string),"%s %s назначил %s %s",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetName(params[0]),GetAdminRankEx(PlayerInfo[params[0]][pAdmin]));
		SendClientMessageToAll(COLOR_LIGHTRED,string);
		return true;
	}
	if(PlayerInfo[params[0]][pAdmin] < params[1])
	{
		format(string,sizeof(string),"%s %s повысил %s %s до %s",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetAdminRankEx2(PlayerInfo[params[0]][pAdmin]),GetName(params[0]),GetAdminRankEx2(params[1]));
		SendClientMessageToAll(COLOR_LIGHTRED,string);
		PlayerInfo[params[0]][pAdmin] = params[1];
		return true;
	}
	if(PlayerInfo[params[0]][pAdmin] > params[1])
	{
		format(string,sizeof(string),"%s %s освободил %s от прав %s",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetName(params[0]),GetAdminRankEx2(PlayerInfo[params[0]][pAdmin]));
		SendClientMessageToAll(COLOR_LIGHTRED,string);
		PlayerInfo[params[0]][pAdmin] = params[1];
		return true;
	}
	if(PlayerInfo[params[0]][pAdmin] > params[1])
	{
		format(string,sizeof(string),"%s %s понизил %s %s до %s",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetAdminRankEx2(PlayerInfo[params[0]][pAdmin]),GetName(params[0]),GetAdminRankEx2(params[1]));
		SendClientMessageToAll(COLOR_LIGHTRED,string);
		PlayerInfo[params[0]][pAdmin] = params[1];
		return true;
	}
	return true;
}
CMD:vipka(playerid, params[])
{
	new string[128];
	if(PlayerInfo[playerid][pAdmin] < 7) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(sscanf(params, "ui", params[0],params[1])) return SendClientMessage(playerid, COL_WHITE, "Введите: /vipka [id игрока] [кол-во часов]");
	if(params[1] < 0 || params[1] > 30) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Количество дней не может быть меньше нуля или больше 30!");
	if(IsPlayerConnected(params[0]))
	{
		if(params[0] != INVALID_PLAYER_ID)
		{
			if(PlayerInfo[params[0]][pVip] == 0)
			{
				format(string,sizeof(string),"<< Администратор %s поместил %s в группу VIP на %d часов >>",GetName(playerid),GetName(params[0]),params[1]);
				SendClientMessageToAll(COL_ORANGE,string);
				log("Vip",string);
				PlayerInfo[params[0]][pVip] = params[1]*3600;
				return true;
			}
			else
			{
				format(string,sizeof(string),"<< Администратор %s исключил %s из группы VIP >>",GetName(playerid),GetName(params[0]));SendClientMessageToAll(COL_ORANGE,string);
				PlayerInfo[params[0]][pVip] = 0;
				log("Vip",string);
				return 1;
			}
		}
	}
	return 1;
}
CMD:map(playerid, params[])
{
	if(!GetPVarInt(playerid, "Logged")) return true;
	if(PlayerInfo[playerid][pAdmin] < 3) return true;
	ShowPlayerDialog(playerid,4,2,"Смена карты","LVA\nКарта в океане с ящиками\nКрыши домов у мэрии\nRC Battlefield\nМаленькие руины на крышах LS\nГаваи\nДва островка напротив LS\nРуины в Ghetto\nРуины\nГрузовой порт\nБандитский городок под ВВ\nТюрьма\nОстровок напротив пляжа LS\nГрузовой склад с кранами и ящиками\nКорабль SF\nКорабль LS\nCaligulas\n4 дракона\nAtrium\nJizzy","Выбор","Отмена");
	return true;
}
CMD:pm(playerid, params[])
{
	new str[144], result[128];
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerSettings[playerid][psPMOff] == true) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Вы заблокировали личные сообщения");
	if(sscanf(params, "us", params[0], result)) return SendClientMessage(playerid, -1, "Использование: /pm [id игрока] [сообщение]");
	if(ServerSettings[ssPM] == false) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Личные отключены администрацией сервера!");
	if(PlayerSettings[params[0]][psPMOff] == true) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Данный игрок заблокмровал личные сообщения");
	if(Blocked[params[0]][playerid] == true) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Данный игрок заблокмровал Вас");
	if(playerid == params[0]) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Вы не можете отправить личное сообщение самому себе");
	if(!IsPlayerConnected(params[0])) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Данный игрок не подключен к серверу");
	format(str, sizeof(str), "Сообщение к %s (ID: %d): %s", GetName(params[0]),params[0], result);
	SendClientMessage(playerid, COL_YELLOW, str);
	if(PlayerAFKTime[params[0]] >= 30) SendClientMessage(playerid, COL_YELLOW, "Этот игрок находится в AFK.");
	format(str, sizeof(str), "Сообщение от %s (ID: %d): %s", GetName(playerid),playerid, result);
	SendClientMessage(params[0], COL_YELLOW, str);
	PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
	PlayerPlaySound(params[0], 1084, 0.0, 0.0, 0.0);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `pmchatlog` (`SenderName`, `SenderID`, `TakingName`, `TakingID`,`Message`,`Time`) VALUES ('%s', '%d', '%s', '%d', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],GetName(params[0]),PlayerInfo[params[0]][pID],result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return true;
}
CMD:block(playerid, params[])
{
	new string[144], result[128];
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(sscanf(params, "us", params[0], result)) return SendClientMessage(playerid, -1, "Использование: /block [id игрока] [причина]");
	if(playerid == params[0]) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Вы не можете заблокировать самого себя");
	if(!IsPlayerConnected(params[0])) return SendClientMessage(playerid, COL_WHITE, "{ff0000}Ошибка {ffffff}> Данный игрок не подключен к серверу");
	switch(Blocked[playerid][params[0]])
	{
		case true:
		{
			Blocked[playerid][params[0]] = false;
			format(string,sizeof(string),"{ff0000}Блокировщик {ffffff}> {ffff99}%s {ffffff}был разблокирован. Причина: {ffff99}%s",GetName(params[0]),result);
			SendClientMessage(playerid,COLOR_WHITE,string);
			format(string,sizeof(string),"{ff0000}Блокировщик {ffffff}> {ffff99}%s {ffffff}разблокировал Вас. Причина: {ffff99}%s",GetName(playerid),result);
			SendClientMessage(params[0],COLOR_WHITE,string);
		}
		case false:
		{
			Blocked[playerid][params[0]] = true;
			format(string,sizeof(string),"{ff0000}Блокировщик {ffffff}> {ffff99}%s {ffffff}был заблокирован. Причина: {ffff99}%s",GetName(params[0]),result);
			SendClientMessage(playerid,COLOR_WHITE,string);
			format(string,sizeof(string),"{ff0000}Блокировщик {ffffff}> {ffff99}%s {ffffff}заблокировал Вас. Причина: {ffff99}%s",GetName(playerid),result);
			SendClientMessage(params[0],COLOR_WHITE,string);
		}
	}
	PlayerPlaySound(playerid, 1084, 0.0, 0.0, 0.0);
	PlayerPlaySound(params[0], 1084, 0.0, 0.0, 0.0);
	return true;
}
CMD:saveacc(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 6) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	foreach(Player, i)
	{
		if(IsPlayerConnected(i))
		{
			SavePlayer(i);
			SendClientMessage(i,COL_RED,"Администратор сохранил ваш аккаунт!");
		}
	}
	return true;
}
CMD:restart(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 6) return true;
	if(!GetPVarInt(playerid, "Logged")) return true;
	GameTextForAll("~r~RESTART", 5000,5);
	new string[128];
	format(string,sizeof(string),"{ff0000}Внимание {ffffff}> %s {ffff99}%s {ffffff}запустил перезагрузку сервера! Это займет несколько секунд!",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
	SendClientMessageToAll(COLOR_WHITE,string);
	foreach(Player,i)
	{
	    SavePlayer(i);
	}
	GameModeExit();
	printf("Info > %s %s запустил перезагрузку сервера", GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
	return true;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	case 1:
		{
			if(!strlen(inputtext))return ShowPlayerDialog(playerid,1,DIALOG_STYLE_INPUT,"Регистрация - Гонка Вооружений","Добро пожаловать на Гонку Вооружений!\nДанный сервер не похож на остальные,\nтак как он является единственным в своем жанре!\n\nНа сервере:\n* 15 уровней с различными оружиями\n* 14 красивых карт\n* Персональная статистика и система лидеров\n\nЭтот аккаунт не зарегистрирован!\n\nВведите пароль:","Далее","Отмена");
			OnPlayerRegister(playerid,inputtext);
			return true;
		}
	case 2://Авторизация
		{
			if(!strlen(inputtext))return ShowPlayerDialog(playerid,2,DIALOG_STYLE_PASSWORD,"Авторизация - Гонка Вооружений","Добро пожаловать на Гонку Вооружений!\nДанный сервер не похож на остальные,\nтак как он является единственным в своем жанре!\n\nНа сервере:\n* 15 уровней с различными оружиями\n* 14 красивых карт\n* Персональная статистика и система лидеров\n\nЭтот аккаунт зарегистрирован!\nВведите пароль:","Вход","Отмена");
			OnPlayerLogin(playerid,inputtext);
			return true;
		}
	case 3:
		{
			if(response) return PlayerTeam[playerid] = 1; SpawnPlayer(playerid);
			if(!response) return PlayerTeam[playerid] = 2; SpawnPlayer(playerid);
		}
	case 4:
		{
			if(!response) return true;
			Map = listitem;
			new string[144];
			format(string,sizeof(string),"{ffff99}%s {ffffff}сменил карту на {ffff99}%s", GetName(playerid), MapNames[Map]);
			SendClientMessageToAll(COLOR_WHITE,string);
			foreach(Player,i)
			{
				TogglePlayerControllable(i, 1);
				Vubor[i] = 1;
				SetPlayerHealth(i,0);
				ForceClassSelection(i);
			}
			UpdateMap(Map);
			ClearGameVars();
		}
	case 5:
		{
			if(!response) return true;
			if(!strlen(inputtext)) return ShowPlayerDialog(playerid,5,DIALOG_STYLE_INPUT,"Вход под администратора","Введите свой админ-пароль","Ок","Закрыть");
			//if(strval(inputtext) == PlayerInfo[playerid][pPass]){Admlog[playerid] = 1;SendClientMessage(playerid,COL_ORANGE,"Вы успешно вошли под администратора!");}
			else{SendClientMessage(playerid,COL_RED,"Пароль введён не верно!");ShowPlayerDialog(playerid,5,DIALOG_STYLE_INPUT,"Вход под администратора","Введите свой админ-пароль","Ок","Закрыть");}
		}
	case 6:
	{
		if(!response) return true;
		switch(listitem)
		{
			case 0: ShowStats(playerid);
			case 1: ShowThisGameStats(playerid);
			case 2:
			{
				if(GetPVarInt(playerid,"Logged") == 1)
				{
					ShowPlayerDialog(playerid,10,DIALOG_STYLE_LIST,"Помощь по игровому процессу","Основное\nЗвания и рейтинг\nОружие и уровни\nВиды связи\nПолезные команды\nРазличные модификации","Далее","Назад");
				}
			}
			case 3:
			{
				if(GetPVarInt(playerid,"Logged") == 1)
				{
					if(LeaderID == 999) return ShowPlayerDialog(playerid, 8, DIALOG_STYLE_MSGBOX,"Лидеры сервера","Лидер игры - Нет\nЛидер команды террористов - Нет\nЛидер команды спецназа - Нет","Закрыть","Назад");
					new allstring[300], string[128];
					format(string,sizeof(string),"Лидер игры - %s (%d уровень)",GetName(LeaderID),BestScore+1);
					strcat(allstring,string);
					if(LeaderTID == 999)
					{
						strcat(allstring,"\nЛидер команды террористов - Нет");
					}
					else
					{
						format(string,sizeof(string),"\nЛидер команды террористов - %s (%d уровень)",GetName(LeaderTID), BestScoreT+1);
						strcat(allstring,string);
					}
					if(LeaderCTID == 999)
					{
						strcat(allstring,"\nЛидер команды спецназа - Нет");
					}
					else
					{
						format(string,sizeof(string),"\nЛидер команды спецназа - %s (%d уровень)",GetName(LeaderCTID), BestScoreCT+1);
						strcat(allstring,string);
					}
					ShowPlayerDialog(playerid,8,DIALOG_STYLE_MSGBOX,"Лидеры Гонки Вооружений",allstring,"Закрыть","Назад");
				}
			}
			case 4:
			{
				if(GetPVarInt(playerid,"Logged") == 1)
				{
					ShowPlayerDialog(playerid, 8, DIALOG_STYLE_MSGBOX,"Приемущества VIP","На нашем сервере существует функция VIP\nОна дает некоторые приемущества, не влияющие на игровой процесс\n\nСписок приемуществ:\n+ Доступ к VIP скинам\n+ Префикс < VIP > в чате\n+ Доступ к VIP-чату\n+ Откат в чат - 5 секунд","Закрыть","Назад");
				}
			}
			case 5:
			{
				if(GetPVarInt(playerid,"Logged") == 1)
				{
					ShowPlayerDialog(playerid, 8, DIALOG_STYLE_MSGBOX,"О моде","Гонка Вооружений\n\n\nВерсия: 1.0\nДата выхода: 10.02.2016\nГруппа VK: -\nСайт: -\n\n\nАвторы:\n\n+ Скриптер: MaDoy\n+ Тестеры: steadY., Mystery.,_Flomka_\n\n(c) 2014-2016, MaDoy","Закрыть","Назад");
				}
			}
			case 6:
			{
				//new mtext[20];
				new string[300];
				new year, month, day;
				getdate(year, month, day);
/*				switch(month)
				{
					case 1: mtext = "января";
					case 2: mtext = "февраля";
					case 3: mtext = "марта";
					case 4: mtext = "апреля";
					case 5: mtext = "мая";
					case 6: mtext = "июня";
					case 7: mtext = "июля";
					case 8: mtext = "августа";
					case 9: mtext = "сентября";
					case 10: mtext = "октября";
					case 11: mtext = "ноября";
					case 12: mtext = "декабря";
				}
*/
				new minuite,second, hour;
				gettime(hour,minuite,second);
				format(string, sizeof(string), "Гонка Вооружений - Сервер 1\n\nДата - %d %s %d года\nВремя - %02d часов %02d минут %02d секунд\nТекущая карта - %s (ID: %d)\nИгроков онлайн: %d (T: %d | CT: %d | SPEC: %d)", day, GetMonthNameRus(month), year, hour, minuite, second, MapNames[Map], Map, GetOnline(), GetTeamOnline(1), GetTeamOnline(2), GetTeamOnline(3));
				ShowPlayerDialog(playerid,13,DIALOG_STYLE_MSGBOX,"Дата и время",string,"Закрыть","Назад");
				WatchTime[playerid] = true;
			}
			case 7:
			{
				if(PlayerTeam[playerid] == 0 || GetPVarInt(playerid,"Logged") == 0) return SendClientMessage(playerid, COLOR_WHITE, "{ff0000}Ошибка {ffffff}> Недоступно в данный момент");
				new allstring[3000];
				new string[100];
				new countspec;
				new countt = GetTeamOnline(1);
				new countct = GetTeamOnline(2);
				if(countt > 0)
				{
					format(string, sizeof(string),"Террористы (Живые игроки: %d из %d)\nID - Игрок - Уровень - У/С - НСУ - Звание - ARR\n",GetTeamAlive(1),countt);
					strcat(allstring,string);
					foreach(Player,i)
					{
						if(PlayerTeam[i] == 1)
						{
							if(PlayerSpawned[i] == false) format(string,sizeof(string),"\n(Мертв) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							else if(i == LeaderTID) format(string,sizeof(string),"\n(Лидер) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							else format(string,sizeof(string),"\n%d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							strcat(allstring,string);
						}
					}
				}
				if(countct > 0)
				{
			        if(countt > 0) strcat(allstring,"\n\n----------\n\n");
					format(string,sizeof(string),"Спецназ (Живые игроки: %d из %d)\nID - Игрок - Уровень - У/С - НСУ - Звание - ARR\n",GetTeamAlive(1),countct);
					strcat(allstring,string);
					foreach(Player,i)
					{
						if(PlayerTeam[i] == 2)
						{
							if(PlayerSpawned[i] == false) format(string,sizeof(string),"\n(Мертв) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							else if(i == LeaderCTID) format(string,sizeof(string),"\n(Лидер) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							else format(string,sizeof(string),"\n%d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
							strcat(allstring,string);
						}
					}
				}
				if(GetTeamOnline(3) > 0)
				{
					if(countt > 0 || countct > 0) strcat(allstring,"\n\n----------\n\n");
					format(string,sizeof(string),"Наблюдатели (%d)\n",GetTeamOnline(3));
					strcat(allstring,string);
					foreach(Player,i)
					{
						if(PlayerTeam[i] == 3)
						{
							if(countspec == 0) format(string,sizeof(string),"%s",GetName(i));
							else format(string,sizeof(string),",%s",GetName(i));
							strcat(allstring,string);
							countspec++;
						}
					}
				}
				ShowPlayerDialog(playerid,8,DIALOG_STYLE_MSGBOX,"Гонка Вооружений",allstring,"Закрыть","Назад");
			}
			case 8: ShowSettingDialog(playerid);
			case 9:
			{
				new alllstring[500];
				foreach(Player, i)
				{
					if(PlayerInfo[i][pAdmin] > 0)
					{
						if(PlayerAFKTime[i] >= 30) format(alllstring,sizeof(alllstring),"%s%s %s [ID: %d] (AFK)\n",alllstring,GetAdminRank(PlayerInfo[i][pAdmin]),GetName(i),i);
						else format(alllstring,sizeof(alllstring),"%s%s %s [ID: %d]\n",alllstring,GetAdminRank(PlayerInfo[i][pAdmin]),GetName(i),i);
					}
				}
				if(strlen(alllstring) < 1) strcat(alllstring,"Нет администрации онлайн");
				return ShowPlayerDialog(playerid,8, DIALOG_STYLE_MSGBOX, "Администрация Онлайн", alllstring, "Закрыть", "Назад");
			}
			case 10: ShowConfigDialog(playerid);
		}
	}
	case 7:
	{
		if(!response) return true;
		if(playerid == PlayerTarget[playerid]) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы не можете наблюдать за самим собой");
		if(!IsPlayerConnected(PlayerTarget[playerid])) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Данный игрок покинул сервер!");
		new string[144];
		TogglePlayerSpectating(playerid,1);
		PlayerSpectatePlayer(playerid,PlayerTarget[playerid]);
		SendClientMessage(playerid,COL_RED,"Вы вошли в режим наблюдения! Для выхода используйте /specoff");
		TextDrawHideForPlayer(playerid,level[playerid]);
		TextDrawHideForPlayer(playerid,exp[playerid]);
//		TextDrawHideForPlayer(playerid,Textdraw2[playerid]);
//		TextDrawHideForPlayer(playerid,Textdraw3[playerid]);
		TextDrawHideForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
//		TextDrawHideForPlayer(playerid,StatsBG);
//		TextDrawHideForPlayer(playerid,StatsTitle);
		SetPlayerScore(playerid,0);
		PlayerSpawned[playerid] = false;
		if(LeaderID == playerid)
		{
		    TextDrawShowForPlayer(LeaderID,leader);
			LeaderID = 999;
			BestScore = 0;
			foreach(Player,i)
			{
				if(BestScore < GunLevel[i] && i != playerid)
				{
					BestScore = GunLevel[i];
					LeaderID = i;
				}
			}
			TextDrawSetString(leader,"Game Leader: None");
			TextDrawHideForAll(leaderTD);
			if(LeaderID != 999)
			{
				format(string,sizeof(string),"Game Leader: %s (%d level)", GetName(LeaderID),GunLevel[LeaderID]+1);
				TextDrawSetString(leader,string);
				format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {00ff00}игры{ffffff}!",GetName(LeaderID));
				SendClientMessageToAll(COLOR_WHITE, string);
				TextDrawShowForPlayer(LeaderID,leaderTD);
				TextDrawHideForPlayer(LeaderID,leader);
			}
		}
		if(LeaderTID == playerid)
		{
			LeaderTID = 999;
			BestScoreT = 0;
			foreach(Player,i)
			{
				if(BestScoreT < GunLevel[i] && PlayerTeam[i] == 1 && i != playerid)
				{
					BestScoreT = GunLevel[i];
					LeaderTID = i;
				}
			}
			TextDrawHideForAll(leaderTeamT);
			TextDrawShowForPlayer(playerid,leaderT);
			if(LeaderTID != 999)
			{
				format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {ff0000}террористов{ffffff}!",GetName(LeaderTID));
				SendClientMessageToAll(COLOR_WHITE,string);
				TextDrawShowForPlayer(LeaderTID,leaderTeamT);
				TextDrawHideForPlayer(LeaderTID,leaderT);
				format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderTID), GunLevel[LeaderTID]+1);
				TextDrawSetString(leaderT,string);
			}
		}
		if(LeaderCTID == playerid)
		{
			LeaderCTID = 999;
			BestScoreCT = 0;
			foreach(Player,i)
			{
				if(BestScoreCT < GunLevel[i] && PlayerTeam[i] == 2 && i != playerid)
				{
					BestScoreCT = GunLevel[i];
					LeaderCTID = i;
				}
			}
			TextDrawHideForAll(leaderTeamCT);
			TextDrawShowForPlayer(playerid,leaderCT);
			if(LeaderCTID != 999)
			{
				format(string,sizeof(string),"> {ffff99}%s {ffffff}- новый лидер {0000ff}спецназа{ffffff}!",GetName(LeaderCTID));
				SendClientMessageToAll(COLOR_WHITE,string);
				TextDrawShowForPlayer(LeaderCTID,leaderTeamCT);
				TextDrawHideForPlayer(LeaderCTID,leaderCT);
				format(string,sizeof(string),"Team Leader: %s (%d level)",GetName(LeaderCTID), GunLevel[LeaderCTID]+1);
				TextDrawSetString(leaderCT,string);
			}
		}
		PlayerSpectating[playerid] = PlayerTarget[playerid];
		if(PlayerTeam[playerid] != 3)
		{
			format(string,sizeof(string),"{ffff99}%s {ffffff}пресоединился к {00ff00}наблюдателям!",GetName(playerid));
			SendClientMessageToAll(COLOR_WHITE,string);
			SetPlayerColor(playerid,COL_GREEN_INVIS);
			PlayerTeam[playerid] = 3;
		}
	}
	case 8:
	{
		if(!response) cmd::menu(playerid,"");
	}
	case 9:
	{
		if(!response)
		{
			cmd::menu(playerid,"");
			return 1;
		}
		switch(listitem)
		{
			case 0:
			{
				switch(PlayerSettings[playerid][psDInfoOff])
				{
					case false: PlayerSettings[playerid][psDInfoOff] = true;
					case true: PlayerSettings[playerid][psDInfoOff] = false;
				}
				ShowSettingDialog(playerid);
			}
			case 1:
			{
				switch(PlayerSettings[playerid][psDeathStatOff])
				{
					case false: PlayerSettings[playerid][psDeathStatOff] = true;
					case true: PlayerSettings[playerid][psDeathStatOff] = false;
				}
				ShowSettingDialog(playerid);
			}
			case 2:
			{
				switch(PlayerSettings[playerid][psLDInfoOff])
				{
					case false:
					{
						PlayerSettings[playerid][psLDInfoOff] = true;
						if(LDIOn[playerid] == true)
						{
							LDIOn[playerid] = false;
						    DisablePlayerCheckpoint(playerid);
						    DeletePlayer3DTextLabel(playerid,LDI3DText[playerid]);
					    }
					}
					case true:
					{
						PlayerSettings[playerid][psLDInfoOff] = false;
						if(DeathCoords[playerid][posX] != 0.0 && DeathCoords[playerid][posY] != 0.0 && DeathCoords[playerid][posZ] != 0.0)
						{
						    new string[90];
						    format(string,sizeof(string),"Место Вашей предыдущей смерти\nРасстояние: {ffff99}%.0f {ffffff}метров",GetPlayerDistanceFromPoint(playerid,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ]));
					 		SetPlayerCheckpoint(playerid,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ],3.0);
					   		LDI3DText[playerid] = CreatePlayer3DTextLabel(playerid,string,COLOR_WHITE,DeathCoords[playerid][posX],DeathCoords[playerid][posY],DeathCoords[playerid][posZ],1000.0,-1,-1,0);
						    LDIOn[playerid] = true;
					 	}
					}
				}
				ShowSettingDialog(playerid);
			}
			case 3:
			{
				switch(PlayerSettings[playerid][psMonHPOff])
				{
					case false:
					{
						PlayerSettings[playerid][psMonHPOff] = true;
						TextDrawHideForPlayer(playerid,HPTD[playerid][MonitoringHPTD]);
						TextDrawHideForPlayer(playerid,HPTD[playerid][MinusHPTD]);
						TextDrawHideForPlayer(playerid,HPTD[playerid][PlusHPTD]);
                        HideHPTD[playerid][HideMinusHPTD] = 0;
						HideHPTD[playerid][HidePlusHPTD] = 0;
					}
					case true:
					{
						PlayerSettings[playerid][psMonHPOff] = false;
					    new string[10],Float:health;
					    GetPlayerHealth(playerid,health);
						format(string,sizeof(string),"%d HP",floatround(health,floatround_ceil));
						TextDrawSetString(HPTD[playerid][MonitoringHPTD],string);
						TextDrawShowForPlayer(playerid,HPTD[playerid][MonitoringHPTD]);
					}
				}
				ShowSettingDialog(playerid);
			}
			case 4:
			{
				switch(PlayerSettings[playerid][psSInterface])
				{
					case false:
					{
						PlayerSettings[playerid][psSInterface] = true;
						TextDrawHideForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
						TextDrawHideForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
						TextDrawHideForPlayer(playerid,HealAmountTD[playerid]);
						TextDrawHideForPlayer(playerid,HealTD[0]);
						TextDrawHideForPlayer(playerid,HealTD[PlayerSettings[playerid][psInterfaceColor]+1]);
		    			TextDrawHideForPlayer(playerid,LevelUpTD[TextLUTD][playerid]);
					    TextDrawHideForPlayer(playerid,LevelUpTD[TopicLUTD]);
					    TextDrawHideForPlayer(playerid,LevelUpTD[BackgroundLUTD][PlayerSettings[playerid][psInterfaceColor]]);
					    TextDrawHideForPlayer(playerid,LevelUpTD[ModelLUTD][GetGunTD(LevelWeapons[GunLevel[playerid]])]);
					    LevelUpTD[HideLUTD][playerid] = 0;
						HideHealTD[playerid] = 0;
						TextDrawHideForPlayer(playerid,TKPlus1[0]);
						TextDrawHideForPlayer(playerid,TKPlus1[1]);
						TextDrawHideForPlayer(playerid,RDTD[0]);
						TextDrawHideForPlayer(playerid,RDTD[1]);
						TextDrawHideForPlayer(playerid,RDTD[PlayerSettings[playerid][psInterfaceColor]+2]);
						TextDrawHideForPlayer(playerid,RDTimeTD[playerid]);
						if(SK[playerid] > 0)
						{
		  					new string[64];
							format(string,sizeof(string),"Returning in %d seconds",SK[playerid]);
							GameTextForPlayer(playerid, string, 1000,6);
						}
					}
					case true:
					{
						PlayerSettings[playerid][psSInterface] = false;
						TextDrawShowForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
						TextDrawShowForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
						if(SK[playerid] > 0)
						{
						    new string[3];
		  					format(string,sizeof(string),"%d",SK[playerid]);
		  					TextDrawSetString(RDTimeTD[playerid],string);
		  					TextDrawShowForPlayer(playerid,RDTD[0]);
		  					TextDrawShowForPlayer(playerid,RDTD[1]);
		  					TextDrawShowForPlayer(playerid,RDTD[PlayerSettings[playerid][psInterfaceColor]+2]);
		  					TextDrawShowForPlayer(playerid,RDTimeTD[playerid]);
		  					GameTextForPlayer(playerid,"",1000,6);
						}
					}
				}
				ShowSettingDialog(playerid);
			}
			case 5:
			{
			    if(PlayerSettings[playerid][psSInterface] == false)
			    {
			        TextDrawHideForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
			        TextDrawHideForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
			        if(SK[playerid] > 0) TextDrawHideForPlayer(playerid,RDTD[PlayerSettings[playerid][psInterfaceColor]+2]);
			        if(HideHealTD[playerid] > 0) TextDrawHideForPlayer(playerid,HealTD[PlayerSettings[playerid][psInterfaceColor]+1]);
			        if(LevelUpTD[HideLUTD][playerid] > 0) TextDrawHideForPlayer(playerid,LevelUpTD[BackgroundLUTD][PlayerSettings[playerid][psInterfaceColor]]);
			        
			        if(PlayerSettings[playerid][psInterfaceColor] < 3) PlayerSettings[playerid][psInterfaceColor]++;
			        else PlayerSettings[playerid][psInterfaceColor] = 0;
			        
			        TextDrawShowForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
			        TextDrawShowForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
			        if(SK[playerid] > 0) TextDrawShowForPlayer(playerid,RDTD[PlayerSettings[playerid][psInterfaceColor]+2]);
			        if(HideHealTD[playerid] > 0) TextDrawShowForPlayer(playerid,HealTD[PlayerSettings[playerid][psInterfaceColor]+1]);
			        if(LevelUpTD[HideLUTD][playerid] > 0) TextDrawShowForPlayer(playerid,LevelUpTD[BackgroundLUTD][PlayerSettings[playerid][psInterfaceColor]]);
			    }
			    ShowSettingDialog(playerid);
			}
			case 6:
			{
				switch(PlayerSettings[playerid][psDateTDOff])
				{
					case false:
					{
						PlayerSettings[playerid][psDateTDOff] = true;
						TextDrawHideForPlayer(playerid,DateDisp);
					}
					case true:
					{
						PlayerSettings[playerid][psDateTDOff] = false;
						TextDrawShowForPlayer(playerid,DateDisp);
					}
				}
				ShowSettingDialog(playerid);
			}
			case 7:
			{
				switch(PlayerSettings[playerid][psTimeTDOff])
				{
					case false:
					{
						PlayerSettings[playerid][psTimeTDOff] = true;
						TextDrawHideForPlayer(playerid,TimeDisp);
					}
					case true:
					{
						PlayerSettings[playerid][psTimeTDOff] = false;
						TextDrawShowForPlayer(playerid,TimeDisp);
					}
				}
				ShowSettingDialog(playerid);
			}
			case 8:
			{
			    if(ServerSettings[ssPM] == true)
			    {
					switch(PlayerSettings[playerid][psPMOff])
					{
						case false: PlayerSettings[playerid][psPMOff] = true;
						case true: PlayerSettings[playerid][psPMOff] = false;
					}
				}
				ShowSettingDialog(playerid);
			}
			case 9:
			{
			    if(ServerSettings[ssOChat] == true)
			    {
					new string[128];
					switch(PlayerSettings[playerid][psOChatOff])
					{
						case false:
						{
							format(string,sizeof(string),"{00ff00}> {ffffff}%s покинул общий чат",GetName(playerid));
							SendOChatMessage(playerid,COLOR_WHITE,string);
							PlayerSettings[playerid][psOChatOff] = true;
						}
						case true:
						{
							PlayerSettings[playerid][psOChatOff] = false;
							format(string,sizeof(string),"{00ff00}> {ffffff}%s вернулся в общий чат",GetName(playerid));
							SendOChatMessage(playerid,COLOR_WHITE,string);
						}
					}
				}
				ShowSettingDialog(playerid);
			}
			case 10:
			{
			    if(ServerSettings[ssTeamChat] == true)
			    {
					new string[128];
					switch(PlayerSettings[playerid][psTChatOff])
					{
						case false:
						{
							format(string,sizeof(string),"{00ff00}(КОМАНДА) {ffffff}%s покинул чат команды",GetName(playerid));
							SendTeamMessage(playerid,COLOR_WHITE,string);
							PlayerSettings[playerid][psTChatOff] = true;
						}
						case true:
						{
							PlayerSettings[playerid][psTChatOff] = false;
							format(string,sizeof(string),"{00ff00}(КОМАНДА) {ffffff}%s вернулся в чат команды",GetName(playerid));
							SendTeamMessage(playerid,COLOR_WHITE,string);
						}
					}
				}
				ShowSettingDialog(playerid);
			}
			case 11:
			{
				new string[128];
				if(PlayerInfo[playerid][pVip] > 0)
				{
				    if(ServerSettings[ssVIPChat] == true)
				    {
						switch(PlayerSettings[playerid][psVIPChatOff])
						{
							case false:
							{
								format(string,sizeof(string),"{0000ff}(VIP-чат) {ffffff}%s покинул VIP чат",GetName(playerid));
								SendVipMessage(playerid,COLOR_WHITE,string);
								PlayerSettings[playerid][psVIPChatOff] = true;
							}
							case true:
							{
								PlayerSettings[playerid][psVIPChatOff] = false;
								format(string,sizeof(string),"{0000ff}(VIP-чат) {ffffff}%s вернулся в VIP чат",GetName(playerid));
								SendVipMessage(playerid,COLOR_WHITE,string);
							}
						}
					}
				}
				else if(PlayerInfo[playerid][pAdmin] > 0)
				{
					switch(PlayerSettings[playerid][psAChatOff])
					{
						case false:
						{
							format(string,sizeof(string),"{ff0000}(А-чат) {ffffff}%s покинул чат администрации",GetName(playerid));
							SendAdminMessage(COLOR_WHITE,string);
							PlayerSettings[playerid][psAChatOff] = true;
						}
						case true:
						{
							PlayerSettings[playerid][psAChatOff] = false;
							format(string,sizeof(string),"{ff0000}(А-чат) {ffffff}%s вернулся в чат администрации",GetName(playerid));
							SendAdminMessage(COLOR_WHITE,string);
						}
					}
				}
				ShowSettingDialog(playerid);
			}
			case 12:
			{
				new string[128];
				if(PlayerInfo[playerid][pAdmin] > 0)
				{
					switch(PlayerSettings[playerid][psAChatOff])
					{
						case false:
						{
							format(string,sizeof(string),"{ff0000}(А-чат) {ffffff}%s покинул чат администрации",GetName(playerid));
							SendAdminMessage(COLOR_WHITE,string);
							PlayerSettings[playerid][psAChatOff] = true;
						}
						case true:
						{
							PlayerSettings[playerid][psAChatOff] = false;
							format(string,sizeof(string),"{ff0000}(А-чат) {ffffff}%s вернулся в чат администрации",GetName(playerid));
							SendAdminMessage(COLOR_WHITE,string);
						}
					}
					ShowSettingDialog(playerid);
				}
			}
		}
	}
	case 10:
	{
	if(!response) return cmd::menu(playerid,"");
	switch(listitem)
	{
	case 0: ShowPlayerDialog(playerid,11,DIALOG_STYLE_MSGBOX, "Общее","Еще в разработке","Закрыть","Назад");
	case 1: ShowPlayerDialog(playerid,11,DIALOG_STYLE_MSGBOX,"Звания и рейтинг","На Гонке Вооружений присутствует система званий и рейтинга.\nВсего в игре 5 групп званий по 5 званий в каждой (всего 25).\nЗвание выдается после трех игр и впоследствии может повышаться, либо понижаться, в зависимости от Вашей игры.\nРейтинг же накапливается с самого начала игры и представляет собой число, отражающее Ваш опыт игры.\nЗвание и рейтинг отображаются в статистике игрока", "Закрыть","Назад");
	case 2: ShowPlayerDialog(playerid, 11, DIALOG_STYLE_MSGBOX, "Оружие и уровни","В игре оружие напрямую зависит от уровня игрока.\nЧем выше ваш уровень, тем мощнее Ваше оружие.\nЧтобы перейти на следующий уровень, необходимо совершить два убийства, либо одно убийство кулаком.\nДве помощи (ассиста) приравниваются к одному убийству.\nАссист выдается, кога Вы нанесли большое кол-во урона (больше всех), но убийцей оказались не Вы.", "Закрыть", "Назад");
	case 3: ShowPlayerDialog(playerid,11,DIALOG_STYLE_MSGBOX,"Виды связи","В игре существует несколько видов связи:\n\nОбщий чат [по умолчанию] - всеобщий чат всех игроков сервера\nКомандный чат [/t(eam)] - чат Вашей команды\nЛичные сообщения [/pm] - персональные сообщения игроку\n\n/block - заблокировать все виды связи с конкретным игроком (вы не будете видеть его сообщения ни в одном из чатов)","Закрыть","Назад");
	case 4: ShowPlayerDialog(playerid,11,DIALOG_STYLE_MSGBOX,"Полезные команды","Так же на сервере имеются вспомогательные команды. Вот некоторые из них:\n\n/help - помощь по игре\n/info - информация о создателях\n/changeteam - сменить команду\n/healme - пополнить здоровье\n/vipinfo - информация о VIP\n/leaders - лидеры сервера\n/team - чат команды\n/id - узнать ID по нику\n/menu - меню игрока\n/time - дата и время\n/players - список игроков","Закрыть","Назад");
	case 5: ShowPlayerDialog(playerid, 11, DIALOG_STYLE_MSGBOX,"Различные модификации","Игровой мод динамичен, поэтому поддерживает\nизменение различных параметров.\nНапример: кол-во уровней, макс.ехр, макс.ассист и так далее\nСостояние всех папаметров Вы можете увидеть, использовав:\n/menu (Клавиша ALT) - Игровые настройки","Закрыть","Назад");
	// Диалог помощи по игровому процессу
	}
	}
	case 11:
	{
		if(!response) return cmd_help(playerid,"");
	}
   	case 13:
   	{
   	    if(!response) cmd::menu(playerid,"");
   	    WatchTime[playerid] = false;
   	}
   	case 14:
   	{
   	    // Server Config Dialog
   	    if(PlayerInfo[playerid][pAdmin] < 7) return true;
   	    new string[300];
   	    if(!response)
	   	{
		   ChangingVar[playerid] = -1;
		   return true;
		}
   	    switch(listitem)
   	    {
   	        case 0:
   	        {
   	            switch(ServerSettings[ssAntiCheat])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssAntiCheat] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил античит",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssAntiCheat] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил античит",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
   	        }
   	        case 1:
   	        {
				ChangingVar[playerid] = 1;
				format(string,sizeof(string),"Вы изменяете параметр автобаланса команд.\n\nДоступные значения:\n1-5 - допустимое приемущество в количестве игроков одной команды над другой\n\n0 - отключение автобаланса команд\n\nТекущее значение параметра: %d\nВведите свое значение:",ServerSettings[ssAutoteambalance]);
				ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Балансировка команд - Панель конфигурации сервера",string,"Далее","Назад");
			}
			case 2:
			{
   	            switch(ServerSettings[ssTeamfire])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssTeamfire] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил огонь по своим",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                    foreach(Player,i)
   	                    {
   	                        if(PlayerTeam[playerid] == 1 || PlayerTeam[playerid] == 2) SetPlayerTeam(playerid,PlayerTeam[playerid]);
   	                    }
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssTeamfire] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил огонь по своим",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                    foreach(Player,i)
   	                    {
   	                        SetPlayerTeam(playerid,NO_TEAM);
   	                    }

   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 3:
			{
   	            switch(ServerSettings[ssAntiAFK])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssAntiAFK] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил Анти-АФК",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssAntiAFK] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил Анти-АФК",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 4:
			{
   	            switch(ServerSettings[ssHeadshots])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssHeadshots] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил двойной урон при попадании в голову",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssHeadshots] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил двойной урон при попадании в голову",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
   			case 5:
   	        {
				ChangingVar[playerid] = 5;
				format(string,sizeof(string),"Вы изменяете количество уровней.\n\nДоступные значения:\n3-14 - количество игровых уровней\n\nВНИМАНИЕ: Новое значение обязательно должно быть больше, чем уровень лидера игры!\n\nТекущее количество уровней: %d\nВведите свое значение:",ServerSettings[ssLevels]+1);
				ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество уровней - Панель конфигурации сервера",string,"Далее","Назад");
			}
   			case 6:
   	        {
				ChangingVar[playerid] = 6;
				format(string,sizeof(string),"Вы изменяете количество EXP ля поднятия уровня.\n\nДоступные значения:\n1-5 - количество EXP, необходимых для поднятия одного уровня\n\nТекущее количество EXP для поднятия: %d\nВведите свое значение:",ServerSettings[ssExpNeed]);
				ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество EXP - Панель конфигурации сервера",string,"Далее","Назад");
			}
   			case 7:
   	        {
				ChangingVar[playerid] = 7;
				format(string,sizeof(string),"Вы изменяете количество ассистов ля поднятия EXP.\n\nДоступные значения:\n1-5 - количество ассистов, необходимых для поднятия одного EXP\n\nТекущее количество ассистов для поднятия: %d\nВведите свое значение:",ServerSettings[ssAssists]);
				ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество ассистов - Панель конфигурации сервера",string,"Далее","Назад");
			}
			case 8:
			{
   	            switch(ServerSettings[ssLevelCompensation])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssLevelCompensation] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил компенсацию уровня",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssLevelCompensation] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил компенсацию уровня",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 9:
			{
   	            switch(ServerSettings[ssProgressBackup])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssProgressBackup] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил восстановление прогресса",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssProgressBackup] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил восстановление прогресса",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 10:
			{
   	            switch(ServerSettings[ssOChat])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssOChat] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил общий чат",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssOChat] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил общий чат",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 11:
			{
   	            switch(ServerSettings[ssVIPChat])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssVIPChat] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил чат VIP игроков",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssVIPChat] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил чат VIP игроков",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 12:
			{
   	            switch(ServerSettings[ssTeamChat])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssTeamChat] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил командные чаты",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssTeamChat] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил командные чаты",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 13:
			{
   	            switch(ServerSettings[ssPM])
   	            {
   	                case true:
   	                {
   	                    ServerSettings[ssPM] = false;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил личные сообщения",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
   	                case false:
   	                {
   	                    ServerSettings[ssPM] = true;
   	                    format(string,sizeof(string),"{0000ff}> {ffffff}%s %s включил личные сообщения",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
   	                }
				}
    			SendClientMessageToAll(COLOR_WHITE,string);
       			ShowConfigDialog(playerid);
			}
			case 14:
			{
			    // Изменение оружия по уровням
                ShowLevelWeaponsMenu(playerid);
			}
			case 15:
			{
				ChangingVar[playerid] = 15;
				ShowPlayerDialog(playerid,15,DIALOG_STYLE_MSGBOX,"Сброс настроек - Панель конфигурации сервера","Вы точно хотите сбросить все настройки сервера?\n\nВНИМАНИЕ: Отменить данное действие невозможно!","Да","Нет");
			}
   	    }
   	}
   	case 15:
   	{
   	    if(PlayerInfo[playerid][pAdmin] < 7) return true;
   	    if(!response)
   	    {
		   ShowConfigDialog(playerid);
		   ChangingVar[playerid] = -1;
		   return true;
		}
		if(ChangingVar[playerid] == -1) return ShowConfigDialog(playerid);
		new string[300];
		switch(ChangingVar[playerid])
		{
			case 1:
			{
			    new entervar = strval(inputtext);
				if(entervar < 0 || entervar > 5)
				{
					format(string,sizeof(string),"Вы ввели недопутимое значение.\n\nДоступные значения:\n1-5 - допустимое приемущество в количестве игроков одной команды над другой\n\n0 - отключение автобаланса команд\n\nТекущее значение параметра: %d\nВведите свое значение:",ServerSettings[ssAutoteambalance]);
					ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Балансировка команд - Панель конфигурации сервера",string,"Далее","Назад");
					return true;
				}
				if(ServerSettings[ssAutoteambalance] != entervar)
				{
					if(ServerSettings[ssAutoteambalance] > 0 && entervar == 0) format(string,sizeof(string),"{0000ff}> {ffffff}%s %s отключил балансировку команд",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),entervar);
					else if(ServerSettings[ssAutoteambalance] == 0 && entervar > 0) format(string,sizeof(string),"{0000ff}> {ffffff}%s %s вкоючил автобаланс с допутимым перевесом игроков одной команды в %d игрока(ов)",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),entervar);
					else format(string,sizeof(string),"{0000ff}> {ffffff}%s %s установил допустимый перевес игроков одной команды в %d игрока(ов)",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid), strval(inputtext));
					SendClientMessageToAll(COLOR_WHITE,string);
				}
				ServerSettings[ssAutoteambalance] = entervar;
			}
			case 5:
			{
			    new entervar = strval(inputtext);
				if(entervar < 3 || entervar > 14 || entervar >= BestScore)
				{
					format(string,sizeof(string),"Вы ввели недопутимое значение.\n\nДоступные значения:\n3-14 - количество игровых уровней\n\nВНИМАНИЕ: Новое значение обязательно должно быть больше, чем уровень лидера игры!\n\nТекущее количество уровней: %d\nВведите свое значение:",ServerSettings[ssLevels]+1);
					ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество уровней - Панель конфигурации сервера",string,"Далее","Назад");
					return true;
				}
				if(entervar != ServerSettings[ssLevels])
				{
					format(string,sizeof(string),"{0000ff}> {ffffff}%s %s изменил количество уровней на %d",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),entervar);
					SendClientMessageToAll(COLOR_WHITE,string);
				}
				ServerSettings[ssLevels] = entervar-1;
				foreach(Player,i)
				{
				    UpdateLevelTD(i);
				}
			}
			case 6:
			{
			    new entervar = strval(inputtext);
				if(entervar < 1 || entervar > 5)
				{
					format(string,sizeof(string),"Вы ввели недопутимое значение.\n\nДоступные значения:\n1-5 - количество EXP, необходимых для поднятия одного уровня\n\nТекущее количество EXP для поднятия: %d\nВведите свое значение:",ServerSettings[ssLevels]);
					ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество EXP - Панель конфигурации сервера",string,"Далее","Назад");
					return true;
				}
				if(entervar != ServerSettings[ssExpNeed])
				{
					format(string,sizeof(string),"{0000ff}> {ffffff}%s %s изменил количество EXP на %d",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),entervar);
					SendClientMessageToAll(COLOR_WHITE,string);
				}
				ServerSettings[ssExpNeed] = entervar;
				foreach(Player,i)
				{
				    while(KillScore[i] >= ServerSettings[ssExpNeed])
					{
					    KillScore[i]-=ServerSettings[ssExpNeed];
					    LevelUp(i);
					}
					UpdateExpTD(i);
				}
			}
			case 7:
			{
			    new entervar = strval(inputtext);
				if(entervar < 1 || entervar > 5)
				{
					format(string,sizeof(string),"Вы ввели недопутимое значение.\n\nДоступные значения:\n1-5 - количество ассистов, необходимых для поднятия одного EXP\n\nТекущее количество ассистов для поднятия: %d\nВведите свое значение:",ServerSettings[ssLevels]);
					ShowPlayerDialog(playerid,15,DIALOG_STYLE_INPUT,"Количество ассистов - Панель конфигурации сервера",string,"Далее","Назад");
					return true;
				}
				if(entervar != ServerSettings[ssAssists])
				{
					format(string,sizeof(string),"{0000ff}> {ffffff}%s %s изменил количество ассистов на %d",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),entervar);
					SendClientMessageToAll(COLOR_WHITE,string);
				}
				ServerSettings[ssAssists] = entervar;
				foreach(Player,i)
				{
				    while(Assists[i] >= ServerSettings[ssAssists])
					{
					    Assists[i]-=ServerSettings[ssAssists];
					    KillScore[i]++;
					    if(KillScore[i] >= ServerSettings[ssExpNeed])
					    {
					    	LevelUp(i);
						}
					}
					UpdateExpTD(i);
				}
			}
			case 14:
			{
				ResetServerSettings();
				format(string,sizeof(string),"{0000ff}> {ffffff}%s %s восстановил стандартные настройки сераера",GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid));
				SendClientMessageToAll(COLOR_WHITE,string);
				foreach(Player,i)
				{
				    SetPlayerTeam(i,NO_TEAM);
				    while(Assists[i] >= ServerSettings[ssAssists])
				    {
					    Assists[i]-=ServerSettings[ssAssists];
					    KillScore[i]++;
				    }
				    while(KillScore[i] >= ServerSettings[ssExpNeed])
					{
					    KillScore[i]-=ServerSettings[ssExpNeed];
					    LevelUp(i);
					}
					UpdateExpTD(i);
				    UpdateLevelTD(i);
				}
			}
		}
		ChangingVar[playerid] = -1;
		ShowConfigDialog(playerid);
   	}
	case 16:
	{
	    if(!response) return ShowConfigDialog(playerid);
	    new string[64];
		format(string,sizeof(string),"Выбор оружмя для %d уровня",listitem+1);
	 	ChangingLevel[playerid] = listitem;
        ShowPlayerDialog(playerid,17,DIALOG_STYLE_LIST,string,"Silenced Pistol\nDual Pistols\nDesert Eagle\nShotgun\nSawn-off Shotgun\nCombat Shotgun\nMicro SMG\nTec-9\nMP5\nAK-47\nM4A1\nCountry Rifle\nSniper Rifle","Далее","Назад");

	}
	case 17:
	{
	    if(!response) return ShowLevelWeaponsMenu(playerid);
	    if(listitem > sizeof(DefaultLevelWeapons)) return true;
	    new string[128];
	    LevelWeapons[ChangingLevel[playerid]] = DefaultLevelWeapons[listitem];
	    format(string,sizeof(string),"{0000ff}Уровни {ffffff}> Оружие %d уровня изменено на %s",ChangingLevel[playerid]+1,GetGunName(DefaultLevelWeapons[listitem]));
	    SendClientMessageToAll(COLOR_WHITE,string);
	    foreach(Player,i)
	    {
	        if(GunLevel[i] == ChangingLevel[playerid])
	        {
	            LevelUpDelay[i] = true;
	            ReloadWeapons(i);
	            UpdateLevelTD(i);
	            if(PlayerSpawned[i] == true) UpdateInformer(i);
	        }
	    }
	    ShowLevelWeaponsMenu(playerid);
	}
	}
	return true;
}
forward OneSecondTimer();
public OneSecondTimer()
{
	new string[128];
	foreach(Player,i)
	{
		if(SK[i] > 0)
		{
			SK[i]--;
			if(PlayerSettings[i][psSInterface] == false)
			{
				format(string,sizeof(string),"%d",SK[i]);
				TextDrawSetString(RDTimeTD[i], string);
			}
			else
			{
				format(string,sizeof(string),"Returning in %d seconds",SK[i]);
				GameTextForPlayer(i, string, 1000,6);
			}
			if(SK[i] == 0)
			{
				SetPlayerHealth(i,100.0);
				SetPlayerVirtualWorld(i,0);
				SendClientMessage(i, COL_GREEN, "Вы возвращены в игру!");
				if(PlayerSettings[i][psSInterface] == false)
				{
					TextDrawHideForPlayer(i,RDTD[0]);
					TextDrawHideForPlayer(i,RDTD[1]);
					TextDrawHideForPlayer(i,RDTD[PlayerSettings[i][psInterfaceColor]+2]);
					TextDrawHideForPlayer(i,RDTimeTD[i]);
				}
				else GameTextForPlayer(i,"Go!",1000,6);
				TogglePlayerControllable(i,1);
				switch(PlayerTeam[i])
				{
					case 1: SetPlayerColor(i,COL_RED);
					case 2: SetPlayerColor(i,COLOR_BLUE);
				}
				PlayerSpawned[i] = true;
				foreach(Player,x)
				{
					if(PlayerSpectating[x] == i && PlayerTeam[x] == 3)
					{
						PlayerSpectatePlayer(x,i);
					}
				}
			}
		}
		foreach(Player,id)
    	{
	        if(id != i && PlayerSpawned[id] == true)
			{
		        if(PlayerTeam[i] == PlayerTeam[id])
		        {
			        switch(PlayerTeam[i])
			        {
				        case 1:
						{
							SetPlayerMarkerForPlayer(id,i,COL_RED);
							SetPlayerMarkerForPlayer(i,id,COL_RED);
						}
				        case 2:
						{
			                SetPlayerMarkerForPlayer(id,i,COLOR_BLUE);
							SetPlayerMarkerForPlayer(i,id,COLOR_BLUE);
						}
			        }
				}
				else
				{
			        switch(PlayerTeam[i])
			        {
				        case 1:
						{
							SetPlayerMarkerForPlayer(id,i,COL_RED_INVIS);
							SetPlayerMarkerForPlayer(i,id,COLOR_BLUE_INVIS);
						}
				        case 2:
						{
			                SetPlayerMarkerForPlayer(id,i,COLOR_BLUE_INVIS);
							SetPlayerMarkerForPlayer(i,id,COL_RED_INVIS);
						}
			        }
				}
			}
	    }
		if(PlayerInfo[i][pMute] > 0)PlayerInfo[i][pMute]--;
		if(AntiFlood[i] > 0) AntiFlood[i]--;
		if(ReportChat[i] > 0) ReportChat[i]--;
		if(PlayerInfo[i][pVip] > 0) PlayerInfo[i][pVip]--;
		if(InformerUpdate[i] > 0)
		{
			InformerUpdate[i]--;
		    if(InformerUpdate[i] <= 0)
			{
				UpdateInformer(i);
			    Update3DTextLabelText(PlayerStatus[i],COLOR_WHITE,"");
		    }
		}
		if(PlayerGiveDamage[i] > 0)
		{
		    new bool:changed;
		    foreach(Player,x)
		    {
		        if(DamageSeries[x][i][dsHideTimeGive] > 0)
		        {
		            DamageSeries[x][i][dsHideTimeGive]--;
					if(DamageSeries[x][i][dsHideTimeGive] == 0)
					{
					    DamageSeries[x][i][dsDamage] = 0.0;
					    DamageSeries[x][i][dsCombo] = 0;
					    DamageSeries[x][i][dsWeapon] = -1;
					    PlayerGiveDamage[i]--;
					    changed = true;
					}
		        }
		    }
			if(PlayerGiveDamage[i] == 0)
			{
			    TextDrawHideForPlayer(i,HealthTD_G[i]);
			    TextDrawSetString(HealthTD_G[i],"");
			}
			else if(changed == true)
			{
			    new updater[500];
				foreach(Player,x)
				{
				    if(DamageSeries[i][x][dsDamage] > 0.0)
				    {
				        format(updater, sizeof(updater), "%s%s // -%d HP // %s~n~",updater,GetName(x), floatround(DamageSeries[i][x][dsDamage]), GetGunName(DamageSeries[i][x][dsWeapon]));
				    }
				}
				TextDrawSetString(HealthTD_G[i],updater);
			}
		}
		if(PlayerTakeDamage[i] > 0)
		{
		    new bool:changed;
		    foreach(Player,x)
		    {
		        if(DamageSeries[i][x][dsHideTimeTake] > 0)
		        {
		            DamageSeries[i][x][dsHideTimeTake]--;
					if(DamageSeries[i][x][dsHideTimeTake] == 0)
					{
					    DamageSeries[i][x][dsDamage] = 0.0;
					    DamageSeries[i][x][dsCombo] = 0;
					    DamageSeries[i][x][dsWeapon] = -1;
					    PlayerTakeDamage[i]--;
					    changed = true;
					}
		        }
		    }
			if(PlayerTakeDamage[i] == 0)
			{
			    TextDrawHideForPlayer(i,HealthTD_R[i]);
			    TextDrawSetString(HealthTD_R[i],"");
	    		Update3DTextLabelText(PlayerStatus[i],COLOR_WHITE,"");
				UpdateInformer(i);
			}
			else if(changed == true)
			{
			    new updater[1000];
				foreach(Player,x)
				{
				    if(DamageSeries[x][i][dsDamage] > 0.0)
				    {
				        format(updater, sizeof(updater), "%s%s // -%d HP // %s~n~",updater,GetName(x), floatround(DamageSeries[x][i][dsDamage]), GetGunName(DamageSeries[x][i][dsWeapon]));
				    }
				}
				TextDrawSetString(HealthTD_G[i],updater);
				switch(PlayerTeam[i])
				{
					case 1: format(updater,sizeof(updater), "{FF0000}%s - Террорист{ffffff}\n\n",GetName(i));
					case 2: format(updater,sizeof(updater), "{0000FF}%s - Спецназовец{ffffff}\n\n",GetName(i));
				}
				foreach(Player,x)
				{
				    if(DamageSeries[i][x][dsDamage] > 0.0)
				    {
					    switch(PlayerTeam[x])
					    {
							case 1: format(updater,sizeof(updater),"%s{ff0000}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(x),floatround(Float:DamageSeries[i][x][dsDamage], floatround_ceil), GetGunName(DamageSeries[i][x][dsWeapon]));
							case 2: format(updater,sizeof(updater),"%s{0000ff}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(x),floatround(Float:DamageSeries[i][x][dsDamage], floatround_ceil), GetGunName(DamageSeries[i][x][dsWeapon]));
						}
					}
				}
				Update3DTextLabelText(PlayerStatus[i],COLOR_WHITE,updater);
			}
		}
		if(HideHealTD[i] > 0)
		{
		    HideHealTD[i]--;
		    if(HideHealTD[i] <= 0)
		    {
			    TextDrawHideForPlayer(i,HealAmountTD[i]);
			    TextDrawHideForPlayer(i,HealTD[0]);
			    TextDrawHideForPlayer(i,HealTD[PlayerSettings[i][psInterfaceColor]+1]);
		    }
		}
		if(LevelUpTD[HideLUTD][i] > 0)
		{
		    LevelUpTD[HideLUTD][i]--;
		    if(LevelUpTD[HideLUTD][i] <= 0)
		    {
			    TextDrawHideForPlayer(i,LevelUpTD[TextLUTD][i]);
			    TextDrawHideForPlayer(i,LevelUpTD[TopicLUTD]);
			    TextDrawHideForPlayer(i,LevelUpTD[BackgroundLUTD][PlayerSettings[i][psInterfaceColor]]);
			    TextDrawHideForPlayer(i,LevelUpTD[ModelLUTD][GetGunTD(LevelWeapons[GunLevel[i]])]);
		    }
		}
		if(HideHPTD[i][HideMinusHPTD] > 0)
		{
		    HideHPTD[i][HideMinusHPTD]--;
		    if(HideHPTD[i][HideMinusHPTD] <= 0)
		    {
		        TextDrawHideForPlayer(i,HPTD[i][MinusHPTD]);
		    }
		}
		if(HideHPTD[i][HidePlusHPTD] > 0)
		{
		    HideHPTD[i][HidePlusHPTD]--;
		    if(HideHPTD[i][HidePlusHPTD] <= 0)
		    {
		        TextDrawHideForPlayer(i,HPTD[i][PlusHPTD]);
		    }
		}
		if(LDIOn[i] == true)
		{
		    format(string,sizeof(string),"Место Вашей предыдущей смерти\nРасстояние: {ffff99}%.0f {ffffff}метров",GetPlayerDistanceFromPoint(i,DeathCoords[i][posX],DeathCoords[i][posY],DeathCoords[i][posZ]));
		    UpdatePlayer3DTextLabelText(i,LDI3DText[i],COLOR_WHITE,string);
		}
		if(WatchTime[i] == true)
		{
			new sstring[300];
			new year, month, day;
			getdate(year, month, day);
			new minuite,second, hour;
			gettime(hour,minuite,second);
			format(sstring, sizeof(sstring), "Гонка Вооружений - Сервер 1\n\nДата - %d %s %d года\nВремя - %02d часов %02d минут %02d секунд\nТекущая карта - %s (ID: %d)\nИгроков онлайн: %d (T: %d | CT: %d | SPEC: %d)", day, GetMonthNameRus(month), year, hour, minuite, second, MapNames[Map], Map, GetOnline(), GetTeamOnline(1), GetTeamOnline(2), GetTeamOnline(3));
			ShowPlayerDialog(i,13,DIALOG_STYLE_MSGBOX,"Дата и время",sstring,"Закрыть","Назад");
		}
		if(GetPlayerWeapon(i) != LevelWeapons[GunLevel[i]] && GetPlayerWeapon(i) != 0 && PlayerSpawned[i] == true && LevelUpDelay[i] == false && GunLevel[i] < ServerSettings[ssLevels] && ServerSettings[ssAntiCheat] == true)
		{
		    format(string,sizeof(string),"%s был кикнут за использование чита на оружие (LvL: %d | Оружие: %s)",GetName(i),GunLevel[i]+1,GetGunName(GetPlayerWeapon(i)));
			SendClientMessageToAll(COLOR_LIGHTRED,string);
			KickEx(i,COLOR_LIGHTRED,"Античит: Вы были кикнуты за использование чита на оружие!");
		}
		if(LevelUpDelay[i] == true) LevelUpDelay[i] = false;
	}
	if(GameStarted == true)
	{
		GameSeconds++;
		if(GameSeconds >= 60)
		{
			GameSeconds -= 60;
			GameMinutes++;
		}
	}
	if(TKPlus1_Time[0] > 0)
	{
	    TKPlus1_Time[0]--;
	    if(TKPlus1_Time[0] == 0) TextDrawHideForAll(TKPlus1[0]);
	}
	if(TKPlus1_Time[1] > 0)
	{
	    TKPlus1_Time[1]--;
	    if(TKPlus1_Time[1] == 0) TextDrawHideForAll(TKPlus1[1]);
	}
	AFKCheck();
	return true;
}
public OnPlayerText(playerid, text[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return false;
	if(ServerSettings[ssOChat] == false)
	{
		SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Общий чат был отключен администрацией сервера!");
		return false;
	}
	if(PlayerSettings[playerid][psOChatOff] == true)
	{
		SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы покинули общий чат!");
		return false;
	}
//	if(PlayerTeam[playerid] == 3) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Недоступно для наблюдателей!");
	new string[144];
	if(PlayerInfo[playerid][pMute] >= 1)
	{
		format(string,sizeof(string),"{ff0000}Ошибка{ffffff} > У вас бан чата! Снятие через {ff0000}%d {ffffff}секунд!",PlayerInfo[playerid][pMute]);
		SendClientMessage(playerid,COLOR_WHITE,string);
		return false;
	}
	if(AntiFlood[playerid] > 0)
	{
		format(string,sizeof(string),"Анти-флуд: Ты сможешь написать следующее сообщение через {ffff99}%d {ffffff}секунд!",AntiFlood[playerid]);
		SendClientMessage(playerid,COLOR_WHITE,string);
		return false;
	}
	if(PlayerInfo[playerid][pVip] >= 1 && PlayerInfo[playerid][pAdmin] == 0)
	{
		if(PlayerTeam[playerid] == 1) format(string,144,"< {FFCC33}VIP{FFFFFF} | {ff0000}T {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		else if(PlayerTeam[playerid] == 2) format(string,144,"< {FFCC33}VIP{FFFFFF} | {0000ff}CT {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		else format(string,144,"< {FFCC33}VIP{FFFFFF} | {00ff00}SPEC {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		SendOChatMessage(playerid,COL_WHITE,string);
		AntiFlood[playerid] = 5;
		new query[512], year,month,day,hour,minute,second,timestamp;
		getdate(year,month,day);
		gettime(hour,minute,second);
		timestamp = date_to_timestamp(year,month,day,hour,minute,second);
		mysql_format(connectionHandle, query, "INSERT INTO `ochatlog` (`SenderName`, `SenderID`, `SenderTeam`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '%s', '%d')",
		 GetName(playerid),PlayerInfo[playerid][pID],PlayerTeam[playerid],text,timestamp);
		mysql_query(query, -1, 0, connectionHandle);
		return false;
	}
	if(PlayerInfo[playerid][pAdmin] > 0)
	{
		
		switch(PlayerInfo[playerid][pAdmin])
		{
			case 1:format(string,144,"< {F81414}М 1 ур. {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 2:format(string,144,"< {F81414}М 2 ур. {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 3:format(string,144,"< {F81414}М 3 ур. {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 4:format(string,144,"< {F81414}Гл.М {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 5:format(string,144,"< {F81414}А {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 6:format(string,144,"< {F81414}Гл.А {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
			case 7:format(string,144,"< {F81414}О {FFFFFF}> %s[%d]: %s",GetName(playerid),playerid,text);
		}
		SendOChatMessage(playerid,COL_WHITE,string);
 		new query[512], year,month,day,hour,minute,second,timestamp;
		getdate(year,month,day);
		gettime(hour,minute,second);
		timestamp = date_to_timestamp(year,month,day,hour,minute,second);
		mysql_format(connectionHandle, query, "INSERT INTO `ochatlog` (`SenderName`, `SenderID`, `SenderTeam`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '%s', '%d')",
		 GetName(playerid),PlayerInfo[playerid][pID],PlayerTeam[playerid],text,timestamp);
		mysql_query(query, -1, 0, connectionHandle);
		return false;
	}
	else
	{
		if(PlayerTeam[playerid] == 1) format(string,144,"< {ff0000}T {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		else if(PlayerTeam[playerid] == 2) format(string,144,"< {0000ff}CT {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		else format(string,144,"< {00ff00}SPEC {ffffff}> %s[%d]: %s",GetName(playerid),playerid,text);
		SendOChatMessage(playerid,COL_WHITE,string);
		AntiFlood[playerid] = 10;
		new query[512], year,month,day,hour,minute,second,timestamp;
		getdate(year,month,day);
		gettime(hour,minute,second);
		timestamp = date_to_timestamp(year,month,day,hour,minute,second);
		mysql_format(connectionHandle, query, "INSERT INTO `ochatlog` (`SenderName`, `SenderID`, `SenderTeam`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '%s', '%d')",
		 GetName(playerid),PlayerInfo[playerid][pID],PlayerTeam[playerid],text,timestamp);
		mysql_query(query, -1, 0, connectionHandle);
		return false;
	}
/*	if(PlayerInfo[playerid][pVip] >= 1 && PlayerInfo[playerid][pAdmin] > 0 && PlayerTeam[playerid] == 2){format(string,100,"{FFCC33}[VIP]{FF0000}[Админ] %s[%d]: {FFFFFF}%s",GetName(playerid),playerid,text);SendClientMessageToAll(COL_WHITE,string);return false;}
	if(PlayerInfo[playerid][pAdmin] > 0 && PlayerTeam[playerid] == 1){format(string,100,"{F81414}< A > %s[%d]: {FFFFFF}%s",GetName(playerid),playerid,text);SendClientMessageToAll(COL_WHITE,string);return false;}
	if(PlayerInfo[playerid][pAdmin] > 0 && PlayerTeam[playerid] == 2){format(string,100,"{FFCC33} < Админ > %s[%d]: {FFFFFF}%s",GetName(playerid),playerid,text);SendClientMessageToAll(COL_WHITE,string);return false;} */
//	return true;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    if(damagedid == INVALID_PLAYER_ID) return 1;
    if(ServerSettings[ssTeamfire] == false && PlayerTeam[playerid] == PlayerTeam[damagedid]) return true;
   	if(PlayerTeam[playerid] == PlayerTeam[damagedid]) SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Внимание {ffffff}> Старайтесь не ранить товарищей по команде!");
 	PlayerGoodShots[playerid]++;
 	PlayerInfo[playerid][pGoodShots]++;
  	AllGoodShots++;
	Damage[damagedid][playerid][gShots]++;
  	new updater[1000];
    if(bodypart == 9 && ServerSettings[ssHeadshots] == true) // Headshot
    {
		new Float:health;
		GetPlayerHealth(damagedid,health);
		SetPlayerHealth(damagedid,health-amount*2);
		Damage[damagedid][playerid][gTaken]+=amount*2;
		PlayerInfo[playerid][pDamageGiven] += floatround(amount*2, floatround_ceil);
		PlayerInfo[damagedid][pDamageTaken] += floatround(amount*2, floatround_ceil);
		DamageGiven[playerid] += floatround(amount*2, floatround_ceil);
		DamageTaken[damagedid] += floatround(amount*2, floatround_ceil);
		DamageSeries[damagedid][playerid][dsDamage]+=amount*2;
        DamageSeries[damagedid][playerid][dsCombo]++;
        DamageSeries[damagedid][playerid][dsWeapon]=weaponid;
        if(DamageSeries[damagedid][playerid][dsHideTimeGive] == 0) PlayerGiveDamage[damagedid]++;
		if(DamageSeries[playerid][damagedid][dsHideTimeTake] == 0) PlayerTakeDamage[playerid]++;
		DamageSeries[damagedid][playerid][dsHideTimeTake] = 3;
		DamageSeries[playerid][damagedid][dsHideTimeGive] = 3;
		// ==========
		switch(PlayerTeam[damagedid])
		{
			case 1: format(updater,sizeof(updater), "{FF0000}%s - Террорист{ffffff}\n\n",GetName(damagedid));
			case 2: format(updater,sizeof(updater), "{0000FF}%s - Спецназовец{ffffff}\n\n",GetName(damagedid));
		}
		foreach(Player,i)
		{
		    if(DamageSeries[damagedid][i][dsDamage] > 0.0)
		    {
		        if(i == playerid)
				{
					switch(PlayerTeam[i])
					{
						case 1: format(updater,sizeof(updater),"%s{ff0000}%s {ffffff}// -{ffff99}%d{ffffff} HP (-{ffff99}%d {ffffff}HP - {ffff99}HS{ffffff}) // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil),floatround(Float:amount*2, floatround_ceil),GetGunName(DamageSeries[damagedid][i][dsWeapon]));
						case 2: format(updater,sizeof(updater),"%s{0000ff}%s {ffffff}// -{ffff99}%d{ffffff} HP (-{ffff99}%d {ffffff}HP - {ffff99}HS{ffffff}) // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil),floatround(Float:amount*2, floatround_ceil),GetGunName(DamageSeries[damagedid][i][dsWeapon]));
					}
				}
				else
				{
				    switch(PlayerTeam[i])
				    {
						case 1: format(updater,sizeof(updater),"%s{ff0000}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
						case 2: format(updater,sizeof(updater),"%s{0000ff}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
					}
				}
			}
		}
		Update3DTextLabelText(PlayerStatus[damagedid],COLOR_WHITE,updater);
		Update3DTextLabelText(PlayerInformer[damagedid],COLOR_WHITE,"");
		// =========
		if(PlayerSettings[playerid][psDInfoOff] == false)
		{
			format(updater, sizeof(updater), "%s // -%d HP (-%d HP - HS) // %s",GetName(damagedid), floatround(DamageSeries[damagedid][playerid][dsDamage]),floatround(Float:amount*2, floatround_ceil), GetGunName(weaponid));
			foreach(Player,i)
			{
			    if(DamageSeries[i][playerid][dsDamage] > 0.0 && i != damagedid && i != playerid)
			    {
			        format(updater, sizeof(updater), "%s~n~%s // -%d HP // %s",updater,GetName(i), floatround(DamageSeries[i][playerid][dsDamage]), GetGunName(DamageSeries[i][playerid][dsWeapon]));
			    }
			}
			TextDrawSetString(HealthTD_G[playerid],updater);
			TextDrawShowForPlayer(playerid,HealthTD_G[playerid]);
			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		}
		if(PlayerSettings[damagedid][psDInfoOff] == false)
		{
			format(updater, sizeof(updater), "%s // -%d HP (-%d HP - HS) // %s",GetName(playerid), floatround(DamageSeries[damagedid][playerid][dsDamage]),floatround(Float:amount*2, floatround_ceil), GetGunName(weaponid));
			foreach(Player,i)
			{
			    if(DamageSeries[damagedid][i][dsDamage] > 0.0 && i != damagedid && i != playerid)
			    {
			        format(updater, sizeof(updater), "%s~n~%s // -%d HP // %s",updater,GetName(i), floatround(DamageSeries[damagedid][i][dsDamage]), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
			    }
			}
			TextDrawSetString(HealthTD_R[damagedid],updater);
			TextDrawShowForPlayer(damagedid,HealthTD_R[damagedid]);
			PlayerPlaySound(damagedid, 1057, 0.0, 0.0, 0.0);
		}
  		if(PlayerSettings[damagedid][psMonHPOff] == false)
        {
            new string[10];
			format(string,sizeof(string),"-%d",floatround(amount*2, floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MinusHPTD],string);
			TextDrawShowForPlayer(damagedid,HPTD[damagedid][MinusHPTD]);
			HideHPTD[damagedid][HideMinusHPTD] = 3;
			GetPlayerHealth(damagedid,health);
			format(string,sizeof(string),"%d HP",floatround(health,floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MonitoringHPTD],string);
        }
    }
	else
    {
		new Float:health;
		GetPlayerHealth(damagedid,health);
		SetPlayerHealth(damagedid,health-amount);
		Damage[damagedid][playerid][gTaken]+=amount;
		PlayerInfo[playerid][pDamageGiven] += floatround(amount, floatround_ceil);
		PlayerInfo[damagedid][pDamageTaken] += floatround(amount, floatround_ceil);
		DamageGiven[playerid] += floatround(amount, floatround_ceil);
		DamageTaken[damagedid] += floatround(amount, floatround_ceil);
		DamageSeries[damagedid][playerid][dsDamage]+=amount;
        DamageSeries[damagedid][playerid][dsCombo]++;
        DamageSeries[damagedid][playerid][dsWeapon]=weaponid;
		DamageSeries[damagedid][playerid][dsHideTimeTake] = 3;
		DamageSeries[playerid][damagedid][dsHideTimeGive] = 3;
		if(DamageSeries[damagedid][playerid][dsHideTimeGive] == 0) PlayerGiveDamage[damagedid]++;
		if(DamageSeries[playerid][damagedid][dsHideTimeTake] == 0) PlayerTakeDamage[playerid]++;
		// ==========
		switch(PlayerTeam[damagedid])
		{
			case 1: format(updater,sizeof(updater), "{FF0000}%s - Террорист{ffffff}\n\n",GetName(damagedid));
			case 2: format(updater,sizeof(updater), "{0000FF}%s - Спецназовец{ffffff}\n\n",GetName(damagedid));
		}
		foreach(Player,i)
		{
		    if(DamageSeries[damagedid][i][dsDamage] > 0.0)
		    {
		        if(i == playerid)
				{
					switch(PlayerTeam[i])
					{
						case 1: format(updater,sizeof(updater),"%s{ff0000}%s {ffffff}// -{ffff99}%d{ffffff} HP (-{ffff99}%d {ffffff}HP) // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil),floatround(Float:amount, floatround_ceil),GetGunName(DamageSeries[damagedid][i][dsWeapon]));
						case 2: format(updater,sizeof(updater),"%s{0000ff}%s {ffffff}// -{ffff99}%d{ffffff} HP (-{ffff99}%d {ffffff}HP) // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil),floatround(Float:amount, floatround_ceil),GetGunName(DamageSeries[damagedid][i][dsWeapon]));
					}
				}
				else
				{
				    switch(PlayerTeam[i])
				    {
						case 1: format(updater,sizeof(updater),"%s{ff0000}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
						case 2: format(updater,sizeof(updater),"%s{0000ff}%s {ffffff}// -{ffff99}%d{ffffff} HP // {ffff99}%s",updater,GetName(i),floatround(Float:DamageSeries[damagedid][i][dsDamage], floatround_ceil), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
					}
				}
			}
		}
		Update3DTextLabelText(PlayerStatus[damagedid],COLOR_WHITE,updater);
		Update3DTextLabelText(PlayerInformer[damagedid],COLOR_WHITE,"");
		// =========
		if(PlayerSettings[playerid][psDInfoOff] == false)
		{
			format(updater, sizeof(updater), "%s // -%d HP (-%d HP) // %s",GetName(damagedid), floatround(DamageSeries[damagedid][playerid][dsDamage]),floatround(Float:amount, floatround_ceil), GetGunName(weaponid));
			foreach(Player,i)
			{
			    if(DamageSeries[i][playerid][dsDamage] > 0.0 && i != damagedid && i != playerid)
			    {
			        format(updater, sizeof(updater), "%s~n~%s // - %d HP // %s",updater,GetName(i), floatround(DamageSeries[i][playerid][dsDamage]), GetGunName(DamageSeries[i][playerid][dsWeapon]));
			    }
			}
			TextDrawSetString(HealthTD_G[playerid],updater);
			TextDrawShowForPlayer(playerid,HealthTD_G[playerid]);
			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		}
		if(PlayerSettings[damagedid][psDInfoOff] == false)
		{
			format(updater, sizeof(updater), "%s // -%d HP (-%d HP) // %s",GetName(playerid), floatround(DamageSeries[damagedid][playerid][dsDamage]),floatround(Float:amount, floatround_ceil), GetGunName(weaponid));
			foreach(Player,i)
			{
			    if(DamageSeries[damagedid][i][dsDamage] > 0.0 && i != damagedid && i != playerid)
			    {
			        format(updater, sizeof(updater), "%s~n~%s // -%d HP // %s",updater,GetName(i), floatround(DamageSeries[damagedid][i][dsDamage]), GetGunName(DamageSeries[damagedid][i][dsWeapon]));
			    }
			}
			TextDrawSetString(HealthTD_R[damagedid],updater);
			TextDrawShowForPlayer(damagedid,HealthTD_R[damagedid]);
			PlayerPlaySound(damagedid, 1057, 0.0, 0.0, 0.0);
		}
  		if(PlayerSettings[damagedid][psMonHPOff] == false)
        {
            new string[10];
			format(string,sizeof(string),"-%d",floatround(amount, floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MinusHPTD],string);
			TextDrawShowForPlayer(damagedid,HPTD[damagedid][MinusHPTD]);
			HideHPTD[damagedid][HideMinusHPTD] = 3;
			GetPlayerHealth(damagedid,health);
			format(string,sizeof(string),"%d HP",floatround(health,floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MonitoringHPTD],string);
        }
    }
/*    else
    {
        new Float:health;
  		GetPlayerHealth(damagedid,health);
		SetPlayerHealth(damagedid,health-amount);
	    Damage[damagedid][playerid][gTaken]+=amount;
   		PlayerInfo[playerid][pDamageGiven] += floatround(amount, floatround_ceil);
		PlayerInfo[damagedid][pDamageTaken] += floatround(amount, floatround_ceil);
		DamageGiven[playerid] += floatround(amount, floatround_ceil);
		DamageTaken[damagedid] += floatround(amount, floatround_ceil);
		switch(PlayerTeam[damagedid])
		{
			case 1: format(updater,sizeof(updater), "{FF0000}%s - Террорист{ffffff}\n\n",GetName(damagedid));
			case 2: format(updater,sizeof(updater), "{0000FF}%s - Спецназовец{ffffff}\n\n",GetName(damagedid));
		}
		foreach(Player,i)
		{
		    if(Damage[damagedid][i][gTaken] > 0.0)
		    {
		        if(i == playerid)
				{
					switch(PlayerTeam[i])
					{
						case 1: format(updater,sizeof(updater),"%s- {ffff99}%d{ffffff} HP (- {ffff99}%d {ffffff}HP) // {ff0000}%s",updater,floatround(Float:Damage[damagedid][i][gTaken], floatround_ceil),floatround(Float:amount, floatround_ceil),GetName(i));
						case 2: format(updater,sizeof(updater),"%s- {ffff99}%d{ffffff} HP (- {ffff99}%d {ffffff}HP) // {0000ff}%s",updater,floatround(Float:Damage[damagedid][i][gTaken], floatround_ceil),floatround(Float:amount, floatround_ceil),GetName(i));
					}
				}
				else
				{
				    switch(PlayerTeam[i])
				    {
						case 1: format(updater,sizeof(updater),"%s- {ffff99}%d{ffffff} HP // {ff0000}%s",updater,floatround(Float:Damage[damagedid][i][gTaken], floatround_ceil),GetName(i));
						case 2: format(updater,sizeof(updater),"%s- {ffff99}%d{ffffff} HP // {0000ff}%s",updater,floatround(Float:Damage[damagedid][i][gTaken], floatround_ceil),GetName(i));
					}
				}
			}
		}
		Update3DTextLabelText(PlayerStatus[damagedid],COLOR_WHITE,updater);
		Update3DTextLabelText(PlayerInformer[damagedid],COLOR_WHITE,"");
		InformerUpdate[damagedid] = 3;
		// ====
  		if(OldID[playerid] != damagedid)
        {
            OldID[playerid] = damagedid;
            ComboX[playerid] = 1;
            ComboDamage[playerid] = amount;
        }
        else
        {
            ComboX[playerid] ++;
            ComboDamage[playerid] += amount;
        }
		new Float:Distance;
		Distance = GetDistanceBetweenPlayers(playerid,damagedid);
		if(PlayerSettings[playerid][psDInfoOff] == false)
		{
			TextDrawColor(HealthTD_G[playerid], 15597823);
			format(updater, sizeof(updater), "%d HP // %s // %s~n~Combo x%d // Distance %.3f",floatround(ComboDamage[playerid]), GetGunName(weaponid),GetName(damagedid),ComboX[playerid],Distance);
			TextDrawSetString(HealthTD_G[playerid],updater);
			TextDrawShowForPlayer(playerid,HealthTD_G[playerid]);
			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
			ShowingTD_G[playerid] = 3;
		}
		if(PlayerSettings[damagedid][psDInfoOff] == false)
		{
			TextDrawColor(HealthTD_R[damagedid], -871300865);
			format(updater, sizeof(updater), "%d HP // %s // %s~n~Combo x%d // Distance %.3f",floatround(ComboDamage[playerid]), GetGunName(weaponid),GetName(playerid),ComboX[playerid],Distance);
			TextDrawSetString(HealthTD_R[damagedid],updater);
			TextDrawShowForPlayer(damagedid,HealthTD_R[damagedid]);
			PlayerPlaySound(damagedid, 1057, 0.0, 0.0, 0.0);
			ShowingTD_R[damagedid] = 3;
		}
  		if(PlayerSettings[damagedid][psMonHPOff] == false)
        {
            new string[10];
			format(string,sizeof(string),"-%d",floatround(amount, floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MinusHPTD],string);
			TextDrawShowForPlayer(damagedid,HPTD[damagedid][MinusHPTD]);
			HideHPTD[damagedid][HideMinusHPTD] = 3;
			GetPlayerHealth(damagedid,health);
			format(string,sizeof(string),"%d HP",floatround(health,floatround_ceil));
			TextDrawSetString(HPTD[damagedid][MonitoringHPTD],string);
        }
    }*/
	return true;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys == KEY_FIRE && PlayerTeam[playerid] == 3 && PlayerSpectating[playerid] != 999) // Left Spec Looping
	{
	    for(new i= PlayerSpectating[playerid]-1;i>=0;i--)
	    {
	        if(!IsPlayerConnected(playerid)) continue;
	        if(i == playerid) continue;
	        if(PlayerSpectating[i] != 999) continue;
	        if(PlayerSpawned[i] == false) continue;
	        //TogglePlayerSpectating(playerid,true);
	        PlayerSpectatePlayer(playerid,i);
	        PlayerSpectating[playerid] = i;
	        return 1;
	    }
	    for(new i = MAX_PLAYERS-1; i >= 0; i--)
	    {
	        if(IsPlayerConnected(i)) continue;
	        if(i == playerid) continue;
	        if(PlayerSpectating[i] != 999) continue;
	        if(PlayerSpawned[i] == false) continue;
	        if(i == PlayerSpectating[playerid]) continue;
	        PlayerSpectatePlayer(playerid,i);
	        PlayerSpectating[playerid] = i;
	        return 1;
	    }
	}
	if(newkeys == 128 && PlayerTeam[playerid] == 3 && PlayerSpectating[playerid] != 999) // Right Spec Looping
	{
	    for(new i= PlayerSpectating[playerid]+1;i< MAX_PLAYERS;i++)
	    {
	        if(!IsPlayerConnected(playerid)) continue;
	        if(i == playerid) continue;
	        if(PlayerSpectating[i] != 999) continue;
	        if(PlayerSpawned[i] == false) continue;
	        //TogglePlayerSpectating(playerid,true);
	        PlayerSpectatePlayer(playerid,i);
	        PlayerSpectating[playerid] = i;
	        return 1;
	    }
	    foreach(Player,i)
	    {
	        if(i != playerid && PlayerSpectating[i] == 999 && PlayerSpawned[i] == true)
	        {
		        PlayerSpectatePlayer(playerid,i);
		        PlayerSpectating[playerid] = i;
		        return 1;
	        }
	    }
	}
	if(newkeys == KEY_WALK)
	{
		cmd::menu(playerid,"");
		return 1;
	}
	return true;
}


forward OnPlayerRegCheck(playerid);
public OnPlayerRegCheck(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		new rows, fields;cache_get_data(rows, fields);
		if(rows) 
		{
		ShowPlayerDialog(playerid,2,DIALOG_STYLE_PASSWORD,"Авторизация - Гонка Вооружений","Добро пожаловать на Гонку Вооружений!\nДанный сервер не похож на остальные,\nтак как он является единственным в своем жанре!\n\nНа сервере:\n* 14 уровней с различными оружиями\n* 20 красивых карт\n* Персональная статистика и система лидеров\n\nЭтот аккаунт зарегистрирован!\n\nВведите пароль:","Вход","Отмена");
		SendClientMessage(playerid,COLOR_WHITE,"Добро пожаловать на сервер {ffff99}Гонка Вооружений!{ffffff} Этот аккаунт {00ff00}зарегистрирован {ffffff}на сервере!");
		}
		else
		{ 
		ShowPlayerDialog(playerid,1,DIALOG_STYLE_INPUT,"Регистрация - Гонка Вооружений","Добро пожаловать на Гонку Вооружений!\nДанный сервер не похож на остальные,\nтак как он является единственным в своем жанре!\n\nНа сервере:\n* 14 уровней с различными оружиями\n* 20 красивых карт\n* Персональная статистика и система лидеров\n\nЭтот аккаунт не зарегистрирован!\n\nВведите пароль:","Далее","Отмена");
		SendClientMessage(playerid,COLOR_WHITE,"Добро пожаловать на сервер {ffff99}Гонка Вооружений!{ffffff} Этот аккаунт {ff0000}не зарегистрирован {ffffff}на сервере!");
		}
		}
	return true;
	}

stock OnPlayerRegister(p, password[])
{
	new str[230], regip[32];
	new year,month,day,hour,minute, unixreg;
	getdate(year,month,day);
	gettime(hour,minute);
	unixreg = date_to_timestamp(year,month,day,hour,minute,0);
	PlayerInfo[p][pRegTime] = unixreg;
	GetPlayerIp(p,regip,sizeof(regip));
	format(str, sizeof(str), "INSERT INTO `accounts` (`Name`, `Password`, `RegIP`,`RegDate`) VALUES ('%s', '%s', '%s', '%d')", GetName(p), password, regip, unixreg);
	mysql_function_query(connectionHandle, str, false, "RegisterCallback","d", p);
	return true;
}

forward RegisterCallback(playerid);
public RegisterCallback(playerid)
{
	SendClientMessage(playerid,COLOR_WHITE,"Регистрация прошла {00ff00}успешно! {ffffff}Добро пожаловать на {ffff99}Гонку Вооружений!");
	new string[128];
	format(string, sizeof(string),"SELECT * FROM `accounts` WHERE `Name` = '%s'", GetName(playerid));
	mysql_function_query(connectionHandle, string, true, "FixAccountID","d", playerid);
	SetPVarInt(playerid,"Logged", 1), TogglePlayerSpectating(playerid, 0),ForceClassSelection(playerid);
	return true;
}

forward FixAccountID(playerid);
public FixAccountID(playerid)
{
//	SendClientMessage(playerid,COLOR_WHITE,"Регистрация прошла {00ff00}успешно! {ffffff}Добро пожаловать на {ffff99}MaDoy's MatchMaking!");
	new rows, fields, maximum[16];
	cache_get_data(rows, fields);
	cache_get_field_content(0, "ID", maximum), PlayerInfo[playerid][pID] = strval(maximum);
	return true;
}

stock SavePlayer(p)
{
	if(GetPVarInt(p,"Logged") == 0) return true;
	new querystr[512];
	mysql_format(connectionHandle, querystr,"UPDATE `accounts` SET `Admin` = '%d', `Vip` = '%d', `Mute` = '%d', `Warn` = '%d', `Kills` = '%d', `Deaths` = '%d',`Wins` = '%d',`Games` = '%d',`Levels` = '%d',`BestSeries` = '%d',`Rank` = '%d',`Leaves` = '%d', `Rating` = '%d', `RankProgress` = '%d', `LGID` = '%d', \
	`LGlevel` = '%d', `LGexp` = '%d', `Banned` = '%d', `CTime` = '%d' WHERE `Name` = '%s'", PlayerInfo[p][pAdmin],PlayerInfo[p][pVip],PlayerInfo[p][pMute],PlayerInfo[p][pWarn],PlayerInfo[p][pKills],
	 PlayerInfo[p][pDeaths],PlayerInfo[p][pWins],PlayerInfo[p][pGames],PlayerInfo[p][pLevels],PlayerInfo[p][pBestSeries],PlayerInfo[p][pRank],PlayerInfo[p][pLeaves],PlayerInfo[p][pRating],PlayerInfo[p][pRankProgress],PlayerInfo[p][pLGID],PlayerInfo[p][pLGlevel],PlayerInfo[p][pLGexp],PlayerInfo[p][pBanned],PlayerInfo[p][pCTime],GetName(p));
	mysql_query(querystr, -1, 0, connectionHandle);
	mysql_format(connectionHandle,querystr,"UPDATE `accounts` SET `Shots` = '%d', `GoodShots` = '%d', `DamageGiven` = '%d', `DamageTaken` = '%d' WHERE `Name` = '%s'", PlayerInfo[p][pShots],PlayerInfo[p][pGoodShots],PlayerInfo[p][pDamageGiven],PlayerInfo[p][pDamageTaken],GetName(p));
	mysql_query(querystr, -1, 0, connectionHandle);
	return true;
}

stock OnPlayerLogin(i, password[])
{
	new str[128];
	format(str, sizeof(str),"SELECT * FROM `accounts` WHERE `Name` = '%s' AND `Password` = '%s'", GetName(i), password);
	mysql_function_query(connectionHandle, str, true, "LoginCallback","ds", i, password);
	return true;
}
forward LoginCallback(i, password[]);
public LoginCallback(i, password[])
{
	new rows, fields, string[144], maximum[128];
	cache_get_data(rows, fields);
	if(!rows)
	{
		if(GetPVarInt(i, "wrongPass") == 2) return SendClientMessage(i,COL_RED,"Вы ввели 3 раза неверный пароль, поэтому были кикнуты сервером."), Kick(i);
		SetPVarInt(i, "wrongPass", GetPVarInt(i, "wrongPass")+1);
		format(string, sizeof(string), "Неверный пароль(попыток:  %i/3)\nВведите пароль:", 3 - GetPVarInt(i, "wrongPass"));
		ShowPlayerDialog(i, 2, DIALOG_STYLE_PASSWORD, "Авторизация", string, "Вход", "Отмена");
		return true;
	}
	cache_get_field_content(0, "Admin", maximum), PlayerInfo[i][pAdmin] = strval(maximum);
	cache_get_field_content(0, "Vip", maximum), PlayerInfo[i][pVip] = strval(maximum);
	cache_get_field_content(0, "Mute", maximum), PlayerInfo[i][pMute] = strval(maximum);
	cache_get_field_content(0, "Warn", maximum), PlayerInfo[i][pWarn] = strval(maximum);
	cache_get_field_content(0, "Kills", maximum), PlayerInfo[i][pKills] = strval(maximum);
	cache_get_field_content(0, "Deaths", maximum), PlayerInfo[i][pDeaths] = strval(maximum);
	cache_get_field_content(0, "Cash", maximum), PlayerInfo[i][pCash] = strval(maximum);
	cache_get_field_content(0, "Wins", maximum), PlayerInfo[i][pWins] = strval(maximum);
	cache_get_field_content(0, "Games", maximum), PlayerInfo[i][pGames] = strval(maximum);
	cache_get_field_content(0, "Levels", maximum), PlayerInfo[i][pLevels] = strval(maximum);
	cache_get_field_content(0, "BestSeries", maximum), PlayerInfo[i][pBestSeries] = strval(maximum);
	cache_get_field_content(0, "Rank", maximum), PlayerInfo[i][pRank] = strval(maximum);
	cache_get_field_content(0, "Leaves", maximum), PlayerInfo[i][pLeaves] = strval(maximum);
	cache_get_field_content(0, "Rating", maximum), PlayerInfo[i][pRating] = strval(maximum);
	cache_get_field_content(0, "RankProgress", maximum), PlayerInfo[i][pRankProgress] = strval(maximum);
	cache_get_field_content(0, "LGID", maximum), PlayerInfo[i][pLGID] = strval(maximum);
	cache_get_field_content(0, "LGlevel", maximum), PlayerInfo[i][pLGlevel] = strval(maximum);
	cache_get_field_content(0, "LGexp", maximum), PlayerInfo[i][pLGexp] = strval(maximum);
	cache_get_field_content(0, "Banned", maximum), PlayerInfo[i][pBanned] = strval(maximum);
	cache_get_field_content(0, "BanInfo", maximum), strmid(string,maximum,0,strlen(maximum),255);
	cache_get_field_content(0, "CTime", maximum), PlayerInfo[i][pCTime] = strval(maximum);
	cache_get_field_content(0, "RegDate", maximum), PlayerInfo[i][pRegTime] = strval(maximum);
	cache_get_field_content(0, "ID", maximum), PlayerInfo[i][pID] = strval(maximum);
	cache_get_field_content(0, "Shots", maximum), PlayerInfo[i][pShots] = strval(maximum);
	cache_get_field_content(0, "GoodShots", maximum), PlayerInfo[i][pGoodShots] = strval(maximum);
	cache_get_field_content(0, "DamageGiven", maximum), PlayerInfo[i][pDamageGiven] = strval(maximum);
	cache_get_field_content(0, "DamageTaken", maximum), PlayerInfo[i][pDamageTaken] = strval(maximum);
	mysql_free_result();
	if(PlayerInfo[i][pBanned] >= 1)
	{
		new d,m,y,h,mint,s,curtimestamp;
		new baninfo[4][32];
		getdate(y,m,d);
		gettime(h,mint,s);
		split(string, baninfo, '|');
		curtimestamp = date_to_timestamp(y,m,d,h,mint,s);
		if(curtimestamp < strval(baninfo[0]))
		{
		    timestamp_to_date(strval(baninfo[0]),y,m,d,h,mint,s);
		    format(string,sizeof(string),"Аккаунт {F81414}%s{ffffff} временно {F81414}заблокирован{ffffff}.", GetName(i));
			SendClientMessage(i,COL_RED,string);
			format(string,sizeof(string),"Причина бана: {F81414}%s{ffffff}. Забанил: {F81414}%s{ffffff}.",baninfo[2], baninfo[1]);
			SendClientMessage(i,COLOR_WHITE,string);
			format(string,sizeof(string),"Дата разблокировки: {F81414}%02d %s %04dг.{ffffff} Время: {F81414}%02d:%02d{ffffff}.",d,GetMonthNameRus(m),y,h,mint);
            SendClientMessage(i,COLOR_WHITE,string);
			Kick(i);
			return 1;
		}
		PlayerInfo[i][pBanned] = 0;
	}
	SetPVarInt(i, "Logged", 1);
	SendClientMessage(i,COLOR_WHITE, "Вы успешно {00ff00}авторизовались!  {ffffff}Добро пожаловать на {ffff99}Гонку Вооружений!");
	new ip[MAX_PLAYER_NAME];
	GetPlayerIp(i, ip, sizeof(ip));
	format(string, sizeof(string), "{b51414}>>> {808080}%s (ID: %d) подключился к серверу | IP: {b51414}%s.",GetName(i),i,ip);
	SendAdminMessage(COLOR_WHITE,string);
	mysql_format(connectionHandle,string,"UPDATE `accounts` SET `LastConnection` = '-1', `LastIP` = '%s' WHERE `Name` = '%s'",ip,GetName(i));
	mysql_query(string, -1, 0, connectionHandle);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `connectlog` (`PlayerName`, `PlayerID`, `ConnectType`, `PlayerALevel`,`PlayerIP`,`Time`) VALUES ('%s', '%d', '-1', '%d', '%s', '%d')",
	 GetName(i),PlayerInfo[i][pID],PlayerInfo[i][pAdmin],ip,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	format(string, sizeof(string), "{FFAF00}%s (ID: %d) {FFFFFF}подключился к серверу.",GetName(i),i);
	SendClientMessageToAll(-1, string);
	if(PlayerInfo[i][pAdmin] > 0)
	{
	    format(string,sizeof(string),"Внимание {ffffff}> {ffff99}%s {ffffff}авторизовался как {ffff99}%s",GetName(i),GetAdminRank(PlayerInfo[i][pAdmin]));
	    SendClientMessageToAll(COL_GREEN,string);
	}
	PlayerTeam[i] = 1;
	TogglePlayerSpectating(i, 0), ForceClassSelection(i);
	return true;
}
stock UpdateInformer(playerid)
{
	new updater[600];
	if(PlayerTeam[playerid] == 1) format(updater,sizeof(updater), "{FF0000}%s - Террорист\n\n{FFFFFF}Уровень: {FFFF99}%d {FFFFFF}({FFFF99}%d{FFFFFF}/{FFFF99}2{FFFFFF})\nОружие: {FFFF99}%s\n{FFFFFF}Звание: {FFFF99}%s {ffffff}({ffff99}%d {ffffff}ARR)",GetName(playerid),GunLevel[playerid]+1,KillScore[playerid],GetGunName(LevelWeapons[GunLevel[playerid]]),RankNames[PlayerInfo[playerid][pRank]],PlayerInfo[playerid][pRating]);
	else if(PlayerTeam[playerid] == 2) format(updater,sizeof(updater), "{0000FF}%s - Спецназовец\n\n{FFFFFF}Уровень: {FFFF99}%d {FFFFFF}({FFFF99}%d{FFFFFF}/{FFFF99}2{FFFFFF})\nОружие: {FFFF99}%s\n{FFFFFF}Звание: {FFFF99}%s {ffffff}({ffff99}%d {ffffff}ARR)",GetName(playerid),GunLevel[playerid]+1,KillScore[playerid],GetGunName(LevelWeapons[GunLevel[playerid]]),RankNames[PlayerInfo[playerid][pRank]], PlayerInfo[playerid][pRating]);
	Update3DTextLabelText(PlayerInformer[playerid],COLOR_WHITE,updater);
	return 1;
}

CMD:help(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 1)
	{
		ShowPlayerDialog(playerid,10,DIALOG_STYLE_LIST,"Помощь по игре","Основное\nЗвания и рейтинг\nОружие и уровни\nВиды связи\nПолезные команды","Далее","Назад");
	}
	return 1;
}

CMD:healme(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 1)
	{
		if(PlayerSpawned[playerid] == false || PlayerTeam[playerid] == 3) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Недоступно в данный момент!");
		if(Healings[playerid] > 0)
		{
			new Float: health;
			new healhealth = 20+random(20); 
			new string[128];
			GetPlayerHealth(playerid,health);
			Healings[playerid]--;
			HealTimes[playerid]++;
			PlayerInfo[playerid][pRating]++;
			PlayerInfo[playerid][pRankProgress]+=10;
			UpdateInformer(playerid);
			SetPlayerHealth(playerid,health + healhealth);
			format(string,sizeof(string),"%s воспользовался аптечкой и пополнил себе здоровье!", GetName(playerid));
			SendClientMessageToAll(COL_GREEN,string);
			format(string,sizeof(string),"Ты использовал аптечку и пополнил себе здоровье до %.0f HP. Аптечек осталось: %d.",health+healhealth,Healings[playerid]);
			SendClientMessage(playerid,COL_YELLOW,string);
			if(PlayerTeam[playerid] == 1) format(string,sizeof(string), "{FF0000}%s - Террорист{ffffff}\n\nИспользовал аптечку (+{ffff99}%d {ffffff}HP)",GetName(playerid),healhealth);
			else if(PlayerTeam[playerid] == 2) format(string,sizeof(string), "{0000FF}%s - Спецназовец{ffffff}\n\nИспользовал аптечку (+{ffff99}%d {ffffff}HP)",GetName(playerid),healhealth);
			Update3DTextLabelText(PlayerStatus[playerid],COLOR_WHITE,string);
			Update3DTextLabelText(PlayerInformer[playerid],COLOR_WHITE,"");
			InformerUpdate[playerid] = 3;
			format(string,sizeof(string),"+%d HP",healhealth);
			TextDrawSetString(HealAmountTD[playerid],string);
			if(PlayerSettings[playerid][psSInterface] == false)
			{
				TextDrawShowForPlayer(playerid,HealTD[0]);
				TextDrawShowForPlayer(playerid,HealTD[PlayerSettings[playerid][psInterfaceColor]+1]);
				TextDrawShowForPlayer(playerid,HealAmountTD[playerid]);
				HideHealTD[playerid] = 3;
			}
            if(PlayerSettings[playerid][psMonHPOff] == false)
			{
				format(string,sizeof(string),"+%d",healhealth);
				TextDrawSetString(HPTD[playerid][PlusHPTD],string);
				TextDrawShowForPlayer(playerid,HPTD[playerid][PlusHPTD]);
				HideHPTD[playerid][HidePlusHPTD] = 3;
				format(string,sizeof(string),"%d HP",floatround(health + healhealth,floatround_ceil));
				TextDrawSetString(HPTD[playerid][MonitoringHPTD],string);
			}
            
		}
		else SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> У Вас нет аптечки!");
	}
	return 1;
}


public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(issuerid == INVALID_PLAYER_ID)
	{
		PlayerInfo[playerid][pDamageTaken] += floatround(amount, floatround_ceil);
		DamageTaken[playerid] += floatround(amount, floatround_ceil);
        if(PlayerSettings[playerid][psMonHPOff] == false)
        {
            new string[10],Float:health;
			format(string,sizeof(string),"-%d",floatround(amount, floatround_ceil));
			TextDrawSetString(HPTD[playerid][MinusHPTD],string);
			TextDrawShowForPlayer(playerid,HPTD[playerid][MinusHPTD]);
			HideHPTD[playerid][HideMinusHPTD] = 3;
			GetPlayerHealth(playerid,health);
			format(string,sizeof(string),"%d HP",floatround(health-amount,floatround_ceil));
			TextDrawSetString(HPTD[playerid][MonitoringHPTD],string);
        }
	}
	return true;
}
stock UpdateMap(mapid)
{
	switch(mapid)
	{
		case 0: SendRconCommand("mapname LVA (1 map)");
		case 1: SendRconCommand("mapname Ocean Boxes (2 map)");
		case 2: SendRconCommand("mapname Roofs Near Town-Hall (3 map)");
		case 3: SendRconCommand("mapname Advanced Battlefield (4 map)");
		case 4: SendRconCommand("mapname Ruins On Roofs (5 map)");
		case 5: SendRconCommand("mapname Hawai (6 map)");
		case 6: SendRconCommand("mapname Two Islands (7 map)");
		case 7: SendRconCommand("mapname Ruins of Ghetto (8 map)");
		case 8: SendRconCommand("mapname Ruins (9 map)");
		case 9: SendRconCommand("mapname Port (10 map)");
		case 10: SendRconCommand("mapname Bandits' Town (11 map)");
		case 11: SendRconCommand("mapname Jail (12 map)");
		case 12: SendRconCommand("mapname Island Near LS (13 map)");
		case 13: SendRconCommand("mapname Warehouse (14 map)");
		case 14: SendRconCommand("mapname Ship SF (15 map)");
		case 15: SendRconCommand("mapname Ship LS (16 map)");
		case 16: SendRconCommand("mapname Caligulas (17 map)");
		case 17: SendRconCommand("mapname Four Dragons (18 map)");
		case 18: SendRconCommand("mapname Atrium (19 map)");
		case 19: SendRconCommand("mapname Jizzy's (20 map)");
	}
	return 1;
}
forward InfoTimer();
public InfoTimer()
{
	SendClientMessageToAll(COLOR_WHITE, "\n");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Ты играешь на сервере {ffff99}Гонка Вооружений");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Здесь ты получаешь уровни за убийства, пытаясь достичь {ffff99}последнего {ffffff}уровня.");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Ты можешь настроить сервер под себя используя раздел меню {ffff99}'Персональные настройки'.");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Для связи с администрацией используй {ffff99}/report");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}В меню игрока содержится помощь по игровому процессу, статистика, монитринги, настройки и многое другое.");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Меню игрока - {ffff99}/menu {ffffff}(Клавиша {ffff99}ALT{ffffff})");
	SendClientMessageToAll(COLOR_WHITE, "{FF0000}>>> {ffffff}Оградить себя от {ffff99}спамщиков {ffffff}можно командой {ffff99}/block");
	SendClientMessageToAll(COLOR_WHITE, "\n");
	return 1;
}
CMD:vipinfo(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 1)
	{
		ShowPlayerDialog(playerid, 1337, DIALOG_STYLE_MSGBOX,"Приемущества VIP","На нашем сервере существует функция VIP\nОна дает некоторые приемущества, не влияющие на игровой процесс\n\nСписок приемуществ:\n+ Доступ к VIP скинам\n+ Префикс < VIP > в чате\n+ Доступ к VIP-чату\n+ Откат в чат - 5 секунд","Окей","");
	}
	return 1;
}
CMD:leaders(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 1)
	{
		if(LeaderID == 999) return ShowPlayerDialog(playerid, 1337, DIALOG_STYLE_MSGBOX,"Лидеры сервера","Лидер игры - Нет\nЛидер команды террористов - Нет\nЛидер команды спецназа - Нет","Закрыть","");
		new allstring[300], string[128];
		format(string,sizeof(string),"Лидер игры - %s (%d уровень)",GetName(LeaderID),BestScore+1);
		strcat(allstring,string);
		if(LeaderTID == 999)
		{
			strcat(allstring,"\nЛидер команды террористов - Нет");
		}
		else
		{
			format(string,sizeof(string),"\nЛидер команды террористов - %s (%d уровень)",GetName(LeaderTID), BestScoreT+1);
			strcat(allstring,string);
		}
		if(LeaderCTID == 999)
		{
			strcat(allstring,"\nЛидер команды спецназа - Нет");
		}
		else
		{
			format(string,sizeof(string),"\nЛидер команды спецназа - %s (%d уровень)",GetName(LeaderCTID), BestScoreCT+1);
			strcat(allstring,string);
		}
		ShowPlayerDialog(playerid,1337,DIALOG_STYLE_MSGBOX,"Лидеры Гонки Вооружений",allstring,"Закрыть","");
	}
	return 1;
}
stock AFKCheck()
{
	new updstr[300];
	foreach(Player,id)
    {
        if(PlayerTeam[id] != 3)
        {
	        GetPlayerPos(id,PlayerAFKCoords[id][0],PlayerAFKCoords[id][1],PlayerAFKCoords[id][2]);
	        if(PlayerAFKCoords[id][0] == PlayerAFKCoords[id][3] && PlayerAFKCoords[id][1] == PlayerAFKCoords[id][4] && PlayerAFKCoords[id][2] == PlayerAFKCoords[id][5])
	        {
		        PlayerAFKTime[id]++;
	        }
	        else if(PlayerAFKTime[id] >= 30)
	        {
		        UpdateInformer(id);
		        PlayerAFKTime[id] = 0;
	        }
	        else
	        {
		        PlayerAFKTime[id] = 0;
	        }
	        PlayerAFKCoords[id][3] = PlayerAFKCoords[id][0];
	        PlayerAFKCoords[id][4] = PlayerAFKCoords[id][1];
	        PlayerAFKCoords[id][5] = PlayerAFKCoords[id][2];
	        if(PlayerAFKTime[id] >= 30)
	        {
		        if(PlayerTeam[id] == 1)
		        {
			        format(updstr,sizeof(updstr),"{ff0000}%s - Террорист\n\n{ffff99}AFK {ffffff}({ffff99}%d {ffffff}секунд)",GetName(id),PlayerAFKTime[id]);
			        Update3DTextLabelText(PlayerInformer[id],COLOR_WHITE,updstr);
		        }
		        else if(PlayerTeam[id] == 2)
		        {
		            format(updstr,sizeof(updstr),"{0000ff}%s - Спецназовец\n\n{ffff99}AFK {ffffff}({ffff99}%d {ffffff}секунд)",GetName(id),PlayerAFKTime[id]);
		            Update3DTextLabelText(PlayerInformer[id],COLOR_WHITE,updstr);
		        }
	        }
	        if(PlayerAFKTime[id] >= 300 && PlayerInfo[id][pAdmin] == 0 && ServerSettings[ssAntiAFK] == true)
	        {
	            SendClientMessage(id, -1,"Анти-AFK: Вы были кикнуты за состояние AFK более 5 минут!");
	            Kick(id);
	            continue;
	        }
	        if(PlayerAFKTime[id] == 180 && PlayerInfo[id][pAdmin] == 0 && ServerSettings[ssAntiAFK] == true) SendClientMessage(id, -1,"Анти-AFK: Вы будете кикнуты через 2 минуты, если не начнете двигаться!");
        }
    }
}
stock SendAdminMessage(color, string[])
{
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pAdmin] >= 1 && PlayerSettings[i][psAChatOff] == false)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
}
CMD:a(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerInfo[playerid][pAdmin] == 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вам недоступен данный вид связи!");
	if(PlayerSettings[playerid][psAChatOff] == true) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы покинули чат администрации!");
	new result[128];
	if(sscanf(params,"s[128]",result)) return SendClientMessage(playerid,COLOR_WHITE,"Используйте: (/a)dmin [текст сообщения]");
	new string[180];
	format(string,sizeof(string),"{ff0000}(А-чат) {ffffff}%s {ffff99}%s {ffffff}(ID: %d): %s",GetAdminRank(PlayerInfo[playerid][pAdmin]), GetName(playerid),playerid,result);
	SendAdminMessage(COLOR_WHITE,string);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `achatlog` (`SenderName`, `SenderID`, `SenderALevel`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],PlayerInfo[playerid][pAdmin],result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}
ALT:a:admin;
CMD:report(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerInfo[playerid][pAdmin] != 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы являетесь администратором!");
	if(ReportChat[playerid] != 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Недавно Вы уже использовали данную команду!");
	new result[128];
	if(sscanf(params,"s[128]",result)) return SendClientMessage(playerid,COLOR_WHITE,"Используйте: (/re)port [сообщение для администрации]");
	new string[180];
	format(string,sizeof(string),"Репорт от %s (ID: %d): %s", GetName(playerid),playerid,result);
	SendAdminMessage(COLOR_LIGHTRED,string);
	ReportChat[playerid] = 60;
	SendClientMessage(playerid,COLOR_LIGHTRED,"Ваше сообщение отправлено администрации сервера, ожидайте ответа");
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `reportlog` (`SenderName`, `SenderID`, `SenderALevel`,`TakingID`,`TakingName`,`MessageType`,`Message`,`Time`) VALUES ('%s', '%d', '0', '-1','AdminTeam','1', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}
ALT:report:re;

CMD:rr(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerInfo[playerid][pAdmin] == 0) return true;
	new result[128], giveplayerid;
	if(sscanf(params,"us[128]",giveplayerid,result)) return SendClientMessage(playerid,COLOR_WHITE,"Используйте: /rr [ID игрока] [ответ]");
	new string[180];
	if(PlayerInfo[giveplayerid][pAdmin] > 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Данный игрок является администратором!");
	format(string,sizeof(string),"%s %s ответил на твой репорт: %s", GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),result);
	SendClientMessage(giveplayerid,COLOR_BLUE,string);
	format(string,sizeof(string),"%s %s ответил на репорт %s: %s", GetAdminRank(PlayerInfo[playerid][pAdmin]),GetName(playerid),GetName(giveplayerid),result);
	SendAdminMessage(COLOR_LIGHTRED,string);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `reportlog` (`SenderName`, `SenderID`, `SenderALevel`,`TakingID`,`TakingName`,`MessageType`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '2', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],PlayerInfo[playerid][pAdmin],giveplayerid,GetName(giveplayerid),result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}
stock SendTeamMessage(senderid,color, string[])
{
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerTeam[i] == PlayerTeam[senderid] && PlayerSettings[i][psTChatOff] == false && Blocked[i][senderid] == false)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
}

stock SendOChatMessage(senderid,color, string[])
{
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerSettings[i][psOChatOff] == false && Blocked[i][senderid] == false)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
}
CMD:t(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerTeam[playerid] == 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы не вступили не в одну из команд!");
	if(PlayerTeam[playerid] == 3) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Недоступно для наблюдателей!");
	if(ServerSettings[ssTeamChat] == false) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Чаты команд были отключены администрацией сервера!");
	if(PlayerSettings[playerid][psTChatOff] == true) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы покинули командный чат!");
	new result[128];
	if(sscanf(params,"s[128]",result)) return SendClientMessage(playerid,COLOR_WHITE,"Используйте: (/t)eam [текст сообщения]");
	new string[180];
	format(string,sizeof(string),"{00ff00}(КОМАНДА) {ffff99}%s {ffffff}(ID: %d | Уровень: %d): %s", GetName(playerid),playerid, GunLevel[playerid]+1,result);
	SendTeamMessage(playerid, COLOR_WHITE, string);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `tchatlog` (`SenderName`, `SenderID`, `SenderTeam`,`Message`,`Time`) VALUES ('%s', '%d', '%d', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],PlayerTeam[playerid],result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}
ALT:t:team;
stock SendVipMessage(senderid,color, string[])
{
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pVip] >= 1 && PlayerSettings[i][psVIPChatOff] == false && Blocked[i][senderid] == false)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
}
CMD:vip(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return true;
	if(PlayerInfo[playerid][pVip]  == 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вам недоступен данный вид связи!");
	if(ServerSettings[ssVIPChat] == false) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Чат VIP пользователей был отключен администрацией сервера!");
	if(PlayerSettings[playerid][psVIPChatOff] == true) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы покинули чат VIP!");
	new result[128];
	if(sscanf(params,"s[128]",result)) return SendClientMessage(playerid,COLOR_WHITE,"Используйте: (/v)ip [текст сообщения]");
	new string[180];
	format(string,sizeof(string),"{0000ff}(VIP-чат) {ffff99}%s {ffffff}(ID: {ffff99}%d{ffffff}): %s", GetName(playerid),playerid,result);
	SendVipMessage(playerid,COLOR_WHITE, string);
	new query[512], year,month,day,hour,minute,second,timestamp;
	getdate(year,month,day);
	gettime(hour,minute,second);
	timestamp = date_to_timestamp(year,month,day,hour,minute,second);
	mysql_format(connectionHandle,query, "INSERT INTO `vchatlog` (`SenderName`, `SenderID`,`Message`,`Time`) VALUES ('%s', '%d', '%s', '%d')",
	 GetName(playerid),PlayerInfo[playerid][pID],result,timestamp);
	mysql_query(query, -1, 0, connectionHandle);
	return 1;
}
ALT:vip:v;

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	AllShots++;
	PlayerShots[playerid]++;
	PlayerInfo[playerid][pShots]++;
	return true;
}
forward GetPlayerShotQuallity(playerid);
public GetPlayerShotQuallity(playerid)
{
	if(PlayerShots[playerid] == 0) return 0;
	return floatround(PlayerGoodShots[playerid]*100/PlayerShots[playerid]);
}
forward GetAllPlayerShotQuallity(playerid);
public GetAllPlayerShotQuallity(playerid)
{
	if(PlayerInfo[playerid][pShots] == 0) return 0;
	return floatround(PlayerInfo[playerid][pGoodShots]*100/PlayerInfo[playerid][pShots]);
}
stock ClearGameVars()
{
	TextDrawHideForAll(leaderTD);
	TextDrawHideForAll(leaderTeamT);
	TextDrawHideForAll(leaderTeamCT);
	TextDrawSetString(leader,"Game Leader: None");
	TextDrawSetString(leaderT,"Team Leader: None");
	TextDrawSetString(leaderCT,"Team Leader: None");
	TextDrawSetString(TeamScore,"~r~Terrorists ~w~[~y~0~w~] - [~y~0~w~] ~b~Counter Terrorists");
	LeaderTID = 999;
	LeaderCTID = 999;
	LeaderID = 999;
	BestScore = 0;
	BestScoreT = 0;
	BestScoreCT = 0;
	AllShots = 0;
	AllGoodShots = 0;
	TeamKills[1] = 0;
	TeamKills[2] = 0;
	GameID = random(9999);
	GameMinutes = 0;
	GameSeconds = 0;
	foreach(Player,i)
	{
		ClearPlayerVars(i);
	}
	return 1;
}
stock ClearPlayerVars(playerid)
{
	GunLevel[playerid] = 0;
	PlayerTeam[playerid] = 0;
	KillScore[playerid] = 0;
	Assists[playerid] = 0;
	KillsInGame[playerid] = 0;
	DeathsInGame[playerid] = 0;
	PlayerShots[playerid] = 0;
	PlayerGoodShots[playerid] = 0;
	DamageGiven[playerid] = 0;
	DamageTaken[playerid] = 0;
	KillSeries[playerid] = 0;
	BestKillSeries[playerid] = 0;
	HealTimes[playerid] = 0;
	PlayerTarget[playerid] = 999;
	PlayerSpectating[playerid] = 999;
	GunCheatWarns[playerid] = 0;
	FirstSpawn[playerid] = false;
	ComboDamage[playerid] = 0.0;
	ComboX[playerid] = 0;
	ShowingTD_G[playerid] = 0;
	ShowingTD_R[playerid] = 0;
	OldID[playerid] = -1;
	DeathCoords[playerid][posX] = 0.0;
	DeathCoords[playerid][posY] = 0.0;
	DeathCoords[playerid][posZ] = 0.0;
	PlayerGiveDamage[playerid] = 0;
	PlayerTakeDamage[playerid] = 0;
	return 1;
}
CMD:menu(playerid,params[])
{
	if(GetPVarInt(playerid,"Logged") == 0) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы не авторизованы!");
	ShowPlayerDialog(playerid,6,DIALOG_STYLE_LIST,"Игровое меню | Гонка Вооружений","Общая статистика\nСтатистика в текущей игре\nПомощь по игровому процессу\nЛидеры сервера\nИнформация о VIP\nИнформация о моде\nДата и время\nСписок игроков\nПерсональные настройки\nАдминистрация Онлайн\nИгровые настройки","Далее","Закрыть");
	return 1;
}
stock ShowStats(playerid)
{
	new allstring[500];
	new year,day,month,hour,minute;
	timestamp_to_date(PlayerInfo[playerid][pRegTime],year,month,day,hour,minute);
	format(allstring,sizeof(allstring),"Ник: %s\nЗвание: %s\nРейтинг ARR: %d\n\nУбийств: %d\nСмертей: %d\nКоэффициент У/С: %.2f\n\nВыстрелов: %d\nПопаданий: %d\nМеткость: %d%%\n\nУрона нанесено: %d\nУрона получено: \
	%d\n\nНаибольшая серия убийств: %d",GetName(playerid),
	RankNames[PlayerInfo[playerid][pRank]],PlayerInfo[playerid][pRating],PlayerInfo[playerid][pKills],PlayerInfo[playerid][pDeaths],float(PlayerInfo[playerid][pKills]) / float(PlayerInfo[playerid][pDeaths]),PlayerInfo[playerid][pShots],PlayerInfo[playerid][pGoodShots],
	GetAllPlayerShotQuallity(playerid),PlayerInfo[playerid][pDamageGiven],
	PlayerInfo[playerid][pDamageTaken],PlayerInfo[playerid][pBestSeries]);
	format(allstring,sizeof(allstring),"%s\nИгр сыграно: %d\nИгр выиграно: %d\nИгр покинуто: %d\nСредний уровень в играх: %d\n\nНомер аккаунта: %d\nРегистрация: %d.%02d.%d в %d:%02d\nИгровая активность: %d минут\n\nПредупреждений: %d/3\nУровень администированния: %s",allstring,PlayerInfo[playerid][pGames], PlayerInfo[playerid][pWins],PlayerInfo[playerid][pLeaves],GetPlayerMiddleLevel(playerid),PlayerInfo[playerid][pID],day,month,year,hour,minute,
	PlayerInfo[playerid][pCTime],PlayerInfo[playerid][pWarn],GetAdminRank(PlayerInfo[playerid][pAdmin]));
	if(PlayerInfo[playerid][pVip] == 0) strcat(allstring,"\nVIP аккаунт: Нет");
	else
	{
	    switch(PlayerInfo[playerid][pVip])
	    {
	        case 0..59: format(allstring,sizeof(allstring),"%s\nVIP аккаунт: Есть (%d секунд осталось)",allstring,PlayerInfo[playerid][pVip]);
	        case 60..359: format(allstring,sizeof(allstring),"%s\nVIP аккаунт: Есть (%.0f минут осталось)",allstring,float(PlayerInfo[playerid][pVip])/60.0);
	        default: format(allstring,sizeof(allstring),"%s\nVIP аккаунт: Есть (%.0f часов осталось)",allstring,float(PlayerInfo[playerid][pVip])/360.0);
	    }
	}
	return ShowPlayerDialog(playerid,8,DIALOG_STYLE_MSGBOX,"Статистика",allstring,"Закрыть","Назад");
}
stock GetPlayerRank(playerid)
{
	if(PlayerInfo[playerid][pGames] < 3) return 0;
	if(PlayerInfo[playerid][pDeaths] == 0) return 25;
	if(floatround(PlayerInfo[playerid][pKills]*5/PlayerInfo[playerid][pDeaths] + 0.5) > 25) return 25;
	return floatround(PlayerInfo[playerid][pKills]*5/PlayerInfo[playerid][pDeaths] + 0.5);
}
forward GetPlayerMiddleLevel(playerid);
public GetPlayerMiddleLevel(playerid)
{
	if(PlayerInfo[playerid][pGames] == 0) return 1;
	return floatround(PlayerInfo[playerid][pLevels]/PlayerInfo[playerid][pGames])+1;
}
stock OnPlayerRankChange(playerid,newrank)
{
	if(newrank > 25 || newrank < 1)
	{
	    PlayerInfo[playerid][pRankProgress] = 0;
		return 1;
	}
	new string[144];
	if(PlayerInfo[playerid][pGames] == 3)
	{
		format(string,sizeof(string),"> По результатам трех игр {ffff99}%s {ffffff}получает звание {ffff99}%s",GetName(playerid),RankNames[newrank]);
		SendClientMessageToAll(COLOR_WHITE,string);
		PlayerInfo[playerid][pRank] = newrank;
		format(string,sizeof(string),"Ты отыграл 3 игры и получил звание {ffff99}%s",RankNames[newrank]);
		SendClientMessage(playerid,COLOR_WHITE,string);
		PlayerInfo[playerid][pRating]+=100;
		PlayerInfo[playerid][pRankProgress] = 0;
		return 1;
	}
	if(PlayerInfo[playerid][pRank] < newrank)
	{
		format(string,sizeof(string),"> {ffff99}%s {ffffff}повысил свое звание до {ffff99}%s",GetName(playerid),RankNames[newrank]);
		SendClientMessageToAll(COLOR_WHITE,string);
		PlayerInfo[playerid][pRank] = newrank;
		format(string,sizeof(string),"Поздравляем! Ты {00ff00}повысил {ffffff}свое звание! Новое звание - {ffff99}%s",RankNames[newrank]);
		SendClientMessage(playerid,COLOR_WHITE,string);
		PlayerInfo[playerid][pRating]+=30;
		PlayerInfo[playerid][pRankProgress] = 0;
		return 1;
	}
	if(PlayerInfo[playerid][pRank] > newrank)
	{
		format(string,sizeof(string),"> {ffff99}%s {ffffff}понизил свое звание до {ffff99}%s",GetName(playerid),RankNames[newrank]);
		SendClientMessageToAll(COLOR_WHITE,string);
		PlayerInfo[playerid][pRank] = newrank;
		format(string,sizeof(string),"Сожалеем! Ты {ff0000}понизил {ffffff}свое звание! Новое звание - {ffff99}%s",RankNames[newrank]);
		SendClientMessage(playerid,COLOR_WHITE,string);
		PlayerInfo[playerid][pRating]-=20;
		PlayerInfo[playerid][pRankProgress] = 0;
		return 1;
	}
	return 1;
}
stock ShowThisGameStats(playerid)
{
	new allstring[500];
	if(PlayerTeam[playerid] == 3) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Недоступно для наблюдателей!");
	format(allstring,sizeof(allstring),"Ник: %s\nЗвание: %s\nРейтинг ARR: %d\n\nУбийств: %d\nСмертей: %d\nКоэффициент У/С: %.2f\n\nВыстрелов: %d\nПопаданий: %d\nМеткость: %d%%\n\nУрона нанесено: %d\nУрона получено: %d\n\nНаибольшая серия убийств: %d\nАптечек использовано: %d",GetName(playerid),
	RankNames[PlayerInfo[playerid][pRank]], PlayerInfo[playerid][pRating],KillsInGame[playerid], DeathsInGame[playerid],float(KillsInGame[playerid]) / float(DeathsInGame[playerid]),PlayerShots[playerid], PlayerGoodShots[playerid],GetPlayerShotQuallity(playerid),DamageGiven[playerid],DamageTaken[playerid], BestKillSeries[playerid],HealTimes[playerid]);
	return ShowPlayerDialog(playerid,8,DIALOG_STYLE_MSGBOX,"Статистика в этой игре",allstring,"Закрыть","Назад");
}
stock ClearRelogPlayerVars(playerid)
{
	GunLevel[playerid] = 0;
	KillScore[playerid] = 0;
	Assists[playerid] = 0;
	KillsInGame[playerid] = 0;
	DeathsInGame[playerid] = 0;
	PlayerShots[playerid] = 0;
	PlayerGoodShots[playerid] = 0;
	DamageGiven[playerid] = 0;
	DamageTaken[playerid] = 0;
	KillSeries[playerid] = 0;
	BestKillSeries[playerid] = 0;
	HealTimes[playerid] = 0;
	PlayerInfo[playerid][pKills] = 0;
	PlayerInfo[playerid][pDeaths] = 0;
	PlayerInfo[playerid][pBestSeries] = 0;
	PlayerInfo[playerid][pWins] = 0;
	PlayerInfo[playerid][pGames] = 0;
	PlayerInfo[playerid][pAdmin] = 0;
	PlayerInfo[playerid][pVip] = 0;
	PlayerInfo[playerid][pLevels] = 0;
	PlayerInfo[playerid][pMute] = 0;
	PlayerInfo[playerid][pWarn] = 0;
	PlayerInfo[playerid][pRank] = 0;
	PlayerInfo[playerid][pRating] = 0;
	PlayerInfo[playerid][pRankProgress] = 0;
	PlayerInfo[playerid][pLeaves] = 0;
	PlayerInfo[playerid][pCTime] = 0;
	PlayerInfo[playerid][pBanned] = 0;
	PlayerInfo[playerid][pRegTime] = 0;
	PlayerInfo[playerid][pID] = 0;
	PlayerInfo[playerid][pShots] = 0;
	PlayerInfo[playerid][pGoodShots] = 0;
	PlayerInfo[playerid][pDamageGiven] = 0;
	PlayerInfo[playerid][pDamageTaken] = 0;
	for(new i; i < MAX_PLAYERS; i++)
	{
	Blocked[i][playerid] = false;
	Blocked[playerid][i] = false;
	}
	AntiFlood[playerid] = 0;
	ReportChat[playerid] = 0;
	FirstSpawn[playerid] = false;
	WatchTime[playerid] = false;
	LevelUpDelay[playerid] = false;
	PlayerSpectating[playerid] = 999;
	PlayerTarget[playerid] = 999;
	GunCheatWarns[playerid] = 0;
	InformerUpdate[playerid] = 0;
	PlayerSettings[playerid][psDInfoOff] = false;
	PlayerSettings[playerid][psDeathStatOff] = false;
	PlayerSettings[playerid][psPMOff] = false;
	PlayerSettings[playerid][psOChatOff] = false;
	PlayerSettings[playerid][psTChatOff] = false;
	PlayerSettings[playerid][psVIPChatOff] = false;
	PlayerSettings[playerid][psAChatOff] = false;
	PlayerSettings[playerid][psLDInfoOff] = false;
	PlayerSettings[playerid][psMonHPOff] = false;
	PlayerSettings[playerid][psSInterface] = false;
	PlayerSettings[playerid][psInterfaceColor] = 0;
	PlayerSettings[playerid][psDateTDOff] = false;
	PlayerSettings[playerid][psTimeTDOff] = false;
	ComboDamage[playerid] = 0.0;
	ComboX[playerid] = 0;
	ShowingTD_G[playerid] = 0;
	ShowingTD_R[playerid] = 0;
	OldID[playerid] = -1;
	DeathCoords[playerid][posX] = 0.0;
	DeathCoords[playerid][posY] = 0.0;
	DeathCoords[playerid][posZ] = 0.0;
	PlayerGiveDamage[playerid] = 0;
	PlayerTakeDamage[playerid] = 0;
	return 1;
}
forward Float:GetDistanceBetweenPlayers(p1,p2);
public Float:GetDistanceBetweenPlayers(p1,p2)
{
	new Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2;
	if(!IsPlayerConnected(p1) || !IsPlayerConnected(p2)) return -1.00;
	GetPlayerPos(p1,x1,y1,z1);
	GetPlayerPos(p2,x2,y2,z2);
	return floatsqroot(floatpower(floatabs(floatsub(x2,x1)),2)+floatpower(floatabs(floatsub(y2,y1)),2)+floatpower(floatabs(floatsub(z2,z1)),2));
}
CMD:time(playerid,params[])
{
	if(IsPlayerConnected(playerid))
	{
		new mtext[20];
		new string[300];
		new year, month, day;
		getdate(year, month, day);
		switch(month)
		{
			case 1: mtext = "января";
			case 2: mtext = "февраля";
			case 3: mtext = "марта";
			case 4: mtext = "апреля";
			case 5: mtext = "мая";
			case 6: mtext = "июня";
			case 7: mtext = "июля";
			case 8: mtext = "августа";
			case 9: mtext = "сентября";
			case 10: mtext = "октября";
			case 11: mtext = "ноября";
			case 12: mtext = "декабря";
		}
		new minuite,second, hour;
		gettime(hour,minuite,second);
		format(string, sizeof(string), "Гонка Вооружений - Сервер 1\n\nДата - %d %s %d года\nВремя - %02d часов %02d минут %02d секунд\nТекущая карта - %s (ID: %d)\nИгроков онлайн: %d (T: %d | CT: %d | SPEC: %d)", day, mtext, year, hour, minuite, second, MapNames[Map], Map, GetOnline(), GetTeamOnline(1), GetTeamOnline(2), GetTeamOnline(3));
		ShowPlayerDialog(playerid,1337,DIALOG_STYLE_MSGBOX,"Дата и время",string,"Закрыть","");
	}
	return 1;
}
stock GetOnline()
{
	new online;
	foreach(Player,i)
	{
		online++;
	}
	return online;
}
stock GetTeamOnline(teamid)
{
	new online;
	foreach(Player,i)
	{
		if(PlayerTeam[i] == teamid) online++;
	}
	return online;
}
stock GetTeamAlive(teamid)
{
	new alive;
	foreach(Player,i)
	{
		if(PlayerTeam[i] == teamid && PlayerSpawned[i] == true) alive++;
	}
	return alive;
}
CMD:players(playerid,params[])
{
	if(PlayerTeam[playerid] == 0 || GetPVarInt(playerid,"Logged") == 0) return SendClientMessage(playerid, COLOR_WHITE, "{ff0000}Ошибка {ffffff}> Недоступно в данный момент");
	new allstring[3000];
	new string[100];
	new countspec;
	new countt = GetTeamOnline(1);
	new countct = GetTeamOnline(2);
	if(countt > 0)
	{
		format(string, sizeof(string),"Террористы (Живые игроки: %d из %d)\nID - Игрок - Уровень - У/С - НСУ - Звание - ARR\n",GetTeamAlive(1),countt);
		strcat(allstring,string);
		foreach(Player,i)
		{
			if(PlayerTeam[i] == 1)
			{
				if(PlayerSpawned[i] == false) format(string,sizeof(string),"\n(Мертв) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				else if(i == LeaderTID) format(string,sizeof(string),"\n(Лидер) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				else format(string,sizeof(string),"\n%d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i], BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				strcat(allstring,string);
			}
		}
	}
	if(countct > 0)
	{
        if(countt > 0) strcat(allstring,"\n\n----------\n\n");
		format(string,sizeof(string),"Спецназ (Живые игроки: %d из %d)\nID - Игрок - Уровень - У/С - НСУ - Звание - ARR\n",GetTeamAlive(1),countct);
		strcat(allstring,string);
		foreach(Player,i)
		{
			if(PlayerTeam[i] == 2)
			{
				if(PlayerSpawned[i] == false) format(string,sizeof(string),"\n(Мертв) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				else if(i == LeaderCTID) format(string,sizeof(string),"\n(Лидер) %d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				else format(string,sizeof(string),"\n%d - %s - %d - %d/%d - %d - %s - %d",i,GetName(i),GunLevel[i]+1,KillsInGame[i],DeathsInGame[i],BestKillSeries[i],RankNames[PlayerInfo[i][pRank]],PlayerInfo[i][pRating]);
				strcat(allstring,string);
			}
		}
	}
	if(GetTeamOnline(3) > 0)
	{
		if(countt > 0 || countct > 0) strcat(allstring,"\n\n----------\n\n");
		format(string,sizeof(string),"Наблюдатели (%d)\n",GetTeamOnline(3));
		strcat(allstring,string);
		foreach(Player,i)
		{
			if(PlayerTeam[i] == 3)
			{
				if(countspec == 0) format(string,sizeof(string),"%s",GetName(i));
				else format(string,sizeof(string),",%s",GetName(i));
				strcat(allstring,string);
				countspec++;
			}
		}
	}
	ShowPlayerDialog(playerid,1337,DIALOG_STYLE_MSGBOX,"Гонка Вооружений",allstring,"Закрыть","");
	return 1;
}
CMD:specoff(playerid,params[])
{
	if(PlayerSpectating[playerid] == 999) return SendClientMessage(playerid,COLOR_WHITE,"{ff0000}Ошибка {ffffff}> Вы не находитесь в режиме наблюдателя!");
	ClearPlayerVars(playerid);
	PlayerTeam[playerid] = 3;
	ForceClassSelection(playerid);
	TogglePlayerSpectating(playerid,0);
	return 1;
}
forward SetTeamColor(playerid);
public SetTeamColor(playerid)
{
    foreach(Player,i)
    {
        if(i != playerid)
		{
	        if(PlayerTeam[playerid] == PlayerTeam[i])
	        {
		        switch(PlayerTeam[playerid])
		        {
			        case 1:
					{
						SetPlayerMarkerForPlayer(i,playerid,COL_RED);
						SetPlayerMarkerForPlayer(playerid,i,COL_RED);
//						SendClientMessage(playerid,COLOR_WHITE,"LOL - red");
					}
			        case 2:
					{
		                SetPlayerMarkerForPlayer(i,playerid,COLOR_BLUE);
						SetPlayerMarkerForPlayer(playerid,i,COLOR_BLUE);
//						SendClientMessage(playerid,COLOR_WHITE,"LOL-Blue");
					}
		        }
			}
			else
			{
		        switch(PlayerTeam[playerid])
		        {
			        case 1:
					{
						SetPlayerMarkerForPlayer(i,playerid,COL_RED_INVIS);
						SetPlayerMarkerForPlayer(playerid,i,COLOR_BLUE_INVIS);
//						SendClientMessage(playerid,COLOR_WHITE,"LOL - red");
					}
			        case 2:
					{
		                SetPlayerMarkerForPlayer(i,playerid,COLOR_BLUE_INVIS);
						SetPlayerMarkerForPlayer(playerid,i,COL_RED_INVIS);
//						SendClientMessage(playerid,COLOR_WHITE,"LOL-Blue");
					}
		        }
			}
		}
    }
//    SendClientMessage(playerid,COLOR_WHITE,"Complete!");
    return 1;
}

forward UpdateTime();
public UpdateTime()
{
	new hour,minute;
	gettime(hour, minute);
	new timestr[32];
	format(timestr,32,"%02d:%02d",hour,minute);
	TextDrawSetString(TimeDisp,timestr);
	SetWorldTime(hour);
	foreach(Player,i)
	{
		if(IsPlayerConnected(i))
		{
			if(GetPlayerState(i) != PLAYER_STATE_NONE) SetPlayerTime(i,hour,minute);
		}
		PlayerInfo[i][pCTime]++;
	}
	if(hour == 23 && minute == 55)
	{
	    SendClientMessageToAll(COLOR_WHITE,"{ff0000}Внимание {ffffff}> Через 5 минут произойдет автоматическая пеезагрузка сервера!");
	    SetTimer("AutoRestart",5*60*1000,false);
	}
}
forward AutoRestart();
public AutoRestart()
{
	SendClientMessageToAll(COLOR_WHITE,"{ff0000}Внимание {ffffff}> Производится автоматическая перезагрузка сервера! Это займет несколько секунд!");
	foreach(Player,i)
	{
	    SavePlayer(i);
	}
	GameModeExit();
	printf("Info > Запущена автоматическая перезагрузка сервера");
	return 1;
}
log(filename[],string[])
{
	new year, month,day;
	new hour,minuite,second;
	new stringer[64];
	new str[256];
	gettime(hour,minuite,second);
	getdate(year, month, day);
	format(stringer,sizeof(stringer),"Logs/%s.log",filename);
	new File:file = fopen(stringer, io_append);
	format(str,sizeof(str),"%s [%d/%d/%d][%d:%d:%d]\r\n",string,day,month,year,hour,minuite,second);
	for(new io=0; io<strlen(str); io++)
	{
		fputchar(file, str[io], false);
	}
	fclose(file);
}
stock GetDayMount(mount,yer)
{
	switch(mount)
	{
	case 1: return 31;
	case 2:
		{
			if((yer - 8)%4 == 0)
			{
				return 29;
			}
			else
			{
				return 28;
			}
		}
	case 3: return 31;
	case 4: return 30;
	case 5: return 31;
	case 6: return 30;
	case 7: return 31;
	case 8: return 31;
	case 9: return 30;
	case 10: return 31;
	case 11: return 30;
	case 12: return 31;
	}
	return 1;
}
forward split(const strsrc[], strdest[][], delimiter);
public split(const strsrc[], strdest[][], delimiter)
{
	new i, li;
	new aNum;
	new len;
	while(i <= strlen(strsrc)){
		if(strsrc[i]==delimiter || i==strlen(strsrc)){
			len = strmid(strdest[aNum], strsrc, li, i, 128);
			strdest[aNum][len] = 0;
			li = i+1;
			aNum++;
		}
		i++;
	}
	return 1;
}
stock TextDrawsHide(playerid)
{
		TextDrawHideForPlayer(playerid,leader);
		TextDrawHideForPlayer(playerid,level[playerid]);
		TextDrawHideForPlayer(playerid,exp[playerid]);
		TextDrawHideForPlayer(playerid,leaderBG[PlayerSettings[playerid][psInterfaceColor]]);
		TextDrawHideForPlayer(playerid,lvlexpBG[PlayerSettings[playerid][psInterfaceColor]]);
		TextDrawHideForPlayer(playerid,leader);
		TextDrawHideForPlayer(playerid,leaderT);
		TextDrawHideForPlayer(playerid,leaderCT);
		TextDrawHideForPlayer(playerid,leaderTeamT);
		TextDrawHideForPlayer(playerid,leaderTeamCT);
		TextDrawHideForPlayer(playerid,level[playerid]);
		TextDrawHideForPlayer(playerid,exp[playerid]);
		TextDrawHideForPlayer(playerid,TeamScore);
		if(PlayerSettings[playerid][psTimeTDOff] == false) TextDrawHideForPlayer(playerid,TimeDisp);
		if(PlayerSettings[playerid][psDateTDOff] == false) TextDrawHideForPlayer(playerid,DateDisp);
		TextDrawHideForPlayer(playerid,URL);
}
stock ShowSettingDialog(playerid)
{
	new string[700];
	if(PlayerSettings[playerid][psDInfoOff] == true) format(string,sizeof(string),"{ffffff}DamageInformer {ff0000}(ВЫКЛ)\n");
	else format(string,sizeof(string),"{ffffff}DamageInformer {00ff00}(ВКЛ)\n");
	if(PlayerSettings[playerid][psDeathStatOff] == true) strcat(string,"{ffffff}Информация при смерти {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Информация при смерти {00ff00}(ВКЛ)\n");
	if(PlayerSettings[playerid][psLDInfoOff] == true) strcat(string,"{ffffff}Место предыдущей смерти {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Место предыдущей смерти {00ff00}(ВКЛ)\n");
	if(PlayerSettings[playerid][psMonHPOff] == true) strcat(string,"{ffffff}HP в цифрах {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}HP в цифрах {00ff00}(ВКЛ)\n");
	if(PlayerSettings[playerid][psSInterface] == true) strcat(string,"{ffffff}Интерфейс {ff0000}(Простой)\n");
	else strcat(string,"{ffffff}Интерфейс {00ff00}(Продвинутый)\n");
	if(PlayerSettings[playerid][psSInterface] == false)
	{
	    switch(PlayerSettings[playerid][psInterfaceColor])
	    {
	    	case 0: strcat(string,"{ffffff}Цвет интерфейса {000000}(Черный)\n");
	    	case 1: strcat(string,"{ffffff}Цвет интерфейса {ff0000}(Красный)\n");
	    	case 2: strcat(string,"{ffffff}Цвет интерфейса {00ff00}(Зеленый)\n");
	    	case 3: strcat(string,"{ffffff}Цвет интерфейса {0000ff}(Синий)\n");
	    }
	}
	else strcat(string,"{696969}Цвет интерфейса\n");
	if(PlayerSettings[playerid][psDateTDOff] == true) strcat(string,"{ffffff}Отображение даты {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Отображение даты {00ff00}(ВКЛ)\n");
	if(PlayerSettings[playerid][psTimeTDOff] == true) strcat(string,"{ffffff}Отображение времени {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Отображение времени {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssPM] == false) strcat(string,"{696969}Личные сообщения\n");
	else if(PlayerSettings[playerid][psPMOff] == true) strcat(string,"{ffffff}Личные сообщения {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Личные сообщения {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssOChat] == false) strcat(string,"{696969}Общий чат\n");
	else if(PlayerSettings[playerid][psOChatOff] == true) strcat(string,"{ffffff}Общий чат {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Общий чат {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssTeamChat] == false) strcat(string,"{696969}Командный чат\n");
	else if(PlayerSettings[playerid][psTChatOff] == true) strcat(string,"{ffffff}Командный чат {ff0000}(ВЫКЛ)");
	else strcat(string,"{ffffff}Командный чат {00ff00}(ВКЛ)");
	if(PlayerInfo[playerid][pVip] > 0)
	{
	    if(ServerSettings[ssVIPChat] == false) strcat(string,"{696969}Чат VIP\n");
		else if(PlayerSettings[playerid][psVIPChatOff] == true) strcat(string,"\n{ffffff}Чат VIP {ff0000}(ВЫКЛ)");
		else strcat(string,"\n{ffffff}Чат VIP {00ff00}(ВКЛ)");
	}
	if(PlayerInfo[playerid][pAdmin] > 0)
	{
		if(PlayerSettings[playerid][psAChatOff] == true) strcat(string,"\n{ffffff}Чат администрации {ff0000}(ВЫКЛ)");
		else strcat(string,"\n{ffffff}Чат администрации {00ff00}(ВКЛ)");
	}
	ShowPlayerDialog(playerid,9,DIALOG_STYLE_LIST,"Персональные настройки",string,"Изменить","Назад");
}
GetPlayersMiddleLevel()
{
	new levels, players;
	foreach(Player,i)
	{
		if(FirstSpawn[i] == true)
		{
			levels += GunLevel[i];
			players++;
		}
	}
	if(players == 0) return 0;
	return floatround(levels/players);
}


/*mysql_player_exist(name[])
{
new logstr[128], rows, fields;
format(logstr, sizeof(logstr),"SELECT `Name` FROM `accounts` WHERE `Name` = '%s'", name);
	mysql_function_query(connectionHandle, logstr, true, "OnPlayerRegCheck","d", playerid);
	cache_get_data(rows, fields);
	if(rows) return true;
	else return false;
}*/

UpdateScore()
{
	new string[144];
	format(string, sizeof(string),"~r~Terrorists ~w~[~y~%d~w~] - [~y~%d~w~] ~b~Counter Terrorists",TeamKills[1],TeamKills[2]);
	TextDrawSetString(TeamScore,string);
	return 1;
}

stock KickEx(playerid, color, reason[])
{
    SendClientMessage(playerid, color, reason);
    return SetTimerEx("KickPlayer", GetPlayerPing(playerid) + 100, false, "i", playerid);
}
forward KickPlayer(playerid);
public KickPlayer(playerid) return Kick(playerid);

ResetServerSettings()
{
	ServerSettings[ssAntiCheat] = true;
	ServerSettings[ssLevels] = 13;
	ServerSettings[ssExpNeed] = 2;
	ServerSettings[ssAssists] = 2;
	ServerSettings[ssAutoteambalance] = 2;
	ServerSettings[ssTeamfire] = true;
	ServerSettings[ssAntiAFK] = true;
	ServerSettings[ssHeadshots] = true;
	ServerSettings[ssLevelCompensation] = true;
	ServerSettings[ssProgressBackup] = true;
	ServerSettings[ssOChat] = true;
	ServerSettings[ssVIPChat] = true;
	ServerSettings[ssTeamChat] = true;
	ServerSettings[ssPM] = true;
	ServerSettings[ssGameMode] = 1;
	ServerSettings[ssRoundTime] = 3;
	ServerSettings[ssBuyTime] = 10;
	ServerSettings[ssStartMoney] = 1000;
	ServerSettings[ssMaxMoney] = 16000;
}

UpdateExpTD(playerid)
{
	new string[35];
	if(ServerSettings[ssAssists] > 0)
	{
		switch(Assists[playerid])
		{
		    case 0: format(string,sizeof(string),"Exp: %d/%d (No assists)",KillScore[playerid],ServerSettings[ssExpNeed]);
		    case 1: format(string,sizeof(string),"Exp: %d/%d (1 assist)",KillScore[playerid],ServerSettings[ssExpNeed]);
		    default: format(string,sizeof(string),"Exp: %d/%d (%d assists)",KillScore[playerid],ServerSettings[ssExpNeed],Assists[playerid]);
		}
	}
	else format(string,sizeof(string),"Exp: %d/%d",KillScore[playerid],ServerSettings[ssExpNeed]);
	TextDrawSetString(exp[playerid],string);
}
UpdateLevelTD(playerid)
{
	new string[64];
	format(string,sizeof(string),"Level: %d/%d (%s)",GunLevel[playerid]+1,ServerSettings[ssLevels]+1,GetGunName(LevelWeapons[GunLevel[playerid]]));
	TextDrawSetString(level[playerid],string);
}

stock ShowConfigDialog(playerid)
{
	
	new string[700];
	if(ServerSettings[ssAntiCheat] == false) format(string,sizeof(string),"{ffffff}Античит {ff0000}(ВЫКЛ)\n");
	else format(string,sizeof(string),"{ffffff}Античит {00ff00}(ВКЛ)\n");
    if(ServerSettings[ssAutoteambalance] == 0) strcat(string,"{ffffff}Балансировка команд {ff0000}(ВЫКЛ)\n");
	else format(string,sizeof(string),"%s{ffffff}Балансировка команд {00ff00}(Перевес не более %d игроков)\n",string,ServerSettings[ssAutoteambalance]);
    if(ServerSettings[ssTeamfire] == false) strcat(string,"{ffffff}Огонь по своим {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Огонь по своим {00ff00}(ВКЛ)\n");
 	if(ServerSettings[ssAntiAFK] == false) strcat(string,"{ffffff}Анти АФК {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Анти АФК {00ff00}(ВКЛ)\n");
 	if(ServerSettings[ssHeadshots] == false) strcat(string,"{ffffff}Двойной урон при попадании в голову {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Двойной урон при попадании в голову {00ff00}(ВКЛ)\n");
	format(string,sizeof(string),"%s{ffffff}Количество уровней {00ff00}(%d)\n",string,ServerSettings[ssLevels]+1);
	format(string,sizeof(string),"%s{ffffff}EXP для повышения уровня {00ff00}(%d)\n",string,ServerSettings[ssExpNeed]);
	if(ServerSettings[ssAssists] == 0) strcat(string,"{ffffff}Ассисты для повышения EXP {ff0000}(Отключено)\n");
	else format(string,sizeof(string),"%s{ffffff}Ассисты для повышения EXP {00ff00}(%d)\n",string,ServerSettings[ssAssists]);
 	if(ServerSettings[ssLevelCompensation] == false) strcat(string,"{ffffff}Компенсация уровня {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Компенсация уровня {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssProgressBackup] == false) strcat(string,"{ffffff}Восстановление прогресса при перезаходе {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Восстановление прогресса при перезаходе {00ff00}(ВКЛ)\n");
 	if(ServerSettings[ssOChat] == false) strcat(string,"{ffffff}Общий чат {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Общий чат {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssVIPChat] == false) strcat(string,"{ffffff}Чат VIP игроков {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Чат VIP игроков {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssTeamChat] == false) strcat(string,"{ffffff}Чаты команд {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Чаты команд {00ff00}(ВКЛ)\n");
	if(ServerSettings[ssPM] == false) strcat(string,"{ffffff}Личные сообщения {ff0000}(ВЫКЛ)\n");
	else strcat(string,"{ffffff}Личные сообщения {00ff00}(ВКЛ)");
	if(PlayerInfo[playerid][pAdmin] < 7)
	{
		ShowPlayerDialog(playerid,8,DIALOG_STYLE_MSGBOX,"Игровые настройки",string,"Закрыть","Назад");
		return true;
	}
	strcat(string,"\n{ffffff}Оружия по уровням");
	strcat(string,"\n{0000ff}> {ffffff}Сбросить настройки");
 	ShowPlayerDialog(playerid,14,DIALOG_STYLE_LIST,"Панель конфигурации сервера",string,"Изменить","Закрыть");
	return true;
}
ShowLevelWeaponsMenu(playerid)
{
	new string[400];
	for(new i = 0;i<ServerSettings[ssLevels];i++)
    {
    	format(string,sizeof(string),"%sУровень %d - %s\n",string,i+1,GetGunName(LevelWeapons[i]));
    }
    ShowPlayerDialog(playerid,16,DIALOG_STYLE_LIST,"Оружия по уровням - Панель конфигурации сервера",string,"Изменить","Назад");
	return 1;
}
/*CMD:config(playerid,params[]) // отладочная команда, необходимо заменить или дописать
{
	if(PlayerInfo[playerid][pAdmin] < 7) return true;
	ShowConfigDialog(playerid);
	return true;
} */


/*stock GetADateAsString(timestamp, lenght, string[]) // Записывает в строку дату, конвертированную из unix, относительно текущего времени | Нуждается в тесте, еще не протестированно
{
	new cyear,cmonth,cday,chour,cminute,csecond, delta;
	new year,month,day,hour,minute,second;
	getdate(cyear,cmonth,cday);
	gettime(chour,cminute,csecond);
	delta = date_to_timestamp(cyear,cmonth,cday,chour,cminute,csecond) - timestamp;
	timestamp_to_date(timestamp,year,month,day,hour,minute,second);
	switch(delta)
	{
		case 0..59: format(string,lenght,"меньше минуты назад");
		case 60..119: format(string,lenght,"минуту назад");
		case 120..3599:
		{
			switch(minute % 10)
			{
			case 1: format(string,lenght,"%.0f минуту назад",float(minute)/60.0);
			case 2..4: format(string,lenght,"%.0f минуты назад",float(minute)/60.0);
			default: format(string,lenght,"%.0f минут назад",float(minute)/60.0);
			}
		}
		case 3600..7199: format(string,lenght,"час назад (в %d:%02d)",hour,minute);
		case 7200..10799: format(string,lenght,"два часа назад (в %d:%02d)",hour,minute);
		case 10800..14399: format(string,lenght,"три часа назад (в %d:%02d)",hour,minute);
		case 14400..86399:
		{
			if(chour > hour) format(string,lenght,"сегодня в %d:%02d",hour,minute);
			else format(string,lenght,"вчера в %d:%02d",hour,minute);
		}
		case 86400..172799:
		{
			if(chour > hour || (chour == hour && cminute > hour) || (chour == hour && cminute == minute && csecond >= second)) format(string,lenght,"вчера в %d:%02d",hour,minute);
			else format(string,lenght,"%d %s в %d:%02d",day, GetMonthName(month),hour,minute);
		}
		default:
		{
			if(cyear == year) format(string,lenght,"%d %s в %d:%02d",day, GetMonthName(month),hour,minute);
			else: format(string,lenght,"%d %s %d года в %d:%02d",day, GetMonthName(month),year,hour,minute);
		}
	}
	return true;
}*/
forward CheckForUpdates();
public CheckForUpdates()
{
	new day,month,year;
	getdate(year,month,day);
	day-=RELEASE_DAY;
	month-=RELEASE_MONTH;
	year-=RELEASE_YEAR;
	if(day < 0)
	{
		day+=31;
		month--;
	}
	if(month < 0)
	{
		month+=12;
		year--;
	}
	if(month > 0)
	{
		printf("");
		printf("ВНИМАНИЕ!");
		printf("Со дня выпуска текущей версии Гонки Вооружений прошло более месяца!");
		printf("Мы рекомендуем скачать самую последнюю сборку по адресу:");
		printf("> https://github.com/mdoynichenko <");
		printf("Подсказка: Для отключения уведомления измените макрос ANNOUNCE_IF_OLD на 0");
		printf("");
	}
	return true;
}
// Гонка Вооружений - v1.0
// (c) 2014-2016, MaDoy
