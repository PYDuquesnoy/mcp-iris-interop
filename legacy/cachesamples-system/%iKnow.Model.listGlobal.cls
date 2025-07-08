/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Subclass of <class>%iKnow.Model.list</class> dedicated to represent lists for the 
/// Global Lister. This class has its own set of properties representing the specific Lister
/// paramaters of the Global Lister and hence is more easy to use than the generic list class.
/// Any &lt;parameter&gt; elements nested within this element will be overwritten with the values
/// specified for the corresponding shorthand attributes.</p>
/// <p>See also <class>%iKnow.Source.Global.Lister</class> for more details on these Lister
/// Parameters.</p>
Class %iKnow.Model.listGlobal Extends %iKnow.Model.list [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "global";

Property listerClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = "%iKnow.Source.Global.Lister", ReadOnly ];

/// The global containing the data to be indexed.
Property globalReference As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The subscript to start from (default "")
Property beginSubscript As %String(MAXLEN = 250);

/// End subscript (default "")
Property endSubscript As %String(MAXLEN = 250);

/// If set, this COS expression is called using xecute command for every node visited by the
/// Global Lister. If it returns false, the node is skipped.
Property filterCondition As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// How the textual data in the global nodes between <property>beginSubscript</property> and
/// <property>endSubscript</property> is stored. Either of the following:
/// <ul>
/// 	<li>0 - single node (default)</li>
/// 	<li>1 - top node has count with subnodes 1..n having data</li>
/// 	<li>2 - top node has metadata, subnodes 1..n have data</li>
/// </ul>
Property globalType As %Integer(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Separator to add between nodes if <property>globalType</property> is 1 or 2. Defaults to "".
Property separator As %String(MAXLEN = 50, XMLPROJECTION = "attribute");

/// For <property>globalType</property> = 2 only, a comma-separated list of metadata fields stored in the top node.
Property metadataFields As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

ClassMethod %OnBeforeApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine(" set tNull = ##class(%iKnow.Model.parameter).%CreateNull()")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.globalReference),1)")
	do %code.WriteLine(" do pObj.parameters.SetAt($s((pObj.beginSubscript=""""):tNull, 1:##class(%iKnow.Model.parameter).%Create(pObj.beginSubscript)),2)")
	do %code.WriteLine(" do pObj.parameters.SetAt($s((pObj.endSubscript=""""):tNull, 1:##class(%iKnow.Model.parameter).%Create(pObj.endSubscript)),3)")
	do %code.WriteLine(" do pObj.parameters.SetAt($s((pObj.filterCondition=""""):tNull, 1:##class(%iKnow.Model.parameter).%Create(pObj.filterCondition)),4)")
	
	do %code.WriteLine(" set:'$isobject(pObj.processor) pObj.processor = ##class(%iKnow.Model.processor).%New()")
	do %code.WriteLine(" do:0'=+pObj.globalType pObj.processor.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.globalType),1)")
	do %code.WriteLine(" do:""""'=pObj.separator pObj.processor.parameters.SetAt($s((pObj.separator=""""):tNull, 1:##class(%iKnow.Model.parameter).%Create(pObj.separator)),2)")
	do %code.WriteLine(" do:""""'=pObj.metadataFields pObj.processor.parameters.SetAt($s((pObj.metadataFields=""""):tNull, 1:##class(%iKnow.Model.parameter).%Create(pObj.metadataFields,1)),3)")
}

}
