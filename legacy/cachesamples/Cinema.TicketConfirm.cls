Class Cinema.TicketConfirm Extends (%CSP.Page, Cinema.Utils) [ Inheritance = right, Not ProcedureBlock ]
{

ClassMethod OnPage() As %Status
{
 Write "<HTML>",!
 Write "<HEAD>",!
 Write "</HEAD>",!
 Write "<BODY>",!
 If $data(%session.Data("Order")) {
	Do ..CompleteOrder()
	Write "Your order was processed successfully. ",!
	Write "Thank you for using Cach&eacute; Cinema!<br><br>",!
	If $G(%request.Data("OrderEmail",1))'="" {
		Write ..SendEmail( %request.Data("OrderEmail",1),
		"Your tickets have been ordered"),!
 	}
 } Else {
 	Write "Your order expired before it was completed.",!
 }
 Write "</BODY>",!
 Write "</HTML>",!
 Quit $$$OK
}

/// Event handler for <B>PREHTTP</B> event: this is invoked before
/// the HTTP headers for a CSP page have been sent.  All changes to the
/// <class>%CSPResponse</class> class, such as adding cookies, HTTP headers,
/// setting the content type etc. must be made from within the OnPreHTTP() method.
/// Return <B>0</B> to prevent <method>OnPage</method> from being called.
ClassMethod OnPreHTTP() As %Boolean
{
 If $data(%session.Data("Order")) {
	New ord,itm,cat
	Set ord = ##class(Cinema.TicketOrder).%OpenId(%session.Data("Order"))
	Set itm = ord.Items.GetAt(1)
	Set cat = itm.Show.Film.Category.%Id()

	// Put a cookie on the users computer
	Set Expires = +$H + 7
	Set Expires = $ZD(Expires,11) _ ", " _ $ZD(Expires,2) _ " 00:00:00 GMT"
	Do %response.SetCookie("CacheCinemaLastCategory", cat, Expires, "/")
 }
 
 Quit 1
}

}

