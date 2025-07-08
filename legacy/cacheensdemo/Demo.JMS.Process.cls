Class Demo.JMS.Process Extends Ens.BusinessProcess
{

/// Handle a 'Request'
Method OnRequest(request As EnsLib.JMS.Message, Output response As %Library.Persistent) As %Status
{
	set index = $i(^JMSLOG)
	set ^JMSLOG(index,"*","type")="process"
	set ^JMSLOG(index,"*","name") = ..%ConfigName
	set ^JMSLOG(index,"*","time")= ##class(%UTC).NowLocal()
	set ^JMSLOG(index,"messageId") = request.messageId
	set ^JMSLOG(index,"messageText") = request.text
	set ^JMSLOG(index,"messageType") = request.type
	set key="" for  {
		set key = request.getNextPropertyKey(key) quit:key=""
		set value = request.getProperty(key)
		set ^JMSLOG(index,"messageProperty",key) = request.getProperty(key)
	}
	quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
