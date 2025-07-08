/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.MetaInfo [ System = 4 ]
{

Query ProjectableClasses(pLanguage As %String) As %Query(ROWSPEC = "ClassName:%String")
{
}

ClassMethod ProjectableClassesExecute(ByRef qHandle As %Binary, pLanguage As %String) As %Status
{
	set qHandle=$lb($g(pLanguage),"")
	quit $$$OK
}

ClassMethod ProjectableClassesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ProjectableClassesExecute ]
{
	kill qHandle
	quit $$$OK
}

ClassMethod ProjectableClassesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ProjectableClassesExecute ]
{
	if AtEnd quit $$$OK
	set language=$li(qHandle,1)
	set class=$li(qHandle,2)
	for  {
		set class=$o(^rINDEXCLASS(class)) quit:class=""
		if $$isClientSpecialClass^%occMetaInfo(class,language) continue
		if $$$comClassKeyGet(class,$$$cCLASSserveronly) continue
		quit
	}
	set Row=$lb($li(^rINDEXCLASS(class),2))
	set qHandle=$lb(language,class)
	set AtEnd=((class="")||($o(^rINDEXCLASS(class))=""))
	quit $$$OK
}

}
