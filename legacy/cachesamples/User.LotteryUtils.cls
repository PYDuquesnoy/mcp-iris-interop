Include (%occInclude, %cspInclude)

IncludeGenerator %occInclude

/// The <CLASS>LotteryUtils</CLASS> class contains a number of common methods used by 
/// the pages within the CSP Lottery Example application.
Class User.LotteryUtils [ Abstract, Not ProcedureBlock ]
{

Method onPrePage()
{
 ; perform page authorization
 ; if user is not logged in, jump to Error Page
 Quit $$$OK
}

/// Write out the HTML to display the common title used by pages within the 
/// Lottery example.
ClassMethod displayTitle() As %String
{
 &html<<p align="center"><img src="lotterylogo.jpg"></p><hr>>
 Quit ""
}

/// Write out the HTML to display the common message display for 
/// unauthorized access within the Lottery example.
ClassMethod displayUnauthorized() As %String
{
 &html<
 <p align="center">
 <font face="Lucida Sans" color="yellow"  size="+3">
 <font color="red"><b>Unauthorized access.</b></font></p>
 <p align="center">
 You must <a href='#(##class(%CSP.Page).Link("lottery.csp"))#'>login</a> to visit this page.</p>
 </font>
 >
 Quit ""
}

}

