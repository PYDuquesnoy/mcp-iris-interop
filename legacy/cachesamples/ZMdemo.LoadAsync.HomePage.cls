/// Created using the page template: Default
Class ZMdemo.LoadAsync.HomePage Extends %ZEN.Mojo.basePage
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZMdemo.LoadAsync.Application";

/// Displayed name of this page.
Parameter PAGENAME = "HomePage";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// List of JSON providers created for this page.
/// Used by contentProvider.
Parameter PROVIDERLIST = "data,layout";

/// Starting template class for this page
/// Used by contentProvider.
/// This is overriden by application settings, of provided.
Parameter TEMPLATECLASS = "ZMdemo.LoadAsync.baseTemplate";

/// Comma-separated list of additional CSS3 include files for the page.
/// If this is defined *and* this page is using CSS3, then the CSSINCLUDES parameter is ignored.
/// If this is not defined *and* this page is using CSS3, then the CSSINCLUDES parameter is used.
Parameter CSSINCLUDES As STRING = "jquery.mobile-1.3.2.min.css";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "jquery-1.10.2.min.js,jquery.mobile-1.3.2.min.js";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
	.ui-listview-filter {
		margin: 0px;
	}
</style>
}

/// This XML block defines the contents of this pane.
XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen"
xmlns:mojo="http://www.intersystems.com/zen/mojo"
layout="none">

<mojo:documentView id="mainView"
developerMode="true" 
initialDocumentKey="home"
initialLayoutKey="home"
maxPanels="15"
ongetlayout = "return zenPage.getContent('layout',key,criteria);"
ongetdata = "return zenPage.getContent('data',key,criteria);"
>
<mojo:jQM-1.3.2-PageManager jQueryAnimation="fade" onPageShow="zenPage.onPageShow(layoutkey,documentkey);">
<mojo:jQM-1.3.2-Helper/>
<mojo:HTML5Helper/>
</mojo:jQM-1.3.2-PageManager>
</mojo:documentView>

</pane>
}

ClientMethod onPageShow(layoutkey, documentkey) [ Language = javascript ]
{
}

/// This callback is called at the start of the HTML HEAD section of the page (just after the title).<br/>
/// It allows a page to write out meta tags, if desired.
/// (default implementation is a simple expression).
Method %OnDrawHTMLMeta() As %Status
{
	// Make it so that, when the user has selected IE compatibility mode, we ignore it and use the most recent IE version available
	//Write "<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"" />"
	// turn off unless this is actually mobile
	Write "<meta name=""viewport"" content=""width=device-width, initial-scale=1.0,maximum-scale=1, user-scalable=no""/>"
	Quit $$$OK
}

}

