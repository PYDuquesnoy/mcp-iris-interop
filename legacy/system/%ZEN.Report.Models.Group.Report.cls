/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Models.Group.Report Extends (%RegisteredObject, %XML.Adaptor) [ Deprecated, Inheritance = right, System = 4 ]
{

Parameter XMLNAME = "report";

/// document element
Property document As Document(XMLPROJECTION = "element");

/// (optional) Name of the class containing the class query that will
/// be used to create a <class>%ResultSet</class> object.<br>
/// This property is only used if <property>queryName<property> is defined.
/// If this property is not defined, then it is assumed that the current report
/// class contains the specified query.
Property queryClass As %ZEN.Datatype.className;

/// (optional) Name of the class query that will
/// be used to create a <class>%ResultSet</class> object.
Property queryName As %ZEN.Datatype.classMember(MEMBERTYPE = "QUERY");

/// (optional) SQL statement that, if present, will be used to 
/// create a <class>%ResultSet</class> object.<br>
/// If defined, this takes precedence over 
/// <property>queryClass</property> and <property>queryName</property>.
Property sql As %ZEN.Datatype.sql;

/// Optional description for this report.
Property description As %String(MAXLEN = 5000, XMLPROJECTION = "attribute");

/// name of ZEN Report class
Property className As %String(XMLNAME = "class-name", XMLPROJECTION = "attribute");

/// name of ZEN Report
Property name As %String(XMLNAME = "name", XMLPROJECTION = "attribute");

/// Set of groups within this report.
Property groups As list Of Group(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

ClassMethod ImportFile(filename As %String) As Report
{
	Set reader = ##class(%XML.Reader).%New()
	Do reader.OpenFile(filename)
	Do reader.Correlate("report","%ZEN.Report.Models.Group.Report")
	while (reader.Next(.report,.status)) {
		Write "report name="_report.name
		quit  ; only one report
	}
	If $system.Status.IsError(status) do $System.Status.DisplayError(status)
	quit report
}

}
