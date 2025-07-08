/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class to represent MIME charsets within InterSystems IRIS and map these charsets
/// to InterSystems IRIS locales.
Class %Net.Charset [ System = 3 ]
{

/// Test if the translate table name for the input charset name is loaded.
ClassMethod TranslateTableExists(charset As %String, Output table) As %Boolean
{
	set $ZTRAP="NoTT"
	set table=$$MapCharset^%SYS.NLS(charset)
	if table="" quit 0
	set x=$zcvt("","O",table)
	quit 1
NoTT Set $ZTRAP=""
	quit 0
}

/// Return the translate table name for the given charset name. 
/// For information on translate tables, see <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.</p>
ClassMethod GetTranslateTable(ByRef charset As %String) As %String
{
	if charset="" set charset=..GetDefaultCharset()
	Quit $$MapCharset^%SYS.NLS(charset)
}

/// Return default charset for the current locale.
ClassMethod GetDefaultCharset() As %String
{
	if ..IsLocaleUnicode() {
		#; On unicode default CharSet is UTF-8 always
		quit "UTF-8"
	} else {
		#; For 8-bit system ask for locale default charset.
		quit $$MapExtCharset^%SYS.NLS($$GetCharset^%SYS.NLS())
	}
}

ClassMethod IsLocaleUnicode() As %Integer [ CodeMode = expression ]
{
$zbitget($zversion(0),1)
}

}
