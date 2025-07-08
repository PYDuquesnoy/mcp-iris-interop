/// Sample Zen Mojo tutorial page. Use this tutorial after working with <class>ZMbasics.Tutorial1.HomePage</class>.
/// <p>The primary difference from Tutorial 1 is that *this* tutorial demonstrates 
/// the server-side method <method>%OnGetJSONContent</method>.
/// <p>This ZM page class uses the template class <class>ZMbasics.Tutorial2.Template</class>.
/// <p>Next tutorial in the series: <class>ZMbasics.Tutorial3.HomePage</class>.
Class ZMbasics.Tutorial2.HomePage Extends %ZEN.Mojo.basePage
{

/// Name of the default template class that this page uses.
Parameter TEMPLATECLASS = "ZMbasics.Tutorial2.Template";

/// Localization domain; best practice is to always specify this
Parameter DOMAIN = "Zen Mojo Demo";

/// List of server-side JSON providers for ZM to create; each of these can send a JSON string to the client.
/// This works as follows: The parameter is a comma-separated list of strings. 
/// For each string in this list, ZM creates an instance of the associated template class (see TEMPLATECLASS) 
/// and invokes its %OnGetJSONContent() method, passing the PROVIDERLIST list item as the first argument.
/// The method returns a set of JSON strings, which are available on the client.
/// <p>In this example, there is only one JSON provider. 
Parameter PROVIDERLIST = "mainViewData";

/// This XML block defines the contents of the pageContents pane.
XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
xmlns:mojo="http://www.intersystems.com/zen/mojo" layout="none">
<mojo:documentView id="mainView" 
developerMode="true"
ongetdata    ="return zenPage.getContent('mainViewData',key,criteria);" 
ongetlayout  ="return zenPage.getContent('mainViewLayout',key,criteria);">
<mojo:mojoDefaultPageManager>
<mojo:HTML5Helper/>
</mojo:mojoDefaultPageManager>
</mojo:documentView>

</pane>
}

/// Implementation for this page. This method adjusts the size of the documentView components 
/// within the content area based on the current width and height of the screen. 
/// In this case there is only one documentView.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
    // This method should have an if{} block for each component. 
    
    var mainView = zen('mainView');
    if (mainView) {
        mainView.setSize(width, height);
        var mainDiv = mainView.getEnclosingDiv();
        mainDiv.style.top =  '0px';
        mainDiv.style.left = '0px';
    }
}

/// Method override for this page. This method defines the application name,
/// which controls the name shown on the browser tab.
Method %GetAppSettings(pPage As %String = "", pMode As %String = "") As %ZEN.proxyObject
{
    //get most settings from the superclass
    set tInfo = ##super()

    // then override the nameApplication setting -- this affects the browser tab name
    set tInfo.nameApplication = "ZM Tutorial 2"

    quit tInfo
}

XData Style
{
<style type="text/css">

* {
  	font-family: arial;
	margin: 0;
	padding: 0;
}

body {
	position: relative;
	font-family: arial;
	font-size: 12pt;
	background: #F8F8F1;
	overflow: auto;
}

#zMojoHeaderPane {
}

#zMojoForegroundGroup {
	position: relative;
	top: 0px;
	left: 0px;
	border: 1px;
	overflow: hidden;
	padding: 0px;
}

#zMojoFooterGroup {
}


</style>
}

/// This implementation erases the default contents of the header area.
Method ZMojoDrawQuickLinks(pSeed As %String) As %Status [ ZenMethod ]
{
	Quit $$$OK
}

}

