/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XML.XPATH.DOMResult Extends %XML.XPATH.Result [ System = 4 ]
{

/// Public property, contains the current path to the containing element
Property Path As %String;

/// Public property, Only applicable to element nodes. Returns the number of attributes on the current node.
Property AttributeCount As %Integer;

/// Public property, true if the reader is positioned at the end of the stream; otherwise, false.
Property EOF As %Boolean;

/// Public property, Gets a value indicating whether the current node has any attributes.
/// true if the current node has attributes; otherwise, false.
Property HasAttributes As %Boolean;

/// Public property, returns true if the node on which the reader is currently positioned can have a Value; 
Property HasValue As %Boolean;

/// Public property, The qualified name of the current node. The name returned is dependent on the NodeType of the node.
Property Name As %String;

/// Public property, The unqualified name of the current node. The name returned is dependent on the NodeType of the node.
Property LocalName As %String;

/// Public property, The uri of the current node. The name returned is dependent on the NodeType of the node.
Property Uri As %String;

/// Public property, contains the node type of the current node as indicated by the 
/// following table:-
/// 
/// Node Type
/// ---------
/// attribute
/// chars
/// cdata
/// comment
/// document
/// documentfragment
/// documenttype
/// element
/// entity
/// entityreference
/// notation
/// processinginstruction
Property NodeType As %String;

/// Public property, returns the current read state of the reader
/// The following table lists the states and their meanings
/// State        Meaning
/// -----        -------
/// eof          The end of the file has been reached successfully. 
/// initial      The Read method has not been called. 
/// cursoractive The Read method has been called. Additional methods may be called on the reader. 
Property ReadState As %String;

/// Public property, returns the value of the current node. If the value is <32k in length then a string
/// will be returned, if greater then a character stream
Property Value;

Property attrseq As %Integer [ Private ];

Property seq As %Integer [ Private ];

Method %LoadData(id As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
    // initialize the object
    Set i%target=id,i%ReadState="initial"
    Set (i%attrseq,i%seq,i%AttributeCount)=0
    Set (i%Name,i%NodeType,i%Value,i%Path)=""
    Quit $$$OK
}

/// AttributeCount Implementation
Method AttributeCountGet() As %Integer
{
 Quit i%AttributeCount
}

/// EOF Implementation
Method EOFGet() As %Boolean
{
 If i%ReadState="initial" Quit 0
 Quit '$Data($$$JobPrivateGlobalRef(i%target,i%seq))
}

/// HasAttributes Implementation
Method HasAttributesGet() As %Boolean
{
 Quit ''i%AttributeCount
}

/// Path Implementation
Method PathGet() As %String
{
    Set tThis=i%seq,tPath=""
    while (tThis)
    {    
        If $$$JobPrivateGlobalRef(i%target,tThis)="element" {
            Set tPath=$List($$$JobPrivateGlobalRef(i%target,tThis,"n"))_"\"_tPath
        }
        Set tThis=$$$JobPrivateGlobalRef(i%target,tThis,"p")
    }
    Quit tPath
}

/// HasValue Implementation
Method HasValueGet() As %Boolean
{
  If ((i%NodeType="element")||(i%NodeType="")) Quit 0
  Quit 1
}

///  Moves to the attribute with the specified index. Returns 'true' on success, 'false' otherwise
Method MoveToAttributeIndex(pIndex As %String) As %Boolean
{
 Set tRetval=0
 Do
 {
    If i%NodeType'="element"&&(i%NodeType'="attribute") Quit
    If pIndex>i%AttributeCount!(pIndex<1) Quit
    Set i%NodeType="attribute",i%attrseq=pIndex,tRetval=1
 } While 0
 Quit tRetval
}

/// Move to the attribute with the specified name. Returns 'true' on success, 'false' otherwise
Method MoveToAttributeName(pName As %String, pUri As %String = "") As %Boolean
{
 Set tRetval=0
 Do
 {
    If i%NodeType'="element"&&(i%NodeType'="attribute") Quit
    For tI=1:1:..AttributeCount {
        If $List($$$JobPrivateGlobalRef(i%target,i%seq,"a",tI,"n"),1)=pName Set tRetval=1 Quit
    }
    If tRetval=1 Set i%NodeType="attribute",i%attrseq=tI
 } While 0
 Quit tRetval
}

/// Moves to the associated element when the current node is of type attribute
Method MoveToElement() As %Boolean
{
 If i%NodeType'="attribute" Quit 0
 Set i%NodeType="element",i%attrseq=0
 Quit 1
}

/// Name implementation
Method NameGet() As %String
{
  Quit $Case(i%NodeType,"":"","attribute":$List($$$JobPrivateGlobalRef(i%target,i%seq,"a",i%attrseq,"n"),1),:$List($$$JobPrivateGlobalRef(i%target,i%seq,"n"),1))
}

Method LocalNameGet() As %String
{
     Quit $Case(i%NodeType,"":"","attribute":$List($$$JobPrivateGlobalRef(i%target,i%seq,"a",i%attrseq,"n"),2),:$List($$$JobPrivateGlobalRef(i%target,i%seq,"n"),2))
}

Method UriGet() As %String
{
     Quit $Case(i%NodeType,"":"","attribute":$List($$$JobPrivateGlobalRef(i%target,i%seq,"a",i%attrseq,"n"),3),:$List($$$JobPrivateGlobalRef(i%target,i%seq,"n"),3))
}

/// NodeType implementation
Method NodeTypeGet() As %String
{
 Quit i%NodeType
}

/// Reads the next node from the stream.
/// Returns true if the next node was read successfully; false if there are no more nodes to read.
/// When an DOMResult is first created and initialized, there is no information available. You must 
/// call Read to read the first node.
Method Read() As %Boolean
{
 Set tAtEnd=0
 Do
 {
  Set i%attrseq=0,i%seq=i%seq+1
  Set tAtEnd=..EOF If tAtEnd Set i%ReadState="eof" Quit
  If i%ReadState="initial" Set i%ReadState="cursoractive" 
  Set i%NodeType=$$$JobPrivateGlobalRef(i%target,i%seq)
  Set i%AttributeCount=+$Get($$$JobPrivateGlobalRef(i%target,i%seq,"a"))
 } while 0
 Quit 'tAtEnd
}

/// ReadState Implementation
Method ReadStateGet() As %String
{
  If i%ReadState="initial" Quit "initial"
  If ..EOF Quit "eof"
  Quit "cursoractive"
}

/// Resets the reader to the initial state
Method Rewind()
{
    Set i%attrseq=0,i%seq=0,i%AttributeCount=0,i%ReadState="initial",i%NodeType=""
}

/// Value Implementation
Method ValueGet()
{
    If '..HasValue Quit ""
    If i%NodeType="attribute" Quit $$$JobPrivateGlobalRef(i%target,i%seq,"a",i%attrseq,"v")
    
    #; Test for simple value
    If $$$JobPrivateGlobalRef(i%target,i%seq,"v")=1 Quit $$$JobPrivateGlobalRef(i%target,i%seq,"v",1)
    
    Set tResult=##class(%GlobalCharacterStream).%New()
    For tI=1:1:$$$JobPrivateGlobalRef(i%target,i%seq,"v") {
        Do tResult.Write($$$JobPrivateGlobalRef(i%target,i%seq,"v",tI))
    }
    Do tResult.Rewind()
    Quit tResult
}

Storage custom
{
<Type>%Library.CustomStorage</Type>
}

}
