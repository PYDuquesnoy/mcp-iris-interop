/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An Archive Content is an object of source or target of Archive operations (cf. <class>%Archive.Session</class>) <p>
/// Sample script that creates an Archive Content object for a (source) file or files to be archived:
/// <example>
///    Set ContentOref = ##class(%Archive.Content).%New() 
///    Set ContentOref.Name = "File" // description of the content 
///    Set ContentOref.RetentionSpec = 0 // a retention period or class name 
///    Set Status = ContentOref.AddSource(SourceFilePath1,"Test File 1") // path of the source file and a brief description ("tagname") 
///    // and if there are more files to store (as a single content) --
///    Set Status = ContentOref.AddSource(SourceFilePath2,"Test File 2") 
///    // and so on
/// </example>
/// Sample script that creates an Archive Content object for a file or files as the target of a retrieval:
/// <example>
///    Set ContentOref = ##class(%Archive.Content).%New() 
///    Set Status = ContentOref.DataSink.Insert(TargetFilePath1) 
///    // and if the content contains more than one file --
///    Set Status = ContentOref.DataSink.Insert(TargetFilePath2) 
///    // and so on
/// </example>
Class %Archive.Content Extends %RegisteredObject [ System = 4 ]
{

/// An optional, descriptive name for the content
Property Name As %String;

/// Either a retention period, specified as a number (consisting of only digits) in seconds, or a retention class name
Property RetentionSpec As %String;

/// Optional attributes of the content, in pairs of AttributeName and AttributeValue
Property Attribute As array Of %String;

/// for storing content to server <ul><li>
/// DataSource = DataSourceCount  </li><li>
/// DataSource(DataSourceID,"TagName") = TagName </li><li>
/// DataSource(DataSourceID,"Source") = Output source (file path, %Stream, etc.) </li></ul>
Property DataSource As %String [ MultiDimensional ];

/// a list of targets (file path, %Stream, etc.) for retrieving content from server
Property DataSink As list Of %String;

/// Specify a data source to export to server
Method AddSource(DataSource As %RegisteredObject, TagName As %String) As %Status
{
	If $i(i%DataSource)
	Set ..DataSource(i%DataSource,"Source") = DataSource
	Set ..DataSource(i%DataSource,"TagName") = TagName
	Quit $$$OK
}

}
