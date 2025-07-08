/// This is the home page of the <b>Mojo HTML5 Plugin Demo</b>.
/// <p>The <class>%ZEN.Mojo.Plugin.HTML5Helper</class> is a helper plugin, which is always used in conjunction with a page manager plugin.</p>
/// <p>In this demo a Dojo-based Mojo application is enriched with HTML5 elements.</p>
Class ZMdemo.html5.HomePage Extends %ZEN.Mojo.basePage
{

/// Class name of application this page belongs to.
/// This is set by the %OnCreateApplication method.
Parameter APPLICATION = "ZMdemo.html5.Application";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// Starting template class for this page
/// Used by contentProvider.
/// This is overriden by application settings, if provided.
Parameter TEMPLATECLASS = "ZMdemo.html5.baseTemplate";

/// Comma-separated list of additional CSS3 include files for the page.
/// If this is defined *and* this page is using CSS3, then the CSSINCLUDES parameter is ignored.
/// If this is not defined *and* this page is using CSS3, then the CSSINCLUDES parameter is used.
Parameter CSSINCLUDES As STRING = "dojo-release-1-9-1/dijit/themes/claro/claro.css";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "dojo-release-1-9-1/dojo/dojo.js";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* Style definitions for the proper operation of the Dojo Plugin */
.dvDocument {
	width: 100%;
	height: 100%;
}

.dvEnclosingClass iframe {
	position:relative;
}

.dvEnclosingClass {
	border: none;
}

#zMojoContentGroup {
	border:none;
}
/* End of style definitions of the Dojo Plugin */

.contentHeader {
	height:60px;
	line-height:60px;
	padding: 0px;

	background-image: url(images/zentitle.jpg);
	background-repeat: no-repeat;
	background-position: left;
	background-color: #c5d6d6;

	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
	vertical-align: middle;

	color: rgb(53,107,141);
}

/* Style settings for the menu buttons of the left menu pane */
.divMenuItem {
	position: relative;
	font-size: 24px;
	font-family: arial;
	font-style: normal;
	font-weight: bold;
	text-decoration: none;

	background: #E0E0F0;
	border: 1px solid #E0E0F0;
	height: 60px;
	margin: 5px;

	color: #444;
}

.divMenuItem:hover {
	background-color: #FFEEAA;
}

.divMenuItemSelected, .divMenuItemSelected:hover {
	background-color: rgb(53,107,141);
	color: white;
}

.imageMenuItem {
	position: absolute;
	width: 32px;
	height: 32px;
	
	margin: 14px 5px;
}

.titleMenuItem {
	position: relative;
	line-height: 60px;
	text-align: left;
	vertical-align: middle;
	
	padding-left: 50px;
}
/* End of style settings for the menu buttons */

/* HTML range input customization */
input[type=range] {
	-webkit-appearance: none;
	width: 200px;

	/*fix for FF unable to apply focus style bug */
	border: 1px solid white;
}

input[type=range]::-webkit-slider-runnable-track {
	width: 200px;
	height: 6px;
	background-image: url(images/docindexgradient.png);
	background-repeat: repeat-y;
	border: none;
	border-radius: 3px;
}
input[type=range]::-moz-range-track {
	width: 200px;
	height: 6px;
	background-image: url(images/docindexgradient.png);
	background-repeat: repeat-y;
	border: none;
	border-radius: 3px;
}
input[type=range]::-ms-track {
	width: 200px;
	height: 6px;
	background-image: url(images/docindexgradient.png);
	background-repeat: repeat-y;
	border: none;
	border-radius: 3px;
}

input[type=range]::-webkit-slider-thumb {
    -webkit-appearance: none;
    border: none;
    height: 16px;
    width: 16px;
    background-image: url(images/MacGreenDotB.png);
    margin-top: -5px;
}
input[type=range]::-moz-range-thumb {
    -webkit-appearance: none;
    border: none;
    height: 16px;
    width: 16px;
    background-image: url(images/MacGreenDotB.png);
    margin-top: -5px;
}
input[type=range]::-ms-thumb {
    -webkit-appearance: none;
    border: none;
    height: 16px;
    width: 16px;
    background-image: url(images/MacGreenDotB.png);
    margin-top: -5px;
}

input[type=range]:focus {
    outline: none;
}

/* hide the outline behind the border in Firefox - workaround of a known bug */
input[type=range]:-moz-focusring{
    outline: 1px solid white;
    outline-offset: -1px;
}
/* End of HTML range input customization */

.tableDemo {
	border: 1px solid black;
	font-size: 1em;
}

.tableDemo tfoot tr td {
	background-color:rgb(53,107,141);
	color:white;
	font-weight:bold;
}

.tPerson tr td {
	padding: 5px;
}

.tPerson td label {
	font-weight: bold;
}
</style>
}

/// This XML block defines the contents of this page.
/// Subclasses will replace this.
XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane 
xmlns="http://www.intersystems.com/zen" 
xmlns:mojo="http://www.intersystems.com/zen/mojo"
layout="none">

<!-- 
	Outer document view, containing the header, the left menu and only a placeholder for the actual content.
	In this implementation it never changes the document- or the layout key, as both the header and the menu are "static".
-->
<mojo:documentView id="mainView"
developerMode="false" 
initialDocumentKey="home"
initialLayoutKey="home"
maxPanels="15"
ongetlayout = "return zenPage.getContent('layout',key,criteria);"
ongetdata = "return zenPage.getContent('data',key,criteria);"
>
<mojo:dojo-1.9.1-PageManager onPageShow="return zenPage.onPageShow(key);">
<mojo:dojo-1.9.1-DijitHelper />
<mojo:HTML5Helper/>
<mojo:mojoDefaultHelper/>
</mojo:dojo-1.9.1-PageManager>
</mojo:documentView>

<!-- 
	Inner document view, implementing the actual content of the page (except header and left menu).
	Its content is injected into a placeholder of the outer document view. This is done by the content template.
-->
<mojo:documentView id="centerView"
developerMode="false" 
initialDocumentKey="empty"
initialLayoutKey="empty"
maxPanels="15"
ongetlayout = "return zenPage.getContent('layout',key,criteria);"
ongetdata = "return zenPage.getContent('data',key,criteria);"
>
<mojo:dojo-1.9.1-PageManager onPageShow="return zenPage.onPageShow(key);">
<mojo:dojo-1.9.1-DijitHelper/>
<mojo:HTML5Helper/>
<mojo:mojoDefaultHelper/>
</mojo:dojo-1.9.1-PageManager>
</mojo:documentView>
</pane>
}

/// Adjust size of components within the content area.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var mainView = zen('mainView');
	if (mainView) {
		mainView.setSize(width, height);

		var mainDiv = mainView.getEnclosingDiv();
		mainDiv.style.top =  '0px';
		mainDiv.style.left = '0px';
	}
}

/// Triggers the automatic resize of the topmost Dojo container every time, 
/// when the page is first loaded or whenever it is resized. 
ClientMethod onlayoutHandler() [ Language = javascript ]
{
	this.invokeSuper('onlayoutHandler',arguments);
	
	var topContainer = zen('mainView').getItemByKey('top-container');
	if (topContainer) {
		topContainer.$dojoItem.resize();
	}
}

/// Dispatches <var>onPageShow</var> event handling to the current content template.
/// <p>The content template has to implement the <var>pageShow()</var> JavaScript function.</p>
ClientMethod onPageShow(key) [ Language = javascript ]
{
	// dispatch to template object
	var template = this.getTemplate();
	return (template&&template.pageShow) ? template.pageShow(key) : null;
}

/// In non-embed mode, maximum width of page content area.
ClientMethod getMaxContentWidth() [ Language = javascript ]
{
	return 3000;
}

}

