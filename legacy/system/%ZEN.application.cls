/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

IncludeGenerator %ZEN.Utils

/// This class is used to define a ZEN application.
/// This is an instantiable CSP page.
Class %ZEN.application Extends (%RegisteredObject, %CSP.Page) [ CompileAfter = %ZEN.Generator, Deprecated, Inheritance = right, System = 3 ]
{

/// Optional name of this application.<br/>
/// If not defined, the class name of the application is used.
/// This is used for display purposes within some utilities
/// but it not used at run-time.
Parameter APPLICATIONNAME As STRING;

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE As STRING;

/// Comma-separated list of additional JS include files that should be
/// included for every page within the application.
Parameter JSINCLUDES As STRING;

/// Comma-separated list of additional CSS include files that should be
/// included for every page within the application.<br/>
/// The CSS files will be included <em>after</em> any component style sheets
/// and <em>before</em> styles defined by this application class or the page class.
Parameter CSSINCLUDES As STRING;

/// Comma-separated list of additional CSS3 include files that should be
/// included for every page within the application.<br/>
/// This is used when the page uses CSS3.
/// The CSS files will be included <em>after</em> any component style sheets
/// and <em>before</em> styles defined by this application class or the page class.
Parameter CSS3INCLUDES As STRING;

/// Comma-separated list of User class packages whose HTML class
/// and style definitions are in pre-generated include files.
/// These include files will be used by every page within the application.
Parameter USERPACKAGES As STRING;

/// Comma-separated list of User class packages whose SVG class
/// and style definitions are in pre-generated include files.
/// These include files will be used by every applicable page within the application.
Parameter USERSVGPACKAGES As STRING;

/// Status code for this object.
/// If a page encounters errors when trying to create the
/// application object instance, this property will be set to
/// an error code.
Property %StatusCode As %Status;

/// Defines application-wide overrides for style sheets.
/// Any styles defined here will be rendered as part of
/// every page within the application.
XData Style
{
}

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	/// Redirect to home page for application
	If (..#HOMEPAGE '= "") {
		Set %response.Redirect = ..#HOMEPAGE
		Quit 1
	}

	Quit 1
}

/// Return the display name of this application class.
ClassMethod %GetApplicationName()
{
	Quit $S(..#APPLICATIONNAME="":..%ClassName(1),1:..#APPLICATIONNAME)
}

/// Return the USERPACKAGE and USERSVGPACKAGE lists defined for this application class.
ClassMethod %GetUserPackages(Output pUserPackages As %String, Output pUserSVGPackages As %String)
{
	Set pUserPackages = ..#USERPACKAGES
	Set pUserSVGPackages = ..#USERSVGPACKAGES
}

/// Default OnPage handler-- only called if no HOMEPAGE
/// is defined for this application.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tAppName = ..%GetApplicationName()
	Set msgApp = $$$TextHTML("ZEN Application:","%ZEN")
	Set msgNoHome = $$$TextHTML("There is no home page defined for this application.","%ZEN")

	&html<
	<html>
	<head>
	<title>#($ZCVT(tAppName,"O","HTML"))#</title>
	</head>
	<body style="background: #AADDFF; font-family: verdana;">
	<br/>
	<div style="text-align: center; font-size: 1.2em;">#(msgApp)# <b>#($ZCVT(tAppName,"O","HTML"))#</b></div>
	<br/>
	<div style="text-align: center;">#(msgNoHome)#</div>
	</body>
	</html>
	>

	Quit $$$OK
}

/// Write out HTML/CSS style sheet defined for this application.<br/>
/// This is based on the XData block, Style.<br/>
/// This style sheet is used to provide application-wide
/// overrides for styles.
ClassMethod %DrawStyleHTML(pSuper As %Boolean = 0, pCSSLevel As %Integer = 2) [ CodeMode = objectgenerator ]
{
	#; write out links to app-wide JS include files
	#; (only for *this* class, not super classes)
	Set tIncludeList = $G(%parameter("JSINCLUDES"))
	If (tIncludeList'="") {
		Do %code.WriteLine(" If (pSuper=0) {")
		Do %code.WriteLine("  Write ""<!-- application-wide js includes -->"",!")
		For n = 1:1:$L(tIncludeList,",") {
			Set tFile = $P(tIncludeList,",",n)
			If (tFile '= "") {
				Do %code.WriteLine("  Write ..%LinkScript("_$$$quote(tFile)_"),!")
			}
		}
		Do %code.WriteLine(" }")
	}

	#; write out links to app-wide style sheets
	#; (only for *this* class, not super classes)
	If ($G(%parameter("CSS3INCLUDES"))'="") {
		Do %code.WriteLine(" If (pCSSLevel>=3) {")
		Set tIncludeList = $G(%parameter("CSS3INCLUDES"))
		If (tIncludeList'="") {
			Do %code.WriteLine(" If (pSuper=0) {")
			Do %code.WriteLine("  Write ""<!-- application-wide css includes -->"",!")
			For n = 1:1:$L(tIncludeList,",") {
				Set tFile = $P(tIncludeList,",",n)
				If (tFile '= "") {
					Do %code.WriteLine("  Write ..%LinkCSS("_$$$quote(tFile)_"),!")
				}
			}
			Do %code.WriteLine(" }")
		}
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Else {")
		Set tIncludeList = $G(%parameter("CSSINCLUDES"))
		If (tIncludeList'="") {
			Do %code.WriteLine(" If (pSuper=0) {")
			Do %code.WriteLine("  Write ""<!-- application-wide css includes -->"",!")
			For n = 1:1:$L(tIncludeList,",") {
				Set tFile = $P(tIncludeList,",",n)
				If (tFile '= "") {
					Do %code.WriteLine("  Write ..%LinkCSS("_$$$quote(tFile)_"),!")
				}
			}
			Do %code.WriteLine(" }")
		}
		Do %code.WriteLine(" }")
	}
	Else {
		Set tIncludeList = $G(%parameter("CSSINCLUDES"))
		If (tIncludeList'="") {
			Do %code.WriteLine(" If (pSuper=0) {")
			Do %code.WriteLine("  Write ""<!-- application-wide css includes -->"",!")
			For n = 1:1:$L(tIncludeList,",") {
				Set tFile = $P(tIncludeList,",",n)
				If (tFile '= "") {
					Do %code.WriteLine("  Write ..%LinkCSS("_$$$quote(tFile)_"),!")
				}
			}
			Do %code.WriteLine(" }")
		}
	}

	#; write out inherited styles (ignore CSSINCLUDES for super classes)
	If (%class.Name '= "%ZEN.application") {
		Do %code.WriteLine(" Do ##super(1,pCSSLevel)")
	}

	#; write out contents of our style block
	#; let utility class handle generation
	// test if there is a CSS3Style block declared locally
	Set tHasCSS3 = ##class(%ZEN.Generator).%DoesXDataExist("CSS3Style",1)

	If ('tHasCSS3) {
		#; use CSS2 for both cases
		Set tSC = ##class(%ZEN.Generator).%GenerateStyleSheet("Style")
	}
	Else {
		#; use CSS3 or CSS2 depending on level
		Do %code.WriteLine(" If (+pCSSLevel >= 3) {")
		Set tSC = ##class(%ZEN.Generator).%GenerateStyleSheet("CSS3Style")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Else {")
		Set tSC = ##class(%ZEN.Generator).%GenerateStyleSheet("Style")
		Do %code.WriteLine(" }")
	}
	Quit tSC
}

/// Return string used to include a CSS file.
/// [Previously private]
ClassMethod %LinkCSS(pFile As %String) As %String [ CodeMode = expression ]
{
"<link rel=""stylesheet"" type=""text/css"" href="""_pFile_"""/>"
}

/// Return string used to include a script file.
/// [Previously private]
ClassMethod %LinkScript(pFile As %String) As %String [ CodeMode = expression ]
{
"<script type=""text/javascript"" src="""_pFile_"""></script>"
}

/// Applications can implement this callback method in order to define a set of
/// client-side resources: javascript strings that have been localized.<br/>
/// This is the same as the Zen page callback method except that
/// it is shared by all pages within an application.<br/>
/// This method should fill in the array <var>pResources</var> with a set of 
/// localized strings, indexed by resource id:<br/>
/// <example>
///  Set pResources("MyId") = $$$Text("Some string")
/// </example>
/// Javascript methods can refer to these resources using the helper function zenGetResource:
/// <example language="javascript">
///  alert(zenText('MyId'));
/// </example>
/// Zen defines a set of built-in resource strings using this mechanism. These
/// have a "zen" prefix to keep them seperate from user ids.<br/>
/// Be sure to define the <parameter>DOMAIN</parameter> for your
/// application class if you override this method.
Method %OnGetJSResources(ByRef pResources As %String) As %Status
{
	Quit $$$OK
}

}
