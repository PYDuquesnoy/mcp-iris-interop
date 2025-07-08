/// Removes the cookie used by the Cache Cinema sample application
Class Cinema.RemoveCookie Extends %CSP.Page [ Not ProcedureBlock ]
{

ClassMethod OnPage() As %Status
{
 &html<
 <html><head></head>
 <body bgcolor="#FFFFFF"><p><img src="CacheCinemaLogo.gif" width="273" height="70"> </p>
 >
 
 If (%request.Data("Action",1) = "R") {
 	Write "<b>Cookie Removed</b>",!
 } ElseIf ($D(%request.Cookies("CacheCinemaLastCategory"))) {
	&html< 
	<form method="post" action='Cinema.RemoveCookie.cls?Action=R' name="RemoveForm">
		<table cellpadding="5"> 
			<tr>
			<td valign="bottom">To remove the cookie used by the Cache Cinema sample application click</td>
			<td valign="bottom"><input type="submit" name="RemoveButton" value="Remove Cookie"></td> 
			</tr>
		</table>
	</form>
	>
 } Else {
	Write "<b>No cookie found</b>",!
 }
 
 &html<
 </body></html>
 >
 Quit 1
}

/// Event handler for <B>PREHTTP</B> event: this is invoked before
/// the HTTP headers for a CSP page have been sent.  All changes to the
/// <class>%CSP.Response</class> class, such as adding cookies, HTTP headers,
/// setting the content type etc. must be made from within the OnPreHTTP() method.
/// Also changes to the state of the CSP application such as changing %session.Preserve,
/// %session.EndSession or %session.AppTimeout must be made within the OnPreHTTP() method.
/// Return <B>0</B> to prevent <method>OnPage</method> from being called.
ClassMethod OnPreHTTP() As %Boolean
{
 If (%request.Data("Action",1) = "R") {
	// Delete the cookie by setting the expiration date to yesterday
	Set Expires = +$H - 1
	Set Expires = $ZD(Expires,11) _ ", " _ $ZD(Expires,2) _ " 00:00:00 GMT"
	Do %response.SetCookie("CacheCinemaLastCategory", "", Expires, "/")
 }
 Quit 1
}

}

