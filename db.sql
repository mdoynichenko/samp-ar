-- phpMyAdmin SQL Dump
-- version 3.5.1
-- http://www.phpmyadmin.net
--
-- Хост: 127.0.0.1
-- Время создания: Фев 09 2016 г., 15:03
-- Версия сервера: 5.5.25
-- Версия PHP: 5.3.13

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- База данных: `gungame`
--

-- --------------------------------------------------------

--
-- Структура таблицы `accounts`
--

CREATE TABLE IF NOT EXISTS `accounts` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(24) COLLATE cp1251_bin NOT NULL,
  `Password` varchar(30) CHARACTER SET utf8 NOT NULL,
  `Admin` int(11) NOT NULL DEFAULT '0',
  `Vip` int(11) NOT NULL DEFAULT '0',
  `Mute` int(11) NOT NULL DEFAULT '0',
  `Warn` int(11) NOT NULL DEFAULT '0',
  `Kills` int(11) NOT NULL DEFAULT '0',
  `Deaths` int(11) NOT NULL DEFAULT '0',
  `Cash` int(11) NOT NULL DEFAULT '0',
  `Wins` int(11) NOT NULL DEFAULT '0',
  `Games` int(11) NOT NULL DEFAULT '0',
  `Levels` int(11) NOT NULL DEFAULT '0',
  `BestSeries` int(11) NOT NULL DEFAULT '0',
  `Rank` int(11) NOT NULL DEFAULT '0',
  `Leaves` int(11) NOT NULL DEFAULT '0',
  `Rating` int(11) NOT NULL DEFAULT '0',
  `RankProgress` int(11) NOT NULL DEFAULT '0',
  `LGID` int(11) NOT NULL,
  `LGInfo` varchar(150) COLLATE cp1251_bin NOT NULL,
  `LGlevel` int(11) NOT NULL,
  `LGexp` int(11) NOT NULL,
  `Banned` int(11) NOT NULL,
  `BanInfo` varchar(70) COLLATE cp1251_bin NOT NULL,
  `CTime` int(11) NOT NULL,
  `RegIP` varchar(32) COLLATE cp1251_bin NOT NULL,
  `RegDate` bigint(20) NOT NULL,
  `LastConnection` bigint(20) NOT NULL,
  `LastIP` varchar(30) COLLATE cp1251_bin NOT NULL,
  `EMail` varchar(100) COLLATE cp1251_bin NOT NULL,
  `SName` varchar(35) COLLATE cp1251_bin NOT NULL,
  `Shots` bigint(20) NOT NULL,
  `GoodShots` bigint(20) NOT NULL,
  `DamageGiven` bigint(20) NOT NULL,
  `DamageTaken` bigint(20) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=cp1251 COLLATE=cp1251_bin AUTO_INCREMENT=134 ;


-- --------------------------------------------------------

--
-- Структура таблицы `achatlog`
--

CREATE TABLE IF NOT EXISTS `achatlog` (
  `MessageID` bigint(20) NOT NULL AUTO_INCREMENT,
  `SenderName` varchar(32) NOT NULL,
  `SenderID` bigint(20) NOT NULL,
  `SenderALevel` int(11) NOT NULL,
  `Message` varchar(128) NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=13 ;

--
-- Структура таблицы `connectlog`
--

CREATE TABLE IF NOT EXISTS `connectlog` (
  `LogID` bigint(20) NOT NULL AUTO_INCREMENT,
  `PlayerName` varchar(32) NOT NULL,
  `PlayerID` bigint(20) NOT NULL,
  `ConnectType` int(11) NOT NULL,
  `PlayerALevel` int(11) NOT NULL,
  `PlayerIP` varchar(32) NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`LogID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=265 ;

-- --------------------------------------------------------

--
-- Структура таблицы `games`
--

CREATE TABLE IF NOT EXISTS `games` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Winner` varchar(32) NOT NULL,
  `KillsT` int(11) NOT NULL,
  `KillsCT` int(11) NOT NULL,
  `Date` bigint(20) NOT NULL,
  `Code` int(11) NOT NULL,
  `Map` varchar(20) NOT NULL,
  `Shots` bigint(20) NOT NULL,
  `GoodShots` bigint(20) NOT NULL,
  `Time` int(11) NOT NULL,
  `BestShotQuallityName` varchar(32) NOT NULL,
  `BestShotQuallity` int(11) NOT NULL,
  `BestKDName` varchar(32) NOT NULL,
  `BestKD` double NOT NULL,
  `BestKillerName` varchar(32) NOT NULL,
  `BestKills` int(11) NOT NULL,
  `BestSeriesName` varchar(32) NOT NULL,
  `BestSeries` int(11) NOT NULL,
  `BestDeathsName` varchar(32) NOT NULL,
  `BestDeaths` int(11) NOT NULL,
  `BestHealingsName` varchar(32) NOT NULL,
  `BestHealings` int(11) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

-- --------------------------------------------------------

--
-- Структура таблицы `ochatlog`
--

CREATE TABLE IF NOT EXISTS `ochatlog` (
  `MessageID` bigint(20) NOT NULL AUTO_INCREMENT,
  `SenderName` varchar(32) NOT NULL,
  `SenderID` int(11) NOT NULL,
  `SenderTeam` int(11) NOT NULL,
  `Message` varchar(128) CHARACTER SET cp1251 NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=280 ;

-- --------------------------------------------------------

--
-- Структура таблицы `pmchatlog`
--

CREATE TABLE IF NOT EXISTS `pmchatlog` (
  `MessageID` bigint(20) NOT NULL AUTO_INCREMENT,
  `SenderName` varchar(32) NOT NULL,
  `SenderID` bigint(20) NOT NULL,
  `TakingName` varchar(32) NOT NULL,
  `TakingID` bigint(20) NOT NULL,
  `Message` varchar(128) NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;


-- --------------------------------------------------------

--
-- Структура таблицы `tchatlog`
--

CREATE TABLE IF NOT EXISTS `tchatlog` (
  `MessageID` bigint(20) NOT NULL AUTO_INCREMENT,
  `SenderName` varchar(32) NOT NULL,
  `SenderID` bigint(20) NOT NULL,
  `SenderTeam` int(11) NOT NULL,
  `Message` varchar(128) NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=12 ;

-- --------------------------------------------------------

--
-- Структура таблицы `vchatlog`
--

CREATE TABLE IF NOT EXISTS `vchatlog` (
  `MessageID` bigint(20) NOT NULL AUTO_INCREMENT,
  `SenderName` varchar(32) NOT NULL,
  `SenderID` bigint(20) NOT NULL,
  `Message` varchar(128) NOT NULL,
  `Time` bigint(20) NOT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3 ;


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
