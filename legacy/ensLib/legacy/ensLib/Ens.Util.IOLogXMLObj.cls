/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A header class that records raw Adapter Inputs and Outputs
Class Ens.Util.IOLogXMLObj Extends Ens.Util.IOLogObj [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property InObjectXML As %GlobalBinaryStream;

Property OutObjectXML As %GlobalBinaryStream;

Method IsEmpty() As %Boolean
{
	Quit ""=..%Id()&&'$IsObject(..InObject)&&'$IsObject(..OutObject)
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	If $IsObject(..InObject) {
		If ..InObject.%Extends("%XML.Adaptor") {
			Do ..InObject.XMLExportToStream(..InObjectXML)
			//Set ..InObjectXML = ..InObject.XMLExportToString()
		} Else {
			Do ..InObjectXML.Write("No XML facility for non-Persistent, non-XML-Enabled object "_..InObject)
			//Set ..InObjectXML = "No XML facility for non-Persistent, non-XML-Enabled object "_..InObject
		}
	}
	If $IsObject(..OutObject) {
		If ..OutObject.%Extends("%XML.Adaptor") {
			Do ..OutObject.XMLExportToStream(..OutObjectXML)
			//Set ..OutObjectXML = ..OutObjectXML_" | "_..OutObject.XMLExportToString()
		} Else {
			Do ..OutObjectXML.Write("No XML facility for non-Persistent, non-XML-Enabled object "_..OutObject)
			//Set ..OutObjectXML = ..OutObjectXML_" | "_"No XML facility for non-Persistent, non-XML-Enabled object "_..OutObject
		}
	}
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private ]
{
	Set tSC=##Class(Ens.Util.XML.Reader).ObjectFromStream(.tObj,..InObjectXML,..InObjectClass)  Set:$$$ISOK(tSC) ..InObject=tObj
	Set tSC=##Class(Ens.Util.XML.Reader).ObjectFromStream(.tObj,..OutObjectXML,..OutObjectClass)  Set:$$$ISOK(tSC) ..OutObject=tObj
	Quit $$$OK
}

Storage Default
{
<Data name="IOLogXMLObjDefaultData">
<Subscript>"IOLogXMLObj"</Subscript>
<Value name="1">
<Value>InObjectXML</Value>
</Value>
<Value name="2">
<Value>OutObjectXML</Value>
</Value>
</Data>
<DefaultData>IOLogXMLObjDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
