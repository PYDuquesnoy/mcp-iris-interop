/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This persistent class represents a folder within the DeepSee User Portal.
/// Folders are used to group dashboards, saved pivots, and other user-defined elements.
Class %DeepSee.UserLibrary.Folder Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "folder";

Index name On (folder, name) [ Unique ];

/// Full name used for xml import/export.
Property %exportName As %String(MAXLEN = 32000, XMLNAME = "name", XMLPROJECTION = "attribute") [ Transient ];

/// Full-name (including parent folders) of the folder.
Property fullName As %String(MAXLEN = 32000, XMLPROJECTION = "none") [ Calculated, SqlComputeCode = {Set {fullName}=##class(%DeepSee.UserLibrary.Folder).%GetFullName({ID})}, SqlComputed, Transient ];

/// User-specified (local) name of the folder.
Property name As %String(MAXLEN = 255, XMLPROJECTION = "none");

/// Parent folder this item belongs to, if any.
Relationship folder As %DeepSee.UserLibrary.Folder [ Cardinality = one, Inverse = items ];

/// Subfolders within this folder, if any.
Relationship items As %DeepSee.UserLibrary.Folder [ Cardinality = many, Inverse = folder ];

/// Default resource applied to items within this folder.
/// Any items within this folder that do not supply a resource will use this value.
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Compute the full name of this folder.
ClassMethod %GetFullName(pID As %String) As %String [ Internal ]
{
	Set tFullName = ..nameGetStored(pID)
	Set tFolder = ..folderGetStored(pID)
	If (tFolder'="") {
		Set tFullName = ..%GetFullName(tFolder) _ "/" _ tFullName
	}
	Quit tFullName
}

/// Get the resource value for this folder.
/// Also return the name of the folder that defines the resource.
Method %GetResource(Output pOrigin As %String) As %String
{
	; avoid compiler issues
	New %ISCCountErrors

	Set pOrigin = ""
	If (..resource'="") {
		Set pOrigin = ..fullName
		Quit ..resource
	}
	ElseIf ((..folderGetObjectId()'="") && $IsObject(..folder)) {
		Quit ..folder.%GetResource(.pOrigin)
	}
	Quit ""
}

/// Folder is being deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tID = $$$oidPrimary(oid)
	Set tFullName = ..%GetFullName(tID)

	// delete everything that refers to this folder
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderContents(tFullName)
	Quit tSC
}

Storage Default
{
<Data name="FolderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>folder</Value>
</Value>
<Value name="4">
<Value>resource</Value>
</Value>
</Data>
<DataLocation>^DeepSee.FolderD</DataLocation>
<DefaultData>FolderDefaultData</DefaultData>
<IdLocation>^DeepSee.FolderD</IdLocation>
<IndexLocation>^DeepSee.FolderI</IndexLocation>
<StreamLocation>^DeepSee.FolderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
