/// Application definition for ZENMVC test pages.
Class ZENMVC.MVCApplication Extends %ZEN.application
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "Zen MVC Test Suite";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "ZENMVC.MVCMasterDetail.cls";

/// example of customized style sheet for application
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

#intro {
	font-family: arial;
	color: darkblue;
	font-size: 1.2em;
	margin: 10px;
}

/* Column labels for dynaGrid. */
table.dynaGrid th.dynaGridLabel,
table.dynaGrid th.dynaGridRow,
table.dynaGrid th.dynaGridColumn {
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.dynaGrid th.dynaGridLabel:hover,
table.dynaGrid th.dynaGridRow:hover,
table.dynaGrid th.dynaGridColumn:hover {
	color: white;
	background: #F0F0F0;
	background-image: url(images/grad-gray2-10x100.png);
	background-repeat: repeat-x;
}

/* descriptive text */
.msg {
	font-size: 0.8em;
	color: darkblue;
	width: 500px;
	padding-top: 3px;
	padding-bottom: 10px;
}

.msg:first-letter {
	font-size: 0.9em;
	font-weight: bold;
}

</style>
}

}

