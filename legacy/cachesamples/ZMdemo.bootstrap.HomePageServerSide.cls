/// Created using the page template: Default
Class ZMdemo.bootstrap.HomePageServerSide Extends %ZEN.Mojo.basePage
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZMdemo.bootstrap.Application";

Parameter AUTOLOGOUT As BOOLEAN = 0;

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
Parameter TEMPLATECLASS = "ZMdemo.bootstrap.baseTemplateServerSide";

/// Comma-separated list of additional CSS3 include files for the page.
/// If this is defined *and* this page is using CSS3, then the CSSINCLUDES parameter is ignored.
/// If this is not defined *and* this page is using CSS3, then the CSSINCLUDES parameter is used.
Parameter CSSINCLUDES As STRING = "bootstrap-3-3-5/dist/css/bootstrap.min.css";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "jquery-1.11.3.min.js,bootstrap-3-3-5/dist/js/bootstrap.min.js";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
	.headerDiv {
		width: 100%;
		height: 50px;
		line-height: 40px;
		background-color: black;
		color: white;
		padding: 3px 10px;
		font-size: 1.5em;
	}
	.headerDiv .header {
		display: inline-block;
		text-align: center;
		width: 80%;
		position: absolute;
		left: 10%;
		z-index:-1;
	}
	.navbar-header {
	    float: left;
	    padding: 15px;
	    text-align: center;
	    width: 100%;
	}
	.navbar-brand {float:none;}
	.main-grid {
		width: 80%;
		margin: 0 auto;
		margin-top: 70px;
	}
	#detail-form {
		width: 50%;
	}
	.modal-header {
		border-bottom:none;
	}
	.modal-title {
		text-align: left;
	}
	.modal-body button {
		margin-right: 10px;
	}
	.modal-footer {
		border-top:none;
	}
	.modal-dialog {
  		padding-top: 15%;
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
developerMode="false" 
initialDocumentKey="home"
initialLayoutKey="home"
ongetlayout = "return zenPage.getContent('layout',key,criteria);"
ongetdata = "return zenPage.getContent('data',key,criteria);"
>

<mojo:mojoDefaultPageManager>
<mojo:bootstrap-3.3.x-Helper/>
<mojo:HTML5Helper/>
<mojo:mojoDefaultHelper/>
</mojo:mojoDefaultPageManager>
</mojo:documentView>

</pane>
}

ClientMethod onPageShow(layoutkey, documentkey) [ Language = javascript ]
{
}

/// Implementation for this page. This method adjusts the size of components 
/// within the content area based on the current width and height of the screen. 
/// In this case there is only one component.
/// Adjust size of components within the content area.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var view = zen('mainView');
	if (view) {
		view.setSize(width,height);
	}
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

/// If true, only show the core content.
Property embedded As %ZEN.Datatype.boolean(ZENURL = "EMBED") [ InitialExpression = 1 ];

}

