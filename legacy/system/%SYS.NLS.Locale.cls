/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// Exposes some properties and methods associated with
/// a locale. If no locale is given to %New(), then the
/// current one is used.<br><br>
/// 
/// For system and process NLS table settings see <class>%SYS.NLS.Table</class>.<br>
/// For current device NLS properties see <class>%SYS.NLS.Device</class>.<br>
/// For date, time and number format properties see <class>%SYS.NLS.Format</class>.<br>
Class %SYS.NLS.Locale Extends %RegisteredObject [ System = 4 ]
{

/// List of available Accent tables.
Property AccentTables As %String;

/// Name of character set on which the current locale is based.
Property CharacterSet As %String;

/// List of available collation tables.
Property CollationTables As %String;

/// Country supported by the current locale.
Property Country As %String;

/// ISO 3166-1 alpha-2 two-letter abbreviation of Country.
Property CountryAbbr As %String;

/// Currency symbol.
Property Currency As %String;

/// Short description of the current locale.
Property Description As %String;

/// List of available identifier tables.
Property IdentifierTables As %String;

/// Localization language for the current locale.
Property Language As %String;

/// ISO 639-1 two-letter abbreviation of Language.<br><br>
/// In a few cases, where the language is used by more than one country,
/// this abbreviation is hyphenated with the uppercase abbreviation of
/// the country. For example, en-US, en-GB, pt-BR.
Property LanguageAbbr As %String;

/// List of available lower-case tables.
Property LowerCaseTables As %String;

/// Code name of the current locale.
Property Name As %String;

/// List of available pattern match tables.
Property PatternTables As %String;

/// List of available title-case tables.
Property TitleCaseTables As %String;

/// List of available upper-case tables.
Property UpperCaseTables As %String;

/// List of available translation (i/o) tables
Property XLTTables As %String;

/// List of available $X/$Y tables.
Property XYTables As %String;

Method %OnNew(sloc As %String = "") As %Status [ Internal ]
{
 Set $ZT="Error"
 If sloc="",'$D($$$LOCALENAME,sloc) Quit $$$ERROR($$$GeneralError,"Current locale is undefined")
 Set rloc=$Name($$$NLSLocalesGbl),rloc=$Name(@rloc@(sloc)),lrec=$G(@rloc)
 If lrec="" Quit $$$ERROR($$$GeneralError,"Could not access locale "_sloc)
 Set ..Name=sloc
 Set ..CharacterSet=$$$GetLocaleCharacterSet(lrec)
 Set ..Country=$$$GetLocaleCountry(lrec)
 Set ..CountryAbbr=$$$GetLocaleCountryAbbr(lrec)
 Set ..Currency=$$$GetLocaleCurrency(lrec)
 Set ..Description=$$$GetLocaleDescription(lrec)
 Set ..Language=$$$GetLocaleLanguage(lrec)
 Set ..LanguageAbbr=$$$GetLocaleLanguageAbbr(lrec)
 #; Available tables
 Set ..AccentTables=$$$GetLocaleAccentTables(lrec)
 Set ..CollationTables=$$$GetLocaleCollationTables(lrec)
 Set ..IdentifierTables=$$$GetLocaleIdentifierTables(lrec)
 Set ..LowerCaseTables=$$$GetLocaleLowerCaseTables(lrec)
 Set ..PatternTables=$$$GetLocalePatternTables(lrec)
 Set ..TitleCaseTables=$$$GetLocaleTitleCaseTables(lrec)
 Set ..UpperCaseTables=$$$GetLocaleUpperCaseTables(lrec)
 Set ..XYTables=$$$GetLocaleXYTables(lrec)
 Set tabs=$LB(..CharacterSet,"RAW","BIN","SAME","UTF8","UnicodeLittle","UnicodeBig","URL","JS","JSML","JSON","JSONML","HTML","XML","XMLA","XMLC")
 Set tab=$O(@rloc@("XLTTables",""))
 While tab'="" { Set:'$LF(tabs,tab) tabs=tabs_$LB(tab) Set tab=$O(@rloc@("XLTTables",tab)) }
 Set ..XLTTables=tabs
 Quit $$$OK
 
Error Set $ZT=""
 Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Returns the language associated with a locale as<br>
/// $LB({Property LanguageAbbr},{Property Language})<br><br>
/// Parameters:<ul>
///   <li>Loc - Locale code (optional)</li></ul>
/// If the locale code is not given, use the current locale.<br>
ClassMethod GetLanguage(Loc As %String = "") As %List
{
 #; Force character size to be consistent with current system
 Set sfx=$S($ZBitget($ZVersion(0),1):"w",1:"8")
 If Loc="" {
	#; Use current locale 
 	Set Loc=$G($$$LOCALENAME)
 	If Loc="" Set Loc="enu"_sfx
 } Else { Set Loc=$E(Loc,1,3)_sfx }
 Set rloc=$Name($$$NLSLocalesGbl),rloc=$Name(@rloc@(Loc)),lrec=$G(@rloc)
 If lrec="" { Set abbr="en-US",lang="English" }
 Else { Set abbr=$$$GetLocaleLanguageAbbr(lrec),lang=$$$GetLocaleLanguage(lrec)}
 Quit $LB(abbr,lang)
}

}
