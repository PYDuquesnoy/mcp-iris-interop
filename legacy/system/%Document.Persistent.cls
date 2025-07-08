/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Document.Persistent Extends %Persistent [ Abstract, NoExtent, PropertyClass = %Document.Property, StorageStrategy = EDoc, System = 3 ]
{

Property %Document As %Document.Object;

Method %DocumentGetObject(force As %Integer = 0) As %Library.ObjectIdentity
{
	quit $$$oidCompose($Select(r%%Document'="":r%%Document,1:""),"%Document.Object")
}

Method %DocumentGetObjectId(force As %Integer = 0) As %Library.String
{
	quit $Select(r%%Document'="":r%%Document,1:"")
}

ClassMethod %Get(id As %Integer = "", pDocument As %Binary = "", pFieldExpr As %String(MAXLEN="") = "") As %Binary [ CodeMode = generator, SqlName = Get, SqlProc ]
{
	if '($$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
		set tLocation = $Get($$$EXTPROPondisk($$$pEXT,%class,"%Document"))
			// I don't like this - we shouldn't rely on the expression form in this context!
		set tLocation = $Extract(tLocation,4,*-2) _ ",tDocumentId,"
		$$$GENERATE($Char(9)_"try {")
		$$$GENERATE($Char(9,9)_"")
		$$$GENERATE($Char(9,9)_"set tValue = """", tDocumentId = 1")
		$$$GENERATE($Char(9,9)_"if pFieldExpr '[ ""."" {")
		$$$GENERATE($Char(9,9,9)_"if '$Isobject(pDocument) { set tValue = $Get("_tLocation_"1,pFieldExpr)) }")
		$$$GENERATE($Char(9,9,9)_"else { set tValue = $Select(pFieldExpr'=+pFieldExpr:$property(pDocument,pFieldExpr),1:pDocument.GetAt(pFieldExpr)) }")
		$$$GENERATE($Char(9,9)_"}")
		$$$GENERATE($Char(9,9)_"elseif '$Isobject(pDocument) {")
		$$$GENERATE($Char(9,9,9)_"do parseDotExpr^%occStorageUtil(pFieldExpr,.tFieldToken)")
		$$$GENERATE($Char(9,9,9)_"set tBaseRef = $Name("_$Extract(tLocation,1,*-1)_"))")
		$$$GENERATE($Char(9,9,9)_"set tObject = $Get(@(tBaseRef)@(1,tFieldToken(1)))")
		$$$GENERATE($Char(9,9,9)_"for tPtr = 2:1:tFieldToken-1 {")
		$$$GENERATE($Char(9,9,9,9)_"set tObject = $Get(@(tBaseRef)@($Extract(tObject,2,*),tFieldToken(tPtr)))")
		$$$GENERATE($Char(9,9,9)_"}")
		$$$GENERATE($Char(9,9,9)_"set tValue =  $Get(@(tBaseRef)@($Extract(tObject,2,*),tFieldToken(tFieldToken)))")
		$$$GENERATE($Char(9,9)_"}")
		$$$GENERATE($Char(9,9)_"else {")
		$$$GENERATE($Char(9,9,9)_"do parseDotExpr^%occStorageUtil(pFieldExpr,.tFieldToken)")
		$$$GENERATE($Char(9,9,9)_"set tObject = $Select(tFieldToken(1)'=+tFieldToken(1):$property(pDocument,tFieldToken(1)),1:pDocument.GetAt(tFieldToken(1)))")
		$$$GENERATE($Char(9,9,9)_"for tPtr = 2:1:tFieldToken-1 {")
		$$$GENERATE($Char(9,9,9,9)_"set tObject = $Select(tFieldToken(tPtr)'=+tFieldToken(tPtr):$property(tObject,tFieldToken(tPtr)),1:tObject.GetAt(tFieldToken(tPtr)))")
		$$$GENERATE($Char(9,9,9)_"}")
		$$$GENERATE($Char(9,9,9)_"set tValue = $Select(tFieldToken(tFieldToken)'=+tFieldToken(tFieldToken):$property(tObject,tFieldToken(tFieldToken)),1:tObject.GetAt(tFieldToken(FieldToken)))")
		$$$GENERATE($Char(9,9)_"}")
		$$$GENERATE($Char(9)_"}")
		$$$GENERATE($Char(9)_"catch tException {")
		$$$GENERATE($Char(9,9)_"set tValue = """"")
		$$$GENERATE($Char(9)_"}")
		$$$GENERATE($Char(9)_"quit tValue")
		$$$GENERATE($Char(9)_"")
	}
	quit $$$OK
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew(pDocument As %String(MAXLEN="") = "") As %Status [ Private, ServerOnly = 1 ]
{
	set ..%Document = ##class(%Document.Object).%New(pDocument)
	Quit $$$OK
}

Storage EDoc
{
<Data name="Document">
<Attribute>%Document</Attribute>
<Structure>subnode</Structure>
<Subscript>1</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}
