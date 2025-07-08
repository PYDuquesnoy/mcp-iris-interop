/// ZENApp.SampleApp
/// This is a sample application: it is a simple
/// help disk application.
Class ZENApp.SampleApp Extends %ZEN.application
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "Sample Application";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "ZENApp.HelpDesk.cls";

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

.locatorBarSelect {
	color: white;
}

.locatorBarLinks a:hover {
	color: red;
	background: #FFFAE7;
}
</style>
}

}

