/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// Handles results of XPATH expression validation
Class %XML.XPATH.ResultHandler Extends %RegisteredObject [ System = 3 ]
{

/// This method is called when a match is made. It specifies the Match key as well
/// as the result type. The type may be $$$XPATHVALUE or $$$XPATHDOM
Method StartMatch(pResultType As %Integer)
{
	Quit // Subclass Responsibility
}

/// This method is called when a match is completed
Method EndMatch(pMatch As %Integer)
{
	Quit // Subclass Responsibility
}

Method Result(pChunk As %Integer, pResult As %String)
{
	Quit // Subclass Responsibility
}

Method Attribute(pIndex As %Integer, pParent As %Integer, pName As %String, pLocalName As %String, pUri As %String, pValue As %String)
{
	Quit // Subclass Responsibility
}

Method Node(pIndex As %Integer, pParent As %Integer, pNodeType As %Integer, pName As %String, pLocalName As %String, pUri As %String)
{
	Quit // Subclass Responsibility
}

Method Value(pIndex As %Integer, pChunk As %Integer, pValue As %String)
{
	Quit // Subclass Responsibility
}

Method NodeType(pNodeType As %Integer = "") As %String
{
	do {
		Set tResult=$Case(pNodeType,$$$UNKNOWN:"unknown",$$$ELEMENT:"element",$$$ATTRIBUTE:"attribute",:"")
		If tResult'="" Quit
		Set tResult=$Case(pNodeType,$$$TEXT:"chars",$$$CDATASECTION:"cdata",$$$ENTITYREFERENCE:"entityreference",:"")
		If tResult'="" Quit
		Set tResult=$Case(pNodeType,$$$ENTITY:"entity",$$$PROCESSINGINSTRUCTION:"processinginstruction",$$$COMMENT:"comment")
		If tResult'="" Quit
		Set tResult=$Case(pNodeType,$$$DOCUMENT:"document",$$$DOCUMENTTYPE:"documenttype",$$$DOCUMENTFRAGMENT:"documentfragment",$$$NOTATION:"notation")
	} while (0)
	Quit tResult
}

}
