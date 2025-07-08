/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Document.XML [ Abstract, System = 3 ]
{

ClassMethod Import(pContainerClass As %String(MAXLEN="") = "", pDocument As %String(MAXLEN="") = "")
{
#dim tXMLDocument as %XML.Document
#dim tXMLNode as %XML.Node
	if pDocument '= "" {
		set tInputStream = ##class(%Stream.FileCharacter).%New()
		do tInputStream.LinkToFile(pDocument)
		set tStatus = ##class(%XML.Document).GetDocumentFromStream(tInputStream,.tXMLDocument)
		if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
		set tXMLNode = tXMLDocument.GetDocumentElement()
		if tXMLNode.MoveToFirstChild(1) {
			do {
				if tXMLNode.NodeType = $$$xmlELEMENTNODE {
					set tContainer = $classmethod(pContainerClass,"%New")
					set tContainer.%Document = ##class(%Document.Object).%New("{_contentType:"_tXMLNode.LocalName_"}")
					do ..ImportContent(tContainer.%Document,tXMLNode)
					set tStatus = tContainer.%Save()
				}
			} while tXMLNode.MoveToNextSibling(1)
		}
	}
}

ClassMethod ImportContent(pDocument As %Document.Object, pXMLNode As %XML.Node)
{
		// Process attributes
	set tAttribute = pXMLNode.NextAttributeName("")
	while tAttribute '= "" {
		set $property(pDocument,tAttribute) = pXMLNode.GetAttributeValue(tAttribute)
		set tAttribute = pXMLNode.NextAttributeName(tAttribute)
	}
		// Process child elements
	if pXMLNode.HasChildNodes(1) {
		if pXMLNode.MoveToFirstChild(1) {
			do {
				set tField = pXMLNode.LocalName
				set tFieldCount = $Increment(tList(tField))
					// If this field has already been defined in this document then convert the field to a list
				if tFieldCount = 2 {
						// Convert this singleton to a list
					set tFieldValue = $property(pDocument,tField)
					set tList = ##class(%Document.Object).%New(,1)
					do tList.Insert(tFieldValue)
					set $property(pDocument,tField) = tList
				}
					// Also, if this element has attributes then we have a nested object, not just a simple property
				if (pXMLNode.HasChildNodes(1)) || ($Data(pXMLNode.AttributeList) > 2) {
						// What if this element is a simple element? We can detect with HasChildNodes
						// in combination with attribute count
					set tFieldValue = ##class(%Document.Object).%New()
					do ..ImportContent(tFieldValue,pXMLNode)
				}
				else {
					set tFieldValue = pXMLNode.GetText()
				}
				if tList(tField) '> 1 {
					set $property(pDocument,tField) = tFieldValue
				}
				else {
					set tList = $property(pDocument,tField)
					do tList.Insert(tFieldValue)
				}
			} while pXMLNode.MoveToNextSibling(1)
		}
		do pXMLNode.MoveToParent()
	}
}

}
