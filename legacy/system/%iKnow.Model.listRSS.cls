/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Subclass of <class>%iKnow.Model.list</class> dedicated to represent lists for the 
/// RSS Lister. This class has its own set of properties representing the specific Lister
/// paramaters of the RSS Lister and hence is more easy to use than the generic list class.
/// Any &lt;parameter&gt; elements nested within this element will be overwritten with the values
/// specified for the corresponding shorthand attributes.</p>
/// <p>See also <class>%iKnow.Source.RSS.Lister</class> for more details on these Lister
/// Parameters.</p>
Class %iKnow.Model.listRSS Extends %iKnow.Model.list [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "rss";

Property listerClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = "%iKnow.Source.RSS.Lister", ReadOnly ];

/// Name of the server the RSS is hosted on, for example "feeds.bbci.co.uk"
Property serverName As %String(MAXLEN = 250, XMLPROJECTION = "ATTRIBUTE");

/// URL of the RSS XML on the server, for example "/news/world/rss.xml"
Property url As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

/// Which RSS item elements to use as the text body for this source. Defaults to "description",
/// but combinations such as "title,description" or "description,content:encoded" are convenient
/// alternatives.
Property textElements As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

ClassMethod %OnBeforeApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.serverName),1)")
	do %code.WriteLine(" do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.url),2)")
	do %code.WriteLine(" if (pObj.textElements'="""") {")
	do %code.WriteLine("  do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%CreateNull(),3)")
	do %code.WriteLine("  do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%CreateNull(),4)")
	do %code.WriteLine("  do pObj.parameters.SetAt(##class(%iKnow.Model.parameter).%Create(pObj.textElements),5)")
	do %code.WriteLine(" }")
}

}
