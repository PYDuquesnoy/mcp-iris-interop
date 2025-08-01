/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Table that maps to the internal Studio open dialog data so additional filtering can be done via SQL
Class %Studio.OpenDialogItems Extends %Persistent [ Owner = {%Developer}, StorageStrategy = Storage, System = 4 ]
{

/// True if this is a document that can be opened, and false if it is a directory
Property IsDoc As %Boolean;

/// Value use to make sure the table collates in the order the user specified
Property Coll As %RawString;

/// Name of the item to display, this could just be the classname without the package qualifier
Property Name As %String(MAXLEN = 256);

/// The type of the item which can be one of:<ul>
/// <li>0  - MAC file, a routine containing macros</li>
/// <li>1  - INT file, a standard routine</li>
/// <li>2  - INC file, an include file</li>
/// <li>3  - BAS file, a Cache Basic routine</li>
/// <li>4  - CLS, a class</li>
/// <li>5  - CSP, a Cache Server Page or another file in this directory</li>
/// <li>7  - GBL, a Global</li>
/// <li>8  - PRJ, a Project</li>
/// <li>9  - a Package</li>
/// <li>10 - a CSP application</li>
/// <li>11 - MVB file, a MultiValue Basic macro routine</li>
/// <li>12 - MVI file, a MultiValue Basic routine</li>
/// <li>13 - OBJ, object code</li>
/// </ul>Further numbers are reserved for future use.
Property Type As %Integer;

/// Size of this item in characters
Property Characters As %Integer;

/// Date/time this item was last modified
Property Modified As %TimeStamp;

/// Brief description of the document
Property Description As %String(MAXLEN = 1024);

/// Internal use only
Property DirectoryChar As %String(MAXLEN = 1);

/// True if the document is generated by another document
Property Generated As %Boolean [ Calculated, SqlComputeCode = {	Set {Generated}=##class(%RoutineMgr).IsGenerated(^||%RoutineList(%INDEX)_{Name})}, SqlComputed ];

/// The full name of the document including any package information
Property FullName As %String(MAXLEN = 256) [ Calculated, SqlComputeCode = { Set {FullName}=^||%RoutineList(%INDEX)_{Name}}, SqlComputed ];

/// True if the document is server only
Property ServerOnly As %Boolean [ Calculated, SqlComputeCode = { Set {ServerOnly}=##class(%RoutineMgr).IsServerOnly({FullName}) }, SqlComputed ];

/// True if the document is not from the default routines database for this namespace
Property Mapped As %Boolean [ Calculated, SqlComputeCode = { Set {Mapped}=##class(%RoutineMgr).IsMapped({FullName}) }, SqlComputed ];

Index IDKEY On (IsDoc, Coll) [ IdKey, Unique ];

Storage Storage
{
<Data name="Node">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>DirectoryChar</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Characters</Value>
</Value>
<Value name="5">
<Value>Modified</Value>
</Value>
<Value name="6">
<Value>Description</Value>
</Value>
<Value name="7">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^||%RoutineList(%INDEX)</DataLocation>
<DefaultData>Node</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^||%RoutineList(%INDEX)</IdLocation>
<IndexLocation>^||%RoutineList(%INDEX)</IndexLocation>
<StreamLocation>^%Studio.OpenDialogItemsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
