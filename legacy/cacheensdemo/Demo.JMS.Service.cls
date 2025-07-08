Class Demo.JMS.Service Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.JMS.InboundAdapter";

Method OnProcessInput(pMessage As %Net.Remote.Proxy, Output pOutput As %RegisteredObject) As %Status
{
	set index = $i(^JMSLOG)
	set ^JMSLOG(index,"*","type")="service"
	set ^JMSLOG(index,"*","name") = ..%ConfigName
	set ^JMSLOG(index,"*","time")= ##class(%UTC).NowLocal()
	set ^JMSLOG(index,"messageId") = pMessage.getMessageId()
	set ^JMSLOG(index,"messageText") = pMessage.getText()
	set ^JMSLOG(index,"messageType") = pMessage.getType()
	set keys = pMessage.getPropertyKeys()
	for i=1:1:keys.size() {
		set key = keys.get(i-1)
		set ^JMSLOG(index,"messageProperty",key) = pMessage.getProperty(key)
	}
	quit $$$OK
}

}
