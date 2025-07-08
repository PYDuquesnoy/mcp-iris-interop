Class Cinema.Utils Extends (%CSP.SessionEvents, %CSP.Page) [ Inheritance = right, Not ProcedureBlock ]
{

ClassMethod AddShow(ShowID As %Library.String)
{
 // Get an order object
 New itm,ord,shw
 If $data(%session.Data("Order")) {
	Set ord = ##class(Cinema.TicketOrder).%OpenId(%session.Data("Order"))
 } Else {
	Set ord=##class(Cinema.TicketOrder).%New()
	Set %session.EventClass = "Cinema.Utils"
 }
 
 // Add an item to the order for this show.
 Set itm=##class(Cinema.TicketItem).%New()
 Set shw=##class(Cinema.Show).%OpenId(ShowID)
 Set itm.Show=shw
 Set itm.TicketOrder=ord
 Set ord.Total=ord.Total
 			+(itm.AdultTickets*itm.Show.Theater.AdultPrice)
 			+(itm.ChildTickets*itm.Show.Theater.ChildPrice)
 
 // Save incomplete order and remember its Id in %session.
 Do ord.%Save()
 Set %session.Data("Order") = ord.%Id()

 // Update Order.csp page 
 &js<parent.Order.location="Order.csp">
}

ClassMethod ChangeQuantity(ItemNum As %Library.Integer, TicketType As %Library.Integer, NewQuantity As %Library.Integer)
{
 If $data(%session.Data("Order")) {
	// Open the current order object
	New itm,ord
	Set ord = ##class(Cinema.TicketOrder).%OpenId(%session.Data("Order"))
	
	// Update quantity
	Set itm=ord.Items.GetAt(ItemNum)
	If TicketType=1 {  
		Set ord.Total=ord.Total+((NewQuantity-itm.AdultTickets)*itm.Show.Theater.AdultPrice)
		Set itm.AdultTickets=NewQuantity
	} Else {  
		Set ord.Total=ord.Total+((NewQuantity-itm.ChildTickets)*itm.Show.Theater.ChildPrice)
		Set itm.ChildTickets=NewQuantity
	}
	
	// Update Order.csp page 
	&js<parent.Order.document.OrderTickets.TotalCharge.value=#(..QuoteJS($FN(ord.Total,"",2)))#;>
	
	// Save incomplete order.
	Do ord.%Save()
 }
}

ClassMethod CompleteOrder()
{
 If $data(%session.Data("Order")) {
	// Open the current order object
	New cat,flm,i,itm,ord
	Set ord = ##class(Cinema.TicketOrder).%OpenId(%session.Data("Order"))
	
	// Update the number of tickets sold for each film in the order
	For i = 1:1:ord.Items.Count() {
		Set itm = ord.Items.GetAt(i)
		Set flm = itm.Show.Film
		Set flm.TicketsSold = flm.TicketsSold + 
			itm.AdultTickets + itm.ChildTickets
		Set cat = flm.Category.%Id()
		Do flm.%Save()
 	}

	// Mark order as complete and save
	Set ord.Complete=1
 	Do ord.%Save()
 	Kill %session.Data("Order")
 }
}

ClassMethod OnEndSession()
{
 If $data(%session.Data("Order")) {
	// Delete the incomplete order
	Do ##class(Cinema.TicketOrder).%DeleteId(%session.Data("Order"))
 	Kill %session.Data("Order")
 }
}

ClassMethod SendEmail(Addr As %Library.String, MessageText As %Library.String) As %Library.String
{
 // To enable email processing, you must:
 //Replace the "**" with the name of your mail server
 //Replace the "*@*" with your own email address, 
 //which will be used as the "from" address
 //Comment out or remove the following Quit statement
 //
 Quit "Unable to send confirmation to " _ Addr _ ".<br>" _
 "In order to send a mail message, " _
 "you must supply a server name and " _
 "email address in the SendEmail method " _
 "of the Cinema.Utils class"
 //
 New Mailer,Msg
 // Create an SMTP object and connect to a server
 Set Mailer = ##class(%Net.SMTP).%New()
 // Fill in the name of your mail server
 Set Mailer.smtpserver = "**"
 // Create a Message object and fill in From, To, Subject
 Set Msg = ##class(%Net.MailMessage).%New()
 // Fill in an email address
 Set Msg.From="**"
 Do Msg.To.Insert(Addr)
 Set Msg.Subject = "Theater Tickets"
 // Add message content
 Do Msg.TextData.Write(MessageText)
 // Send the message and close objects
 Do Mailer.Send(Msg)
 Quit "Email confirmation has been sent to " _ Addr
}

}

