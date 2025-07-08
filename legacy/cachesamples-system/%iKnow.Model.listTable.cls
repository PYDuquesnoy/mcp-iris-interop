/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Subclass of <class>%iKnow.Model.list</class> dedicated to represent lists for the 
/// SQL Lister, geared to one specific table/class.
/// This class has its own set of properties mapping to the specific Lister
/// paramaters of the SQL Lister and hence is more easy to use than the generic list class.
/// Any &lt;parameter&gt; elements nested within this element will be overwritten with the values
/// specified for the corresponding shorthand attributes.</p>
/// <p>See also <class>%iKnow.Source.SQL.Lister</class> for more details on these Lister
/// Parameters.</p>
Class %iKnow.Model.listTable Extends %iKnow.Model.list [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "table";

Property listerClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = "%iKnow.Source.SQL.Lister", ReadOnly ];

/// The table which contents should be indexed.
Property tableName As %String(MAXLEN = 500, XMLPROJECTION = "ATTRIBUTE");

/// An optional WHERE clause to filter the contents of table <property>tableName</property>
Property whereClause As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

/// The column in table <property>tableName</property> containing the local reference to use for
/// constructing the external ID for a loaded source.
Property idField As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The column in table <property>tableName</property> containing the group name to use for
/// constructing the external ID for a loaded source.
Property groupField As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The columns in table <property>tableName</property> containing the actual data to be indexed.
Property dataFields As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The columns in table <property>tableName</property> containing any metadata values to be
/// stored with loaded sources.
Property metadataColumns As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// The names of the metadata fields positionally corresponding to the columns identified in
/// <property>metadataColumns</property>. If left empty, the column names in
/// <property>metadataColumns</property> are expected to correspond to metadata field names
/// themselves.
Property metadataFields As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

ClassMethod %OnBeforeApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ CodeMode = objectgenerator, Internal ]
{
	/// BDB544: When building the query, we need to mark parts that are actual code (containing
	/// an expression), as they'll need to be re-separated when resolving the expression later on
	do %code.WriteLine(" #define WrapCode(%s) $s(##class(%iKnow.DomainDefinition).%IsProperCode(%s):%s, 1:$$$QUOTE(%s))")
	do %code.WriteLine(" if ..%IsExpression(pObj.idField)||..%IsExpression(pObj.groupField)||..%IsExpression(pObj.dataFields)||..%IsExpression(pObj.tableName)||..%IsExpression(pObj.metadataColumns)||..%IsExpression(pObj.whereClause) {")
	do %code.WriteLine("  set tQuery = """"""SELECT """"_""_ $$$WrapCode(pObj.idField)_""_"""" __idField, """"_""")
	do %code.WriteLine("  set tQuery = tQuery _ $$$WrapCode(pObj.groupField)_""_"""" __groupField, """"_""")
	do %code.WriteLine("  set tQuery = tQuery _ $$$WrapCode(pObj.dataFields)")
	do %code.WriteLine("  set:pObj.metadataColumns'="""" tQuery = tQuery _ ""_"""", """"_"" _ $$$WrapCode(pObj.metadataColumns)")
	do %code.WriteLine("  set tQuery = tQuery _ ""_"""" FROM """"_"" _ $$$WrapCode(pObj.tableName)")
	do %code.WriteLine("  set:pObj.whereClause'="""" tQuery = tQuery _ ""_"""" WHERE """"_"" _ $$$WrapCode(pObj.whereClause)")
	do %code.WriteLine(" } else {")
	do %code.WriteLine("  set tQuery = ""SELECT ""_pObj.idField_"" __idField, ""_pObj.groupField_"" __groupField, ""_pObj.dataFields")
	do %code.WriteLine("  set:pObj.metadataColumns'="""" tQuery = tQuery _ "", ""_pObj.metadataColumns")
	do %code.WriteLine("  set tQuery = tQuery _ "" FROM ""_pObj.tableName")
	do %code.WriteLine("  set:pObj.whereClause'="""" tQuery = tQuery _ "" WHERE ""_pObj.whereClause")
	do %code.WriteLine(" }")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(tQuery),1)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(""__idField""),2)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(""__groupField""),3)")
	do %code.WriteLine(" set tDF = $lfs(pObj.dataFields)")
	do %code.WriteLine(" for i=1:1:$ll(tDF) { set tAlias = $li(tDF,i), tPos = $f($$$UPPER(tAlias),"" AS ""), tAlias = $e(tAlias, tPos, *), tAlias=$p(tAlias,""->"",$l(tAlias,""->"")), $li(tDF,i) = $zstrip($translate(tAlias,""""""""),""<>W"") }")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create($lts(tDF),1),4)")
	do %code.WriteLine(" if (pObj.metadataColumns'="""") {")
	do %code.WriteLine("  set tMF = $lfs(pObj.metadataColumns)")
	do %code.WriteLine("  for i=1:1:$ll(tMF) {")
	do %code.WriteLine("   set tAlias = $zstrip($li(tMF,i),""<>W"")")
	do %code.WriteLine("   if ($e(tAlias,*)="""""""") { set tAlias = $p(tAlias,"""""""",*-1) }")
	do %code.WriteLine("   elseif $find(tAlias,"" "") { set tAlias = $p(tAlias,"" "",*) }")
	do %code.WriteLine("   elseif $find(tAlias,""->"") { set tAlias=$p(tAlias,""->"",*) }")
	do %code.WriteLine("   set $li(tMF,i) = $zstrip($translate(tAlias,""""""""),""<>W"")")
	do %code.WriteLine("  }")
	do %code.WriteLine("  do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create($lts(tMF),1),5)")
	do %code.WriteLine(" }")
	do %code.WriteLine(" do:(pObj.metadataFields'="""") pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.metadataFields,1),6)")
}

}
