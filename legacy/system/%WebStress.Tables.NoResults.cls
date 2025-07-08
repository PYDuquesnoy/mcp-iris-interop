/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Tables.NoResults Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60212,85655";

/// The suffix type (jpg,gif,etc)
Property Code As %String(TRUNCATE = 1, XMLPROJECTION = "Attribute");

/// Free text that describes the type of file
Property Description As %String(TRUNCATE = 1, XMLPROJECTION = "Attribute");

Index Code On Code [ Unique ];

/// Name of item to correlate on to import this XData 
Parameter CorrelateOn = "Item";

XData UI
{
<Codes>
<Item Code="gif" Description="Image file"/>
<Item Code="jpg" Description="Image file"/>
<Item Code="jpeg" Description="Image file"/>
<Item Code="bmp" Description="Image file"/>
<Item Code="css" Description="Style sheet"/>
<Item Code="js" Description="Javascript file"/>
<Item Code="htm" Description="Web page"/>
<Item Code="html" Description="Web page"/>
</Codes>
}

/// This is called by the projection method to find the XDATA blocks and build the persistent data from the items within these blocks
ClassMethod Populate() As %Status
{

	Do ..%DeleteExtent()
	
	Set reader = ##class(%XML.Reader).%New(),sc=$$$OK
	
	#; Open the compiled class definition for this class
	Set cc=##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1),0,.sc)
	If $$$ISERR(sc) Quit sc

	#; Find all the named XDATA blocks
	Set id=""
	For {
		Set index=cc.XDatas.GetNext(.id) Quit:id=""
		Set tTable=index.Name
		Set stream=index.Data
		Do stream.Rewind()	
		
		Do reader.OpenStream(stream)
		Do reader.Correlate(..#CorrelateOn,..%ClassName(1))
		
		#; Import Route objects
		Set counter=0
		While reader.Next(.obj,.sc)&&$$$ISOK(sc) {
			Set sc=obj.%Save()
			If $$$ISOK(sc) Set counter=counter+1
			If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc)
		}	
	}
	
	Quit sc
}

Storage Default
{
<Data name="NoResultsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^WebStress.Tables.NoResultsD</DataLocation>
<DefaultData>NoResultsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Tables.NoResultsD</IdLocation>
<IndexLocation>^WebStress.Tables.NoResultsI</IndexLocation>
<StreamLocation>^WebStress.Tables.NoResultsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
