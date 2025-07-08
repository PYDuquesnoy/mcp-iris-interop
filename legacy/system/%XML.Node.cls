/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Document">Representing an XML Document as a DOM</a>.</p>
/// <class>%XML.Node</class> may be used to navigate the an XML document which is 
/// represented as an Document Object Model (DOM) using the <class>%XML.Document</class>.
/// The <class>%XML.Document</class> may be created either
/// <li>from an XML document by accessing the Document property of %XML.Reader 
/// after calling an Openxxx method of %XML.Reader.</li>
/// <li>as a new DOM by calling the <method>CreateDocument</method> of this class.</li><br>
/// The <class>%XML.Node</class> instance that is used to navigate the DOM is created 
/// using the <method>GetDocumentElement</method> of <class>%XML.Document</class>.<br><br>
/// 
/// <class>%XML.Node</class> navigates through the nodes of the DOM rather
/// than representing a fixed node in a DOM tree.  The MoveToxxx methods are used to move 
/// through the DOM.  The properties and methods of <class>%XML.Node</class> are then used
/// to retrieve and modify the node contents. 
Class %XML.Node Extends %RegisteredObject [ System = 2 ]
{

/// The DOM that this %XML.Node instance is navigating.  The Document property may be
/// set to change which DOM is being navigated.  When the Document is set, %XML.Node is 
/// positioned at the document node, i.e. the parent of the root element.
Property Document As %XML.Document;

Method DocumentSet(document As %XML.Document) As %Status [ Internal ]
{
	Set r%Document=document
	Set ..DocId=document.DocumentId
	Set ..NodeId=$$$xmlaGetDocumentNode(..DocId)
	Kill ..AttributeList
	Quit $$$OK
}

/// Contains document id in DOM global.
Property DocId As %String [ Internal ];

/// The id of the current node.  
/// The NodeId property may be set in order to move the specified node.
Property NodeId As %String;

/// When setting NodeId, the descriptor part must be recomputed in case the tree has been updated.
Method NodeIdSet(id As %String) As %Status [ Internal ]
{
	If id=0 {
		Set id=$$$xmlaGetDocumentNode(..DocId)
	}
	Set i%NodeId=id
	If $$$xmlaIsTop(..DocId,id) {
		Set ..Childlist=""
		Set ..Descriptor=""
	} Else {
		Set ..Descriptor=$$$xmliGetDescriptor(..DocId,id)
		If $$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE {
			$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
		} Else {
			Set ..Childlist=""
		}
	}
	Quit $$$OK
}

/// Childlist associated with NodeId
Property Childlist As %String [ Internal ];

/// Descriptor associated with NodeId
Property Descriptor As %String [ Internal ];

/// List of attributes
Property AttributeList As %String [ Internal, MultiDimensional ];

/// Type of node: $$$xmlELEMENTNODE, $$$xmlTEXTNODE, $$$xmlWHITESPACENODE.
Property NodeType As %String [ Calculated ];

Method NodeTypeGet() As %String [ CodeMode = expression, Internal ]
{
$$$xmlaGetNodeType(..DocId,..Descriptor)
}

Method NodeTypeSet(type As %String) As %Status [ Internal ]
{
	If $case(type,$$$xmlELEMENTNODE:1,$$$xmlTEXTNODE:1,$$$xmlRAWTEXTNODE:1,$$$xmlWHITESPACENODE:1,:0) {
		$$$xmlSetNodeType(..DocId,..NodeId,type)
		$$$xmlaGetChildList(..DocId,..NodeId,..Childlist,..Descriptor)
		Quit $$$OK
	} Else {
		Quit $$$ERROR($$$XMLInvalidNodeType,type)
	}
}

/// Value of a character node.
Property NodeData As %String [ Calculated ];

Method NodeDataGet() As %String [ Internal ]
{
	If $$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE {
		Quit $$$xmlaGetLocalName(..DocId,..Childlist)
	} Else {
		Quit $$$xmlaGetData(..DocId,..Descriptor)
	}
}

Method NodeDataSet(val As %String) As %Status [ Internal ]
{
	$$$xmlSetData(..DocId,..NodeId,val)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// Get the text contents of an element node.
/// GetText returns false if an error is encountered in evaluating the node.  
/// GetText returns true if text is found.  The text which is found may be the empty string.
/// The found text is appended to the text argument.
/// The text argument is created if it is not already defined.
/// If the mixed argument is = 1, then the mixed character and element content in the
/// current node is returned in the text argument.
Method GetText(ByRef text, mixed As %Boolean = 0) As %Boolean
{
	Quit ''##class(%XML.ImportHandler).SerializeNode(..DocId,..NodeId,0,mixed,.text,,,..Childlist)
}

/// Local name for element node.
Property LocalName As %String [ Calculated ];

Method LocalNameGet() As %String [ CodeMode = expression, Internal ]
{
$select($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE:$$$xmlaGetLocalName(..DocId,..Childlist),1:"")
}

Method LocalNameSet(name As %String) As %Status [ Internal ]
{
	$$$xmlSetLocalName(..DocId,..NodeId,name)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// Qname for element node.
/// Only used for output as XML when the prefix is valid for the document.
Property QName As %String [ Calculated ];

Method QNameGet() As %String [ CodeMode = expression, Internal ]
{
$select($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE:$$$xmlaGetQName(..DocId,..Childlist),1:"")
}

Method QNameSet(name As %String) As %Status [ Internal ]
{
	$$$xmlSetQName(..DocId,..NodeId,name)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// XML namespace for element node.
Property Namespace As %String [ Calculated ];

Method NamespaceGet() As %String [ CodeMode = expression, Internal ]
{
$select($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE:$$$xmlaGetNamespaceURI(..DocId,..Childlist),1:"")
}

Method NamespaceSet(namespace As %String) As %Status [ Internal ]
{
	$$$xmlSetNamespaceIndex(..DocId,..NodeId,##class(%XML.ImportHandler).GetNamespaceIndex(..DocId,namespace))
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// Index into XML namespace table for element node.
Property NamespaceIndex As %String [ Calculated ];

Method NamespaceIndexGet() As %String [ Internal ]
{
	If $$$xmlaGetNodeType(..DocId,..Descriptor)'=$$$xmlELEMENTNODE Quit ""
	Set index=$$$xmlaGetNamespaceIndex(..DocId,..Childlist)
	Quit $select(index=0:"",1:index)
}

Method NamespaceIndexSet(nsIndex As %String) As %Status [ Internal ]
{
	$$$xmlSetNamespaceIndex(..DocId,..NodeId,nsIndex)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// True if xsi:nil or xsi:null specified as true or 1 for this element node.
Property Nil As %Boolean [ Calculated ];

Method NilGet() As %Boolean [ CodeMode = expression, Internal ]
{
$select($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE:$$$xmlaIsNil(..DocId,..Childlist),1:"")
}

Method NilSet(value As %Boolean) As %Status [ Internal ]
{
	$$$xmlSetNil(..DocId,..NodeId,value)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// True if node is to be skipped during canonicalization.
Property SkipFlag As %Boolean [ Calculated, Internal ];

Method SkipFlagGet() As %Boolean [ CodeMode = expression, Internal ]
{
$$$xmlaGetSkipFlag(..DocId,..Childlist)
}

Method SkipFlagSet(value As %Boolean) As %Status [ Internal ]
{
	$$$xmlSetSkipFlag(..DocId,..NodeId,value)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)
	Quit $$$OK
}

/// Move node to current node's parent.<br>
/// If restrictDocumentNode is true, then MoveTopParent will not move to document node.
Method MoveToParent(restrictDocumentNode As %Boolean = 0) As %Boolean
{
	If $$$xmlaIsTop(..DocId,..NodeId) Quit 0
	
	Set nodeid=$$$xmlaParentNode(..DocId,..NodeId)
	If restrictDocumentNode,$$$xmlaIsTop(..DocId,nodeid) Quit 0
	if nodeid'="" Set ..NodeId=nodeid
	quit (nodeid'="")
}

/// Move node to current node's ancestor which has the specified local name.
Method MoveToParentElement(localName As %String) As %Boolean
{
	If $$$xmlaIsTop(..DocId,..NodeId) Quit 0
	
	Set nodeid=..NodeId
	While '$$$xmlaIsTop(..DocId,nodeid) {
		If $$$xmlGetLocalName(..DocId,nodeid)=localName Quit
		Set nodeid=$$$xmlaParentNode(..DocId,nodeid)
	}	
	Set ..NodeId=nodeid
	quit '$$$xmlaIsTop(..DocId,nodeid)
}

/// Return non-zero (true) if this node has any child nodes.
Method HasChildNodes(skipWhitespace As %Boolean = 0) As %Boolean
{
	If $$$xmlaIsTop(..DocId,..NodeId) || ($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE) {
		If skipWhitespace {
			Set childlist=..Childlist
			$$$xmlaFirstChildElement(..DocId,..NodeId,childlist,childid,descriptor)
			Quit (childid'="")
		} Else {
			Quit $$$xmlaHasChildNodes(..DocId,..Childlist)
		}
	} Else {
		Quit 0
	}
}

/// Move node to current node's first child node.
/// Optionally skip whitespace nodes.
Method MoveToFirstChild(skipWhitespace As %Boolean = 0) As %Boolean
{
	If $$$xmlaIsTop(..DocId,..NodeId) || ($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE) {
		If skipWhitespace {
			$$$xmlaGetChildList(..DocId,..NodeId,childlist,descriptor)
			$$$xmlaFirstChildElement(..DocId,..NodeId,childlist,childid,descriptor)
		} Else {
			$$$xmlaGetChildList(..DocId,..NodeId,childlist,descriptor)
			$$$xmlaFirstChild(..DocId,..NodeId,childlist,childid,descriptor)
		}
	} Else {
		Set childid=""
	}

	If childid'="" {
		Set i%NodeId=childid
		Set ..Descriptor=descriptor
		If $$$xmlaGetNodeType(..DocId,descriptor)=$$$xmlELEMENTNODE {
			$$$xmlaGetChildListFromDescriptor(..DocId,descriptor,..Childlist)
		} Else {
			Set ..Childlist=""
		}
		Quit 1
	} Else {
		Quit 0
	}
}

/// Move node to current node's last child node.
/// Optionally skip whitespace nodes.
Method MoveToLastChild(skipWhitespace As %Boolean = 0) As %Boolean
{
	If $$$xmlaIsTop(..DocId,..NodeId) || ($$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE) {
		If skipWhitespace {
			$$$xmlLastChildElement(..DocId,..NodeId,childid)
		} Else {
			Set childid=$$$xmlGetLastChild(..DocId,..NodeId)
		}
	} Else {
		Set childid=""
	}
	If childid'="" {
		Set ..NodeId=childid
		Quit 1
	} Else {
		Quit 0
	}
}

/// Move node to current node's next sibling.
/// Optionally skip whitespace nodes.
Method MoveToNextSibling(skipWhitespace As %Boolean = 0) As %Boolean
{
	Set nodeid=..NodeId
	$$$xmlaGetParentNodeWithChildlist(..DocId,nodeid,parent,parentChildlist,parentDescriptor)
	If $$$xmlaIsTop(..DocId,parent) Quit 0
	If skipWhitespace {
		$$$xmlaNextChildElement(..DocId,parent,parentChildlist,nodeid,descriptor)
	} Else {
		$$$xmlaNextChild(..DocId,parent,parentChildlist,nodeid,descriptor)
	}
	If nodeid'="" {
		Set i%NodeId=nodeid
		Set ..Descriptor=descriptor
		If $$$xmlaGetNodeType(..DocId,..Descriptor)=$$$xmlELEMENTNODE {
			$$$xmlaGetChildListFromDescriptor(..DocId,descriptor,..Childlist)
		} Else {
			Set ..Childlist=""
		}
		Quit 1
	} Else {
		Quit 0
	}
}

/// Move node to current node's previous sibling.
/// Optionally skip whitespace nodes.
Method MoveToPreviousSibling(skipWhitespace As %Boolean = 0) As %Boolean
{
	If skipWhitespace {
		Set nodeid=..NodeId
		Set parent=$$$xmlaParentNode(..DocId,nodeid)
		$$$xmlPreviousChildElement(..DocId,parent,nodeid)
	} Else {
		Set nodeid=$$$xmlGetPreviousSibling(..DocId,..NodeId)
	}
	If nodeid'="" {
		Set ..NodeId=nodeid
		Quit 1
	} Else {
		Quit 0
	}
}

/// Check is a this node is the descendant of specified node
Method IsDescendant(sourceNode As %XML.Node) As %Boolean
{
	// Must be in same document to be descendant
	If ..DocId'=sourceNode.DocId Quit 0
	
	// Top is not descendant of any node
	If $$$xmlaIsTop(..DocId,..NodeId) Quit 0
	
	// Check ancestors of this node for the source node.
	Set isDescendant=0
	Set nodeid=..NodeId
	While '$$$xmlaIsTop(..DocId,nodeid) {
		If nodeid=sourceNode.NodeId {
			Set isDescendant=1
			Quit
		}
		Set nodeid=$$$xmlaParentNode(..DocId,nodeid)
	}	
	quit isDescendant
}

/// Copy the attributes of the source node to this node.
Method CopyAttributes(sourceNode As %XML.Node) [ Internal ]
{
	Set docid=sourceNode.DocId
	$$$xmlaForEachAttribute(docid,sourceNode.Childlist,o,attribute)
		Set attrname=$$$xmlaGetAttributeName(docid,attribute)
		Set namespace=$$$xmlaGetAttrNamespaceURI(docid,attribute)
		If (attrname'="xmlns") || (namespace'=""), namespace'=$$$XMLNSns {
			Set value=$$$xmlaGetAttribute(docid,attribute)
			Set valueNamespace=$$$xmlaGetAttrValueNsURI(docid,attribute)
			Do ..SetAttribute(attrname,namespace,value,valueNamespace)
		}
	$$$xmlaEndForEachAttribute(docid,baseChildlist,o,attribute)
}

/// Append new element node to the list of children of this node.
/// If the text argument is specified, then character data is added as 
/// the child of the new element.
/// The current node pointer does not change.  This node is still the parent of the appended child.
Method AppendElement(localName As %String, namespace As %String = "", text As %String, qname As %String = "")
{
	Set docId=..DocId
	Set parentCLid=$$$xmliGetChildList(docId,..NodeId)

	// Create element descriptor and append to child list
	Set CLid=$increment($$$xmliDocGlobal(docId))
	Set desc=$$$xmliNewElementDescriptor(docId,CLid)
	Do ##class(%XML.ImportHandler).ExtendChildList(docId,.parentCLid,desc)

	// Create the new child list 
	Set offset=$length($$$xmliCLNode(docId,parentCLid))-$$$xmliDescriptorSize-$$$xmliDescriptorSize1
	Set CLNode=$$$xmliNewCLNode(docId,parentCLid,offset,localName,0,0,namespace,qname,0,0)
	Set $$$xmliCLNode(docId,CLid)=CLNode
 	$$$xmliSetCLnext(docId,CLid,0)

	If $get(text)'="" {
		Set nodeId=$$$xmliMakeNodeId(docId,parentCLid,offset)
		Do ..AppendCharacter(text,,nodeId)
	}
}

/// Append new character data node to the list of children of this element node.
/// The current node pointer does not change.  This node is still the parent of the appended child.<br>
/// If <var>raw</var> is true, the node is marked as $$$xmlRAWTEXTNODE<br>
/// <var>parent</var> is for internal use only.
Method AppendCharacter(text As %String, raw As %Boolean, parent As %String)
{
	Set docId=..DocId
	If $get(parent)="" Set parent=..NodeId
	Set parentCLid=$$$xmliGetChildList(docId,parent)
	If $get(raw) {
		Set desc=$$$xmliNewRawCharacterDescriptor(docId,text)
	} Else {
		Set desc=$$$xmliNewCharacterDescriptor(docId,text)
	}
	// Do not append empty character nodes as these will not have a corresponding "D" index or "d" data node.
	// Required behavior for safe XML node merging via AppendTree 
	Do:$$$xmliDescIsNotEmpty(desc) ##class(%XML.ImportHandler).ExtendChildList(docId,parentCLid,desc)
}

/// Append a copy of the specified node to the list of children of this node.
/// The node to copy may be from any document. 
/// The current node pointer does not change.  This node is still the parent of the appended child.
Method AppendNode(sourceNode As %XML.Node) As %Status
{
	// Verify that this node is an element node
	If $$$xmlaGetNodeType(..DocId,..Descriptor)'=$$$xmlELEMENTNODE {
		Quit $$$ERROR($$$XMLTargetElement)
	}
	
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Remember the original position of this node
		Set nodeid=..NodeId
	
		// Copy element node
		Do ..AppendElement(sourceNode.LocalName,sourceNode.Namespace,,sourceNode.QName)

		// Move to the new element node in the target tree
		Do ..MoveToLastChild()

		// Copy the attributes
		Do ..CopyAttributes(sourceNode)

		// Restore the original position of this node
		Set ..NodeId=nodeid
	
	} Else {
		// Copy character node
		Do ..AppendCharacter(sourceNode.NodeData)
	}
	
	Quit $$$OK
}

/// Append a copy of the specified node, including all its children, to the list of children of this node.
/// The tree to copy may be from any document, but this node may not be a descendant of the source node. 
/// The current node pointer does not change.  This node is still the parent of the appended child.
Method AppendTree(sourceNode As %XML.Node) As %Status
{
	// Verify that this node is an element node
	If $$$xmlaGetNodeType(..DocId,..Descriptor)'=$$$xmlELEMENTNODE {
		Quit $$$ERROR($$$XMLTargetElement)
	}
	
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Verify that this node is not a descendant of the source node
		If ..IsDescendant(sourceNode) {
			Quit $$$ERROR($$$XMLNoDescendant)
		}
		
		// Remember the original position of this node and source node
		Set sourceNodeid=sourceNode.NodeId
		Set nodeid=..NodeId
	
		// Copy element node
		Do ..AppendNode(sourceNode)
		
		// Move to the new element node in the target tree
		Do ..MoveToLastChild()
		
		// Transverse the source tree copying nodes
		If sourceNode.MoveToFirstChild() {
			For {
				Do ..AppendTree(sourceNode)
				If 'sourceNode.MoveToNextSibling() Quit
			}
		}

		// Restore the original position of nodes
		Set sourceNode.NodeId=sourceNodeid
		Set ..NodeId=nodeid
	
	} Else {
		// Copy character node
		Do ..AppendCharacter(sourceNode.NodeData)
	}
	
	Quit $$$OK
}

/// Insert a new element node to the list of children of this node.
/// The new element is inserted just before the specified child node. 
/// The child node is specified by passing its NodeId.
/// The child node is passed by reference so that it may be updated with a new NodeId after the insert.
/// The nodeId of the inserted element is returned.
/// If the text argument is specified, then character data is added as 
/// the child of the new element.
/// The current node pointer does not change.  This node is still the parent of the appended child.
Method InsertElement(localName As %String, namespace As %String = "", ByRef child As %String, text As %String, qname As %String = "") As %String
{
	Set docId=..DocId
	Set parent=..NodeId

	// Create the new child list 
	Set (childCLid,newCLid)=$$$xmliNodeIdCLparent(child)
	Set (childOffset,newOffset)=$$$xmliNodeIdCLoffset(child)
	Set CLid=$increment($$$xmliDocGlobal(docId))
	Set CLNode=$$$xmliNewCLNode(docId,childCLid,childOffset,localName,0,0,namespace,qname,0,0)
	Set $$$xmliCLNode(docId,CLid)=CLNode
	$$$xmliSetCLnext(docId,CLid,0)
 
	// Create element descriptor and append to child list
	Set desc=$$$xmliNewElementDescriptor(docId,CLid)
	Do ##class(%XML.ImportHandler).InsertDescriptor(docId,0,.childCLid,.childOffset,desc)
	
	// Update child nodeId and return the new nodeId
	Set newNode=$$$xmliMakeNodeId(docId,newCLid,newOffset)
	Set child=$$$xmliMakeNodeId(docId,childCLid,childOffset)
	If $data(text) Do ..AppendCharacter(text,,newNode)
	Quit newNode
}

/// Insert a new character data node to the list of children of this element node.
/// The new character data is inserted just before the specified child node. 
/// The child node is specified by passing its NodeId.
/// The child node is passed by reference so that it may be updated with a new NodeId after the insert.
/// The nodeId of the inserted character data node is returned.
/// The current node pointer does not change.  This node is still the parent of the appended child.
Method InsertCharacter(text As %String, ByRef child As %String) As %String
{
	Set docId=..DocId
	Set parent=..NodeId
	
	// Insert the new descriptor for the character node
	Set (childCLid,newCLid)=$$$xmliNodeIdCLparent(child)
	Set (childOffset,newOffset)=$$$xmliNodeIdCLoffset(child)
	Set desc=$$$xmliNewCharacterDescriptor(docId,text)
	Do ##class(%XML.ImportHandler).InsertDescriptor(..DocId,0,.childCLid,.childOffset,desc)

	// Update child nodeId and return the new nodeId
	Set child=$$$xmliMakeNodeId(docId,childCLid,childOffset)
	Quit $$$xmliMakeNodeId(docId,newCLid,newOffset)
}

/// Insert a copy of the specified node to the list of children of this node.
/// The node to copy may be from any document. 
/// The new node is inserted just before the specified child node. 
/// The child node is specified by passing its NodeId.
/// The child node is passed by reference so that it may be updated with a new NodeId after the insert.
/// The nodeId of the inserted node is returned.
/// The current node pointer does not change.
Method InsertNode(sourceNode As %XML.Node, ByRef child As %String, Output sc As %Status) As %String
{
	Set sc=$$$OK
	
	// Verify that this node is an element node
	If $$$xmlaGetNodeType(..DocId,..Descriptor)'=$$$xmlELEMENTNODE {
		Set sc=$$$ERROR($$$XMLTargetElement)
		Quit ""
	}
	
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Remember the original position of this node
		Set nodeid=..NodeId
	
		// Copy element node
		Set newNodeid=..InsertElement(sourceNode.LocalName,sourceNode.Namespace,.child,,sourceNode.QName)
		
		// Move to the new node
		Set ..NodeId=newNodeid

		// Copy the attributes
		Do ..CopyAttributes(sourceNode)

		// Restore the original position of this node
		Set ..NodeId=nodeid
	
	} Else {
		// Copy character node
		Set newNodeid=..InsertCharacter(sourceNode.NodeData,.child)
	}
	
	Quit newNodeid
}

/// Insert a copy of the specified node, including its children, to the list of children of this node.
/// The tree to copy may be from any document, but this node may not be a descendant of the source node. 
/// The new node is inserted just before the specified child node. 
/// The child node is specified by passing its NodeId.
/// The child node is passed by reference so that it may be updated with a new NodeId after the insert.
/// The nodeId of the inserted node is returned.
/// The current node pointer does not change.
Method InsertTree(sourceNode As %XML.Node, ByRef child As %String, Output sc As %Status) As %String
{
	Set sc=$$$OK
	
	// Verify that this node is an element node
	If $$$xmlaGetNodeType(..DocId,..Descriptor)'=$$$xmlELEMENTNODE {
		Set sc=$$$ERROR($$$XMLTargetElement)
		Quit ""
	}
	
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Verify that this node is not a descendant of the source node
		If ..IsDescendant(sourceNode) {
			Set sc=$$$ERROR($$$XMLNoDescendant)
			Quit ""
		}
	
		// Remember the original position of this node and source node
		Set sourceNodeid=sourceNode.NodeId
		Set nodeid=..NodeId
	
		// Copy element node
		Set newNodeid=..InsertNode(sourceNode,.child,.sc)
		If $$$ISERR(sc) Quit ""
		
		// Move to the new element node in the target tree
		Set ..NodeId=newNodeid
		
		// Transverse the source tree copying nodes
		If sourceNode.MoveToFirstChild() {
			For {
				Do ..AppendTree(sourceNode)
				If 'sourceNode.MoveToNextSibling() Quit
			}
		}

		// Restore the original position of nodes
		Set sourceNode.NodeId=sourceNodeid
		Set ..NodeId=nodeid
	
	} Else {
		// Copy character node
		Set newNodeid=..InsertCharacter(sourceNode.NodeData)
	}
	
	Quit newNodeid
}

/// Replace this node with an element node.
Method ReplaceElement(localName As %String, namespace As %String = "", text As %String, qname As %String = "")
{
	Set docId=..DocId
	Set nodeId=..NodeId

	// Create the new child list 
	Set childCLid=$$$xmliNodeIdCLparent(nodeId)
	Set childOffset=$$$xmliNodeIdCLoffset(nodeId)
	Set CLNode=$$$xmliNewCLNode(docId,childCLid,childOffset,localName,0,0,namespace,qname,0,0)
	Set CLid=$$$xmliDescValue(docId,..Descriptor)
	Set $$$xmliCLNode(docId,CLid)=CLNode
	$$$xmliSetCLnext(docId,CLid,0)

	// Create the new descriptor for the element node
	Set desc=$$$xmliNewElementDescriptor(docId,CLid)
	
	// Replace the descriptor
	$$$xmliReplaceDescriptor(docId,nodeId,desc)
	$$$xmlaGetChildListFromDescriptor(..DocId,..Descriptor,..Childlist)

	// Insert character data if needed.
	If $data(text) Do ..AppendCharacter(text,,nodeId)
}

/// Replace this node with a character node.
Method ReplaceCharacter(text As %String)
{
	Set docId=..DocId
	Set nodeId=..NodeId

	// Create the new descriptor for the character node
	Set desc=$$$xmliNewCharacterDescriptor(docId,text)
	
	// Replace the descriptor
	$$$xmliReplaceDescriptor(docId,nodeId,desc)
}

/// Replace this node with a copy of the specified node.
/// The node to copy may be from any document. 
/// The current node pointer does not change.
Method ReplaceNode(sourceNode As %XML.Node) As %Status
{
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Copy element node
		Do ..ReplaceElement(sourceNode.LocalName,sourceNode.Namespace,,sourceNode.QName)

		// Copy the attributes
		Do ..CopyAttributes(sourceNode)

	} Else {
		// Copy character node
		Do ..ReplaceCharacter(sourceNode.NodeData)
	}
	
	Quit $$$OK
}

/// Replace this node with a copy of the specified node including all its children.
/// The tree to copy may be from any document, but this node may not be a descendant of the source node. 
/// The current node pointer does not change.
Method ReplaceTree(sourceNode As %XML.Node) As %Status
{
	// Element nodes and character nodes are copied differently.
	If $$$xmlaGetNodeType(sourceNode.DocId,sourceNode.Descriptor)=$$$xmlELEMENTNODE {
		// Verify that this node is not a descendant of the source node
		If ..IsDescendant(sourceNode) {
			Quit $$$ERROR($$$XMLNoDescendant)
		}
		
		// Remember the original position of the source node
		Set sourceNodeid=sourceNode.NodeId
	
		// Copy element node
		Do ..ReplaceNode(sourceNode)
		
		// Transverse the source tree copying nodes
		If sourceNode.MoveToFirstChild() {
			For {
				Do ..AppendTree(sourceNode)
				If 'sourceNode.MoveToNextSibling() Quit
			}
		}

		// Restore the original position of the source node
		Set sourceNode.NodeId=sourceNodeid
	
	} Else {
		// Copy character node
		Do ..ReplaceCharacter(sourceNode.NodeData)
	}
	
	Quit $$$OK
}

/// Remove the current node and make its parent the current node.
Method Remove()
{
	Set nodeId=..NodeId
	Do ..MoveToParent()
	Do ##class(%XML.ImportHandler).RemoveDescriptor(..DocId,$$$xmliNodeIdCLparent(nodeId),$$$xmliNodeIdCLoffset(nodeId),$$$xmliDescriptorSize)
}

/// Get array of attributes:  ..AttributeList(name)=attribute
Method GetAttributeList() [ Internal ]
{
	Set docId=..DocId
	Set childlist=..Childlist

	Kill ..AttributeList
	Set ..AttributeList=..NodeId

	$$$xmlaForEachAttribute(docId,childlist,offset,attribute)
		Set attrname=$$$xmlaGetAttributeName(docId,attribute)
		Set ..AttributeList(attrname)=attribute
	$$$xmlaEndForEachAttribute(docId,childlist,offset,attribute)

	Quit
}

/// Return number of attributes for this element.
Method GetNumberAttributes() As %Integer [ CodeMode = expression ]
{
$$$xmlaGetNumberAttributes(..DocId,..Childlist)
}

/// Return non-zero (true) if attribute named attributeName exists for this element.
Method AttributeDefined(attributeName As %String) As %String
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Quit $data(..AttributeList(attributeName))
}

/// Return attribute name for first attribute for this element.
Method FirstAttributeName() As %String
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Quit $order(..AttributeList(""))
}

/// Return attribute name for last attribute for this element.
Method LastAttributeName() As %String
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Quit $order(..AttributeList(""),-1)
}

/// Return attribute name for next attribute for this element.
Method NextAttributeName(attributeName As %String) As %String
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Quit $order(..AttributeList(attributeName))
}

/// Return attribute name for previous attribute for this element.
Method PreviousAttributeName(attributeName As %String) As %String
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Quit $order(..AttributeList(attributeName),-1)
}

/// Return attribute data of attribute named attributeName for this element.
/// 	<li><var>namespace</var> is the namespace URI from QName of attribute named attributeName for this element.</li>
/// 	<li><var>value</var> is the attribute value.</li>
/// 	<li><var>valueNamespace</var> is the namespace URI corresponding to the prefix when the attribute value is of the form "prefix:value".</li>
Method GetAttribute(attributeName As %String, ByRef namespace As %String, ByRef value As %String, ByRef valueNamespace As %String)
{
	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	If attributeName'="" {
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	If attribute'="" {
		Set namespace=$$$xmlaGetAttrNamespaceURI(..DocId,attribute)
		Set value=$$$xmlaGetAttribute(..DocId,attribute)
		Set valueNamespace=$$$xmlaGetAttrValueNsURI(..DocId,attribute)
	} Else {
		Set (namespace,value,valueNamespace)=""
	}
}

/// Return attribute data of attribute named attributeName in namespace for this element.
/// 	<li><var>value</var> is the attribute value.</li>
/// 	<li><var>valueNamespace</var> is the namespace URI corresponding to the prefix when the attribute value is of the form "prefix:value".</li>
Method GetAttributeNS(attributeName As %String, namespace As %String, ByRef value As %String, ByRef valueNamespace As %String)
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	If (attribute'="") && (namespace=$$$xmlaGetAttrNamespaceURI(..DocId,attribute)) {
		Set value=$$$xmlaGetAttribute(..DocId,attribute)
		Set valueNamespace=$$$xmlaGetAttrValueNsURI(..DocId,attribute)
	} Else {
		Set (value,valueNamespace)=""
	}
}

/// Return namespace URI from QName of attribute named attributeName for this element.
Method GetAttributeNamespace(attributeName As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select(attribute'="":$$$xmlaGetAttrNamespaceURI(..DocId,attribute),1:"")
}

/// Return value of attribute named attributeName for this element.
Method GetAttributeValue(attributeName As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select(attribute'="":$$$xmlaGetAttribute(..DocId,attribute),1:"")
}

/// Return value of attribute named attributeName in namespace for this element.
Method GetAttributeValueNS(attributeName As %String, namespace As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select((attribute'="") && (namespace=$$$xmlaGetAttrNamespaceURI(..DocId,attribute)):$$$xmlaGetAttribute(..DocId,attribute),1:"")
}

/// Return QName of attribute named attributeName for this element.
Method GetAttributeQName(attributeName As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select(attribute'="":$$$xmlaGetAttributeQName(..DocId,attribute),1:"")
}

/// Return QName of attribute named attributeName in namespace for this element.
Method GetAttributeQNameNS(attributeName As %String, namespace As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select((attribute'="") && (namespace=$$$xmlaGetAttrNamespaceURI(..DocId,attribute)):$$$xmlaGetAttributeQName(..DocId,attribute),1:"")
}

/// Return namespace of value of attribute named attributeName for this element.
Method GetAttributeValueNamespace(attributeName As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select(attribute'="":$$$xmlaGetAttrValueNsURI(..DocId,attribute),1:"")
}

/// Return namespace value of attribute named attributeName in namespace for this element.
Method GetAttributeValueNamespaceNS(attributeName As %String, namespace As %String) As %String
{
	If attributeName'="" {
		If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
		Set attribute=$get(..AttributeList(attributeName))
	} Else {
		Set attribute=""
	}
	Quit $select((attribute'="") && (namespace=$$$xmlaGetAttrNamespaceURI(..DocId,attribute)):$$$xmlaGetAttrValueNsURI(..DocId,attribute),1:"")
}

/// Set attribute data of attribute named attributeName for this element.
/// 	<li><var>namespace</var> is the namespace URI from QName of attribute named attributeName for this element.</li>
/// 	<li><var>value</var> is the attribute value.</li>
/// 	<li><var>valueNamespace</var> is the namespace URI corresponding to the prefix when the attribute value is of the form "prefix:value".</li>
Method SetAttribute(attributeName As %String, namespace As %String = "", value As %String = "", valueNamespace As %String = "")
{
	If attributeName'="" {
		Set nodeId=..NodeId
		Set attr=$$$xmliNewAttribute(..DocId,attributeName,"",namespace,valueNamespace,value)
		Do ##class(%XML.ImportHandler).SetAttribute(..DocId,nodeId,attributeName,attr,1,$$$xmliAttributeSize)
		Kill ..AttributeList
		Set ..NodeId=nodeId
	}
}

/// Remove attribute named attributeName for this element.
Method RemoveAttribute(attributeName As %String)
{
	If attributeName'="" {
		Set nodeId=..NodeId
		$$$xmlRemoveAttribute(..DocId,nodeId,attributeName)
		Kill ..AttributeList
		Set ..NodeId=nodeId
	}
}

/// Remove attribute named attributeName in namespace for this element.
Method RemoveAttributeNS(attributeName As %String, namespace As %String)
{
	If attributeName'="" {
		Set nodeId=..NodeId
		$$$xmlRemoveAttributeNS(..DocId,nodeId,attributeName,namespace)
		Set ..NodeId=nodeId
	}
}

/// Verify if this node is an ancestor of the specified node.
/// Check if the referenced element contains the element specified by node id.
Method IsAncestor(nodeId As %String) As %Boolean [ Internal ]
{
	// Move up the tree from the specified node looking for ancestor or top
	Set isAncestor=0
	For {
		// If we encounter this node, then it is an ancestor
		If nodeId=..NodeId {
			Set isAncestor=1
			Quit
		}
		// If we reach the top, then this node is not an ancestor
		If $$$xmlaIsTop(..DocId,nodeId) Quit
		Set nodeId=$$$xmlaParentNode(..DocId,nodeId)
		if nodeId="" Quit
	}
	Quit isAncestor
}

/// Serialize this node as element
Method Serialize(Output endElementText) As %String
{
	Set tree=..DocId
	Set childlist=..Childlist
	Set qname=$$$xmlaGetQName(tree,childlist)

	If $get(..AttributeList)'=..NodeId Do ..GetAttributeList()
	Set attributes=""
	Set attrname=""
	For {
		Set attrname=$order(..AttributeList(attrname),1,attribute)
		If attrname="" Quit
		Set attrvalue=$$$xmlaGetAttribute(tree,attribute)
		Set attributes=attributes_" "_$$$xmlaGetAttributeQName(tree,attribute)_"="""_$zcvt(attrvalue,"O","XML")_""""
	}
	Set endElementText="</"_qname_">"
	Quit "<"_qname_attributes_">"
}

/// Get the class name the corresponds to this element.
/// Return "" if not found.
Method GetClassName(BaseClassName As %String) As %String [ Internal ]
{
	If BaseClassName="" Quit ""
	If ..Childlist="" Quit ""

	Set tag=$$$xmlaGetLocalName(..DocId,..Childlist)
	Set classList=$get(^oddCOM(BaseClassName,$$$cCLASSxmldata,"n",tag))_$get(^oddXML(BaseClassName,"n",tag))
	Set class=""
	If classList'="" {
		Set namespace=$$$xmlGetNamespaceURI(..DocId,..NodeId)
		If namespace'="" {
			For i=1:1:$listlength(classList) {
				Set possible=$list(classList,i)
				Set ns=$parameter(possible,"NAMESPACE")
				If ns=namespace Set class=possible Quit
			}
			If class="" {
				For i=1:1:$listlength(classList) {
					Set possible=$list(classList,i)
					Set ns=$parameter(possible,"NAMESPACE")
					If ns="" Set class=possible Quit
				}
			}
		} Else {
			If $listlength(classList)=1 {
				Set class=$list(classList,1)
			}
		}
	}
	Quit class
}

}
