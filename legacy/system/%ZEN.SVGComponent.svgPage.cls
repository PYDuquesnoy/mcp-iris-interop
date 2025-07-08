/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This is a specialized CSP page that serves SVG content for
/// a ZEN svgFrame.<br>
/// This is an instantiable CSP page.
Class %ZEN.SVGComponent.svgPage Extends (%RegisteredObject, %CSP.Page) [ Deprecated, Inheritance = right, PropertyClass = %ZEN.pageParameters, System = 4 ]
{

Parameter CONTENTTYPE = "image/svg+xml";

/// Comma-separated list of component packages whose 
/// style definitions are in pre-generated include files.
/// This is merged with the list provided by the parent page.
Parameter USERSVGPACKAGES As STRING;

/// This is a comma-delimited list of system Resources and associated 
/// permissions. A user must hold the specified permissions on at least
/// one of the specified resources in order to view this page or 
/// invoke any of its server-side methods from the client.<br/>
/// The format of each item in the list should be as follows:<br/>
///  Resource[:Permission] <br/>
/// Permission is optional, and defaults to USE if not supplied. If it
/// is supplied, it should be one of USE, READ or WRITE.
Parameter RESOURCE As STRING;

/// Comma-separated list of additional JS include files.
/// These are included within the inner SVG page served by this class only.
Parameter JSINCLUDES As STRING;

/// Additional set of CSS style files to include.
Parameter CSSINCLUDES As STRING;

/// Internal property.<br>
/// Comma-delimited list of user-defined packages that are included by this page.
/// This list is created by combining the parameter from this class, the parent page, and the application.
Property %SystemSVGPackageList As %String(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br>
/// Comma-delimited list of user-defined packages that are included by this page.
/// This list is created by combining the parameter from this class, the parent page, and the application.
Property %UserSVGPackageList As %String(XMLPROJECTION = "none") [ Internal ];

/// Default style for ZEN SVG pages
XData SVGStyle
{
<style type="text/css">
<![CDATA[
/* overlay rect  */
.zenSvgOverlay {
	fill: yellow;
	stroke: black;
	stroke-width: 1;
	opacity: 0.1;
	fill-opacity: 0.0;
}

/* overlay rect: selected */
.zenSvgOverlaySelected {
	fill: yellow;
	stroke: black;
	stroke-width: 1;
	opacity: 1.0;
	fill-opacity: 0.0;
	stroke-dasharray: 2,2;
}

/* overlay rect: drag */
.zenSvgOverlayDrag {
	fill: yellow;
	stroke: blue;
	stroke-width: 1;
	opacity: 1.0;
	fill-opacity: 0.0;
	stroke-dasharray: 1,3;
	cursor: move;
}

.zenSizingHandle {
	fill: black;
	stroke: none;
	opacity: 1.0;
}

/* error text  */
.zenSvgError {
	fill: red;
	stroke: none;
	font-size: 12pt;
	font-weight: bold;
}

/* fixed overlay rect  */
.zenSvgFixedOverlay {
	fill: none;
	stroke: green;
	stroke-width: 2;
}

]]>
</style>
}

/// Set of standard svg defs shared by all svg components.
XData SVGDef
{
<defs>
<pattern id="zenHatch" patternUnits="userSpaceOnUse" x="0" y="0" width="10" height="10">
  <g style="fill:none; stroke:#808080; stroke-width:1">
    <path d="M 0 0 l 10 10"/>
    <path d="M 10 0 l -10 10"/>
  </g>
</pattern>
<linearGradient id="deep-red" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:#800000" />
</linearGradient>

<linearGradient id="shade-red" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF0000" />
<stop offset="80%" style="stop-color:#A00000" />
<stop offset="100%" style="stop-color:#600000" />
</linearGradient>

<linearGradient id="glow-red" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="40%" style="stop-color:#FF0000" />
<stop offset="60%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>


<linearGradient id="deep-green" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:#008000" />
</linearGradient>

<linearGradient id="shade-green" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FF80" />
<stop offset="20%" style="stop-color:#00FF00" />
<stop offset="80%" style="stop-color:#00A000" />
<stop offset="100%" style="stop-color:#006000" />
</linearGradient>

<linearGradient id="glow-green" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="40%" style="stop-color:#00FF00" />
<stop offset="60%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="deep-blue" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:#000080" />
</linearGradient>

<linearGradient id="shade-blue" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#8080FF" />
<stop offset="20%" style="stop-color:#0000FF" />
<stop offset="80%" style="stop-color:#0000A0" />
<stop offset="100%" style="stop-color:#000060" />
</linearGradient>

<linearGradient id="glow-blue" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="40%" style="stop-color:#0000FF" />
<stop offset="60%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="deep-yellow" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="shade-yellow" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF80" />
<stop offset="20%" style="stop-color:#FFFF00" />
<stop offset="80%" style="stop-color:#A0A000" />
<stop offset="100%" style="stop-color:#606000" />
</linearGradient>

<linearGradient id="glow-yellow" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:#FFFF00" />
<stop offset="60%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-purple" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="shade-purple" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF80FF" />
<stop offset="20%" style="stop-color:#FF00FF" />
<stop offset="80%" style="stop-color:#A000A0" />
<stop offset="100%" style="stop-color:#600060" />
</linearGradient>

<linearGradient id="glow-purple" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="40%" style="stop-color:#FF00FF" />
<stop offset="60%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="deep-teal" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#008080" />
</linearGradient>

<linearGradient id="shade-teal" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FFFF" />
<stop offset="20%" style="stop-color:#00FFFF" />
<stop offset="80%" style="stop-color:#00A0A0" />
<stop offset="100%" style="stop-color:#006060" />
</linearGradient>

<linearGradient id="glow-teal" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="40%" style="stop-color:#00FFFF" />
<stop offset="60%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="deep-orange" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF8000" />
<stop offset="100%" style="stop-color:#804000" />
</linearGradient>

<linearGradient id="shade-orange" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF8000" />
<stop offset="80%" style="stop-color:#A04000" />
<stop offset="100%" style="stop-color:#604000" />
</linearGradient>

<linearGradient id="glow-orange" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:orange" />
<stop offset="60%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-silver" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="shade-silver" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="20%" style="stop-color:#F0F0F0" />
<stop offset="80%" style="stop-color:#A0A0A0" />
<stop offset="100%" style="stop-color:#606060" />
</linearGradient>

<linearGradient id="glow-silver" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="40%" style="stop-color:#FFFFFF" />
<stop offset="60%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="bg-chrome" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="2%" style="stop-color:#F0F0FF" />
<stop offset="10%" style="stop-color:#E0E0E0" />
<stop offset="90%" style="stop-color:#E0E0E0" />
<stop offset="98%" style="stop-color:#F0F0F0" />
<stop offset="100%" style="stop-color:#FFFFFF" />
</linearGradient>

<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
<feOffset dx="4" dy="4" result="offsetBlur" />
<feMerge>
	<feMergeNode in="offsetBlur"/>
	<feMergeNode in="SourceGraphic"/>
</feMerge>
</filter>
</defs>
}

/// Copy URL parameters supplied to this page into the 
/// appropriate properties of this page.
Method %ApplyURLParms() As %Status [ CodeMode = objectgenerator, Final ]
{
	#; let generator class do the work
	Quit ##class(%ZEN.Generator).%GenerateApplyURLParms()
}

/// Draw JavaScript needed to define client-side class for this page (if any).
ClassMethod %DrawClassDefinition() As %Status [ CodeMode = objectgenerator, Final ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%DrawClassDefinition()
}

/// Draw JavaScript needed to initialize properties for client side of this object
Method %DrawObjectProperties() As %Status [ CodeMode = objectgenerator, Final ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%DrawObjectProperties()
}

/// Internal method.<br>
/// Draw JavaScript serialize method for this component.
ClassMethod %DrawJSSerialize() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%JSSerialize()
}

/// Internal method.<br>
/// Draw JavaScript getSettings method for this component.
ClassMethod %DrawJSGetSettings() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	#; let utility class handle generation
	Quit ##class(%ZEN.Generator).%JSGetSettings()
}

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	#; test for namespace change
	Set tNamespace = $G(%request.Data("$NAMESPACE",1))
	If (tNamespace '= "") {
		#; change to specified namespace
		Set tSC = ##class(%ZEN.Controller).%ChangeNS(tNamespace)		
		If $$$ISERR(tSC) Quit 0
	}
	
	If ..#RESOURCE '= "" {
		Set tUse = 0
		For i=1:1:$length(..#RESOURCE, ",") {
			Set tPiece = $piece(..#RESOURCE, ",", i)
			Set tRes = $piece(tPiece,":",1)
			Set tPerm = $piece(tPiece,":",2)
			If tPerm = "" Set tPerm = "USE"
			If $system.Security.Check(tRes, tPerm) {
				Set tUse = 1
				Quit
			}
		}
		If 'tUse {
			#dim %response As %CSP.Response
			Set %response.Status = "403 Forbidden"
			Set %response.ContentType = "text/html"
			Quit 0
		}
	}

	#; Avoid IE HTTP 1.1 bugs with plugins
	If (%request.UserAgent["MSIE") {
		Set %response.HTTPVersion = "HTTP/1.0"
		If (%request.Secure) {
			#; work-around IE HTTPS bug
			Do %response.SetHeader("Cache-Control","private")
		}
	}	
	#; force output to be UTF-8
	Set %response.CharSet="UTF-8"
	
	#; create an instance of *this* class so that we can
	#; use object properties, etc.
	Set %svgpage = ..%New()
	Do %svgpage.%ApplyURLParms()

	Quit 1
}

ClassMethod OnPage() As %Status
{
	#; write out XML version of page
	Write "<?xml version=""1.0"" ?>",!

	Do %svgpage.%DrawSVGPage()

	Quit $$$OK
}

/// Draw standard SVG wrapper
Method %DrawSVGPage() [ Final ]
{
	#; Get attributes passed in via URL
	Set tAttrs("$PAGECLASS") = $G(%request.Data("$PAGECLASS",1))
	Set tAttrs("$SVGCLASSES") = $G(%request.Data("$SVGCLASSES",1))
	Set tAttrs("$PARENTIDX") =..EscapeHTML( $G(%request.Data("$PARENTIDX",1)))
	Set tAttrs("$USERSVGPACKAGES") = ..EscapeHTML($G(%request.Data("$USERSVGPACKAGES",1)))

	Set tAttrs("$WIDTH") = ..EscapeHTML($G(%request.Data("$WIDTH",1),"100%"))
	Set tAttrs("$HEIGHT") = ..EscapeHTML($G(%request.Data("$HEIGHT",1),"100%"))

	Do ..%DrawSVGDocument(.tAttrs,0)
}

/// This does the actual work of writing out the SVG document
/// definition. It can be called for inline or standard SVG.
Method %DrawSVGDocument(ByRef pAttrs As %String, pInline As %Boolean) [ Final, Internal ]
{
	#; name of parent page class
	Set pageClass = $G(pAttrs("$PAGECLASS"))
	Set svgClassList = $G(pAttrs("$SVGCLASSES"))

	#; index of svgFrame object in parent page
	Set parentIdx = $G(pAttrs("$PARENTIDX"))
	
	#; directory containing common generated js/css files
	Set tSystemDir = ""

	#; construct list of user include packages
	Set ..%UserSVGPackageList = $G(pAttrs("$USERSVGPACKAGES"))
	Set:(..#USERSVGPACKAGES'="") ..%UserSVGPackageList = ..%UserSVGPackageList _ $S(..%UserSVGPackageList'="":",",1:"") _ ..#USERSVGPACKAGES

	#; directory containing user generated js/css files (if any)
	If (..%UserSVGPackageList'="") {
		Set tUserDir = $$getDefaultApp^%SYS.cspServer2($namespace) _ "/"
	}

	New %zenIncludeJS,%zenIncludeCSS
	#; Ensure we don't reuse our parent class's dependency tree if we are not rendered inline
	If 'pInline New %zenClassList

	#; build list of include files
	#; list will be in %zenIncludeCSS
	For n = 1:1:$L(svgClassList,",") {
		Set tClass = $P(svgClassList,",",n)
		If (tClass'="") {
			Do $zobjclassmethod(tClass,"%GetIncludeFiles","SVG")
			If $zobjclassmethod(tClass,"%IsA","%ZEN.Component.page") {
				#; keep track of which items are pages
				Set tDepth = $zobjclassmethod(tClass,"%GetClassDepth")
				Set tPageList(tDepth,tClass) = ""

				#; expand page list to get super classes
				Set tSuperList = $zobjclassmethod(tClass,"%GetSuperClassList")
				For c = 1:1:$L(tSuperList,",") {
					Set tSuper = $P(tSuperList,",",c)
					If $zobjclassmethod(tSuper,"%IsA","%ZEN.Component.page") {
						Set tDepth = $zobjclassmethod(tSuper,"%GetClassDepth")
						Set tPageList(tDepth,tSuper) = ""
					}
				}
			}
		}
	}

	If ('pInline) {
		#; includes must come first in xml!
		#; draw styles defined by components (using parent page list)
		// Write:$D(%zenIncludeCSS) "<!-- zenIncludeCSS -->",!
		Kill tVisited
		Set tDepth = $O(%zenIncludeCSS(""))
		While (tDepth'="") {
			Set tOrder = $O(%zenIncludeCSS(tDepth,""))
			While (tOrder'="") {
				Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,""))
				While (tPkg'="") {
					Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,""))
					While (tFile'="") {
						If ('$D(tVisited(tFile))) {
							Set tVisited(tFile) = ""
							Write ..%LinkCSS(tFile),!
						}
						Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,tFile))
					}
					Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,tPkg))
				}
				Set tOrder = $O(%zenIncludeCSS(tDepth,tOrder))
			}
			Set tDepth = $O(%zenIncludeCSS(tDepth))
		}

		#; user packages
		For p=1:1:$L(..%UserSVGPackageList,",") {
			Set tPack = $P(..%UserSVGPackageList,",",p)
			If (tPack '= "") {
				Set tCSSPackage = tUserDir _ $TR(tPack,".%","_")_".css"
				Write ..%LinkCSS(tCSSPackage),!
			}
		}

		#; additional CSS includes (defined by *this* class)
		For n = 1:1:$L(..#CSSINCLUDES,",") {
			Set tFile = $P(..#CSSINCLUDES,",",n)
			If (tFile '= "") {
				Write ..%LinkCSS(tFile),!
			}
		}
		
		#; 
	}

	#; size of svg canvas
	Set svgWidth = $G(pAttrs("$WIDTH"),"100%")
	Set svgHeight = $G(pAttrs("$HEIGHT"),"100%")

	If (pInline) {
		&html<<svg:svg
			xmlns="http://www.w3.org/2000/svg"
			xmlns:xlink="http://www.w3.org/1999/xlink"
			id="zenRoot"
			x="0" y="0"
			width="#(svgWidth)#" height="#(svgHeight)#"
			zoomAndPan="disable"
			>
		>
		
	}
	Else {
		&html<<svg 
			xmlns="http://www.w3.org/2000/svg"
			xmlns:xlink="http://www.w3.org/1999/xlink"
			id="zenRoot"
			x="0" y="0"
			width="#(svgWidth)#" height="#(svgHeight)#"
			onload="zenLoad();" 
			onunload="zenUnload();"
			zoomAndPan="disable"
			>
		>
	}

	#; draw styles defined by this SVG page
	Do ..%DrawStyleSVG()

	#; marker used to inject dynamic style !!!!
	// Write "<style id=""zenSVGStyle"" type=""text/css""></style>",!

	#; Allow override of default SVG font for the Adobe SVG plugin as IE does not provide fonts that work for both Kanji and ASCII.
	#; HCR266 - Font can be user-defined in ^%ZEN.DefaultSVGFontFamily or system-defined in the translation for "FontFamily"/"Ensemble", otherwise we use Arial.
	Set tFont = $G(^%ZEN.DefaultSVGFontFamily)
	Set:tFont="" tFont = $$$LocalizeText("Ensemble","FontFamily","tahoma,verdana")
	Set:tFont="" tFont = "arial"
	If (tFont'="") {
	&html<
<style type="text/css">
	text {
		font-family: #(tFont)#;
	}
</style>
	>
	}

	#; draw styles defined by components (using parent page list)
	Set tDepth = $O(tPageList(""))
	While (tDepth '= "") {
		Set tClass = $O(tPageList(tDepth,""))
		While (tClass '= "") {
			Do $zobjclassmethod(tClass,"%DrawStyleSVG")
			Set tClass = $O(tPageList(tDepth,tClass))
		}
		Set tDepth = $O(tPageList(tDepth))
	}

	#; svg defs from SVG page
	If ('pInline) {
		Do ..%DrawSVGDefs()
	}

	#; svg defs defined by components (using parent page list)
	For n = 1:1:$L(svgClassList,",") {
		Set tClass = $P(svgClassList,",",n)
		Do:tClass'="" $zobjclassmethod(tClass,"%DrawSVGDef")
	}

	#; !!! for in-line move to top of page???
	#; JS includes
	Set tJSIncludes = ..#JSINCLUDES
	For n = 1:1:$L(tJSIncludes,",") {
		Set tFile = $P(tJSIncludes,",",n)
		If (tFile '= "") {
			Write ..%LinkScript(tFile),$C(13,10),!
		}
	}

	#; built-in scripts
	Write ..%StartScript(),!

	#; page-wide variables
	#; index of parent svgFrame
	Write "var zenParentIndex = '",parentIdx,"';",!

	#; local reference to svgFrame on parent page
	Write "var zenParent = null;",!

	If ('pInline) {

		#; local reference to zenPage on parent page
		Write "var zenPage = null;",!

		#; class index
		Write "var _zenClassIdx = new Object();",!
		Write "var _zenIndex = new Array();",!

		&js<
function zenLoad()
{
	try {
		// construct local page object
		zenCreateSVGPageModel();
	
		// register this embedded frame with parent

		// for IE, we have to make sure we can see the zenNotify method
		if (null == self.zenNotify) {
			self.zenNotify = zenNotify;
		}
	
		// Note: use window not *self* or IE will mess up
		if (window.parent && window.parent.zenPageEventHandler) {
			window.parent.zenPageEventHandler('register',window);
		}
	}
	catch(ex) {
		//zenExceptionHandler(ex,arguments,'Error in svgPage:zenLoad');
		alert('Error in svgPage:zenLoad\n' + ex.message);
	}
	
	// invoke svg-page specific callback, if present
	try {
		if (svgPage && svgPage.onSVGLoad) {
			svgPage.onSVGLoad();
		}
	}
	catch(ex) {
		alert('Error in svgPage calling onSVGLoad:zenLoad\n' + ex.message);
	}
}

// This callback is called when the zenPage object is created.
function zenNotify(page)
{
	// point our zenPage to parent zenPage
	zenPage = page;
	if (!zenPage) {
		alert('svgPage: Unable to find zenPage object.');
		return;
	}

	// find our svgFrame parent
	zenParent = zenPage.getComponent(zenParentIndex);

	if (!zenParent) {
		alert('svgPage: Unable to find svgFrame object.\nzenParentIndex = ' + zenParentIndex);
		return;
	}
	// notify parent component
	zenParent.svgLoadHandler(window);
}

function zenUnload()
{
}
	>

		#; draw out "page" object for this svg page
		Do ..%DrawClassDefinitions()
		Do ..%DrawObjectDefinitions()

		#; invoke callback for additional scripts
		Set tSC = ..%InvokeCallback("%OnDrawSVGScript")

	} // !!!

	Write ..%EndScript(),!

	#; group for defining scaling
	&html<<g id="zenScalingGroup">>

	#; special svg group used for items placed underneath (such as connectors)
	&html<<g id="zenUnderlay"/>>

	#; canvas on which shapes are placed
	#; (must be *before* overlay)
	&html<<g id="zenCanvas">>

	#; inject additional static SVG subclass may want to include
	Set tSC = ..%InvokeCallback("%OnDrawSVGPage")
	&html<</g>>

	#; additional svg group used for overlays (scaled with other shapes)
	&html<<g id="zenOverlay"/>>
	&html<</g>> // end of scaling group

	#; additional svg group used for fixed overlays (not scaled)
	&html<<g id="zenFixedOverlay"/>>

	#; if there is an error, show it here
	If $D(%svgError) {
		Do ##class(%ZEN.Utils).%DisplayErrorSVG(##this,%svgError)
	}
	If (pInline) {
		&html<</svg:svg>>
	}
	Else {
		&html<</svg>>
	}
}

/// Internal Method.<br>
/// This is used to invoke callback methods and trap for errors.
Method %InvokeCallback(pMethod As %String) As %Status
{
	Set $ZT="Trap"
	Set tSC = $zobjmethod(##this,pMethod)
	If $$$ISERR(tSC) Goto Error
	Quit tSC
Error
	Set %svgError = tSC
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,pMethod _ ": " _ $ZE)
	Goto Error
}

/// Draw out client-side class definitions for components on this page.
/// Caller is responsible for drawing enclosing script tags.
Method %DrawClassDefinitions() [ Final ]
{
	#; process list of super classes
	Set tList = ..%GetSuperClassList()
	For n=1:1:$L(tList,",") {
		Set tClass = $P(tList,",",n)
		If (tClass '= "") {
			Do $zobjclassmethod(tClass,"%DrawClassDefinition")
		}
	}
}

/// Construct a list of component super classes of this class 
/// as csv list (include this class as well).<br>
/// This is used at page render-time to build the list of classes
/// needed by the client page.
ClassMethod %GetSuperClassList(ByRef pList) As %String [ CodeMode = objectgenerator, Final ]
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

/// Write out client-side object definitions for components on this page.<br>
/// Caller is responsible for drawing enclosing script tags.
Method %DrawObjectDefinitions() [ Final ]
{
	#; define indices of objects for this page: 
	#; 	index->object,  id->object
	#; 	
	#; 	for an SVG page there is only ONE object-- the page itself

	Write "// ",$TR($J(" ",80)," ","-"),! // separator line
	Write "// Object instances",!
	Write "var _zenIndex = new Array();",!
	Write "var _zenIds = new Object();",!
	Write "var svgPage = null;",!

	#; simplified versions of zenCreate & zenLoadClass
	Write "function zenCreate(cls,index,id) {",!
	Write "zenLoadClass(cls);",!
	Write "var creator = new Function('index','id','var o = new ' + cls + '(index,id); if (index>0) {_zenIndex[index] = o;} if (\'\' != id) { _zenIds[id] = o; } return o;');",!
	Write "return creator(index,id);",!
	Write "}",!

	Write "function zenLoadClass(cls) {",!
	Write "var loader = new Function('return ' + cls + '__Loader();');",!
	Write "loader();",!
	Write "}",!

	Write "// ",$TR($J(" ",80)," ","-"),! // separator line
	Write "function zenCreateSVGPageModel() {",!
	Write "var o = null;",!

	#; first create empty page object

	Set tObj = ##this

	#; normalize class name for client
	Set tCls = $TR($classname(tObj),"%.","__")

	#; instantiate client page object
	Set index = 1
	Set id = ""

	Write "svgPage = zenCreate('"_tCls_"',",index,",'",$ZCVT(id,"O","JS"),"');",!

	#; now initialize the properties for the page object
	Set index = 1
	Write !,"o = _zenIndex[",index,"];",!
	Do ..%DrawObjectProperties()
	
	Write "}",!
}

/// Callback method.
/// If defined, this provides a way for a subclass to add static SVG content
/// to the svgPage.
Method %OnDrawSVGPage() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Return string used to include a CSS file
/// [Previously private]
ClassMethod %LinkCSS(pFile As %String) As %String [ CodeMode = expression ]
{
"<?xml-stylesheet type=""text/css"" href="""_pFile_"""?>"
}

/// Return string used to include a script file
/// [Previously private]
ClassMethod %LinkScript(pFile As %String) As %String [ CodeMode = expression ]
{
"<script type=""text/ecmascript"" xlink:href="""_pFile_"""/>"
}

/// Write string used to introduce client-side script code
/// [Previously private]
ClassMethod %StartScript() As %String [ CodeMode = expression ]
{
"<script language=""text/javascript""><![CDATA["
}

/// Write string used to end client-side script code
/// [Previously private]
ClassMethod %EndScript() As %String [ CodeMode = expression ]
{
"]]></script>"
}

/// This method writes out all SVG Defs defined by ZEN library
/// components.
ClassMethod %DrawSVGDefs() [ CodeMode = objectgenerator ]
{
	Set tSC = $$$OK
	
	Do {
		#; write out defs defined by *this* class
		Do %code.WriteLine(" Do ..%DrawSVGDef()")
		
		#; find all subclasses of svgComponent
		#; !!! this means that svgPage has to be recompiled...
		Set tZENLIB = "%ZEN.SVGComponent."
		Set tList = ""
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
		Set tSC = tRS.%Execute("%ZEN.SVGComponent.svgComponent")
		If $$$ISERR(tSC) Quit
		While (tRS.%Next()) {
			Set tClass = tRS.Data("Name")
			Set:($E(tClass,1,$L(tZENLIB))=tZENLIB) tClass = $P(tClass,".",$L(tClass,"."))
			Set tList = tList _ $S(tList="":"",1:",") _ """"_ tClass _ """"
		}

		Set tRS = ""
		Do %code.WriteLine(" For tClass = " _ tList _ " {")
		Do %code.WriteLine("  Set:(tClass'[""."") tClass="""_tZENLIB_"""_tClass")
		Do %code.WriteLine("  For n=1:1:$$$defMemberKeyGet(tClass,$$$cCLASSxdata,""SVGDef"",$$$cXDATAdata) {")
		Do %code.WriteLine("   Write $$$defMemberArrayGet(tClass,$$$cCLASSxdata,""SVGDef"",$$$cXDATAdata,n),!")
		Do %code.WriteLine("  }")
		Do %code.WriteLine(" }")

	} While(0)

	Quit tSC
}

/// Write out SVG/CSS style sheet defined for this component<br>
/// This is based on the XData block, SVGStyle.
ClassMethod %DrawStyleSVG() [ CodeMode = objectgenerator, GenerateAfter = %OnDrawStyleSVG ]
{
	#; let utility class handle generation
	Do ##class(%ZEN.Generator).%GenerateStyleSheet("SVGStyle")

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnDrawStyleSVG",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Do ..%OnDrawStyleSVG()")
	}
	Quit $$$OK
}

/// Write out SVG defs defined for this component<br>
/// This is based on the XData block, SVGDef.
ClassMethod %DrawSVGDef() [ CodeMode = objectgenerator, GenerateAfter = %OnDrawSVGDef ]
{
	#; let utility class handle generation
	Do ##class(%ZEN.Generator).%GenerateStyleSheet("SVGDef")

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnDrawSVGDef",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Do ..%OnDrawSVGDef()")
	}
	Quit $$$OK
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status [ Abstract ]
{
}

/// Callback method called when drawing the SVG defs for this page.
ClassMethod %OnDrawSVGDef() As %Status [ Abstract ]
{
}

/// Callback for adding scripts to this SVG page.
ClassMethod %OnDrawSVGScript() As %Status
{
	Quit $$$OK
}

/// This method is called when this svgPage is loaded.
ClientMethod onSVGLoad() [ Language = javascript ]
{
}

/// Internal method.<br>
/// Get the CRC for this class.
/// This is used to test for client/server mismatch issues. This needs to be a method
/// to avoid class compiler issues.
ClassMethod %GetClassCRC() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %DrawClassDefinition, Internal ]
{
	Set tCRC = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"CRC"))
	Do %code.WriteLine(" Quit " _ $$$quote(tCRC))
	Quit $$$OK
}

}
