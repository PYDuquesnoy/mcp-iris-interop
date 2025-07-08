/// application showing how to load data in an asyncronous way
Class ZMdemo.LoadAsync.Application Extends %ZEN.Mojo.baseApplication
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "load async";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE;

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// Return an object containing the various configured settings for the portal.
ClassMethod %GetAppSettings(pPage As %String = "", pMode As %String = "") As %ZEN.proxyObject
{
	
	Set tInfo = ##class(%ZEN.proxyObject).%New()

	// initial templateClass
	Set tInfo.templateClass = ""

	// names
	Set tInfo.nameApplication = "jQM Load Async Demo"

	// overrides

	Quit tInfo
}

/// Draw the contents of the background div section (this is purely decorative)
/// <var>pPage</var> is the calling page's LOGICALNAME.
ClassMethod ZMojoDrawBackgroundDiv(pPage As %String, pMode As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the quick links section.
/// <var>pPage</var> is the calling page's LOGICALNAME.
ClassMethod ZMojoDrawQuickLinks(pPage As %String, pMode As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the basic section.
/// <var>pPage</var> is the calling page's LOGICALNAME.
ClassMethod ZMojoDrawBasicHelp(pPage As %String, pMode As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the footer group section.
/// <var>pPage</var> is the calling page's LOGICALNAME.
ClassMethod ZMojoDrawFooterGroup(pPage As %String, pMode As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}

