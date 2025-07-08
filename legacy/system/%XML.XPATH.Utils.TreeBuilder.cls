/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class stores the results of evaluation of an XPATH expression in ^IRIS.Temp(Tree,MatchKey)
/// The Tree is a unique integer value, the MatchKey is an integer key which varies from 1 .. n. For
/// each match of the xpath expression, the results are stored in the appropriate subtree of ^IRIS.Temp.
/// The match results can be of two forms, values and DOMS. If the XPATH expression matches an element,
/// a DOM is returned which represents the matching element and it's childeren. If the XPATH expression matches
/// a value then just the value is returned.
Class %XML.XPATH.Utils.TreeBuilder Extends %XML.XPATH.ResultHandler [ System = 4 ]
{

/// This holds the current first subscript of ^IRIS.Temp
Property Tree As %Integer;

/// This holds the collection of results
Property Results As %RawString;

/// This method is called at the end of a match
Method EndMatch(pMatch As %Integer)
{
	If $$$JobPrivateGlobalRef(..Tree)=$$$XPATHVALUE
	{
		Do ..Results.InsertObject($$$oidCompose(..Tree,"%XML.XPATH.ValueResult"))
	} else {
		Do ..Results.InsertObject($$$oidCompose(..Tree,"%XML.XPATH.DOMResult"))
	}
}

/// This method is called when a match is made. It specifies the Match key as well
/// as the type. The type may be $$$XPATHVALUE or $$$XPATHDOM
Method StartMatch(pResultType As %Integer)
{
	Set ..Tree=$Increment($$$JobPrivateGlobalTop),$$$JobPrivateGlobalRef(..Tree)=pResultType
}

Method Result(pChunk As %Integer, pResult As %String)
{
	Set $$$JobPrivateGlobalRef(..Tree,"v",$Increment($$$JobPrivateGlobalRef(..Tree,"v")))=pResult
}

Method Attribute(pIndex As %Integer, pParent As %Integer, pName As %String, pLocalName As %String, pUri As %String, pValue As %String)
{
	#; Update the count of attributes
	Set $$$JobPrivateGlobalRef(..Tree,pParent,"a")=pIndex
	
	#; Set the name
	Set $$$JobPrivateGlobalRef(..Tree,pParent,"a",pIndex,"n")=$ListBuild(pName,pLocalName,pUri)
	
	#; And the value
	Set $$$JobPrivateGlobalRef(..Tree,pParent,"a",pIndex,"v")=pValue
}

Method Node(pIndex As %Integer, pParent As %Integer, pNodeType As %Integer, pName As %String, pLocalName As %String, pUri As %String)
{
	#; Determine the node type
	Set tNodeType=..NodeType(pNodeType)
	
	#; Record the type for this new index
	Set $$$JobPrivateGlobalRef(..Tree,pIndex)=tNodeType
	
	#; Set the name of the node,local name and uri
	Set $$$JobPrivateGlobalRef(..Tree,pIndex,"n")=$ListBuild(pName,pLocalName,pUri)
	
	#; And it's parent ( parent = 0 means document )
	Set $$$JobPrivateGlobalRef(..Tree,pIndex,"p")=pParent
	
	#; If there is a parent node which is not the document
	If pParent {
		
		#; Update the number of children
		If $Increment($$$JobPrivateGlobalRef(..Tree,pParent,"c"))
		
		#; Set the child pointer
		Set $$$JobPrivateGlobalRef(..Tree,pParent,"c",pIndex)=tNodeType
	}
}

Method Value(pIndex As %Integer, pChunk As %Integer, pValue As %String)
{
	#; Record the value of the node
	Set $$$JobPrivateGlobalRef(..Tree,pIndex,"v",$Increment($$$JobPrivateGlobalRef(..Tree,pIndex,"v")))=pValue
}

}
