/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a page within a Zen application.<br>
/// User pages within a Zen application are derived from this class.<br>
/// A page class defines and serves the contents of a Zen page. 
/// The contents of the page are defined by a set of Zen components contained
/// by the page object. This set of components is typically defined
/// within an XData block named <var>Contents</var>. It is also possible
/// to define or modify this set of components by overriding the <method>%OnAfterCreatePage</method>
/// callback method.<br>
/// There are a number of class parameters that a page class can use to control
/// the behavior of the page. These include:
/// <ul>
/// <li>APPLICATION - the name of the <class>%ZEN.application</class> class the page belongs to.</li>
/// <li>RESOURCE - a resource for which the current user must hold USE privileges in order to use this page.</li>
/// <li>PAGENAME - a logical name used to refer to the page.</li>
/// <li>DOMAIN - the localization domain used to localize text within the page.</li>
/// <li>JSINCLUDES - a comma-separated list of additional JavaScript include files the page should include.</li>
/// <li>CSSINCLUDES - a comma-separated list of additional CSS style files the page should include.</li>
/// <li>CSS3INCLUDES - a comma-separated list of additional CSS3 style files the page should include.</li>
/// </ul>
/// There are a number of server-side callback methods that a page class can
/// override to control the behavior of the page. (See <class>%ZEN.Component.abstractPage</class>.) These include:
/// <ul>
/// <li><method>%OnBeforeCreatePage</method> - called before page model is created.</li>
/// <li><method>%OnCreatePage</method> - called after page object is created but before page model is created.</li>
/// <li><method>%OnAfterCreatePage</method> - called after page model is created.</li>
/// <li><method>%OnDrawHTMLHead</method> - called when the HTML head section is rendered.</li>
/// <li><method>%OnDrawHTMLBody</method> - called when the HTML body section is rendered.</li>
/// </ul>
/// This class also provided the definition of the client-side <var>zenPage</var> object
/// that represents the client-side version of the page object.
Class %ZEN.Component.page Extends abstractPage [ Deprecated, System = 3 ]
{

/// Validate user pages
Parameter VALIDATEXML = 0;

/// User pages do not have an XML representation
Parameter XMLINCLUDEINGROUP = 0;

/// Internal parameter.
/// There is nothing to queue up for page classes.
Parameter POSTCOMPILEACTIONS;

/// Reset XMLNAME parameter.
Parameter XMLNAME;

/// Suppress normal XML meta data
Parameter XMLNOMETADATA [ Internal ] = 1;

/// Local override.
/// Suppress normal XML meta data.
ClassMethod %XMLGenerate() [ CodeMode = generator, Internal ]
{
	Set ^oddCOM(%class,$$$cCLASSxmldata,"m")=0
}

/// Local override.
Method XMLImport(top As %String, format As %String, namespace As %String, handler As %XML.Document, node As %Integer, ByRef idlist) As %Status [ Internal, ProcedureBlock = 0 ]
{
	Quit ##super(top,format,namespace,handler,node,.idlist)
}

/// Local override.
Method XMLImportInternal() As %Status [ Internal, ProcedureBlock = 0 ]
{
	Quit ##super()
}

/// Local override.
Method XMLImportAttributes() As %Status [ Internal, Private, ProcedureBlock = 0 ]
{
	Quit ##super()
}

/// Local override.
Method XMLExport(top As %String = "", format As %String = "", namespaces As %XML.Namespaces = "", attrs = "", createId As %String = "", typeAttr As %String = "", ByRef oreflist, ByRef idlist, initialIndent As %String = "", local As %Boolean = 0) As %Status [ ProcedureBlock = 0 ]
{
 	Quit ##super(top,format,namespaces,attrs,createId,typeAttr,.orefList,.idList,initialIndent,local)
}

/// Local override.
Method XMLExportInternal() As %Status [ Internal, ProcedureBlock = 0 ]
{
	Quit ##super()
}

/// Local override.
Method XMLExportToString(ByRef export As %String, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status
{
	Quit ##super(.export,top,format,namespaces,attrs,createId,typeAttr,.oreflist,.idlist,initialIndent)
}

/// Local override.
Method XMLExportToStream(ByRef export As %Stream.Object, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status
{
	Quit ##super(.export,top,format,namespaces,attrs,createId,typeAttr,.oreflist,.idlist,initialIndent)
}

/// Local override.
ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status
{
	Quit ##super(.top,.format,.input,.dtdlist)
}

/// Local override.
ClassMethod XMLSchema(top As %String, format As %String, namespacePrefix As %String = "", input As %Boolean, refOnly As %Boolean, ByRef schema) As %Status
{
	Quit ##super(.top,.format,.namespacePrefix,.input,.refOnly,.schemas)
}

/// Local override.
ClassMethod XMLGetSchemaImports(ByRef imports, ByRef classes) As %Status [ Internal ]
{
	Quit ##super(.imports,.classes)
}

Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, ByRef pURIList, pCollection As %String, pLevel As %Integer = 1, pMode As %String = "page", pKey As %String = "", pParentVar As %String = "unknown") [ Final, Internal ]
{
	Do ##super(pCode,pLocalize,.pURIList,pCollection,pLevel,pMode,pKey,pParentVar)
}

Method %AddComponent(pComponent As %ZEN.Component.object) As %Status [ Final ]
{
	Quit ##super(pComponent)
}

Method %RemoveComponent(pComponent As %ZEN.Component.object) As %Status [ Final ]
{
	Quit ##super(pComponent)
}

Method %AddImportedComponents(pImportList As %String) As %Status [ Final ]
{
	Quit ##super(pImportList)
}

Method %ReallyAddChild(pComponent As %ZEN.Component.object, pSibling As %ZEN.Component.object = "", pBefore As %Boolean = 0) As %Status [ Final, Internal, PlaceAfter = %AddChild ]
{
	Quit ##super(pComponent,pSibling,pBefore)
}

Method %LayoutChildren(pTuple As %Integer = "") [ Final, Private ]
{
	Do ##super(pTuple)
}

/// Remove child component <var>pComponent</var> from this group.
/// Returns true if the component was found and removed.
Method %RemoveChild(pComponent As %ZEN.Component.object) As %Boolean
{
	Quit ##super(pComponent)
}

/// Remove all children from this group.
Method %RemoveChildren(pDynamicOnly As %Boolean = 0) [ Final ]
{
	Do ##super(pDynamicOnly)
}

Method %GetChildIndex(pChild As %ZEN.Component.component) As %Integer
{
	Quit ##super(pChild)
}

Method ReallyRefreshContents() [ Final, Internal, ZenMethod ]
{
	Do ##super()
}

/// Local override.
Method %DrawJSResources() As %Status [ Final, Private ]
{
 	Quit ##super()
}

/// Local override.
Method %GetJSResources(ByRef pResources As %String) As %Status [ Final, Private ]
{
 	Quit ##super(.pResources)
}

}
