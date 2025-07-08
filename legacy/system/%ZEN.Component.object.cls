/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

IncludeGenerator %ZEN.Utils

///  Base class for all ZEN components.
///  An object, by itself, can be used to create objects that can
///  be shared between a server and a browser client environment.
///  All visual component, are derived from <class>component</class>, 
///  which is a subclass of <class>object</class>.
Class %ZEN.Component.object Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = %ZEN.Generator, DependsOn = %ZEN.Generator, Deprecated, PropertyClass = %ZEN.componentParameters, ServerOnly = 1, System = 3 ]
{

///  This is the XML namespace used for library components.
Parameter NAMESPACE = "http://www.intersystems.com/zen";

Parameter XMLIGNORENULL = 1;

///  If XMLFORMAT="Literal", then only support for literal format import and export is generated.<br>
Parameter XMLFORMAT = "Literal";

///  By setting this to 0, we disallow use of invalid attribute names in Zen XML documents.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

///  Subclasses can set this to change default visibilty for a component.
Parameter DEFAULTVISIBLE As BOOLEAN = 0;

///  CSV list of additional include files (either .js or .css) that
///  should be included when this component is used on a page.<br/>
///  By default, the file extension (.js or .css) is used to determine whether an
///  item in the list is a script include or a style include. You can override
///  this behavior by adding the terms "script:" or "style:" to the beginning of
///  the file name or names. This prefix is not used as part of the include filename.
Parameter INCLUDEFILES As STRING;

///  If set, this indicates that this system component should be
///  placed in the given "module". A module is a grouping of components
///  within the same class package that share common include (js or css) files.
///  Note that certain root classes are implicitly placed within the "core"
///  module.<br/>
///  Classes outside of the Zen library should not set this, they should use
///  the <parameter>MODULE</parameter> instead.
Parameter SYSMODULE As STRING [ Internal ];

///  If set, this indicates that this system component should be
///  placed in the given "module". A module is a grouping of components
///  within the same class package that share common include (js or css) files.
Parameter MODULE As STRING;

///  If true, then the include files generated for this component, are placed in the
///  common /csp/broker directory and not the local /csp/*namespace* directory.<br/>
///  This is intended for use with packages that are mapped so as to be visible to every namespace.<br/>
///  All Zen classes within the same package must have the same value for this parameter.
///  It is the developer's responsibility to ensure this.
Parameter USECOMMONDIRECTORY As BOOLEAN = 0;

///  This is a comma-delimited list of which post-compile actions this component
///  is registered for. If this value is defined, then certain actions are carried out
///  after this class is compiled.<br>
///  The available choices are:<br>
///  <ul>
///  <li>"schema" - update the schema used by Studio Assist when editing page definitions.</li>
///  <li>"HTML" - Regenerate any JS or CSS files associated with this class.</li>
///  <li>"SVG" - Regenerate any JS or SVG CSS files associated with this class.</li>
///  </ul>
Parameter POSTCOMPILEACTIONS As STRING = "schema,HTML";

///  This projection is used to keep track of when Zen components
///  are compiled.<br>
///  This is an internal value.
Projection ObjectProjection As %ZEN.ObjectProjection [ Internal ];

///  Link back to page that contains this component.<br>
///  Applications should not set this property.
Property %page As %ZEN.Component.page(XMLPROJECTION = "none") [ Final ];

///  Link to the component that contains this object
///  or somehow caused this component to be placed on the page.<br>
///  For visual components, this is typically set to the group
///  that contains the component.<br>
///  For auxiliary components, this is set to the object that
///  referred to this component in the page definition.<br>
///  Applications should not set this property.
Property parent As %ZEN.Component.object(XMLPROJECTION = "none", ZENSETTING = 0) [ Final ];

///  This is a client-only property that refers to the JavaScript
///  Window object on which this object was created.<br/>
///  Applications should not set this property.
Property window As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0) [ Final ];

///  For components that are created as part of a composite component,
///  this is a link to the composite that contains this object.
///  Applications should not set this property.
Property composite As %ZEN.Component.group(XMLPROJECTION = "none", ZENSETTING = 0) [ Final ];

///  Special property indicating which <i>tuple</i> of a
///  repeating group is rendering this component. This property
///  only has meaning when a component is part of a repeating group.
///  Applications should not set this property.
Property tuple As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Final ];

///  Server-side expression that determines if this component should be
///  added to the set of page components.<br>
///  This property is not available on the client.
Property %condition As %ZEN.Datatype.expression(XMLNAME = "condition");

///  Resource name that determines if this component should be
///  added to the set of page components. If specified, current user must
///  hold USE privilege on this resource or the component will not be added
///  to the set of page components.<br>
///  This property is not available on the client.
Property %resource As %ZEN.Datatype.resource(XMLNAME = "resource");

///  CSV list of additional component classes that this components
///  needs to have defined on the client.
///  Use this for cases where the client will need classes that are not
///  directly used in the original object tree.
///  This property is not available on the client.
Property %import As %ZEN.Datatype.string(MAXLEN = 1000, XMLNAME = "import");

///  CSV list of additional include files (either .js or .css) that
///  should be included when this component is used on a page.<br>
///  This property is not available on the client.
Property %includeFiles As %ZEN.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "none") [ InitialExpression = {..#INCLUDEFILES} ];

///  System-assigned index number used internally to identify this component.<br>
///  Applications can use but should not set this property.
Property index As %Integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Final ];

///  This is a unique identifier that is used to distinguish this object
///  from other objects within the same Zen page.<br/>
///  Every object within a Zen page must have a unique id value.
///  You can find an object with a given id value using the page object's
///  <method>getComponentById</method> method.<br>
Property id As %ZEN.Datatype.id [ Final ];

///  Name of this object.<br>
///  This is primarily used to specify the name used 
///  for identifying a control within a form. It is also used to identify
///  values that are submitted by controls on a form.<br/>
///  It is defined here for convenience.
Property name As %ZEN.Datatype.name [ Final ];

///  This is an auxiliary property that is provided
///  as a place to hold additional user-defined values for components.
///  This property is not used by the ZEN framework.
Property aux As %ZEN.Datatype.string [ Final ];

///  This property indicates whether a component is visible and thus layed out.
///  This is a class-wide property set by the object constructor.<br>
///  Applications should not set this property; Sub-classes can set this
///  via the <parameter>DEFAULTVISIBLE</parameter>.
Property visible As %Boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = {..#DEFAULTVISIBLE} ];

///  Internal property.<br>
///  This internal value is used to trigger a client-side
///  rendering of a component when it is modified on the server.
Property renderFlag As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Final, InitialExpression = 0, Internal ];

///  onupdate event handler:
///  This event is fired after the properties of the object
///  have been updated from the server.
Property onupdate As %ZEN.Datatype.eventHandler;

///  Defines the CSS style sheet used by an object/component.
XData Style
{
}

///  Defines SVG-specific CSS style sheet used by an object/component.
XData SVGStyle
{
}

///  Defines any SVG def elements used by an object/component.
XData SVGDef
{
}

///  Constructor for Zen objects.<br/>
///  If subclasses override %OnNew, they should make sure to
///  invoke this using #super.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; clear the shadow mod bits for this component
	#; to minimize changes during client/server synch.
	Do $System.CLS.SetSModified($this,0)
	Quit $$$OK
}

///  Internal method.<br>
///  This is used to fire the add-to-page callback method.
///  On return, <var>pNotify</var> will be true if this component
///  has an <method>%OnAddToPageAfter</method> method.
Method %OnAddToPage(Output pNotify As %Boolean) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = (%OnAddToPageAfter, %OnAddToPageBefore), Internal ]
{
	Do %code.WriteLine(" Set tSC = $$$OK")

	#; If we have an %OnAddToPageAfter method, add ourselves to the page's notification
	#; list so that the callback will get called
	If ('+$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnAddToPageAfter",$$$cMETHabstract)) {
		Do %code.WriteLine(" Set pNotify = 1")
	}
	Else {
		Do %code.WriteLine(" Set pNotify = 0")
	}

	#; invoke %OnAddToPageBefore callback for component:
	#; check if method is abstract
	If ('+$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnAddToPageBefore",$$$cMETHabstract)) {
		Do %code.WriteLine(" Set tSC = ..%OnAddToPageBefore()")
	}
	Do %code.WriteLine(" Quit tSC")

	Quit $$$OK
}

///  If implemented, this callback method is called at page render-time
///  when this component is added to a page but before any of its children
///  have been created.
Method %OnAddToPageBefore() As %Status [ Abstract ]
{
	Quit $$$OK
}

///  If implemented, this callback method is called at page render-time
///  after this component has been added to a page and after any of its children
///  have been created but before the %DrawHTML methods are called.
Method %OnAddToPageAfter() As %Status [ Abstract ]
{
	Quit $$$OK
}

///  Internal method.<br>
///  Write out HTML/CSS style sheet defined for this component.<br/>
///  <var>pLevel</var> indicates what level of CSS to render.
///  If level is 2 then the XData block, "Style", is used.
///  If level is 3 then the XData block, "CSS3Style", is used.
ClassMethod %DrawStyleHTML(pLevel As %Integer = 2) [ CodeMode = objectgenerator, Internal ]
{
	// test if there is a CSS3Style block declared in the current class
	Set tHasCSS3 = ##class(%ZEN.Generator).%DoesXDataExist("CSS3Style",1)
	If ('tHasCSS3) {
		#; use CSS2 for both cases
		Quit ##class(%ZEN.Generator).%GenerateStyleSheet("Style")
	}
	Else {
		#; use CSS3 or CSS2 depending on level
		Do %code.WriteLine(" If (+pLevel >= 3) {")
		Do ##class(%ZEN.Generator).%GenerateStyleSheet("CSS3Style")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Else {")
		Do ##class(%ZEN.Generator).%GenerateStyleSheet("Style")
		Do %code.WriteLine(" }")
	}
}

///  Internal method.<br>
///  Write out SVG/CSS style sheet defined for this component<br>
///  This is based on the XData block, SVGStyle.
ClassMethod %DrawStyleSVG() [ CodeMode = objectgenerator, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%GenerateStyleSheet("SVGStyle")
}

///  Internal method.<br>
///  Write out SVG Def elements defined for this component<br>
///  This is based on the XData block, SVGDef.
ClassMethod %DrawSVGDef() [ CodeMode = objectgenerator, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%GenerateStyleSheet("SVGDef")
}

///  Internal method.<br>
///  Draw enclosing div element and then draw contents within it.<br>
///  Implemented by subclass.
Method %DrawComponentHTML() [ Internal ]
{
	Do ..%DrawHTML()
}

///  Static HTML display method: draw the BODY of this component
///  as HTML.<br>
///  Subclasses implement this in order to render the static HTML
///  contents of a component.
Method %DrawHTML()
{
	#; Default-- modify renderFlag to force client-side event
	Set ..renderFlag = ..renderFlag + 1
}

///  Set handler for renderFlag property.
Method renderFlagSet(%val) As %Status [ Internal, Private ]
{
	#; add this component to the list of component that need client-side rendering
	If ($IsObject($G(%page)) && (..index'="")) {
		Set %page.%RenderList(..index) = ""
	}
	Set i%renderFlag = %val
	Quit $$$OK
}

///  This method is only needed for SVG components.
///  It is defined here so that we can detect if HTML components
///  are used within an SVG context and throw an error.
ClientMethod renderSVG(document, parent) [ Language = javascript ]
{
	// show error message
	alert('ZEN ERROR\nHTML Components cannot be used within an svgFrame:\nType: '+ this._type + '; index: ' + this.index + '; id: \'' + this.id + '\'');
}

///  Call this method to force the client to call this object's
///  <method>renderContents</method> if it has one.
Method %ForceClientRender() [ Final ]
{
	Set ..renderFlag = ..renderFlag + 1
}

///  Utility method used when writing out HTML attribute values.
///  Given an attribute name and value, this returns the string
///  attr=""value"" with value HTML escaped. If value is "", then ""
///  is returned.
Method %Attr(pName As %String, pValue As %String) As %String [ CodeMode = expression, Final ]
{
$S(pValue="":"",1:pName_"="""_$ZCVT($$$ZENVAL(pValue),"O","HTML")_"""")
}

///  Utility method; takes a property value containing a #()# expression
///  and evaluates it. This is called by the $$$ZENVAL macro.
Method %Eval(pExpr As %String, pEscape As %String = "") As %String
{
	New %out
	#; set up context
	X "S %out="_##class(%ZEN.Utils).%ParseExpr(pExpr,pEscape) 
	Quit %out
}

ClassMethod %EvalC(pExpr As %String, pEscape As %String = "") As %String
{
	New %out
	#; set up context
	X "S %out="_##class(%ZEN.Utils).%ParseExpr(pExpr,pEscape) 
	Quit %out
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject
{
	#; not supported by ZEN classes
	Quit ""
}

Method %NormalizeObject() As %Status
{
	#; not needed; ZEN objects are never persisted
	Quit $$$OK
}

Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0, norecurseon As %String = "") As %Status
{
	#; not needed; ZEN objects are never persisted
	Quit $$$OK
}

Method %RemoveFromSaveSet() As %Status
{
	#; not needed; ZEN objects are never persisted
	Quit $$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status
{
	#; not needed; ZEN objects are never persisted
	Quit $$$OK
}

Method %BindExport(dev As %String, ByRef Seen As %String, RegisterOref As %Boolean, AllowedDepth As %Integer, AllowedCapacity As %Integer) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

Method XMLExport(top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String, local As %Boolean) As %Status
{
	#; not needed;
	Quit $$$ERROR($$$NotImplemented)
}

Method XMLExportToString(ByRef export As %String, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status
{
	#; not needed;
	Quit $$$ERROR($$$NotImplemented)
}

Method XMLExportToStream(ByRef export As %Stream.Object, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status
{
	#; not needed;
	Quit $$$ERROR($$$NotImplemented)
}

///  Internal method.<br/>
///  Construct a list of component super classes of this class 
///  as csv list (include this class as well).<br>
///  This is used at page render-time to build the list of classes
///  needed by the client page.
ClassMethod %GetSuperClassList(ByRef pList) As %String [ CodeMode = objectgenerator, Final, Internal ]
{
	#; Make sure list is built in root-to-subclass order
	Set super = %class.Name
	Set tList = ""
	While ((super '= "") && ($P(super,".",1) '= "%Library")) {
		Set tList = $$$NormalizeClassname(super) _ $S(tList="":"",1:",") _ tList
		Set super = $piece($$$comClassKeyGet(super,$$$cCLASSsuper),",")
	}

	Do %code.WriteLine(" Quit """_tList_"""")

	Quit $$$OK
}

///  Internal method.<br/>
///  Returns information about the generated include files for this class.<br/>
///  <var>pModules</var> <br/>
///  <var>pHasJS</var> indicates that a JS file needs to be generated.<br/>
///  <var>pCSSType</var> indicate the type of CSS needed, if any.<br/>
///  This takes one of the following values:<br/>
///  "HTML" - HTML CSS<br/>
///  "SVG" - SVG CSS<br/>
///  "" - No style sheet is defined for this class.<br/>
///  <var>pInline</var> is set true if this component's style and js should be written
///  inline as part of a page.
ClassMethod %GetIncludeInfo(ByRef pModules As %String, Output pHasJS As %Boolean, Output pCSSType As %String, Output pInline As %Boolean) [ CodeMode = objectgenerator, Final, Internal ]
{
	// return information in the form:
	// pModules(pPackage,pModule) = $LB(depth,classname)
	// This information is cumulative.

	Set tSysMod = $G(%parameter("SYSMODULE"))
	Set tUserMod = $G(%parameter("MODULE"))
	Set tPackage = $P(%class.Name,".",1,$L(%class.Name,".")-1)
	Set tIsZen = %class.Name["%ZEN."
	Set tInline = 0

	If (tIsZen && (tUserMod '= "")) {
		Quit $$$ERROR($$$GeneralError,"ZEN library class should not set MODULE parameter")
	}

	// Apply implicit module mappings
	Set tClassName = ""
	If ((%class.Name = "%ZEN.Component.object")||(%class.Name = "%ZEN.Component.component")) {
		Set tModName = "ZEN_Component__core"
	}
	ElseIf ('tIsZen && (tUserMod '= "")) {
		Set tModName = $TR(tPackage,".%","_") _ "__" _tUserMod
	}
	ElseIf(tIsZen && (tSysMod '= "")) {
		Set tModName = $TR(tPackage,".%","_") _ "__" _tSysMod
	}
	ElseIf (%class.Name [ "%ZEN.Auxiliary") {
		Set tModName = "ZEN_Auxiliary"
	}
	ElseIf (%class.Name [ "%ZEN.SVGComponent") {
		Set tModName = "ZEN_SVGComponent"
	}
	ElseIf ('tIsZen) {
		// User class uses package as module by default
		Set tModName = $TR(tPackage,".%","_")
	}
	Else {
		// This system class is in its own module
		Set tClassName = %class.Name
		Set tModName = $TR(%class.Name,".%","_")
	}

	// compute class depth: number of classes from here to root object class
	Set tIsPage = 0
	Set tDepth = 0
	Set tSuper = %class.Name
	While ((tSuper '= "") && (tSuper '= "%ZEN.Component.object")) {
		If ((tSuper = "%ZEN.Component.page")&&(%class.Name '= "%ZEN.Component.page")) {
			Set tIsPage = 1
		}
		Set tDepth = tDepth + 1
		Set tSuper = $P($$$comClassKeyGet(tSuper,$$$cCLASSsuper),",")
	}

	Do %code.WriteLine(" Set pModules("_$$$quote(tPackage)_","_$$$quote(tModName)_") = $LB("_tDepth_","_$$$quote(tClassName)_")")

	// Now compute js and style type
	Set tType = "HTML"

	// special case for page class
	If (%class.Name = "%ZEN.Component.page") {
		Set tActions = "HTML"
	}
	Else {
		Set tActions = $G(%parameter("POSTCOMPILEACTIONS"))
	}

	If ((tActions [ "HTML")||(tActions [ "SVG")) {
		Set tHasJS = 1
	}
	Else {
		Set tHasJS = 0
	}

	If (tActions [ "SVG") {
		Set tType = "SVG"
	}
	// All classes in the auxiliary package are assumed to have no style.
	If ($P(%class.Name,".",1,2) = "%ZEN.Auxiliary") {
		Set tType = ""
	}

	Set tStyleBlock = ""
	If (tType = "HTML") {
		Set tStyleBlock = "Style"
	}
	ElseIf (tType = "SVG") {
		Set tStyleBlock = "SVGStyle"
	}

	If (tIsPage) {
		if (tUserMod = "") {
			Set tInline = 1
			Set tHasJS = 0
			Set tStyleBlock = ""
		}
	}

	// See if XData has any contents.
	If (tStyleBlock '= "") {
		If ##class(%Dictionary.XDataDefinition).%ExistsId(%class.Name_"||"_tStyleBlock) {
			Set tIndex = %class.XDatas.FindObjectId(%class.Name_"||"_tStyleBlock)
			Set tStream = %class.XDatas.GetAt(tIndex).Data
			If (tStream.Size = 0) {
				Set tType = ""
			}
		}
		Else {
			Set tType = ""
		}
	}

	// check for CSS3 style with no CSS style
	If ((tStyleBlock '= "")&&(tType="")) {
		Set tType = "HTML"
		If ##class(%Dictionary.XDataDefinition).%ExistsId(%class.Name_"||"_"CSS3Style") {
			Set tIndex = %class.XDatas.FindObjectId(%class.Name_"||"_"CSS3Style")
			Set tStream = %class.XDatas.GetAt(tIndex).Data
			If (tStream.Size = 0) {
				Set tType = ""
			}
		}
		Else {
			Set tType = ""
		}
	}

	Do %code.WriteLine(" Set pHasJS = " _ tHasJS)
	Do %code.WriteLine(" Set pCSSType = " _ $$$quote(tType))
	Do %code.WriteLine(" Set pInline = " _ tInline)

	// cache info for other methods
	Set ^||%Cls(%class.Name,"HasJS") = tHasJS
	Set ^||%Cls(%class.Name,"CSSType") = tType
	Set ^||%Cls(%class.Name,"Depth") = tDepth
	Set ^||%Cls(%class.Name,"Inline") = tInline
	Set ^||%Cls(%class.Name,"Module") = tModName
	Quit $$$OK
}

///  Internal method.<br/>
///  Return the list of include files needed by this component.<br/>
///  This is used to (1) generate include files for components, and (2)
///  determine which files need to be included by a page using this component.<br/>
///  On return, <var>%zenIncludeJS</var> and <var>%zenIncludeCSS</var> will contain the list of files in the form:<br/>
///  pFiles(depth,order,package,filename) = $LB(type,localdepth)<br/>
///  Where type can be "user" (not generated),
///  "js","html" (css), or "svg" (css).<br/>
///  If <var>pMode</var> is specified it indicates which kinds of files should be
///  served: "HTML" or "SVG" (for non-inline SVG).
ClassMethod %GetIncludeFiles(pMode As %String = "HTML") [ CodeMode = objectgenerator, Final, GenerateAfter = %GetIncludeInfo, Internal ]
{
	// return information in the form:
	// pFiles(depth,order,pkg,file) = $LB(type,localdepth)
	// depth is distance from root class (so that CSS files are generated in order)
	// order is the order in which user files are listed
	// localdepth is the depth of *this* component (depth is lowest depth in current module)

	Set tIncludes = $G(%parameter("INCLUDEFILES"))
	Set tPackage = $P(%class.Name,".",1,$L(%class.Name,".")-1)
	Set tSysMod = $G(%parameter("SYSMODULE"))
	Set tUserMod = $G(%parameter("MODULE"))
	Set tIsZen = %class.Name["%ZEN."

	// compute class depth: number of classes from here to root object class
	Set tDepth = 0
	Set tModDepth = ""
	Set tSuper = %class.Name
	While ((tSuper '= "") && (tSuper '= "%ZEN.Component.object")) {
		Set tDepth = tDepth + 1
		Set:tModDepth'="" tModDepth = tModDepth + 1
		Set tSuperPackage = $P(tSuper,".",1,$L(tSuper,".")-1)
		Set tSuperSysMod = $$$comMemberKeyGet(tSuper,$$$cCLASSparameter,"SYSMODULE",$$$cPARAMdefault)
		Set tSuperUserMod = $$$comMemberKeyGet(tSuper,$$$cCLASSparameter,"MODULE",$$$cPARAMdefault)

		If ((tSysMod'="")&&(tSysMod=tSuperSysMod)) {
			Set tModDepth = 1
		}
		ElseIf ((tUserMod'="")&&(tUserMod=tSuperUserMod)) {
			Set tModDepth = 1
		}
		Set tSuper = $P($$$comClassKeyGet(tSuper,$$$cCLASSsuper),",")
	}
	
	Set tModDepth = $S(tModDepth="":tDepth,1:tModDepth)

	If (tIsZen && (tUserMod '= "")) {
		Quit $$$ERROR($$$GeneralError,"ZEN library class should not set MODULE parameter")
	}

	// Get module info
	Set tModName = $G(^||%Cls(%class.Name,"Module"))
	If (tModName = "ZEN_Component__core") {
		Set tModDepth = 0
	}

	Do %code.WriteLine(" If $D(%zenClassList("_$$$quote(%class.Name)_")) Quit")
	Do %code.WriteLine(" Set %zenClassList("_$$$quote(%class.Name)_") = """"")
	If (%class.Name '= "%ZEN.Component.object") {
        #; Find the left-most super class that has %GetIncludeFiles
        For i=1:1:$LENGTH(%compiledclass.Super,",") {
            Set tSuper = $PIECE(%compiledclass.Super,",",i)
            If $$$comMemberKeyGet(tSuper,$$$cCLASSmethod,"%GetIncludeFiles",$$$cMETHrunnable) {
                Do %code.WriteLine(" Do ##class("_tSuper_")$this.%GetIncludeFiles(pMode)")
                Quit
            }
        }
	}

	Set tHasJS = $G(^||%Cls(%class.Name,"HasJS"))
	Set tCSSType = $G(^||%Cls(%class.Name,"CSSType"))
	Set tInline = $G(^||%Cls(%class.Name,"Inline"))

	// determine if there are CSS files, and which type
	Set tCond = ""
	Set tType = "html"
	Set tJSName = tModName _ ".js"
	If (tCSSType = "HTML") {
		// use cssx as a place holder;
		// later we emit links to either css2 or css3
		Set tCSSName = tModName _ ".cssx"
		Set tCond = ":(pMode=""HTML"")"
	}
	ElseIf (tCSSType = "SVG") {
		Set tCSSName = tModName _ ".css"
		Set tCond = ":(pMode=""SVG"")"
		Set tType = "svg"
	}
	Else {
		Set tCSSName = ""
	}
	Set tOrder = 1

	If ('tInline) {
		Do:tHasJS %code.WriteLine(" Set:(pMode=""HTML"") %zenIncludeJS("_tModDepth_","_tOrder_","""_tPackage_""","""_tJSName_""") = $LB(""js"","_tDepth_","""_%class.Name_""")")
		Do:tCSSName'="" %code.WriteLine(" Set"_tCond_ " %zenIncludeCSS("_tModDepth_","_tOrder_","""_tPackage_""","""_tCSSName_""") = $LB("""_tType_""","_tDepth_")")
	}

	// preserve the order of additional includes for this class
	If (tIncludes '= "") {
		If ($$$comMemberKeyGet(%class.Name,$$$cCLASSparameter,"INCLUDEFILES",$$$cPARAMtype) = $$$cPARAMTYPECOSEXPRESSION) {
			// DTB475 - Extract list of files at runtime with resolved value for INCLUDEFILES.
			Do %code.WriteLine(" Set tIncludes = ..#INCLUDEFILES")
			Do %code.WriteLine(" For tOrder = 1:1:$L(tIncludes,"","") {")
			Do %code.WriteLine("  Set tFile = $P(tIncludes,"","",tOrder)")
			Do %code.WriteLine("  Set tFile = $ZSTRIP(tFile,""<>W"")")
			Do %code.WriteLine("  If (tFile'="""") {")
			Do %code.WriteLine("   If ($E($$$LOWER(tFile),1,7)=""script:"") {")
			Do %code.WriteLine("    Set tFile = $E(tFile,8,$L(tFile))")
			Do %code.WriteLine("    Set tExt = ""js""")
			Do %code.WriteLine("   } ElseIf ($E($$$LOWER(tFile),1,6)=""style:"") {")
			Do %code.WriteLine("    Set tFile = $E(tFile,7,$L(tFile))")
			Do %code.WriteLine("    Set tExt = ""css""")
			Do %code.WriteLine("   } Else { ")
			Do %code.WriteLine("    Set tExt = $$$LOWER($P(tFile,""."",$L(tFile,""."")))")
			Do %code.WriteLine("   }")
			Do %code.WriteLine("   Set tType = ""user""")
			Do %code.WriteLine("   If (tExt=""js"") {")
			Do %code.WriteLine("    Set:(pMode=""HTML"") %zenIncludeJS("_tDepth_",tOrder,"""_tPackage_""",tFile) = $LB(tType)")
			Do %code.WriteLine("   } Else {")
			Do %code.WriteLine("    Set %zenIncludeCSS("_tDepth_",tOrder,"""_tPackage_""",tFile) = $LB(tType)")
			Do %code.WriteLine("   }")
			Do %code.WriteLine("  }")
			Do %code.WriteLine(" }")
		}
		Else {
			For tOrder = 1:1:$L(tIncludes,",") {
				Set tFile = $P(tIncludes,",",tOrder)
				Set tFile = $ZSTRIP(tFile,"<>W")
				If (tFile'="") {
					// we have to determine if this file is JS or CSS as they are included
					// in different ways;
					// If the file ends with .js then we assume it is a JS file.
					// To override this behavior, the user can prepend
					// "script:" or "style:" at the start of the file name;
					If ($E($$$LOWER(tFile),1,7)="script:") {
						Set tFile = $E(tFile,8,$L(tFile))
						Set tExt = "js"
					}
					ElseIf ($E($$$LOWER(tFile),1,6)="style:") {
						Set tFile = $E(tFile,7,$L(tFile))
						Set tExt = "css"
					}
					Else {
						Set tExt = $$$LOWER($P(tFile,".",$L(tFile,".")))
					}
					Set tType = "user"
					If (tExt="js") {
						Do %code.WriteLine(" Set:(pMode=""HTML"") %zenIncludeJS("_tDepth_","_tOrder_","""_tPackage_""","""_tFile_""") = $LB("""_tType_""")")
					}
					Else {
						Do %code.WriteLine(" Set %zenIncludeCSS("_tDepth_","_tOrder_","""_tPackage_""","""_tFile_""") = $LB("""_tType_""")")
					}
				}
			}
		}
	}
	Quit $$$OK
}

///  Internal method.<br/>
///  Return the inheritance depth of this class.
///  That is, the number of classes from this one to the root object class.<br/>
ClassMethod %GetClassDepth() As %Integer [ CodeMode = objectgenerator, Final, GenerateAfter = %GetIncludeInfo, Internal ]
{
	Set tDepth = $G(^||%Cls(%class.Name,"Depth"))
	Do %code.WriteLine(" Quit " _ tDepth)
	Quit $$$OK
}

///  Return the XML namespace and element name for this component.
///  These are return via the parameters <var>pNamespace</var> and <var>pName</var>
///  respectively.
ClassMethod %GetXMLName(Output pNamespace As %String, Output pName As %String) As %Integer [ CodeMode = objectgenerator, Final ]
{
	Set tNamespace = $$$comMemberKeyGet(%class.Name,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	Set tXMLName = $$$comMemberKeyGet(%class.Name,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
	Set:tXMLName="" tXMLName = $P(%class.Name,".",$L(%class.Name,"."))
	Do %code.WriteLine(" Set pNamespace = " _ $$$quote(tNamespace))
	Do %code.WriteLine(" Set pName = " _ $$$quote(tXMLName))
	Quit $$$OK
}

///  Internal method.<br>
///  Draw JavaScript needed to define client-side class for this component.
ClassMethod %DrawClassDefinition() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%DrawClassDefinition()
}

///  Internal method.<br>
///  Get the CRC for this class.
///  This is used to test for client/server mismatch issues. This needs to be a method
///  to avoid class compiler issues.
ClassMethod %GetClassCRC() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	Set tCRC = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"CRC"))
	Do %code.WriteLine(" Quit " _ $$$quote(tCRC))
	Quit $$$OK
}

///  Internal method.<br>
///  Draw JavaScript serialize method for this component.
ClassMethod %DrawJSSerialize() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%JSSerialize()
}

///  Internal method.<br>
///  Draw JavaScript getSettings method for this component.
ClassMethod %DrawJSGetSettings() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%JSGetSettings()
}

///  Internal method.<br>
///  Draw JavaScript needed to initialize properties for client side of this object
Method %DrawObjectProperties() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %OnDrawObjectProperties, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%DrawObjectProperties()
}

///  Internal method.<br>
///  Draw JavaScript needed to synchronize client object to match
///  state of the server object.<br>
///  This is basically a specialized version of %DrawObjectProperties
///  that is used to send a changes in a server object to a client
///  object. It works by detecting if a property has changed and then
///  applies the value to the client via JS. It either sets the 
///  property directly, or calls the client setProperty method if
///  the property is marked as a "setting".<br>
Method %ObjectSynch() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %OnObjectSynch, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%ObjectSynch()
}

///  Internal method.<br>
///  Server-side method to deserialize a serialized state into an
///  instance of this object. This object has to be created first as 
///  this is an instance method.
Method %ZENDeserialize(pState As %String, ByRef pObjSet) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = (%OnZENDeserialize, %OnObjectSynch, %DrawClassDefinition), Internal ]
{
	Quit ##class(%ZEN.Generator).%ZENDeserialize()
}

///  If defined, this callback is invoked by the <method>%ZENDeserialize</method>
///  method.
Method %OnZENDeserialize() As %Status [ Abstract ]
{
}

///  If defined, this callback is invoked by the <method>%DrawObjectProperties</method>
///  method.
Method %OnDrawObjectProperties() [ Abstract ]
{
}

///  If defined, this callback is invoked by the <method>%ObjectSynch</method>
///  method.
Method %OnObjectSynch() As %Status [ Abstract ]
{
}

///  Internal method.<br>
///  Called during page compilation to generate code to construct
///  an instance of this object.
///  If pLocalize is true, then all localizable values will use $$$Text
///  to generate localization information.
///  <var>pMode</var> indicates what type of code to generate:<br>
///  If "page", then generate contents of a page.<br>
///  If "composite", then generate contents of a composite component.<br>
///  <var>pKey</var>, if defined indicates we are inserting into a parent array
///  usng this key. If <var>pKey</var> = $C(0), then we should set our
///  instance into an object property of our parent.
Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, ByRef pURIList, pCollection As %String, pLevel As %Integer = 1, pMode As %String = "page", pKey As %String = "", pParentVar As %String = "unknown") [ CodeMode = objectgenerator, Internal ]
{
	#; Note: this method *generates* a code generator!
	#; Do %code.WriteLine(" Do pCode.WriteLine("" // "_%class.Name_""")")

	#; Create a local varname based on our class name
	If (%class.Name = "%ZEN.Component.abstractPage") {
		#; for page, we always want to call our variable "pg"
		Do %code.WriteLine(" Set tVar = ""pg""_pLevel")
	}
	Else {
		Do %code.WriteLine(" Set tVar = """_$TR($P(%class.Name,".",$L(%class.Name,".")),"aeiou","")_"""_pLevel")
	}

	#; Check condition to see if this component should be created
	Do %code.WriteLine(" If ((..%condition '= """")||(..%resource '= """")) {")
	Do %code.WriteLine("  Set tCond = $S(..%condition="""":"""",1:""(""_..%condition_"")"")")
	Do %code.WriteLine("  Set tRsc = $S(..%resource="""":"""",1:""$system.Security.Check(""""""_..%resource_"""""",""""USE"""")"")")
	Do %code.WriteLine("  Set tAND = $S((tCond="""")||(tRsc=""""):"""",1:""&&"")")

	Do %code.WriteLine("  Do pCode.WriteLine("" If (""_tRsc_tAND_tCond_"") {"")")
	Do %code.WriteLine(" }")

	#; note: the order of actions is important:
	#; 1) create instances
	#; 2) fill in properties
	#; 3) add to parent
	#; 4) create children

	#; create instance
	#; for top-level use local %New method to get correct class
	Do %code.WriteLine(" If (pLevel>1) {")
	Do %code.WriteLine("  Do pCode.WriteLine("" Set ""_tVar_"" = ##class("_%class.Name_").%New()"")")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("  If (pMode = ""composite"") {")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_tVar_"" = ##this"")")
	Do %code.WriteLine("  } ElseIf (pMode = ""pane"") {")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_tVar_"" = pGroup"")")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Set ""_tVar_"" = ..%New()"")")

	#; set %page *here* as user code may reference it
	Do %code.WriteLine("   Do pCode.WriteLine("" Set %page = ""_tVar_"""")")
	Do %code.WriteLine("   Do pCode.WriteLine("" Do %page.%ApplyURLParms()"")")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")
 
	#; get value for %import
	Set tName = "%import"
	Do %code.WriteLine(" Do:(.."_tName_"'="""") pCode.WriteLine("" "_"Set ""_tVar_""."_tName_"=""_..%QuoteValue(.."_tName_"))")

	#; get value for id (before AddChild is called)
	Set tName = "id"
	Do %code.WriteLine(" Do:(.."_tName_"'="""") pCode.WriteLine("" "_"Set ""_tVar_""."_tName_"=""_..%QuoteValue(.."_tName_"))")

	#; get value for name (before AddChild is called)
	Set tName = "name"
	Do %code.WriteLine(" Do:(.."_tName_"'="""") pCode.WriteLine("" "_"Set ""_tVar_""."_tName_"=""_..%QuoteValue(.."_tName_"))")

	#; list of special properties that we skip in code generation
	Set tIgnore("name")=""
	Set tIgnore("index")=""
	Set tIgnore("id")=""
	Set tIgnore("%import")=""

	#; flag to indicate that there are children to process
	#; we want to defer these til later
	Set tHasChildren = 0

	#; get list of properties and set their values
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)

		#; filter out properties we do not care about
		#; namely: do not process items in tIgnore list or non-XML enabled % properties
		Set tSkip = 0
		If $D(tIgnore(tProp.Name)) {
			Set tSkip = 1
		}
		ElseIf ($E(tProp.Name,1,1)="%") {
			#; if someone sets XMLNAME for %prop then they must need it!
			If (tProp.Parameters.GetAt("XMLNAME")="") {
				Set tSkip = 1
			}
		}
		ElseIf (+tProp.Calculated) {
			#; The client-object model does not include calculated properties.
			Set tSkip = 1
		}

		If ('tSkip) {
			#; use InitialExpression to get default value
			Set tDefVal = tProp.InitialExpression
			
			#; make note of link properties
			If (tProp.Type = "%ZEN.Datatype.uri") {
				Do %code.WriteLine(" Set:(.."_tProp.Name_"'="""") pURIList(.."_tProp.Name_")= """"")
			}

			If (tProp.Collection = "list") {
				If (tProp.Name = "children") {
					#; defer child processing
					Set tHasChildren = 1
				}
				Else {
					#; recurse over list
					Do %code.WriteLine(" For n=1:1:.."_tProp.Name_".Count() {")
					Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(n).%GenerateCode(pCode,pLocalize,.pURIList,"""_tProp.Name_""",pLevel+1,pMode,,tVar)")
					Do %code.WriteLine(" }")
				}
			}
			ElseIf (tProp.Collection = "array") {
				#; recurse over array
				Do %code.WriteLine(" Set key=.."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key'="""") {")
				Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(key).%GenerateCode(pCode,pLocalize,.pURIList,"""_tProp.Name_""",pLevel+1,pMode,key,tVar)")
				Do %code.WriteLine("  Set key=.."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
			}
			ElseIf ($$$comClassKeyGet(tProp.Type,$$$cCLASSclasstype)="") {
				#; simple (non-persistent, non-serial) object-valued property
				#; in this case, pCollection is the name of the container property
				#; and we use $C(0) as a key value to indicate this
				Do %code.WriteLine(" Do:($IsObject(.."_tProp.Name_")&&(.."_tProp.Name_".%IsA(""%ZEN.Component.object""))) .."_tProp.Name_".%GenerateCode(pCode,pLocalize,.pURIList,"""_tProp.Name_""",pLevel+1,pMode,$C(0),tVar)")
			}
			Else {
				#; this line generates a generator to get values for *normal* properties
				#; test if this value needs to be localized
				Set ZENLOCALIZE = tProp.Parameters.GetAt("ZENLOCALIZE")

				If (ZENLOCALIZE) {
					Do %code.WriteLine(" If (pLocalize) {")
					Do %code.WriteLine(" Do:(.."_tProp.Name_"'=("_tDefVal_")) pCode.WriteLine("" "_"Set ""_tVar_""."_tProp.Name_"=""_..%QuoteValueL10N(.."_tProp.Name_")_"""")")
					Do %code.WriteLine(" } Else {")
				}
				Do %code.WriteLine(" Do:(.."_tProp.Name_"'=("_tDefVal_")) pCode.WriteLine("" "_"Set ""_tVar_""."_tProp.Name_"=""_..%QuoteValue(.."_tProp.Name_"))")

				If (ZENLOCALIZE) { // close else
					Do %code.WriteLine(" }")
				}
			}
		}
	}

	#; insert in parent list (unless we are at the top)
	#; There is a special case for "children" of groups
	#; Such children are *registered* with the page (by %AddChild)
	#; For others, we have to explicitly call %AddToPage
	#; this has to be done right after creating the component
	Do %code.WriteLine(" If (pLevel>1) {")
	Do %code.WriteLine("  If ((pCollection=""children"")) {")
	Do %code.WriteLine("  Do pCode.WriteLine("" Do ""_pParentVar_"".%AddChild(""_tVar_"")"")")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   If (pKey="""") {")
	Do %code.WriteLine("    Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".Insert(""_tVar_"")"")")
	Do %code.WriteLine("   }")
	Do %code.WriteLine("   ElseIf (pKey=$C(0)) {")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_pParentVar_"".""_pCollection_"" = ""_tVar)")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_tVar_"".parent = ""_pParentVar)")
	Do %code.WriteLine("   }")
	Do %code.WriteLine("   Else {")
	Do %code.WriteLine("    Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".SetAt(""_tVar_"",""""""_pKey_"""""")"")")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_tVar_"".parent = ""_pParentVar)")
	Do %code.WriteLine("   }")
	Do %code.WriteLine("  Do pCode.WriteLine("" Do:$IsObject(%page) %page.%AddComponent(""_tVar_"")"")")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")

	#; if we have children, add them now
	If (tHasChildren) {
		Set tName = "children"
		#; recurse over list
		Do %code.WriteLine(" For n=1:1:.."_tName_".Count() {")
		Do %code.WriteLine("  Do .."_tName_".GetAt(n).%GenerateCode(pCode,pLocalize,.pURIList,"""_tName_""",pLevel+1,pMode,,tVar)")
		Do %code.WriteLine(" }")
	}

	#; end of outer if condition
	Do %code.WriteLine(" If ((..%condition '= """") || (..%resource '= """")) {")
	Do %code.WriteLine("  Do pCode.WriteLine("" }"")")
	Do %code.WriteLine(" }")

	Quit $$$OK
}

///  Take a value string and return a quoted string.
ClassMethod %QuoteValue(pValue As %String) [ CodeMode = expression ]
{
$TR($$$quote(pValue),$C(10),"")
}

///  Take a value string and return a quoted string wrapped within a
///  $$$Text macro.<br>
///  If value starts and ends with #( )#, then return an expression
ClassMethod %QuoteValueL10N(pValue As %String)
{
	Quit:$E(pValue,1,2)'="#(" "$$$Text("_..%QuoteValue(pValue)_")"
	Quit:$E(pValue,$L(pValue)-1,$L(pValue))'=")#" "$$$Text("_..%QuoteValue(pValue)_")"

	#; return run-time expression
	Quit ..%QuoteValue(pValue)
}

///  Server-side utility method that constructs a component-specific id 
///  value for use in assigning ids to HTML/XML elements.
///  If we are part of a repeating group, the tuple number is included
///  in the id as well.
Method %MakeId(pSubID As %String) As %String [ CodeMode = expression ]
{
pSubID_"_"_..index_$S(..tuple="":"",1:"."_..tuple)
}

///  Return a JS expression that will evaluate to *this* component.
///  This is used when rendering HTML for a component and that HTML
///  needs to refer back to *this* component for a JS expression (such as
///  an event handler):<br>
///  onclick="#(..%Self())#.someMethod();"
Method %Self() As %String [ CodeMode = expression ]
{
"zenPage.getComponent("_$Case(..tuple,"":..index,:"'"_..index_"."_..tuple_"'")_")"
}

///  This helper method returns a string of HTML/XML attributes that
///  will define all event handler properties defined for a control.<br>
///  <var>pIgnore</var> is an array of names of events that should be ignored.<br>
///  If the properties W3CEVENT parameter is set to 0, then it will be ignored.
Method %GetEventHandlers(ByRef pIgnore) As %String [ CodeMode = objectgenerator ]
{
	#; if page is in design mode, then do nothing
	Do %code.WriteLine(" Quit:%page.designMode """"")
	Do %code.WriteLine(" Set out = """"")

	#; find set of all eventHandler properties
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tType = $$$NormalizeClassname(tProp.Type)
		If (tType = "%ZEN.Datatype.eventHandler") {
			Set HANDLER = tProp.Parameters.GetAt("HANDLER")
			If (HANDLER = "normal") {
				Do %code.WriteLine(" Set:((.."_tProp.Name_"'="""")&&('$D(pIgnore("""_tProp.Name_""")))) out = out_"" " _ tProp.Name _ "=""""return zenFireEvent('""_..index_""','""_$ZCVT($$$ZENVALJS(.." _ tProp.Name _ "),""O"",""JS"")_""','"_tProp.Name_"',event);""""""")
			}
			ElseIf (HANDLER '= "") {
				Do %code.WriteLine(" Set:('$D(pIgnore("""_tProp.Name_"""))) out = out_"" " _ tProp.Name _ "="""""_HANDLER_"""""""")
			}
		}
	}
	Do %code.WriteLine(" Quit out")
	Quit $$$OK
}

///  Client-side utility method that finds an HTML element with a 
///  component-specific id.
ClientMethod findElement(subid) [ Final, Language = javascript ]
{
	return this.window.document.getElementById(subid + '_' + this.index + (null==this.tuple||''==this.tuple?'':'.'+this.tuple));
}

///  This client event, if present, is fired before a component 
///  is serialized. This gives the component a chance to make sure that its
///  client-side variables are up-to-date.
ClientMethod onSerialize() [ Abstract, Language = javascript ]
{
}

///  client-side utility method that constructs a component-specific id 
///  value for use in assigning ids to HTML elements.<br>
///  This is simply a client-side version of <method>%MakeId</method>.
ClientMethod makeId(subid) [ Language = javascript ]
{
	return subid + '_' + this.index + (null!=this.tuple&&''!=this.tuple ? ('.'+this.tuple) : '');
}

///  Client-side method that returns a list of this component's
///  run-time settable properties. These are the properties that
///  the page designer Inspector allows a user to edit.<br>
///  This list is returned by inserting
///  the property names in the associative array (object) <var>settings</var>.
///  Note: this method is automatically generated by DrawClassDefinition.
ClientMethod getSettings(settings) [ Final, Language = javascript ]
{
}

///  Invoke the superclass method <var>method</var> of the current
///  object with arguments <var>args</var>.
ClientMethod invokeSuper(method, args) [ Language = javascript ]
{
	var val = null;
	var tArgs = args || [];
	try {
		var oldMethod = this._methodContext;
		var oldContext = this._superContext;
		this._superContext = (this._superContext&&(method==this._methodContext)) ? this._superContext.superClass : this.superClass;
		this._methodContext = method;
		val = this._superContext[method].apply(this,tArgs);
		this._superContext = oldContext;
		this._methodContext = oldMethod;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in invokeSuper.\nMethod: ' + method);
	}
	return val;
}

///  This is called when an object is updated from the server.
///  It will invoke the class-defined and user-defined onupdate event if defined.
ClientMethod fireOnUpdateEvent() [ Language = javascript ]
{
	// class defined
	if (this.onupdateHandler) {
		this.onupdateHandler();
	}

	// user defined
	if ('' != this.onupdate) {
		zenInvokeCallbackMethod(this.onupdate,this,'onupdate');
	}
}

///  This client method, if present, is fired when the object is updated from the server.
ClientMethod onupdateHandler() [ Abstract, Language = javascript ]
{
}

///  This client method, if present, is called when this component is
///  instantiated. This allows for any additional client-side 
///  initialization for this object.<br>
///  Note that this <em>must</em> be a client-side method.
ClientMethod onCreate() [ Abstract, Language = javascript ]
{
}

///  This client method, if present, is called when this component is
///  removed from the page. This allows for any additional client-side 
///  clean up for this object.<br>
///  Note that this <em>must</em> be a client-side method.
ClientMethod onDelete() [ Abstract, Language = javascript ]
{
}

///  This causes a component that draws its contents dynamically
///  to (re)create its contents.<br>
///  This is a wrapper for the <method>renderContents<method>
///  method (if present). Applications should call <method>render<method>
///  to display dynamic components, but implement <method>renderContents<method> to
///  implement dynamic components.
ClientMethod render() [ Final, Language = javascript ]
{
	if (this.renderContents) {
		try {
			this.renderContents();
		}
		catch(ex) {
			var src = 'Source: (' + this._type + ' id="' + this.id + '")\n';
			zenExceptionHandler(ex,arguments,'Error invoking renderContents method.\n' + src);
		}
	}
}

///  This method, if present, is called when this component
///  is placed on a client page.<br>
///  This is used by components that render themselves using
///  client-side, dynamic content (i.e., instead of using the <method>%DrawHTML</method> method).
ClientMethod renderContents() [ Abstract, Language = javascript ]
{
}

///  This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Abstract, Language = javascript ]
{
}

///  This client event, if present, is fired when the page is unloaded.
///  If this method returns a string value, then that is used as the
///  return value of the HTML page's onbeforeunload handler (if more than
///  one component returns a string, the first one encountered is used).
ClientMethod onunloadHandler() [ Abstract, Language = javascript ]
{
}

///  Returns the component type of this object
///  (e.g. "form", or "control").
ClientMethod getType() [ Final, Language = javascript ]
{
	return this._type;
}

///  Returns true if this object is of the given component type
///  or is subclassed from the given component type.
///  (e.g. "form", or "control")
ClientMethod isOfType(type) [ Final, Language = javascript ]
{
	var obj = this;
	while (obj) {
		if (obj._type == type) {
			return true;
		}
		obj = obj.superClass;
	}
	return false;
}

///  Set the value of a named property (i.e., a setting).<br>
///  Subclasses override this for cases where setting a property
///  requires some additional side effect to happen.<br>
///  The optional <var>value2</var> argument is used in cases,
///  such as collections, where a key and a value are needed.
///  In this case <var>value</var> is used as a key and 
///  <var>value2</var> is the value.<br>
///  Return true if the property was explicitly handled and
///  false for the default behavior (setting the property directly).
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'id':
		// notify page
		if (zenPage) {
			zenPage.setComponentId(this,value);
		}
		else {
			this.id = value;
		}
		break;

	case 'name':
		this.name = value;
		break;
	case 'aux':
		this.aux = value;
		break;

	default:
		// default: set property directly
		if ('' != property && (('object'!=typeof(this[property])) || (null===this[property]))) {
			this[property] = value;
		}
		return false;
	}

	return true;
}

///  Return the value of a named property (i.e. a setting).<br>
///  Returns null if this is not a property of this object.<br>
///  <var>key</var> is an optional argument used for properties
///  (such as collections) that may need a key to find a specific value.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	// get property value directly.
	if ('' != property) {
		return this[property];
	}

	return null;
}

///  Render list of localized javascript strings for this object.
ClassMethod %DrawJSStrings(ByRef pVisited As %String) As %Status [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = %DrawClassDefinition ]
{
	#; JMD611
	Do %code.WriteLine(" Set tSC = $$$OK")
	If (%class.Name '= "%ZEN.Component.object") {
		Do %code.WriteLine(" If '$D(pVisited("""_%compiledclass.Name_""")) {")
		#; Find the left-most super class that has %DrawJSStrings
        For i=1:1:$LENGTH(%compiledclass.Super,",") {
            Set tSuper = $PIECE(%compiledclass.Super,",",i)
            If $$$comMemberKeyGet(tSuper,$$$cCLASSmethod,"%DrawJSStrings",$$$cMETHrunnable) {
                Do %code.WriteLine("  Set tSC = ##class("_tSuper_")$this.%DrawJSStrings(.pVisited)")
                Quit
            }
        }
		Do %code.WriteLine("  Set pVisited("""_%compiledclass.Name_""") = """"")
		Do %code.WriteLine(" }")
	}

	Set tKey = $O(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"TextList",""))
	While (tKey'="") {
		// JMD1018: remove JS escape chars
		Set tKey2 = $Replace(tKey,"\\","\")
		Set tKey2 = $Replace(tKey2,"\""","""")
		Set tKey2 = $Replace(tKey2,"\'","'")
		Set tDomain = $P(tKey2,"/",1)
		Set tText = $P(tKey2,"/",2,99999)
		If ((tDomain'="")&&(tText'="")) {
			Do %code.WriteLine(" Write "_$$$quote("self._zenTEXT['"_$ZCVT(tKey2,"O","JS")_"']='")_ "_$ZCVT($$$Text("_$$$quote(tText)_","_$$$quote(tDomain)_"),""O"",""JS"")" _ "_""';"",!")
		}
		Set tKey = $O(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"TextList",tKey))
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

}
