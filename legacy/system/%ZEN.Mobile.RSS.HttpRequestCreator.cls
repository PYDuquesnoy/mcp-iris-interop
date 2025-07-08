/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base callback class to allow an <class>Application</class> to perform
/// feed-specific initialization of a <class>%Net.HttpRequest</class> object.
Class %ZEN.Mobile.RSS.HttpRequestCreator [ Abstract, Deprecated, System = 3 ]
{

/// Customizable callback that should create a <class>%Net.HttpRequest</class>
/// object specific to the <class>Application</class> and <class>Feed</class>
/// specified by <var>pApplication</var> and <var>pFeedURL</var>.
ClassMethod CreateHttpRequest(pApplication As %String = "", pFeedURL As %String = "", Output pHttpRequest As %Net.HttpRequest) As %Status
{
	Set pHttpRequest = ##class(%Net.HttpRequest).%New()
	Quit $$$OK
}

}
