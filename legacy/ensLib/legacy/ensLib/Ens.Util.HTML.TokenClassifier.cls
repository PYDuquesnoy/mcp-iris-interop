/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Uses a table to classify tokens
Class Ens.Util.HTML.TokenClassifier Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Property TokenTable [ MultiDimensional ];

/// tokens - Definition of tokens for possible parsing requirements
Parameter tokUNKN = 0;

Parameter tokBOFL = 1;

Parameter tokEOFL = 2;

Parameter tokEOS = 3;

Parameter tokNEWLN = 4;

Parameter tokSPACE = 5;

Parameter tokRETURN = 6;

Parameter tokFORMFD = 7;

Parameter tokLETTER = 8;

Parameter tokDIGIT = 9;

Parameter tokDOT = 10;

Parameter tokARROW = 11;

Parameter tokATSIGN = 12;

Parameter tokDQUOTE = 13;

Parameter tokLPARN = 14;

Parameter tokDOLLAR = 15;

Parameter tokPERCENT = 16;

Parameter tokSQUOTE = 17;

Parameter tokMINUS = 18;

Parameter tokPLUS = 19;

Parameter tokRPARN = 20;

Parameter tokCOMMA = 21;

Parameter tokCRLF = 22;

Parameter tokSEMI = 23;

Parameter tokASTER = 24;

Parameter tokSLASH = 25;

Parameter tokPOUND = 26;

Parameter tokBSLASH = 27;

Parameter tokUSCORE = 28;

Parameter tokEQUAL = 29;

Parameter tokLESS = 30;

Parameter tokGREAT = 31;

Parameter tokLBRACK = 32;

Parameter tokRBRACK = 33;

Parameter tokAMPER = 34;

Parameter tokEXCLA = 35;

Parameter tokQUEST = 36;

Parameter tokCOLON = 37;

Parameter tokVBAR = 38;

Parameter tokLBRACE = 39;

Parameter tokRBRACE = 40;

Parameter tokBQUOTE = 41;

Parameter tokTILDE = 42;

Method Classify(c As %String) As %Integer [ CodeMode = expression ]
{
$Select($a(c)>127:..#tokLETTER,1:..TokenTable($a(c)))
}

Method initTab() As %Status
{
	Quit:$Data(..TokenTable) $$$OK
	Set ..TokenTable(0)=..#tokUNKN,		..TokenTable(1)=..#tokUNKN,			..TokenTable(2)=..#tokUNKN,			..TokenTable(3)=..#tokUNKN
	Set ..TokenTable(4)=..#tokUNKN,		..TokenTable(5)=..#tokUNKN,			..TokenTable(6)=..#tokUNKN,			..TokenTable(7)=..#tokUNKN 
	Set ..TokenTable(8)=..#tokUNKN,		..TokenTable(9)=..#tokSPACE,		..TokenTable(10)=..#tokSPACE,		..TokenTable(11)=..#tokUNKN
	Set ..TokenTable(12)=..#tokUNKN,	..TokenTable(13)=..#tokSPACE,		..TokenTable(14)=..#tokUNKN,		..TokenTable(15)=..#tokUNKN
	Set ..TokenTable(16)=..#tokUNKN,	..TokenTable(17)=..#tokUNKN,		..TokenTable(18)=..#tokUNKN,		..TokenTable(19)=..#tokUNKN
	Set ..TokenTable(20)=..#tokUNKN,	..TokenTable(21)=..#tokUNKN,		..TokenTable(22)=..#tokUNKN,		..TokenTable(23)=..#tokUNKN
	Set ..TokenTable(24)=..#tokUNKN,	..TokenTable(25)=..#tokUNKN,		..TokenTable(26)=..#tokUNKN,		..TokenTable(27)=..#tokUNKN
	Set ..TokenTable(28)=..#tokUNKN,	..TokenTable(29)=..#tokUNKN,		..TokenTable(30)=..#tokUNKN,		..TokenTable(31)=..#tokUNKN
	Set ..TokenTable(32)=..#tokSPACE,	..TokenTable(33)=..#tokEXCLA,		..TokenTable(34)=..#tokDQUOTE,		..TokenTable(35)=..#tokPOUND
	Set ..TokenTable(36)=..#tokDOLLAR,	..TokenTable(37)=..#tokPERCENT,		..TokenTable(38)=..#tokAMPER,		..TokenTable(39)=..#tokSQUOTE
	Set ..TokenTable(40)=..#tokLPARN,	..TokenTable(41)=..#tokRPARN,		..TokenTable(42)=..#tokASTER,		..TokenTable(43)=..#tokPLUS
	Set ..TokenTable(44)=..#tokCOMMA,	..TokenTable(45)=..#tokMINUS,		..TokenTable(46)=..#tokDOT,			..TokenTable(47)=..#tokSLASH
	Set ..TokenTable(48)=..#tokDIGIT,	..TokenTable(49)=..#tokDIGIT,		..TokenTable(50)=..#tokDIGIT,		..TokenTable(51)=..#tokDIGIT
	Set ..TokenTable(52)=..#tokDIGIT,	..TokenTable(53)=..#tokDIGIT,		..TokenTable(54)=..#tokDIGIT,		..TokenTable(55)=..#tokDIGIT
	Set ..TokenTable(56)=..#tokDIGIT,	..TokenTable(57)=..#tokDIGIT,		..TokenTable(58)=..#tokCOLON,		..TokenTable(59)=..#tokSEMI
	Set ..TokenTable(60)=..#tokLESS,	..TokenTable(61)=..#tokEQUAL,		..TokenTable(62)=..#tokGREAT,		..TokenTable(63)=..#tokQUEST
	Set ..TokenTable(64)=..#tokATSIGN,	..TokenTable(65)=..#tokLETTER,		..TokenTable(66)=..#tokLETTER,		..TokenTable(67)=..#tokLETTER
	Set ..TokenTable(68)=..#tokLETTER,	..TokenTable(69)=..#tokLETTER,		..TokenTable(70)=..#tokLETTER,		..TokenTable(71)=..#tokLETTER
	Set ..TokenTable(72)=..#tokLETTER,	..TokenTable(73)=..#tokLETTER,		..TokenTable(74)=..#tokLETTER,		..TokenTable(75)=..#tokLETTER
	Set ..TokenTable(76)=..#tokLETTER,	..TokenTable(77)=..#tokLETTER,		..TokenTable(78)=..#tokLETTER,		..TokenTable(79)=..#tokLETTER
	Set ..TokenTable(80)=..#tokLETTER,	..TokenTable(81)=..#tokLETTER,		..TokenTable(82)=..#tokLETTER,		..TokenTable(83)=..#tokLETTER
	Set ..TokenTable(84)=..#tokLETTER,	..TokenTable(85)=..#tokLETTER,		..TokenTable(86)=..#tokLETTER,		..TokenTable(87)=..#tokLETTER
	Set ..TokenTable(88)=..#tokLETTER,	..TokenTable(89)=..#tokLETTER,		..TokenTable(90)=..#tokLETTER,		..TokenTable(91)=..#tokLBRACK
	Set ..TokenTable(92)=..#tokBSLASH,	..TokenTable(93)=..#tokRBRACK,		..TokenTable(94)=..#tokARROW,		..TokenTable(95)=..#tokUSCORE
	Set ..TokenTable(96)=..#tokBQUOTE,	..TokenTable(97)=..#tokLETTER,		..TokenTable(98)=..#tokLETTER,		..TokenTable(99)=..#tokLETTER
	Set ..TokenTable(100)=..#tokLETTER,	..TokenTable(101)=..#tokLETTER,		..TokenTable(102)=..#tokLETTER,		..TokenTable(103)=..#tokLETTER
	Set ..TokenTable(104)=..#tokLETTER,	..TokenTable(105)=..#tokLETTER,		..TokenTable(106)=..#tokLETTER,		..TokenTable(107)=..#tokLETTER
	Set ..TokenTable(108)=..#tokLETTER,	..TokenTable(109)=..#tokLETTER,		..TokenTable(110)=..#tokLETTER,		..TokenTable(111)=..#tokLETTER
	Set ..TokenTable(112)=..#tokLETTER,	..TokenTable(113)=..#tokLETTER,		..TokenTable(114)=..#tokLETTER,		..TokenTable(115)=..#tokLETTER
	Set ..TokenTable(116)=..#tokLETTER,	..TokenTable(117)=..#tokLETTER,		..TokenTable(118)=..#tokLETTER,		..TokenTable(119)=..#tokLETTER
	Set ..TokenTable(120)=..#tokLETTER,	..TokenTable(121)=..#tokLETTER,		..TokenTable(122)=..#tokLETTER,		..TokenTable(123)=..#tokLBRACE
	Set ..TokenTable(124)=..#tokVBAR,	..TokenTable(125)=..#tokRBRACE,		..TokenTable(126)=..#tokTILDE,		..TokenTable(127)=..#tokUNKN
	Quit $$$OK
}

}
