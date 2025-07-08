/// This is the application class for the Zen demonstration application.
Class ZENDemo.Application Extends %ZEN.application
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "Zen Demo Application";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "ZENDemo.Home.cls";

/// If defined, this is a comma-delimited list of names of class
/// packages that contain user-define Zen components whose HTML definitions
/// should come from a pre-generated include file.
Parameter USERPACKAGES;

/// If defined, this is a comma-delimited list of CSS style sheet files
/// that will be included within every page of this application.
Parameter CSSINCLUDES;

/// If defined, this is a comma-delimited list of JavaScript files
/// that will be included within every page of this application.
Parameter JSINCLUDES;

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">

/* default body style */
body {
	font-family: arial;
	background: #F0F0F0;
}

/* descriptive text */
#description {
	color: black;
	font-size: 1.2em;
	padding: 5px;
	padding-top: 10px;
	padding-bottom: 10px;
}

#description:first-letter {
	font-size: 1.5em;
}

.locatorBarTable td {
	background: rgb(47,98,128);
	background-image: none;
	border-bottom: 1px solid darkblue;
	padding-bottom: 1px;
	color: white;
}

.locatorBarLinks {
	color: white;
}

.locatorBarLinks a {
	color: white;
}

.locatorBarLinks a:visited {
	color: white;
}

.locatorBarLinks a:hover {
	color: red;
	background: #FFFAE7;
}

</style>
}

/// Return an array of quick links to be displayed by the locator bar
/// within this application.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	Set pLinks("Home") = "ZENDemo.Home.cls"
	Set pLinks("Expense Calculator") = "ZENDemo.ExpenseCalculator.cls"
	Set pLinks("MVC Master Detail") = "ZENMVC.MVCMasterDetail.cls"
	Set pLinks("MVC Chart") = "ZENMVC.MVCChart.cls"
	Set pLinks("MVC Meters") = "ZENMVC.MVCMeters.cls"
	Set pLinks("MVC Form") = "ZENMVC.MVCForm.cls"
	Set pLinks("Test Suite") = "ZENTest.HomePage.cls"
	Set pLinks("Controls") = "ZENDemo.ControlTest.cls"
	Set pLinks("Methods") = "ZENDemo.MethodTest.cls"
	Quit $$$OK
}

}

