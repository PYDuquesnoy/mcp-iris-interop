/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%xmlOldDOM, %xmlDOM, EnsEDIXML)

Class EnsLib.EDI.XML.DOMUpgrader Extends %RegisteredObject
{

ClassMethod UpgradeDOM(pContentRef As %String, pDOMRef As %String, ByRef pXMLDocument As %XML.Document)
{
	// process old content array, create a new content array from old
	if $g(@pContentRef@(0,"e"))'=1 Quit ; don't upgrade elements with 2013.1-and-up content arrays (new Marvin/Jamie/Scott design)
	Set tNode=$$$xmlOldGetDocumentElement(pContentRef)
	Set pXMLDocument=##class(%XML.Document).CreateDocument($$$xmlOldGetNodeValue(pContentRef,tNode),$$$xmlOldGetNamespaceURI(pContentRef,tNode))
	Set pXMLDocument.GetDocumentElement().QName=$$$xmlOldGetQName(pContentRef,tNode)
	Set tNodeMap($$$xmlOldGetDocumentElement(pContentRef))=pXMLDocument.GetDocumentElement().NodeId
	Do ..UpgradeNodeTree(pContentRef, pDOMRef, tNode, pXMLDocument, pXMLDocument.GetDocumentElement(), .tNodeMap)
	Set tDOMSubs=","">/"",1"
	Do ..UpgradeVDocDOM(pDOMRef,tDOMSubs, .tNodeMap) // walk DOM and replace ">I" nodes with new nodes
}

ClassMethod UpgradeNodeTree(pContentRef As %String, pDOMRef As %String, pNode As %String, pXMLDocument As %XML.Document, pXMLNode As %XML.Node, ByRef pNodeMap)
{
	Quit:'$D(@pContentRef@(pNode))
	if $$$xmlOldGetNodeType(pContentRef,pNode)=$$$xmlOldELEMENTNODE {
		Do ..UpgradeNamespaces(pContentRef, pDOMRef, pNode, pXMLDocument, pXMLNode)
		Do ..UpgradeAttributes(pContentRef, pDOMRef, pNode, pXMLDocument, pXMLNode)
		// walk children and upgrade their node tree	
		if $$$xmlOldHasChildNodes(pContentRef,pNode) {
			Set tNode=$$$xmlOldGetFirstChild(pContentRef,pNode)
			while (tNode'="") {
				if $$$xmlOldGetNodeType(pContentRef,tNode)=$$$xmlOldELEMENTNODE {
					Set localName=$$$xmlOldGetNodeValue(pContentRef,tNode)
					Set namespace=$$$xmlOldGetNamespaceURI(pContentRef,tNode)
					Set text="" // we'll pick up text nodes later
					Set qname=$$$xmlOldGetQName(pContentRef,tNode)
					do ..AppendElement(pXMLNode,localName, namespace, text, qname, .nodeId)
					;do pXMLNode.InsertElement(localName, namespace, .nodeId, text, qname)
					Set tXMLNode=pXMLDocument.GetNode(nodeId)
					Set tXMLNode.QName=$$$xmlOldGetQName(pContentRef,tNode)
					Set pNodeMap(tNode)=nodeId
				} elseif $$$xmlOldGetNodeType(pContentRef,tNode)=$$$xmlOldTEXTNODE {
					do ..AppendCharacter(pXMLNode,$$$xmlOldGetNodeValue(pContentRef,tNode),,,.nodeId)
					Set tXMLNode=pXMLDocument.GetNode(nodeId)
					Set pNodeMap(tNode)=nodeId
				} elseif $$$xmlOldGetNodeType(pContentRef,tNode)=$$$xmlOldWHITESPACENODE {
					do ..AppendCharacter(pXMLNode,$$$xmlOldGetNodeValue(pContentRef,tNode),,,.nodeId)
					Set tXMLNode=pXMLDocument.GetNode(nodeId)
					Set pNodeMap(tNode)=nodeId
				}
				do ..UpgradeNodeTree(pContentRef, pDOMRef, tNode, pXMLDocument, tXMLNode, .pNodeMap)
				Set tNode=$$$xmlOldGetNextChild(pContentRef,pNode,tNode)
			}
		}
	}
}

/// If the text argument is specified, then character data is added as 
/// the child of the new element.
/// The current node pointer does not change.  This node is still the parent of the appended child.
ClassMethod AppendElement(pXMLNode, localName As %String, namespace As %String = "", text As %String, qname As %String = "", ByRef nodeId)
{
	Set docId=pXMLNode.DocId
	Set parentCLid=$$$xmliGetChildList(docId,pXMLNode.NodeId)

	// Create element descriptor and append to child list
	Set CLid=$increment($$$xmliDocGlobal(docId))
	Set desc=$$$xmliNewElementDescriptor(docId,CLid)
	Do ##class(%XML.ImportHandler).ExtendChildList(docId,.parentCLid,desc)

	// Create the new child list 
	Set offset=$length($$$xmliCLNode(docId,parentCLid))-$$$xmliDescriptorSize-$$$xmliDescriptorSize1
	Set CLNode=$$$xmliNewCLNode(docId,parentCLid,offset,localName,0,0,namespace,qname,0,0)
	Set $$$xmliCLNode(docId,CLid)=CLNode
 	$$$xmliSetCLnext(docId,CLid,0)
	Set nodeId=$$$xmliMakeNodeId(docId,parentCLid,offset)

	If $data(text),$g(text)'="" {  
		Do ..AppendCharacter(pXMLNode,text,,nodeId)
	}
}

/// Append new character data node to the list of children of this element node.
/// The current node pointer does not change.  This node is still the parent of the appended child.<br>
/// If <var>raw</var> is true, the node is marked as $$$xmlRAWTEXTNODE<br>
/// <var>parent</var> is for internal use only.
ClassMethod AppendCharacter(pXMLNode, text As %String, raw As %Boolean, parent As %String, ByRef nodeId)
{
	Set docId=pXMLNode.DocId
	If $get(parent)="" Set parent=pXMLNode.NodeId
	Set parentCLid=$$$xmliGetChildList(docId,parent)
	If $get(raw) {
		Set desc=$$$xmliNewRawCharacterDescriptor(docId,text)
	} Else {
		Set desc=$$$xmliNewCharacterDescriptor(docId,text)
	}
	Do ##class(%XML.ImportHandler).ExtendChildList(docId,parentCLid,desc)
	Set offset=$length($$$xmliCLNode(docId,parentCLid))-$$$xmliDescriptorSize-$$$xmliDescriptorSize1
	Set nodeId=$$$xmliMakeNodeId(docId,parentCLid,offset)
}

ClassMethod UpgradeAttributes(pContentRef As %String, pDOMRef As %String, pNode As %String, pXMLDocument As %XML.Document, pXMLNode As %XML.Node)
{
	Set attrName=$$$xmlOldFirstAttributeName(pContentRef, pNode)
	while (attrName'="") {
		Set namespace=$$$xmlOldGetAttrNamespaceURI(pContentRef,pNode,attrName)
		Set value=$$$xmlOldGetAttribute(pContentRef, pNode, attrName)
		Set valueNamespace=$$$xmlOldGetAttrValueNsURI(pContentRef, pNode, attrName)
		Set attrQName=$$$xmlOldGetAttrQName(pContentRef, pNode, attrName)
		do pXMLNode.SetAttribute(attrQName, namespace, value, valueNamespace)
		Set attrName=$$$xmlOldNextAttributeName(pContentRef, pNode,attrName)
	}
}

ClassMethod UpgradeNamespaces(pContentRef As %String, pDOMRef As %String, pNode As %String, pXMLDocument As %XML.Document, pXMLNode As %XML.Node, ByRef pNewDomRef)
{
	Set namespace=$$$xmlOldGetNamespaceURI(pContentRef, pNode)
	Set pXMLNode.Namespace=namespace
	Set pXMLNode.QName=$$$xmlOldGetQName(pContentRef, pNode)
}

ClassMethod UpgradeVDocDOM(pDOMRef, pDOMSubs, ByRef tNodeMap)
{
	#define vaDOMRef(%subs)      $S(")"=$E(pDOMRef,*):$E(pDOMRef,1,*-1)_(%subs)_")", ""=(%subs):pDOMRef, 1:pDOMRef_"("_$E(%subs,2,*)_")")

	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp) Set:$e(kDom)=">" kDom="" q:kDom=""
		If $g(dtyp)'="",">"'=$E(dtyp),dtyp[">" { ; it's an element node
			Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
			Set tAttrSubs=pDOMSubs_","">"_tElemName_""","_tElemIndex
			Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
			Set plus=""
			Set:$e(tAfterCNode)="+" plus="+",tAfterCNode=$e(tAfterCNode,2,*)
			if tAfterCNode'="" {
				Set:$D(tNodeMap(tAfterCNode)) @$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I""")=plus_tNodeMap(tAfterCNode)
			}
			Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
			Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
			Set tReplaceContent=(tReplace="c")
			// walk more
			do ..UpgradeVDocDOM(pDOMRef,tAttrSubs,.tNodeMap)
		} else {
			Set sub=pDOMSubs_","_kDom_","">I"""
			Set tAfterCNode=$G(@$$$vaDOMRef(sub))
			if tAfterCNode'="" {
				Set plus=""
				Set:$e(tAfterCNode)="+" plus="+",tAfterCNode=$e(tAfterCNode,2,*)
				if tAfterCNode'="" {
					Set:$D(tNodeMap(tAfterCNode)) @$$$vaDOMRef(sub)=plus_tNodeMap(tAfterCNode)
				}
			}
		}

	}
}

}
