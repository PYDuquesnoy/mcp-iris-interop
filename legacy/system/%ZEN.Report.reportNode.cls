/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for elements within a ZEN XML Report definition.
Class %ZEN.Report.reportNode Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Deprecated, Inheritance = right, System = 3 ]
{

/// XML namespace used for Zen Report definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/definition";

Parameter XMLIGNORENULL = 1;

/// By setting this to 0, we disallow use of invalid attribute names in Zen Report XML documents.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// If XMLFORMAT="Literal", then only support for literal format import and export is generated.<br>
Parameter XMLFORMAT = "Literal";

/// Generate code for this node.
Method %GenerateCode(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pLevel As %Integer, xmlns As %String, xmlprefix As %String, sqlcache As %Boolean, pAggregateTag As %String, removeNulls As %Boolean, SetProcessWideRunTimeMode As %Boolean, pAggregatesIgnoreNLS As %Boolean) As %Status [ Internal ]
{
	Quit $$$OK
}

}
