/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %soap, %xmlDOM)

/// SAX Content handler for ObjectScript XML Implementation.
/// <br><br>
/// 
/// This class and the data structure defined here is used internally by InterSystems IRIS.
/// You should not make direct use of this class or data structure within your applications.
/// The global data structure may be accessed using the macros in %xmlDOM.inc or
/// by using the %XML.Node class.
/// There is no guarantee made about either the behavior or future operation of this class.<br><br>
/// 
/// This content handler stores the XML document as nodes of a tree.
/// The <property>GlobalName</property> property determines where 
/// these nodes are stored.  The default for the <property>GlobalName</property>
/// property is ^||%xmlTemp.  The <property>Tree</property> property determines the 
/// specific node used to store the nodes of the tree.
/// 
/// The structure of the tree is as follows:<br><br>
/// The tree is stored @..GlobalName@(..Tree) which is stored in ..DocumentId.
/// @..GlobalName@(..Tree) - number of nodes.
/// @i%DocumentId@(node) describes the node given by the integer node number.<br><br>
/// 
/// <pre>
/// Each XML DOM node will be described by a 4 character entry node descriptor.
/// Since any node will be the child of an element node, the node descriptor entries will be
/// stored in the childlist of its parent which is in the element descriptor node or one of its extension nodes.  
/// The attribute nodes will be first in the element descriptor node in the order that they are 
/// presented by Xerces.  Element and character node entries follow in the XML document order.
/// Each element descriptor is limited to the maximum length ObjectScript string.  
/// Thus provision is made for extension child lists.
/// The list of element and character nodes is terminated by a next descriptor node which is
/// a reference to the next extension or 0 for the last.
/// Each element descriptor node and element descriptor extension node is structured as follows:<br>
/// @i%DocumentId@(node) is 28 character base followed by the list of node descriptors.
/// @i%DocumentId@(node) = CLparent_CLoffset_name_(prefix|flags)_elementOffset_URI_line_column_ChildList
///     CLparent($zlchar) is the node number of the parent's child list which contains this node's descriptor.
///     CLoffset($zlchar) is the 1-based offset in characters in CLparent node of this node's descriptor.
///     name ($zlchar) - index of element name in the name dictionary.
///     prefix($zlchar\16) - index of the prefix part of the QName (including ':') in the name dictionary or 0 if no prefix
///          If the qname and the unqualified name are the same, then the prefix is not present.
///     flags($zlchar#16)
///         right-most bit (1) if xsi:nil or xsi:null specified as true or 1
///         second bit (2) is skip flag
///     elementOffset($zwchar) is the offset of the first child element in the child list.
///          This value is 29+(numAttrs*16) for the first child list and 29 for all subsequent child lists.
///     URI($zwchar) is index of the URI for this element or not stored.
///     line($zlchar) part of the location for element node.
///     column($zlchar) part of the location for element node.
/// 
///     ChildList is list of attribute, element and character entries.
/// 
/// A document node is introduced which represents the document and has as its child the root element
/// of the document.
/// Node 0 is the document node and node 1 is the child list for the document node.
/// @i%DocumentId@(0) = documentBase_documentChildlist
/// @i%DocumentId@(1) = rootElementDescriptor
///    documentBase:  $zlchar(0,0,0,0,0)_$zwchar(29,0)_$zlchar(0,0)
///    documentChildList:  $zlchar(16) i.e 1 shifted left 4
///    rootElementDescriptor:  $zlchar(0,0,0)_name_prefix_elementOffset_URI_line_column
///       name, URI, prefix, elementOffset, line, column refer to the root element.  
///       See below for definition of element descriptor.
/// 
/// There are 4 types of node descriptors: attribute, element, character and next.
/// 
/// The attribute node descriptor (length 16):  name_prefix_URI_valueURI_value
///    name($zlchar) is the attribute name
///    prefix($zlchar) - index of the prefix (including ':') in the name dictionary or 0 if no prefix
///    URI($zwchar) - index of the namespace URI for this attriibute or 0 if no namespace.
///    valueURI($zwchar) - index of the namespace URI corresponding to the prefix when the attribute value is of the form "prefix:value".
///    value($zlchar) - index of the value of the attribute in the name dictionary
/// 
/// The element node descriptor:  elementDescriptor|type
///     elementDescriptor($zlchar\16) is the node number of the elementDescriptor for this element.
///     type($zlchar#16) of the node: 0 for element
/// 
/// The character node descriptor:  valueindex|type
///     valueindex($zlchar\16) - data dictionary index of character value of the node.
///     type($zlchar#16) of the node: 1 for character data or 2 for character data that is only whitespace.
/// 
/// The next node descriptor:  next|type
///     next($zlchar\16) - index of next element descriptor extension.
///     type($zlchar#16) of the node: 3 for next element descriptor.
/// 
/// Errors and warnings are returned as follows.  
/// The SAX parser also returns immediately following a fatal error with an error status:
/// @i%DocumentId@(type)=count where type is "fatalerror", "error" or "warning".
/// @i%DocumentId@(type,index)=message
/// 
/// Elements with "id" attributes are indexed as follows:
/// @i%DocumentId@("i",id)=CLparent_","_CLoffset
///      id is the value of "id" atribute
///      CLparent is the node number of the parent's child list which contains this node's descriptor.
///      CLoffset is the 1-based offset in characters in CLsub node of this node's descriptor.
/// 
/// The name dictionary is used to store prefixes, attribute values and node values as well as names.
/// The name dictionary used in this XML document is maintained as:
/// @i%DocumentId@("d")=the number of names, values, or prefixes including ':' used by this XML document.
/// @i%DocumentId@("d",index)=name
/// If the value is > than the max node length, then extensions are stored as followed numbered from 1:
/// @i%DocumentId@("d",index,subnodeIndex)=<extension of value>
///    Reverse "D" name to index is only used for COS code added names.  Not for names added by Xerces parser.
/// @i%DocumentId@("D",name)=index
///     where <var>name</var> is a name or prefix and
///     <var>index</var> is the integer index used for this name.
/// 
/// The list of namespaces used in this XML document is maintained as:
/// @i%DocumentId@("n")=the number of namespaces used by this XML document.
/// @i%DocumentId@("n",index)=namespace
/// @i%DocumentId@("N",namespace)=index 
///     where <var>namespace</var> is the the uri for a namespace and
///     <var>index</var> is the integer index used for this namespace in the "u" and "v" nodes above.
/// @i%DocumentId@("N","http://www.w3.org/2001/XMLSchema-instance")=1 and
/// @i%DocumentId@("n",1)="http://www.w3.org/2001/XMLSchema-instance" are always true 
///     to allow easy lookup of the schema instance namespace: "http://www.w3.org/2001/XMLSchema-instance"
/// 
/// The version of the internal content handler is given by a single integer in
/// @i%DocumentId@("v")=version integer -- currently 4
/// </pre>
Class %XML.ImportHandler Extends %XML.SAX.ContentHandler [ System = 2 ]
{

/// Integer tree id within ..GlobalName global
Property Tree As %Integer [ Internal ];

/// Current child list node.  0 means the document.
Property Node As %Integer [ Internal ];

/// Current characcter data that is being built
Property CurrentText As %String [ Internal ];

/// Store a stack of prefixes and associated namespaces.
Property PrefixMap As %String [ Internal, MultiDimensional ];

/// DocumentId for XML parse tree.
Property DocumentId As %String [ Internal ];

/// DOMName is used in COS code as the name of the DOM data structure
Property DOMName As %String [ Internal ];

Method %OnNew(globalName As %String, handlerType As %Integer) As %Status [ Internal ]
{
	#define MyCurrentHandler $$$LocHandler
	
	// Set HandlerType
	Set ..HandlerType=$get(handlerType)
	// Setting ..HandlerType via ^%SYS("XML","SAXHandlerType") is for internal use only
	// and cannot be expected to work in future versions.
	If ..HandlerType="" {
		Set ..HandlerType=$get(^%SYS("XML","SAXHandlerType"))
	}
	If ..HandlerType="" {
		Set ..HandlerType=$$$MyCurrentHandler
	}
	
	If (..HandlerType=$$$FlatIntHandler) || (..HandlerType=$$$IntHandler) || (..HandlerType=$$$ClsHandler) {
		// Set default global for SAX parser.
		If $get(globalName)'="" {
			Set ..GlobalName=globalName
		} ElseIf $get(^%SYS("XML","SAXGlobalName"))'="" {
			Set ..GlobalName=$get(^%SYS("XML","SAXGlobalName"))
		}
		If $get(^%SYS("XML","SAXAppendJob")) {
			Set ..GlobalName=..GlobalName_$job
		}
		If ..GlobalName="" Set ..GlobalName="||%xmlTemp"
		If $extract(..GlobalName)="^" Set ..GlobalName=$extract(..GlobalName,2,*)
		Set ..DOMName="^"_..GlobalName
	} ElseIf ..HandlerType=$$$LocHandler {
		// Local variable case
		If $get(globalName)="" Set globalName="%SAX"
		Set ..GlobalName=globalName
		If $data(@globalName),'$data(@($$$xmliDocId2(globalName,@globalName))) {
			// Reuse an empty node
			Set ..Tree=@globalName
		} Else {
			Set ..Tree=$i(@globalName)
		}
		Set ..controlblock=$zu(72,49,globalName)
		Set ..DOMName=globalName
	} 
	
	Quit $$$OK
}

Method %OnClose() As %Status [ Internal ]
{
	If (..DocumentId'="") && (..Tree'="") {
		Kill $$$xmliDocGlobal(..DocumentId)
	}
	Quit $$$OK
}

/// Callback after XML parse complete.  Used to set DocumentId.
Method OnPostParse() As %Status [ Internal ]
{
	If ..Tree'="" {
		Set ..DocumentId=$$$xmlDocumentId($this)
	}
	Quit $$$OK
}

/// Adds the elements with the wsu:Id to the id table.
Method AddWSSecurityIds() [ Internal ]
{
	Set docid=..DocumentId
	For node=1:1 {
		Set childlist=$get($$$xmliCLNode(docid,node))
		If childlist="" Quit
		If $$$xmliCLnext(docid,childlist)'=0 Continue
		Set nodeid=$$$xmliMakeNodeId(docId,$$$xmliCLparent(docid,childlist),$$$xmliCLoffset(docid,childlist))
		If $$$xmlAttributeDefined(docid,nodeid,"Id") {
			$$$xmlSetNodeById(i%DocumentId,$$$xmlGetAttribute(docid,nodeid,"Id"),nodeid)
		}
	}
}

/// Adds the elements with ID attribute to the id table.
Method AddIDs()
{
	Set docid=..DocumentId
	For node=1:1 {
		Set childlist=$get($$$xmliCLNode(docid,node))
		If childlist="" Quit
		If $$$xmliCLnext(docid,childlist)'=0 Continue
		Set nodeid=$$$xmliMakeNodeId(docId,$$$xmliCLparent(docid,childlist),$$$xmliCLoffset(docid,childlist))
		If $$$xmlAttributeDefined(docid,nodeid,"ID") {
			$$$xmlSetNodeById(docid,$$$xmlGetAttribute(docid,nodeid,"ID"),nodeid)
		}
	}
}

/// Gets the next id for this document based on the id table and returns in id argument.
/// The nodeid for the rewturned id is the return value.
Method GetNextId(ByRef id As %String) As %String
{
	Set docid=..DocumentId
	set nodeid=""
	Set id=$order($$$xmliDocRef(docid)"i",id),1,nodeid)
	Quit nodeid
}

/// Make a copy of the document to another node in the same global.
/// Return the document id of the copy.
Method CopyDocument() As %String
{
	Set documentId=..DocumentId
	If documentId="" Quit ""

	Set global=..DOMName
	Set tree=$increment(@global)
	Set document=global_"("_tree_")"
	Merge @document=$$$xmliDocGlobal(documentId)

	Quit $$$xmliDocId2(global,tree)
}

/// Kill the document specified by the documentId argument
ClassMethod KillDocument(documentId)
{
	Kill $$$xmliDocGlobal(documentId)
}

/// Map name to attribute index for all attributes associated with a node.<br>
/// Format is @documentId@("a",name)=attribute<br>
/// Return count of attributes
ClassMethod GetAttributeMap(documentId As %String, nodeId As %String) As %Integer [ Internal ]
{
	Kill $$$xmliAttributeMap(documentId)
	Set $$$xmliAttributeMap(documentId)=nodeId
	Set count=0
	$$$xmlaGetChildList(documentId,nodeId,childlist,descriptor)
	$$$xmlaForEachAttribute(documentId,childlist,o,attribute)
		Set count=count+1
		Set $$$xmliAttributeMapNode(documentId,$$$xmlaGetAttributeName(documentId,attribute))=attribute
	$$$xmlaEndForEachAttribute(documentId,childlist,o,attribute)
	Quit count
}

/// Set the specified part of the internal attribute.
ClassMethod SetAttribute(documentId As %String, ByRef nodeId As %String, name As %String, value As %String, begin As %Integer, end As %Integer) [ Internal ]
{
	If name="" Quit
	Set offset=$$$xmliCLBase-1
	Set done=0
	$$$xmlaGetChildList(documentId,nodeId,childlist,descriptor)
	$$$xmlaForEachAttribute(documentId,childlist,o,attribute)
		If $$$xmlaGetAttributeName(documentId,attribute)=name {
			Set CLid=$$$xmliGetChildList(documentId,nodeId)
			Set $extract($$$xmliCLNode(documentId,CLid),offset+begin,offset+end)=value
			Set done=1
			Quit
		}
		Set offset=offset+$$$xmliAttributeSize
	$$$xmlaEndForEachAttribute(documentId,childlist,o,attribute)
	If 'done {
		Set attribute=$$$xmliEmptyAttribute
		Set nameIndex=..GetNameIndex(documentId,name)
		Set $extract(attribute,1,4)=$zlchar(nameIndex)
		Set $extract(attribute,begin,end)=value
		Set CLid=$$$xmliGetChildList(documentId,nodeId)
		Do ..InsertDescriptor(documentId,1,CLid,offset+1,attribute)
		Set newElementOffset=$$$xmliCLelementOffset(documentId,$$$xmliCLNode(documentId,CLid))+$$$xmliAttributeSize
		$$$xmliSetCLelementOffset(documentId,CLid,newElementOffset)
		If $get($$$xmliAttributeMap(documentId))=nodeId {
			Set $$$xmliAttributeMapNode(documentId,name)=attribute
		}
	}
}

/// Remove the specified attribute.
ClassMethod RemoveAttribute(documentId As %String, ByRef nodeId As %String, name As %String, namespace As %String) [ Internal ]
{
	If name="" Quit
	Set offset=$$$xmliCLBase
	$$$xmlaGetChildList(documentId,nodeId,childlist,descriptor)
	$$$xmlaForEachAttribute(documentId,childlist,o,attribute)
		If $$$xmlaGetAttributeName(documentId,attribute)=name {
			If '$data(namespace) || (namespace=$$$xmlaGetAttrNamespaceURI(documentId,attribute)) {
				Set CLid=$$$xmliGetChildList(documentId,nodeId)
				Do ..RemoveDescriptor(documentId,CLid,offset,$$$xmliAttributeSize)
				Set newElementOffset=$$$xmliCLelementOffset(documentId,$$$xmliCLNode(documentId,CLid))-$$$xmliAttributeSize
				$$$xmliSetCLelementOffset(documentId,CLid,newElementOffset)
				If $get($$$xmliAttributeMap(documentId))=nodeId {
					Kill $$$xmliAttributeMapNode(documentId,name)
				}
			}
		}
		Set offset=offset+$$$xmliAttributeSize
	$$$xmlaEndForEachAttribute(documentId,childlist,o,attribute)
}

/// GetNameIndex returns the index associated with a name in the document's dictionary.
/// If the name does not exist in the dictionary, it is added
ClassMethod GetNameIndex(docId As %String, name As %String, create As %Boolean = 1) As %Integer [ Internal ]
{
	If name="" {
		Set index=0
	} Else {
		Set index=+$$$xmliNameToIndex(docId,name)
		If index=0,create {
			$$$xmliInsertName(docId,name)
			Set index=$$$xmliCountName(docId)
		}
	}
	Quit index
}

/// GetNamespaceIndex returns the index associated with a namespace in the document's dictionary.
/// If the namespace does not exist in the dictionary, it is added
ClassMethod GetNamespaceIndex(docId As %String, namespace As %String) As %Integer [ Internal ]
{
	If namespace="" {
		Set index=0
	} Else {
		Set index=+$$$xmlNamespaceToIndex(docId,namespace)
		If index=0 {
			$$$xmlInsertNamespace(docId,namespace)
			Set index=$$$xmlNamespaceToIndex(docId,namespace)
		}
	}
	Quit index
}

/// Get the child list from parent node
ClassMethod ExtendChildList(docId As %String, ByRef CLid As %Integer, desc As %String) [ Internal ]
{
	// Move to last child list extension
	For {
		Set childlist=$$$xmliCLNode(docId,CLid)
		Set next=$$$xmliCLnext(docId,childlist)
		If next=0 Quit
		Set CLid=next
	}
	
	// Get child list except new descriptor
	Set len=$length(childlist)
	Set childlist=$extract(childlist,1,*-$$$xmliDescriptorSize)

	If (len+$$$xmliDescriptorSize)>$$$xmliCLMaxNode {
		Set new=$increment($$$xmliDocGlobal(docId))
		Set $extract(childlist,$$$xmliCLBase,len)=""
		Set $$$xmliCLNode(docId,new)=childlist
		$$$xmliSetCLelementOffset(docId,new,$$$xmliCLBase)
		$$$xmliUpdateCLnext(docId,CLid,new)

		Set CLid=new
		Set $$$xmliCLNode(docId,CLid)=$$$xmliCLNode(docId,CLid)_$zlchar(desc)
	} Else {
		Set $$$xmliCLNode(docId,CLid)=childlist_$zlchar(desc)
	}
	$$$xmliSetCLnext(docId,CLid,0)
}

/// Insert a descriptor in a child list by moving the specified descriptor.
/// CLid and offset are updated for the new value when the node is moved.
ClassMethod InsertDescriptor(documentId As %String, attribute As %Boolean, ByRef CLid As %Integer, ByRef offset As %Integer, desc As %String) [ Internal ]
{
	Set (returnCLid,returnOffset)=""
	If attribute {
		Set insert=desc
		Set desclen=$$$xmliAttributeSize
	} Else {
		Set insert=$zlchar(desc)
		Set desclen=$$$xmliDescriptorSize
	}
	For {
		Set len=$length(insert)
		Set cl=$$$xmliCLNode(documentId,CLid)
		Set nextCLid=$$$xmliCLnext(documentId,cl)
		Set cl=$extract(cl,1,*-$$$xmliDescriptorSize)
		If $length(cl)+len>($$$xmliCLMaxNode-$$$xmliDescriptorSize) {
			// This code assumes that the last descriptor is always an element or character descriptor  -- not attribute
			Set last=$length(cl)-len
			Set nextInsert=$extract(cl,*-len+1,*)
		} Else {
			Set nextInsert=""
			Set last=$length(cl)
		}
		Set $$$xmliCLNode(documentId,CLid)=$extract(cl,1,offset-1)_insert_$extract(cl,offset,last)
		$$$xmliSetCLnext(documentId,CLid,nextCLid)
		If returnOffset="" {
			If offset>last {
				Set returnOffset=$$$xmliCLBase
				If nextCLid'=0 Set returnCLid=nextCLid
			} Else {
				Set returnOffset=offset+len
				Set returnCLid=CLid
			}
		}

		Set CLlen=$length($$$xmliCLNode(documentId,CLid))
		While offset<CLlen {
			If attribute,offset>=($$$xmliCLelementOffset(documentId,$$$xmliCLNode(documentId,CLid))+$$$xmliAttributeSize) {
				Set attribute=0
				Set desclen=$$$xmliDescriptorSize
			}
			If 'attribute {
				Set desctemp=$$$xmliCLDesc(documentId,CLid,offset)
				If $$$xmliDescType(documentId,desctemp)=$$$xmlELEMENTNODE {
					Set id=$$$xmliDescValue(documentId,desctemp)
					$$$xmliSetCLoffset(documentId,id,offset)
				}
			}
			Set offset=offset+desclen
		}

		If nextInsert="" {
			Quit
		} ElseIf nextCLid=0 {
			Set nextCLid=$increment($$$xmliDocGlobal(documentId))
			Set $extract(cl,$$$xmliCLBase,$$$xmliCLMaxNode)=""
			Set $$$xmliCLNode(documentId,nextCLid)=cl
			$$$xmliSetCLnext(documentId,nextCLid,0)
			$$$xmliSetCLelementOffset(documentId,nextCLid,$$$xmliCLBase)
			$$$xmliUpdateCLnext(documentId,CLid,nextCLid)
			If returnCLid="" {
				Set returnCLid=nextCLid
			}
		}

		Set offset=$$$xmliCLBase
		Set insert=nextInsert
		Set CLid=nextCLid
	}

	Set CLid=returnCLid
	Set offset=returnOffset
}

/// Remove a descriptor from a child list
ClassMethod RemoveDescriptor(documentId As %String, CLid As %Integer, offset As %Integer, len As %Integer) [ Internal ]
{
	Set attribute=(len=$$$xmliAttributeSize)
	
	// Remove descriptor
	Set $extract($$$xmliCLNode(documentId,CLid),offset,offset+(len-1))=""
	
	// Adjust ids for removed descriptor
	Set id=""
	For {
		Set id=$order($$$xmliDocRef(documentId)"i",id),1,nodeid)
		If id="" Quit
		If $piece(nodeid,",",1)=CLid,$piece(nodeid,",",2)>offset {
			Set $piece(nodeid,",",2)=$piece(nodeid,",",2)-4
			Set $$$xmliDocRef(documentId)"i",id)=nodeid
		}
	}
	
	// Loop over following descriptors and fix up.
	Set CLlen=$length($$$xmliCLNode(documentId,CLid))
	While offset<CLlen {
		If attribute,offset>=($$$xmliCLelementOffset(documentId,$$$xmliCLNode(documentId,CLid))-len) {
			Set attribute=0
			Set len=4
		}
		If 'attribute {
			Set desc=$$$xmliGetDescriptor2(documentId,CLid,offset)
			If $$$xmliDescType(documentId,desc)=$$$xmlELEMENTNODE {
				Set cl=$$$xmliDescValue(documentId,desc)
				$$$xmliSetCLoffset(documentId,cl,offset)
			}
		}
		Set offset=offset+len
	}
}

/// Return the next child of the specified nodeId or "" if none.
ClassMethod NextChild(docId As %String, parent As %String, ByRef parentChildlist As %String, childId As %String, Output descriptor As %String) As %String [ Internal ]
{
	Set id=..GetNextChild(docId,parent,childId,1)
	If id'="" {
		Set descriptor=$$$xmliGetDescriptor(docId,id)
		Set parentChildlist=$$$xmliCLNode(docId,$$$xmliNodeIdCLparent(id))
	}
	Quit id
}

/// Return the next child of the specified nodeId or "" if none.
ClassMethod GetNextChild(docId As %String, nodeId As %String, childId As %String, bNext As %Boolean) As %String [ Internal ]
{
	If childId="" {
		If $$$xmlaIsTop(docId,nodeId) Quit $$$xmlGetDocumentElement(docId)
		Set childCLid=$$$xmliGetChildList(docId,nodeId)
		Set childCLoffset=$$$xmliCLelementOffset(docId,$$$xmliCLNode(docId,childCLid))
	} Else {
		If $$$xmlaIsTop(docId,nodeId) Quit ""
		Set childCLid=$$$xmliNodeIdCLparent(childId)
		Set childCLoffset=$$$xmliNodeIdCLoffset(childId)+$select($get(bNext):0,1:$$$xmliDescriptorSize)
	}
	
	For {
		Set desc=$$$xmliGetDescriptor2(docId,childCLid,childCLoffset)
		If $$$xmliDescType(docId,desc)'=$$$xmliNEXTNODE Quit

		Set childCLid=$$$xmliDescValue(docId,desc)
		If childCLid=0 {
			Set childCLid=""
			Quit
		}
		Set childCLoffset=$$$xmliCLelementOffset(docId,$$$xmliCLNode(docId,childCLid))
	}
	
	If childCLid="" {
		Quit ""
	} Else {
		Quit $$$xmliMakeNodeId(docId,childCLid,childCLoffset)
	}
}

/// Return the previous child of the specified nodeId or "" if none.
ClassMethod GetPreviousChild(docId As %String, nodeId As %String, childId As %String) As %String [ Internal ]
{
	If childId="" {
		If $$$xmlaIsTop(docId,nodeId) Quit $$$xmlGetDocumentElement(docId)
		// Find last child in last child list
		Set childCLid=$$$xmliGetChildList(docId,nodeId)
		For {
			Set childCLoffset=$length($$$xmliCLNode(docId,childCLid))-$$$xmliDescriptorSize1
			Set desc=$$$xmliGetDescriptor2(docId,childCLid,childCLoffset)
			// Must be next node
			Set next=$$$xmliDescValue(docId,desc)
			If next=0 {
				Set childCLoffset=childCLoffset-$$$xmliDescriptorSize
				Quit
			} Else {
				Set childCLid=next
			}
		}
	} Else {
		If $$$xmlaIsTop(docId,nodeId) Quit ""
		Set childCLid=$$$xmliNodeIdCLparent(childId)
		Set childCLoffset=$$$xmliNodeIdCLoffset(childId)-$$$xmliDescriptorSize
	}

	// Test for need to move to previous child list	
	If childCLoffset<$$$xmliCLelementOffset(docId,$$$xmliCLNode(docId,childCLid)) {
		// If first child list, then no more children
		If childCLid=$$$xmliGetChildList(docId,nodeId) Quit ""
		
		// Find previous child list
		Set next=childCLid
		Set childCLid=$$$xmliGetChildList(docId,nodeId)
		For {
			Set childCLoffset=$length($$$xmliCLNode(docId,childCLid))-$$$xmliDescriptorSize1
			Set desc=$$$xmliGetDescriptor2(docId,childCLid,childCLoffset)
			// Must be next node
			If next=$$$xmliDescValue(docId,desc) {
				Set childCLoffset=childCLoffset-$$$xmliDescriptorSize
				Quit
			} Else {
				Set childCLid=$$$xmliDescValue(docId,desc)
			}
		}
	}

	Quit $$$xmliMakeNodeId(docId,childCLid,childCLoffset)
}

Method startDocument() [ Internal ]
{
	If ..HandlerType=$$$FlatIntHandler {
		// SortBegin for internal handler
		Set global=..DOMName_"("_..Tree_")"
		If $SortBegin(@global)
	} Else {
		// Prepare Tree
		Set global=..DOMName
		Set i%Tree=$increment(@global)
		Set i%DocumentId=$$$xmlDocumentId($this)
		Set i%Node=0,i%CurrentText=""
		Kill $$$xmliDocGlobal(i%DocumentId)
		$$$xmliSetDocumentNode(i%DocumentId)
		// Set version of DOM
		Set $$$xmliDocRef(i%DocumentId)"v")=4
		// No dictionary entries yet
		Set $$$xmliDocRef(i%DocumentId)"d")=0
		// Schema instance namespace always has index = 1.
		Set $$$xmliDocRef(i%DocumentId)"n")=0
		$$$xmlInsertNamespace(i%DocumentId,"http://www.w3.org/2001/XMLSchema-instance")
	}
	Quit
}

Method endDocument() [ Internal ]
{
	If ..HandlerType=$$$FlatIntHandler {
		// SortEnd for internal handler
		Set global=..DOMName_"("_..Tree_")"
		If $SortEnd(@global)
	}
	Quit
}

/// Receive notification of the start of an element.<p>
/// 
/// Argument are as follows:<br>
/// @param uri The URI of the associated namespace for this element<br>
/// @param localname the local part of the element name<br>
/// @param qname the QName of this element<br>
/// @param attrs, a list in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> format consisting of a repeating group of attributes :-
/// 
/// 1) uri The URI of the associated namespace for this attribute<br>
/// 2) localname the local part of this attribute<br>
/// 3) qname the QName of this attribute<br>
/// 4) type the type of this attribute<br>
/// 5) value the value of this attribute<br>
/// </p>
Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List) [ Internal ]
{
	$$$XMLTimerNewMark

	Set nil=0
	Set parent=i%Node
	
	// Emit in process character data
	If i%CurrentText'="" {
		Set chardesc=$$$xmliNewCharacterDescriptor(i%DocumentId,i%CurrentText)
		Do ..ExtendChildList(i%DocumentId,.parent,chardesc)
		Set i%CurrentText=""
	}

	// Get child list for parent
	Do ..ExtendChildList(i%DocumentId,.parent,0)
	Set childlist=$$$xmliCLNode(i%DocumentId,parent)
	Set offset=$length(childlist)-$$$xmliDescriptorSize-$$$xmliDescriptorSize1

	// And process the attributes...
	set attributes=""
	For atptr=1:5:$listlength(attrs) {
		Set atval=$list(attrs,atptr+4)
		Set atname=$list(attrs,atptr+1)
		Set atqname=$list(attrs,atptr+2)
		Set aturi=$list(attrs,atptr)
		Set atvaluri=""
		If $length(atval,":")>1 {
			Set atvalp = $piece(atval,":",1)
			If atvalp="" Set atvalp=":"
			If ($length(atvalp)<256) && $data(i%PrefixMap(atvalp)) {
				Set atvaluri=$get(i%PrefixMap(atvalp,i%PrefixMap(atvalp)))
			}
		}
		If ((atname="id") || (atname="Id")) && (atval'="") {
			$$$xmlSetNodeById(i%DocumentId,atval,$$$xmliMakeNodeId(i%DocumentId,parent,offset))
		}
		If aturi="http://www.w3.org/2001/XMLSchema-instance",
		   (atname="nil") || (atname="null"),
		   (atval="true") || (atval="1") {
			Set nil=1
		}
		Set attributes=attributes_$$$xmliNewAttribute(i%DocumentId,atname,atqname,aturi,atvaluri,atval)
	}
 
	// Get location of element
	Do ..LocatePosition(.line,.column)

	// Create the new child list 
	Set CLid=$increment($$$xmliDocGlobal(i%DocumentId))
	Set CLNode=$$$xmliNewCLNode(i%DocumentId,parent,offset,localname,$length(attributes)\$$$xmliAttributeSize,nil,uri,qname,line,column)
	Set $$$xmliCLNode(i%DocumentId,CLid)=CLNode_attributes
	$$$xmliSetCLnext(i%DocumentId,CLid,0)
	Set i%Node=CLid
 
	// Create element descriptor and append to child list
	Set desc=$$$xmliNewElementDescriptor(i%DocumentId,CLid)
	$$$xmliReplaceDescriptor2(i%DocumentId,parent,offset,desc)

	$$$XMLTimerRecord("startElement")
	Quit
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String) [ Internal ]
{
	$$$XMLTimerNewMark

	Set parent=i%Node
	If parent>0 {
		// Restore previous parent node as the current node
		// Emit in process character data
		If i%CurrentText'="" {
			Set chardesc=$$$xmliNewCharacterDescriptor(i%DocumentId,i%CurrentText)
			Do ..ExtendChildList(i%DocumentId,.parent,chardesc)
			Set i%CurrentText=""
		}

		Set i%Node=$$$xmliCLparent(i%DocumentId,$$$xmliCLNode(i%DocumentId,parent))
	}
	
	$$$XMLTimerRecord("endElement")
	Quit
}

Method characters(chars As %Library.String, length As %Library.Integer) [ Internal ]
{
	$$$XMLTimerNewMark
	Set whitespace=($tr(chars,$c(9,10,13,32,160),"")="")
 
	// ignore blank data if not keeping whitespace
	If 'i%KeepWhitespace && whitespace {
 		$$$XMLTimerRecord("blank chars")
		Quit
	}
 
	Set parent=i%Node
	Set text=chars

	If text'="" {
		// Get child list for parent
		Set parent=i%Node
		Set prevdata=i%CurrentText
	
		// If previous node was a character node, then append to it.
		// Break into multiple nodes if length > 32767
		If $length(prevdata)+$length(text) > $$$xmliMaxCharacterNode {
			Set len=$$$xmliMaxCharacterNode-$length(prevdata)
			Set chardesc=$$$xmliNewCharacterDescriptor(i%DocumentId,prevdata_$extract(text,1,len))
			Do ..ExtendChildList(i%DocumentId,.parent,chardesc)
			Set i%CurrentText=$extract(text,len+1,*)
		} Else {
			Set i%CurrentText=prevdata_text
		}
	}

	$$$XMLTimerRecord("characters")
	Quit
}

/// This method records the current prefix mappings which are in scope
/// Prefixes are automatically handled by SAX on element and attribute names but not
/// within element or attribute content.
Method startPrefixMapping(prefix As %String, uri As %String) [ Internal ]
{
	$$$XMLTimerNewMark
	If prefix="" Set prefix=":"
	Set i%PrefixMap(prefix)=$g(i%PrefixMap(prefix))+1
	If uri'="" {
		Set index=$$$xmlNamespaceToIndex(i%DocumentId,uri)
		If index="" {
			$$$xmlInsertNamespace(i%DocumentId,uri)
		}
	}
	Set i%PrefixMap(prefix,i%PrefixMap(prefix))=uri
	$$$XMLTimerRecord("startPrefixMapping")
	Quit
}

Method endPrefixMapping(prefix As %String) [ Internal ]
{
	$$$XMLTimerNewMark
	If prefix="" Set prefix=":"
	Set ptr=+$get(i%PrefixMap(prefix))
	If ptr>1 {
		Kill i%PrefixMap(prefix,ptr)
		Set i%PrefixMap(prefix) = ptr - 1
	} Else {
		Kill i%PrefixMap(prefix)
	}
	$$$XMLTimerRecord("endPrefixMapping")
	Quit
}

Method error(message As %String) [ Internal ]
{
	Do ..SaveError("error",message)
	Quit
}

Method fatalError(message As %String) [ Internal ]
{
	Do ..SaveError("fatalerror",message)
	Quit
}

Method warning(message As %String) [ Internal ]
{
	Do ..SaveError("warning",message)
	Quit
}

Method SaveError(type As %String, message As %String) [ Internal ]
{
	Set count=$increment($$$xmliDocRef(i%DocumentId)type))
	Set $$$xmliDocRef(i%DocumentId)type,count)=message
	Quit
}

/// Formatted dump of iternal structure
ClassMethod Dump(local, repeatable As %Boolean = 0) [ Internal ]
{
	If '$data(local) {
		Set local=($$$MyCurrentHandler=$$$LocHandler)
	}
	If local {
		Set dom="%SAX"
	} Else {
		Set dom="^||%xmlTemp"
	}
	
	For i=1:1:@dom {
		If '$data(@dom@(i)) Continue
		If $get(@dom@(i))="" Continue
		If 'repeatable Write "----- Node ",i,!
		
		For node=0:1:@dom@(i) {
			Set x=@dom@(i,node)
			Write node,"*"_$zlascii(x,1)_":"_$zlascii(x,5)
			Write " N",$zlascii(x,9),"-",$get(@dom@(i,"d",$zlascii(x,9)))
			Write " P",$zlascii(x,13)\16,"-",$get(@dom@(i,"d",$zlascii(x,13)\16))
			Write " F",$zlascii(x,13)#16
			Write " O",$zwascii(x,17)
			Write " U",$zwascii(x,19),"-",$get(@dom@(i,"n",$zwascii(x,19)))
			Write " L",$zlascii(x,21)
			Write " C",$zlascii(x,25)
			Write !
			
			Set offset=$$$xmliCLBase
			Set numAttrs=($zwascii(x,17)-$$$xmliCLBase)/$$$xmliAttributeSize
			For j=1:1:numAttrs {
				Write "    A: "
				Set attr=$extract(x,offset,offset+$$$xmliAttributeSize-1)
				Set index=$zlascii(attr,5)
				If index>0 Write $get(@dom@(i,"d",index)),"[",index,"]:"
				Write $get(@dom@(i,"d",$zlascii(attr,1))),"[",$zlascii(attr,1),"]="
				Write $get(@dom@(i,"d",$zlascii(attr,13))),"[",$zlascii(attr,13),"]"
				Write " U",$zwascii(attr,9),"-",$get(@dom@(i,"n",$zwascii(attr,9)))
				Write " V",$zwascii(attr,11),"-",$get(@dom@(i,"n",$zwascii(attr,11)))
				Write !
				Set offset=offset+$$$xmliAttributeSize
			}
			
			For {
				Set desc=$zlascii(x,offset)
				Set type=desc#16
				If type<0 Quit
				Write "    "_$case(type,0:"E",1:"C",2:"W",3:"N",:"**")_": "
				If type=0 {
					Write " "_(desc\16)
					Write !
					If desc=0 break
				} ElseIf (type=1) || (type=2) {
					Write "[",desc\16,"]=","'",$get(@dom@(i,"d",desc\16)),"'"
					Write !
				} ElseIf type=3 {
					Write " "_(desc\16)
					Write !
					Quit
				} Else {
					Write "Unknown type = ",type,!
					Quit
					break
				}
				Set offset=offset+$$$xmliDescriptorSize
			}
		}

		If $data(@dom@(i,"i")) {
			Merge ids=@dom@(i,"i")
			Zw ids
		}
	}
}

/// Serialize the value ofthe specified attribute as text string.
/// Note that the attribute value may be of any length.<br>
/// <var>tree</var> is the id of the ML document tree.<br>
/// <var>attribute</var> is the internal form of the attribute specifier as returned by 
/// $$$xmliGetAttributeByName or $$$xmlaForEachAttribute.<br>
ClassMethod GetAttribute(tree As %String, attribute) As %String
{
	Quit $select(..SerializeAttribute(tree,attribute,0,.text):text,1:"")
}

/// Serialize the value of the specified attribute as text.
/// Note that the attribute value may be of any length.<br>
/// <var>tree</var> is the id of the ML document tree.<br>
/// <var>attribute</var> is the internal form of the attribute specifier as returned by 
/// $$$xmliGetAttributeByName or $$$xmlaForEachAttribute.<br>
/// <var>outputStream</var> is true if the serialized output is to be sent to
/// to the existing stream <var>data</var>.<br>
/// <var>outputStream</var> is false if the serialized output is to be be appended to
/// the string <var>data</var>.   <var>data</var> is created if it is not already defined.<br>
/// <var>lineMode</var> is true if the stream output should be written in line
/// oriented mode, else the stream output will be written as a continuous block.
ClassMethod SerializeAttribute(tree As %String, attribute, outputStream As %Boolean, ByRef data, lineMode As %Boolean = 0) As %Boolean
{
	Set ok=1
	Set empty=1
	Try {
		If '$data(data) Set data=""
		If outputStream,$isobject(data),'lineMode {
			Try {
				Set data.LineTerminator=$c(10)
			} Catch {
			}
		}
	 
	 	Set ok=..output($get($$$xmliAttributeNode(tree,attribute)),outputStream,.data,lineMode)
	 	If ok,$data($$$xmliAttributeNode(tree,attribute))>=10 {
		 	Set index=""
		 	While ok {
			 	Set index=$order($$$xmliAttributeSubnode(tree,attribute,index),1,text)
			 	If index="" Quit
			 	Set ok=..output(text,outputStream,.data,lineMode)
		 	}
	 	}
	 	
	} Catch ex {
		Set ok=0
	}
	
	If ok && empty set ok=-1
	Quit ok
}

/// Serialize the base64 encoded text children of this node as text.<br>
/// <var>tree</var> is the id of the ML document tree.<br>
/// <var>attribute</var> is the internal form of the attribute specifier as returned by 
/// $$$xmliGetAttributeByName or $$$xmlaForEachAttribute.<br>
/// <var>outputStream</var> is true if the serialized output is to be sent to
/// to the existing stream <var>data</var>.<br>
/// <var>outputStream</var> is false if the serialized output is to be be appended to
/// the string <var>data</var>.   <var>data</var> is created if it is not already defined.<br>
ClassMethod SerializeBase64Attribute(tree As %Integer, attribute, outputStream As %Boolean, ByRef data, hex As %Boolean = 0, baseChildlist As %String) As %Boolean
{
	Try {
		Set ok=1
		If '$data(data) Set data=""
	 
		Set need=16384,out=""
	 	Set text=$get($$$xmliAttributeNode(tree,attribute))
	 	Set index=""
	 	For {
 			While ok && (text'="") {
				Set text=$translate(text,$char(9,10,13,32))
				Set out=out_$extract(text,1,need)
				Set need=need-$length(text)
				If need>0 Quit
				If hex {
					Set ok=..output(..hextobin(out),outputStream,.data,0)
				} Else {
					Set ok=..output($system.Encryption.Base64Decode(out),outputStream,.data,0)
				}
				Set text=$extract(text,*+need+1,*)
	 			Set need=16384,out=""
			}
		 	If 'ok Quit
		 	Set index=$order($$$xmliAttributeSubnode(tree,attribute,index),1,text)
		 	If index="" Quit
	 	}
	 	
		If ok && (out'="") {
			If hex {
				Set ok=..output(..hextobin(out),outputStream,.data,0)
			} Else {
				Set ok=..output($system.Encryption.Base64Decode(out),outputStream,.data,0)
			}
		}
	} Catch ex {
		Set ok=0
	}
	
	Quit ok
}

/// Serialize the children of this node as text.<br>
/// <var>tree</var> is the id of the ML document tree.<br>
/// <var>node</var> is the id of the node to be serialized.<br>
/// <var>outputStream</var> is true if the serialized output is to be sent to
/// to the existing stream <var>data</var>.<br>
/// <var>outputStream</var> is false if the serialized output is to be be appended to
/// the string <var>data</var>.   <var>data</var> is created if it is not already defined.<br>
/// <var>mixed</var> is true if child elements should be serialized, else an
/// error is returned if child elements are found.  
/// mixed=1 uses XML translate table.
/// mixed=2 uses HTML translate table.<br>
/// <var>includeTop</var> is true if the containing element should be included
/// in the returned output.<br>
/// <var>lineMode</var> is true if the stream output should be written in line
/// oriented mode, else the stream output will be written as a continuous block.
ClassMethod SerializeNode(tree As %String, node As %String, outputStream As %Boolean, mixed As %Integer = 0, ByRef data, includeTop As %Boolean = 0, lineMode As %Boolean = 0, baseChildlist As %String) As %Boolean
{
 If '$data(data) Set data=""
 Set ok=1
 Set empty=1
 If outputStream,$isobject(data),'lineMode {
	 Try {
		 Set data.LineTerminator=$c(10)
	 } Catch {
	 }
 }
 If includeTop {
     $$$xmlaGetChildList(tree,node,baseChildlist,descriptor)
     Set segment = node
 } Else {
     If '$data(baseChildlist) $$$xmlaGetChildList(tree,node,baseChildlist,descriptor)
     $$$xmlaFirstChild(tree,node,baseChildlist,segment,descriptor)
 }
 Set escapeTable=$select(mixed=2:"HTML",1:"XMLC")
 Set attributeTable=$select(mixed=2:"HTML",1:"XML")
 While ok && (segment'="") {
	 Set segtype = $$$xmlaGetNodeType(tree,descriptor)
	 If segtype '= $$$xmlELEMENTNODE {
	 	Set segvalue = $$$xmlaGetData(tree,descriptor)
	 	If segvalue'="" {
	 		Set empty=0
	 		If $data(%xmlSerialize),$length(segvalue)=6,$extract(segvalue,1,5)=$c(1,2,3,4,5) {
				// Special hack that the invalid character string $c(1,2,3,4,5) means insert %xmlSerialize content
				Set value=%xmlSerialize($ascii($extract(segvalue,6)))
				If $isobject(value) {
					While ok && 'value.AtEnd {
						Set out=value.Read()
			 			Set ok=..output(out,outputStream,.data,lineMode)
					}
				} Else {
			 		Set ok=..output(value,outputStream,.data,lineMode)
				}
	 		} ElseIf mixed {
		 		While ok && (segvalue'="") {
			 		kill remainder
			 		Set out=$zcvt(segvalue,"O",escapeTable,remainder)
		 			Set segvalue=remainder
		 			Set ok=..output(out,outputStream,.data,lineMode)
		 		}
	 		} Else {
	 			Set ok=..output(segvalue,outputStream,.data,lineMode)
	 		}
	 	}
	 } Else {
	 	// If mixed content not expected, return error.
	 	If 'mixed Set ok=0 Quit
	 	// Serialize attributes here:
		$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	 	Set segvalue = $$$xmlaGetQName(tree,childlist)
	 	Set empty=0
	 	Set attributes = ""
		$$$xmlaForEachAttribute(tree,childlist,o,attribute)
	 		Set attrvalue = $$$xmlaGetAttribute(tree,attribute)
	 		Set attributes = attributes_" "_ $$$xmlaGetAttributeQName(tree,attribute)_"="""_$zcvt(attrvalue,"O",attributeTable)_""""
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
	 	If $$$xmlaHasChildNodes(tree,childlist) {
		 	Set ok=..output("<"_segvalue_attributes_">",outputStream,.data,lineMode)
		 	If ok Set ok=..SerializeNode(tree,segment,outputStream,mixed,.data,0,lineMode,childlist)
		 	If ok Set ok=..output("</"_segvalue_">",outputStream,.data,lineMode)
	 	} Else {
		 	Set ok=..output("<"_segvalue_attributes_"/>",outputStream,.data,lineMode)
	 	}
	 }
	 If includeTop Quit
     $$$xmlaNextChild(tree,node,baseChildlist,segment,descriptor)
 }
 If ok && empty set ok=-1
 Quit ok
}

/// Serialize the base64 encoded text children of this node as text.<br>
/// <var>tree</var> is the id of the ML document tree.<br>
/// <var>node</var> is the id of the node to be serialized.<br>
/// <var>outputStream</var> is true if the serialized output is to be sent to
/// to the existing stream <var>data</var>.<br>
/// <var>outputStream</var> is false if the serialized output is to be be appended to
/// the string <var>data</var>.   <var>data</var> is created if it is not already defined.<br>
ClassMethod SerializeBase64Node(tree As %Integer, node As %Integer, outputStream As %Boolean, ByRef data, hex As %Boolean = 0, baseChildlist As %String) As %Boolean
{
 Set $ztrap="decodeTrap"
 If '$data(data) Set data=""
 Set ok=1
 Set need=16384,out=""
 If '$data(baseChildlist) $$$xmlaGetChildList(tree,node,baseChildlist,d)
 $$$xmlaFirstChild(tree,node,baseChildlist,segment,descriptor)
 While ok && (segment'="") {
	Set segtype = $$$xmlaGetNodeType(tree,descriptor)
	If segtype'=$$$xmlWHITESPACENODE {
	 	If segtype'=$$$xmlTEXTNODE Set ok=0 Quit
	 	Set segvalue = $translate($$$xmlaGetData(tree,descriptor),$char(9,10,13,32))
	 	While ok && (segvalue'="") {
	 		Set out=out_$extract(segvalue,1,need)
	 		Set need=need-$length(segvalue)
	 		If need>0 Quit
	 		If hex {
	 			Set ok=..output(..hextobin(out),outputStream,.data,0)
	 		} Else {
	 			Set ok=..output($system.Encryption.Base64Decode(out),outputStream,.data,0)
	 		}
	 		Set segvalue=$extract(segvalue,*+need+1,*)
	 		Set need=16384,out=""
	 	}
	}
 	$$$xmlaNextChild(tree,node,baseChildlist,segment,descriptor)
 }
 If ok && (out'="") {
 	If hex {
 		Set ok=..output(..hextobin(out),outputStream,.data,0)
 	} Else {
 		Set ok=..output($system.Encryption.Base64Decode(out),outputStream,.data,0)
 	}
 }
 Quit ok
decodeTrap Quit 0
}

ClassMethod hextobin(hex As %String) As %String [ Internal, Private ]
{
 Set bin=""
 For i=1:2:$length(hex) {
	Set bin=bin_$char($zhex($extract(hex,i,i+1)))
 }
 Quit bin
}

ClassMethod output(text As %String, outputStream As %Boolean, ByRef data, lineMode As %Boolean) As %Boolean [ Internal, Private ]
{
 If outputStream {
	If lineMode {
		Set len=$length(text,$c(10))
		Set sc=$$$OK
		For i=1:1:len-1 {
			Set sc=data.WriteLine($piece(text,$c(10),i))
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit 0
		Set last=$piece(text,$c(10),len)
		If (last'="") If $$$ISERR(data.Write(last)) Quit 0
	} Else {
		If $$$ISERR(data.Write(text)) Quit 0
	}
 } Else {
	Set $ztrap="MaxStringError"
	Set data=data_text
 }
 Quit 1

MaxStringError  Set $ztrap=""
	Quit 0
}

}
