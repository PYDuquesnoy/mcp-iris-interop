/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25iKnow.Model.listQuery">NLP Domains</a>.</p>
/// <p>Subclass of <class>%iKnow.Model.list</class> dedicated to represent lists for the 
/// SQL Lister. This class has its own set of properties representing the specific Lister
/// parameters of the SQL Lister and hence is easier to use than the generic list class.
/// Any &lt;parameter&gt; elements nested within this element will be overwritten with the values
/// specified for the corresponding shorthand attributes.</p>
/// <p>See also <class>%iKnow.Source.SQL.Lister</class> for more details on these Lister
/// Parameters.</p>
Class %iKnow.Model.listQuery Extends %iKnow.Model.list [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "query";

Property listerClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = "%iKnow.Source.SQL.Lister", ReadOnly ];

/// The query to run for retrieving sources to process.
Property sql As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// The column name selected by <property>query</property> containing the local reference to use for
/// constructing the external ID for a loaded source.
Property idField As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The column name selected by <property>query</property> containing the group name to use for
/// constructing the external ID for a loaded source.
Property groupField As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The column names selected by <property>query</property> containing the actual data to be indexed.
Property dataFields As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The column names selected by <property>query</property> containing any metadata values to be
/// stored with loaded sources.
Property metadataColumns As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// The names of the metadata fields positionally corresponding to the columns identified in
/// <property>metadataColumns</property>. If left empty, the column names in
/// <property>metadataColumns</property> are expected to correspond to metadata field names
/// themselves.
Property metadataFields As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

ClassMethod %OnBeforeApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.sql),1)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.idField),2)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.groupField),3)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.dataFields,1),4)")
	do %code.WriteLine(" do:(pObj.metadataColumns'="""") pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.metadataColumns,1),5)")
	do %code.WriteLine(" do:(pObj.metadataFields'="""") pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.metadataFields,1),6)")
}

}
