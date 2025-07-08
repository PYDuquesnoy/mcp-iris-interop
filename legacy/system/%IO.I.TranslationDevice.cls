/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occIO

/// This class is intended as a secondary superclass for those Stream classes that are implemented using InterSystems IRIS devices and thus support the use of a Translation Table for character set conversion on input, on output, or both.
/// It contains a property TranslationTable that names the translation table to be used, if any. It also implements a number of classmethods to support the use of a Translation Table.
/// This class also extends the class ILineStream which facilitates line-by-line Read and Write operations.
Class %IO.I.TranslationDevice Extends %IO.IParts.CharacterIO [ Abstract, System = 2 ]
{

/// The name of the TranslationTable in effect for the Stream's device.
Property TranslationTable As %String;

/// Does the TranslationTable currently in effect represent a single-byte encoding.
Property IsSingleByte As %Boolean;

/// Set translation table based on character encoding
Method SetCharEncodingTable(pCharEncoding As %String, pCharEncodingAlias As %String) As %Status
{

	Set tTable=..GetCharEncodingTable(pCharEncoding)
	Quit:""=tTable $$$ERROR($$$ErrIONoCharTable,$G(pCharEncodingAlias,pCharEncoding))
	Quit ..SetTranslationTable(tTable)
}

Method TranslationTableSet(pTable As %String) As %Status [ CodeMode = expression ]
{
..SetTranslationTable(.pTable)
}

Method SetTranslationTable(pTable As %String) As %Status
{
	Quit:i%TranslationTable=pTable $$$OK
	If ""'=..Name&&..IsOpen Do ..SetDeviceTranslationTable(..Name,pTable,.tSC)  Quit:$$$ISERR(tSC) tSC
	Set i%TranslationTable=pTable, ..IsSingleByte=..IsTableSingleByte(pTable)
	Quit $$$OK
}

ClassMethod IsTableSingleByte(pTable As %String) As %String [ CodeMode = expression ]
{
$S(pTable="RAW":1, "Latin"=$E(pTable,1,$L("Latin")):1, 1:0)
}

ClassMethod GetCharEncodingTable(pCharEncoding As %String) As %String
{
	Set pCharEncoding=$ZStrip(pCharEncoding,"<>WC"), tLowerCE=$ZCVT(pCharEncoding,"L")
	If "@"=$E(tLowerCE) { Set $ZT="NoTT"  Set x=$ZCVT("","O",$E(pCharEncoding,2,*))  Quit $E(pCharEncoding,2,*) }
	ElseIf tLowerCE["8859" { Set (pCharEncoding,tLowerCE)="ISO-8859-"_$TR($E(pCharEncoding,$F(pCharEncoding,"8859"),*)," -_/") }
	ElseIf tLowerCE["latin" { Set (pCharEncoding,tLowerCE)="Latin"_$TR($E(pCharEncoding,$F(tLowerCE,"latin"),*)," -_/") }
	Else {
		Set tStripCE=$TR(tLowerCE," -_/")
		Set:$Case($E(tStripCE,1,4),"unic":1,"ucs2":1,"utf1":1,:0) tLowerCE=tStripCE
	}
	Set pCharEncoding=$Case(tLowerCE,
		"ISO-8859-":"ISO-8859-1",
		"Latin":"Latin1",
		"utf8":"utf-8",
		"unicode":"utf16le",
		"utf16":"utf16le",
		"ucs2":"utf16le",
		"unicodelittle":"utf16le",
		"unicodele":"utf16le",
		"unicodefffe":"utf16le",
		"utf16little":"utf16le",
		"utf16le":"utf16le",
		"utf16fffe":"utf16le",
		"ucs2le":"utf16le",
		"ucs2le":"utf16le",
		"ucs2fffe":"utf16le",
		"unicodebig":"utf16be",
		"unicodebe":"utf16be",
		"unicodefeff":"utf16be",
		"utf16big":"utf16be",
		"utf16be":"utf16be",
		"utf16feff":"utf16be",
		"ucs2big":"utf16be",
		"ucs2be":"utf16be",
		"ucs2feff":"utf16be",
		:pCharEncoding)
	Quit $Case(tLowerCE,
		"rawbytes":"RAW",
		"binary":"RAW",
		"bin":"RAW",
		"":"RAW",
		"unicodelocal":"Unicode",
		"unicodenative":"Unicode",
		"utf16local":"Unicode",
		"utf16native":"Unicode",
		"ucs2local":"Unicode",
		"ucs2native":"Unicode",
		"local":..GetLocaleDefaultTable(),
		"native":..GetLocaleDefaultTable(),
		"default":..GetLocaleDefaultTable(),
		:$S(##class(%Net.Charset).TranslateTableExists(pCharEncoding):$$MapCharset^%NLS(pCharEncoding),1:""))
NoTT Set $ZT=""
	Quit ""
}

ClassMethod GetLocaleDefaultTable() As %String [ CodeMode = expression ]
{
$$DefIO^%NLS(5)
}

ClassMethod IsLocaleUnicode() As %Boolean [ CodeMode = expression ]
{
$zbitget($zversion(0),1)
}

ClassMethod GetTableCharEncoding(pTable As %String) As %String
{
	Quit:""=pTable "Native"
	Set tCharEncoding =$$MapExtCharset^%NLS(pTable)
	Quit:""=tCharEncoding "@"_pTable
	Quit tCharEncoding
}

ClassMethod GetDeviceTranslationTable(pDevice As %String) As %String
{
	Set tIO=$IO  Use:pDevice'=tIO pDevice Set tTable=$$GetIO^%NLS()  Use:pDevice'=tIO tIO
	Quit tTable
	Set tIO=$IO  Set $ZTRAP="Trap"
	Use:pDevice'=tIO pDevice  
	Set tTable=$$GetIO^%NLS()
Exit
	Use:pDevice'=tIO tIO
	Quit tTable
Trap
	Set $ZT="",tTable=""
	Goto Exit
}

ClassMethod SetDeviceTranslationTable(pDevice As %String, pTable As %String, Output pSC As %Status) As %String
{
	Set pSC=$$$OK,tIO=$IO  Set $ZTRAP="Trap"
	Use:pDevice'=tIO pDevice
	Set tCurrTable=$$GetIO^%NLS()
	Do SetIO^%NLS(pTable)
Exit
	Use:pDevice'=tIO tIO
	Quit tCurrTable
Trap
	Set $ZT="",tZE=$ZE,tCurrTable=$G(tCurrTable)
	Set pSC = $$$ERROR($$$GeneralError,$G(tZE))
	Goto Exit
}

ClassMethod GetDeviceLineTerminator(pDevice As %String) As %String
{
	Set tIO=$IO  Set $ZTRAP="Trap"
	Use:pDevice'=tIO pDevice  
	Set tLineTerm=$system.Device.GetReadTerminators()
Exit
	Use:pDevice'=tIO tIO
	Quit tLineTerm
Trap
	Set $ZT="",tLineTerm=""
	Goto Exit
}

ClassMethod SetDeviceLineTerminator(pDevice As %String, pLineTerm As %String, Output pSC As %Status)
{
	Set pSC=$$$OK  Quit:"|TCP|"'=$E(pDevice,1,5)  // !!! Set it to the system from pLineTerm
	Set tIO=$IO  Set $ZTRAP="Trap"
	Use pDevice:(::"+":pLineTerm)
Exit
	Use:pDevice'=tIO tIO
	Quit
Trap
	Set $ZT="",tZE=$ZE
	Set pSC = $$$ERROR($$$GeneralError,$g(tZE))
	Goto Exit
}

}
