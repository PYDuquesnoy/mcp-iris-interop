/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This abstract class represents an item within a DeepSee folder.<br/>
Class %DeepSee.UserLibrary.FolderItem Extends (%Persistent, %XML.Adaptor, %CSP.Portal.AbstractPortalModel) [ Abstract, System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLIGNORENULL = 1;

/// This is the extension returned by this type from the Finder.
Parameter ITEMTYPE As STRING;

/// If true, then items of this type (class) are displayed in the user portal table.
Parameter LISTED As BOOLEAN = 1;

/// Default value of public property for the class.
Parameter PUBLIC As BOOLEAN = 1;

/// URL of icon for this item
Parameter ICON As STRING = "portal/window_24.png";

/// URL of large icon for this item
Parameter LARGEICON As STRING = "portal/pie_chart_48.gif";

Index key On (folder, name);

/// Name of this item.
Property name As %String(MAXLEN = 255, XMLPROJECTION = "attribute") [ Required ];

/// Folder this item belongs to.
Property folder As %DeepSee.UserLibrary.Folder(XMLPROJECTION = "none") [ ReadOnly ];

/// Full name of the folder this item belongs to.
Property folderName As %String(MAXLEN = 255, XMLPROJECTION = "attribute") [ SqlComputeCode = {Set {folderName}=##class(%DeepSee.UserLibrary.Folder).%GetFullName({folder})}, SqlComputed, Transient ];

/// Full name of this item (including folder and type extension).
Property fullName As %String(MAXLEN = 32000, XMLPROJECTION = "none") [ Calculated, SqlComputeCode = {Set {fullName}=##class(%DeepSee.UserLibrary.Folder).%GetFullName({folder}), {fullName}={fullName}_$S({fullName}="":"",1:"/")_{name}, {fullName}={fullName}_$S({fullName}=""||($$$comMemberKeyGet($P({x__classname},"~",2),$$$cCLASSparameter,"ITEMTYPE",$$$cPARAMdefault)=""):"", 1:"."_$$$comMemberKeyGet($P({x__classname},"~",2),$$$cCLASSparameter,"ITEMTYPE",$$$cPARAMdefault))}, SqlComputed, Transient ];

/// Name of this item used in document import/export and source control (including folder and type extension plus .DFI).
Property documentName As %String(MAXLEN = 32000, XMLPROJECTION = "none") [ Calculated, ReadOnly, SqlComputeCode = {Set {documentName}=##class(%DeepSee.UserLibrary.Folder).%GetFullName({folder}), {documentName}={documentName}_$S({documentName}="":"",1:"-")_{name}, {documentName}={documentName}_$S({documentName}=""||($$$comMemberKeyGet($P({x__classname},"~",2),$$$cCLASSparameter,"ITEMTYPE",$$$cPARAMdefault)=""):"", 1:"."_$$$comMemberKeyGet($P({x__classname},"~",2),$$$cCLASSparameter,"ITEMTYPE",$$$cPARAMdefault)_".DFI")}, SqlComputed, Transient ];

/// Option title displayed for this item.
Property title As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Optional description for this item.
Property description As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Csv-list of keywords associated with the item.
Property keywords As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// User name of the owner of this item.
Property owner As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// If true, then anyone with permission can view this item, otherwise only the owner can view this item.
Property shared As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// If true, this this item is listed in the user portal (if the user has permission to see it).
Property public As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = {..#PUBLIC}, SqlFieldName = ispublic ];

/// If true, then users are not allowed to save modifications to this item without first unlocking it.
Property locked As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// The resource needed to view or edit this item:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view this item.<br/>
/// If defined and the current user holds the WRITE privilege on this resource, then
/// the user may modify this item.<br/>
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Time that this item was originally created.
Property timeCreated As %TimeStamp(XMLPROJECTION = "attribute") [ InitialExpression = {$ZDT($ZTS,3,,3)} ];

/// Time that this item was last saved.
Property timeModified As %TimeStamp(XMLPROJECTION = "none");

/// Name of the user that originally created this item.
Property createdBy As %String(MAXLEN = 255, XMLPROJECTION = "attribute") [ InitialExpression = {$UserName} ];

/// Category used by the book cover view of this item. 
Property category As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Specification string for the book cover associated with this folder item. 
Property bookCover As %String(MAXLEN = 20000, XMLPROJECTION = "attribute");

///  Time that this item was last accessed.
Property lastAccessed As %TimeStamp(XMLPROJECTION = "none");

/// Getter method for full name.
Method fullNameGet() As %String
{
	Set tFullName = ..folderName _ $S(..folderName="":"",1:"/") _ ..name
	Set:(..#ITEMTYPE'="")&&(tFullName'="") tFullName = tFullName _ "." _ ..#ITEMTYPE
	Quit tFullName
}

/// Setter method for full name.
Method fullNameSet(%val) As %Status
{
	Set tSC = ..%ParseFullName(%val,.tFolderName,.tName,.tExt)
	Set ..name = tName
	Set ..folderName = tFolderName
	Quit tSC
}

/// Getter method for document name that can be imported/exported
Method documentNameGet() As %String
{
	Quit $TR($TR(..fullName,"/","-"),"\","~")_".DFI" ; remove slashes because it makes %RoutineMgr think this is a CSP
}

ClassMethod fullNameFromDocumentName(pDocName As %String) As %String
{
	Quit $TR($TR($E(pDocName,1,*-4),"-","/"),"~","\") ; restore slashes that %RoutineMgr can't handle
}

/// Getter method for folder name.
Method folderNameGet() As %String
{
	New %objlasterror
	Set tFolderName = ""
	If ((..folderGetObjectId()'="")&&$IsObject(..folder)) {
		Set tFolderName = ..folder.fullName
	}
	Quit tFolderName
}

/// Setter method for folder name.
Method folderNameSet(%val As %String) As %Status
{
	Set tSC = $$$OK
	If (%val="") {
		Set r%folder = ""
	} Else {
		// find folder or create if it does not exist
		Set r%folder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(%val,1,.tSC)
	}
	Quit tSC
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Set ..timeModified = $ZDT($ZTS,3,,3)
	Quit $$$OK
}

/// Split the given full name for this item into its parts.
ClassMethod %ParseFullName(pFullName As %String, Output pFolderName As %String, Output pName As %String, Output pExtension As %String) As %Status
{
	Set pExtension = $S(pFullName[".":$P(pFullName,".",$L(pFullName,".")),1:"")
	Set:$L(pFullName,".")>1 pFullName = $P(pFullName,".",1,$L(pFullName,".")-1)
	Set pFolderName = $P(pFullName,"/",1,$L(pFullName,"/")-1)
	Set pName = $P(pFullName,"/",$L(pFullName,"/"))
	Quit $$$OK
}

/// Test if the current user has access to this item.
Method %CheckResource(pPrivilege As %String = "USE") As %Boolean
{
	// JMD1202: change default to "USE" (was "READ")
	New %objlasterror
	Set tAccess = 0
	Set tResource = ..%GetResource()
	If ((tResource="")||($System.Security.Check(tResource,pPrivilege))) {
		Set tAccess = 1
	}
	Quit tAccess
}

/// Get the resource value for this item.
/// Also return the name of the folder that defines the resource or "" if it originates here.
Method %GetResource(Output pOrigin As %String) As %String
{
	New %objlasterror
	Set pOrigin = ""
	Set tResource = ..resource
	If (tResource="") {
		// inherit from folder
		If ((..folderGetObjectId()'="")&&$IsObject(..folder)) {
			Set tResource = ..folder.%GetResource(.pOrigin)
		}
	}
	Quit tResource
}

/// Test if this item is visible to the user portal.
Method %IsVisibleToPortal() As %Boolean [ Internal ]
{
	If (+..#LISTED) {
		Quit 1
	}
	Quit 0
}

/// Return the URL for this item.
Method %GetURL() As %String
{
	Quit ""
}

/// Return the icon for this item.
Method %GetIcon() As %String
{
	Quit ..#ICON
}

/// Return the large icon for this item.
Method %GetLargeIcon() As %String
{
	Quit ..#LARGEICON
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit ""
}

/// Copy the contents of this definition to pivot table <var>pPivot</var>.
Method %CopyToComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Quit $$$ERROR($$$GeneralError,"This item cannot be used as a pivot data source.")
}

/// Set the contents of this definition from pivot table <var>pPivot</var>.
Method %CopyFromComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Quit $$$ERROR($$$GeneralError,"This item cannot be used as a pivot data source.")
}

/// Return a list of all other folder items (including cubes or kpis) that this item depends upon.
/// Returns a list of the form:<br/>
/// pList(itemName) = ""<br/>
/// This is extended by subclasses.
Method %GetDependencies(pList As %String) As %Status
{
	Quit $$$OK
}

/// Diagnostic method: display contents of this folder item to the console.
/// This can be extended by subclasses.
Method %Dump() As %Status
{
	Write "--------------------------------------------------------------",!
	Write "Folder item:",?25,##this,!
	Write "Name:",?25,..name,!
	Write "Title:",?25,..title,!
	Write "Created by:",?25,..createdBy,!
	Write "Time Created:",?25,..timeCreated,!
	Write "Time Modified:",?25,..timeModified,!
	Write "Owner:",?25,..owner,!
	Write "Resource:",?25,..resource,!

	Quit $$$OK
}

/// Notification that this item has just been imported.
Method %OnAfterImport(pNewName As %String) As %Status
{
	Quit $$$OK
}

/// Return the book cover spec for this folder item.
Method %GetCoverSpec() As %String
{
	Set tSpec = ..bookCover
	If (tSpec="") {
		// create a default cover
		Set tTypeName = "$type"
		Set tIcon = ..%GetLargeIcon()
		Set tName = "$title"
		Set tOwner = "$owner"
		Set:tOwner'="" tOwner = ##class(%DeepSee.UserPortal.Utils).%GetUserName(tOwner)
		Set tBackground = "white"

		Set tSpec = "{background: {style:'background:"_tBackground_";'},header: {text:'"_tTypeName_"'},footer: {text:'"_tOwner_"'},title: {text:'"_tName_"'},image: {src:'"_tIcon_"',imageStyle:'width:64px;height:64px;'}}"
	}
	Quit tSpec
}

Storage Default
{
<Data name="FolderItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>folder</Value>
</Value>
<Value name="3">
<Value>name</Value>
</Value>
<Value name="4">
<Value>keywords</Value>
</Value>
<Value name="5">
<Value>owner</Value>
</Value>
<Value name="6">
<Value>shared</Value>
</Value>
<Value name="7">
<Value>resource</Value>
</Value>
<Value name="8">
<Value>timeCreated</Value>
</Value>
<Value name="9">
<Value>timeModified</Value>
</Value>
<Value name="10">
<Value>dummy</Value>
</Value>
<Value name="11">
<Value>description</Value>
</Value>
<Value name="12">
<Value>title</Value>
</Value>
<Value name="13">
<Value>locked</Value>
</Value>
<Value name="14">
<Value>public</Value>
</Value>
<Value name="15">
<Value>createdBy</Value>
</Value>
<Value name="16">
<Value>bookCover</Value>
</Value>
<Value name="17">
<Value>category</Value>
</Value>
<Value name="18">
<Value>lastAccessed</Value>
</Value>
</Data>
<DataLocation>^DeepSee.FolderItemD</DataLocation>
<DefaultData>FolderItemDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^DeepSee.FolderItemD</IdLocation>
<IndexLocation>^DeepSee.FolderItemI</IndexLocation>
<StreamLocation>^DeepSee.FolderItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
