/// Created using the page template: Default
Class ZMdemo.dojo.HomePage Extends %ZEN.Mojo.basePage
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZMdemo.dojo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "DojoHomePage";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// List of JSON providers created for this page.
/// Used by contentProvider.
Parameter PROVIDERLIST = "data,layout";

/// Starting template class for this page
/// Used by contentProvider.
/// This is overriden by application settings, of provided.
Parameter TEMPLATECLASS = "ZMdemo.dojo.baseTemplate";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "dojo-release-1-9-1/dojo/dojo.js,dojo-release-1-9-1/app/dojo_2DChart.js,dojo-release-1-9-1/app/dojo_191Dijit.js";

/// Comma-separated list of additional CSS include files for the page.
/// If this page is using CSS3 then the CSS3INCLUDES parameter is used (if defined).
Parameter CSSINCLUDES As STRING = "dojo-release-1-9-1/dijit/themes/claro/claro.css,dojo-release-1-9-1/gridx/resources/claro/Gridx.css";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
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
.gridx {
	width: 99%;
	height: 300px;
}
.labelAlign50px {
	width: 50px;
	float: left;
    text-align: right;
    margin-right: 5px;
}
.labelAlign75px {
	width: 75px;
	float: left;
    text-align: right;
    margin-right: 5px;
}
.labelAlign140px {
	width: 140px;
	float: left;
	position: relative;
    text-align: right;
    margin-right: 5px;
}
.labelAlign180px {
	width: 180px;
	float: left;
	position: relative;
    text-align: right;
    margin-right: 5px;
}
/*
.gridx {
	width: 99%;
	height: 95px;
}
*/
</style>
}

/// This XML block defines the contents of this pane.
XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane
xmlns="http://www.intersystems.com/zen"
xmlns:mojo="http://www.intersystems.com/zen/mojo"
layout="none"
>

<mojo:documentView
id="mainView"
ongetlayout="return zenPage.getContent('layout',key,criteria);"
ongetdata="return zenPage.getContent('data',key,criteria);"
initialDocumentKey="home"
initialLayoutKey="home"
maxPanels="10"
developerMode="false"
>
<mojo:dojo-1.9.1-PageManager>
<mojo:dojo-1.9.1-DijitHelper/>
<mojo:dojo-1.9.1-2DChartHelper/>
<mojo:dojoGridX-1.3.0-Helper/>
<mojo:HTML5Helper/>
<mojo:mojoDefaultHelper/>
</mojo:dojo-1.9.1-PageManager>
</mojo:documentView>

</pane>
}

/// Implementation for this page. This method adjusts the size of components 
/// within the content area based on the current width and height of the screen. 
/// In this case there is only one component.
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

ClientMethod onlayoutHandler() [ Language = javascript ]
{
	this.invokeSuper('onlayoutHandler',arguments);
	
	var topContainer = zen('mainView').getItemByKey('layoutContainer-1');
	
	if (topContainer) {
		topContainer.$dojoItem.resize();
	}
}

/// In non-embed mode, maximum width of page content area.
ClientMethod getMaxContentWidth() [ Language = javascript ]
{
	return 3000;
}

}

