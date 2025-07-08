/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.RoseLinkUtility Extends %RegisteredObject [ System = 3 ]
{

Property XmlStream As %GlobalCharacterStream;

Property MemberListStream As %GlobalCharacterStream;

Property NewClassname As %String(MAXLEN = 32768);

Method LoadToXmlStream(tClassname As %String) As %Status
{
	Set tStream=##class(%FileCharacterStream).%New()
	Do tStream.Write("")
	Set tSC = $system.OBJ.Export(tClassname_".cls",tStream.Filename,"") Quit:$$$ISERR(tSC) tSC
	Set tSC = ..XmlStream.CopyFrom(tStream) Quit:$$$ISERR(tSC) tSC
	Quit $$$OK
}

Method SaveFromXmlStream() As %Status
{
	Set tStream=##class(%FileCharacterStream).%New()
 	If ..NewClassname="" {
 		Set tSC = tStream.CopyFrom(..XmlStream) Quit:$$$ISERR(tSC) tSC
 	} Else {
 		Set tLine=..XmlStream.Read(10000)
 		Set f=$f(tLine,"<Class name=""")
 		Set g=$f(tLine,"""",f)
 		If f,g Set $e(tLine,f,g-2)=..NewClassname
 		Do tStream.Write(tLine)
 		For  Quit:..XmlStream.AtEnd  Do tStream.Write(..XmlStream.Read(10000))
 	}
	Do tStream.SaveStream()
	Set tSC = $system.OBJ.Load(tStream.Filename,"-c",,.loaded) Quit:$$$ISERR(tSC) tSC
	Do ##class(%File).Delete(tStream.Filename)
	; get classname
	If loaded["," Quit $$$OK
	If $e(loaded,$l(loaded)-3,$l(loaded))'=".cls" Quit $$$OK
	Set classname=$e(loaded,1,$l(loaded)-4)
	; purge members
	For  Set line=..MemberListStream.ReadLine() Quit:line=""  Set existing(line)=""
	Set class=##class(%Dictionary.ClassDefinition).%OpenId(classname)
	If class=$$$NULLOREF Quit $$$OK
	For i=class.Properties.Count():-1:1 If $data(existing("a:"_class.Properties.GetAt(i).Name))=0 Do class.Properties.RemoveAt(i)
	For i=class.Methods.Count():-1:1 If $data(existing("m:"_class.Methods.GetAt(i).Name))=0 Do class.Methods.RemoveAt(i)
	Do class.%Save()
	Quit $$$OK
}

ClassMethod SupportFeature(feature = "") As %Boolean
{
	i feature="Security" q 1
	q 0
}

ClassMethod HasSecurityPermission() As %Boolean
{
	Quit $System.Security.Check("%Development","USE")
}

}
