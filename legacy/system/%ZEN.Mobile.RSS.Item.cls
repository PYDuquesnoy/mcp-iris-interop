/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents an individual item in a feed
Class %ZEN.Mobile.RSS.Item Extends %Persistent [ Deprecated, System = 3 ]
{

Parameter DEFAULTGLOBAL = "^ZEN.Mobile.RSS.Item";

/// This is the timestamp when the item was filed
Property TimeStamp As %TimeStamp [ ReadOnly ];

/// This is the parent Channel's (feed's) Title
Property ChannelTitle As %String [ ReadOnly ];

Method ChannelTitleGet() As %String [ CodeMode = expression ]
{
..Feed.Title
}

/// This is the parent Channel's (feed's) Description
Property ChannelDescription As %String [ ReadOnly ];

Method ChannelDescriptionGet() As %String [ CodeMode = expression ]
{
..Feed.Description
}

/// This is the category of the Item
Property Category As %String(MAXLEN = "") [ ReadOnly ];

/// This is the publication date of the Item
Property PubDate As %String(MAXLEN = "") [ ReadOnly ];

/// This is the title of the item
Property Title As %String(MAXLEN = "") [ ReadOnly ];

/// This is the Description of the item
Property Description As %String(MAXLEN = "") [ ReadOnly ];

/// This is the Link to the full article
Property Link As %String(MAXLEN = "") [ ReadOnly ];

/// Identity
Property ZCRC As %String [ ReadOnly ];

/// Getter for ZCRC
Method ZCRCGet() As %String [ CodeMode = expression ]
{
$LB($ZCRC(..Category,1),$ZCRC(..PubDate,1),$ZCRC(..Title,1),$ZCRC(..Description,1),$ZCRC(..Link,1))
}

Relationship Feed As Feed [ Cardinality = parent, Inverse = Items ];

Method %OnNew(pCategory As %String, pPubDate As %String, pTitle As %String, pDescription As %String, pLink As %String) As %Status [ Private, ServerOnly = 1 ]
{
    Set i%TimeStamp=$zts
    Set i%Category=pCategory
    Set i%PubDate=pPubDate
    Set i%Title=pTitle
    Set i%Description=pDescription
    Set i%Link=pLink
    Quit $$$OK
}

Storage Default
{
<Data name="ItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TimeStamp</Value>
</Value>
<Value name="3">
<Value>ChannelTitle</Value>
</Value>
<Value name="4">
<Value>ChannelDescription</Value>
</Value>
<Value name="5">
<Value>Category</Value>
</Value>
<Value name="6">
<Value>PubDate</Value>
</Value>
<Value name="7">
<Value>Title</Value>
</Value>
<Value name="8">
<Value>Description</Value>
</Value>
<Value name="9">
<Value>Link</Value>
</Value>
<Value name="10">
<Value>ZCRC</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Items")</DataLocation>
<DefaultData>ItemDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ZEN.Mobile.RSS.ItemC("Items")</IdLocation>
<IndexLocation>^ZEN.Mobile.RSS.ItemI</IndexLocation>
<StreamLocation>^ZEN.Mobile.RSS.ItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
