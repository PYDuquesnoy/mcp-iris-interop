Class Demo.JMS.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.JMS.OutboundAdapter";

Parameter INVOCATION = "Queue";

XData MessageMap
{
<MapItems>
<MapItem MessageType="Ens.StringRequest"> 
<Method>OnStringRequest</Method>
</MapItem>
</MapItems>
}

Method OnStringRequest(pRequest As Ens.StringRequest, Output pResponse As Ens.StringRequest) As %Status
{
	try {
		set tSC = ..Adapter.GetNewMessage(.message) quit:$$$ISERR(tSC)
		;
		do message.setText(pRequest.StringValue)
		do message.setType("TextMessage")
		do message.setByteProperty("myByteKey","A")
		do message.setBooleanProperty("myBooleanKey",1)
		do message.setShortProperty("myShortKey",123)
		do message.setIntegerProperty("myIntegerKey",1234567890)
		do message.setLongProperty("myLongKey",9876543210)
		do message.setFloatProperty("myFloatKey",1.2)
		do message.setDoubleProperty("myDoubleKey",3.1415926)
		do message.setStringProperty("myStringKey","XYZ")
		;
		set index = $i(^JMSLOG)
		set ^JMSLOG(index,"*","type") = "operation pre-call"
		set ^JMSLOG(index,"*","name") = ..%ConfigName
		set ^JMSLOG(index,"*","time") = ##class(%UTC).NowLocal()
		set ^JMSLOG(index,"messageText") = message.getText()
		set ^JMSLOG(index,"messageType") = message.getType()
		set keys = message.getPropertyKeys()
		for i=1:1:keys.size() {
			set key = keys.get(i-1)
			set ^JMSLOG(index,"messageProperty",key) = message.getProperty(key)
		}
		;
		set tSC = ..Adapter.SendMessage(message) quit:$$$ISERR(tSC)
		;
		set index = $i(^JMSLOG)
		set ^JMSLOG(index,"*","type") = "operation post-call"
		set ^JMSLOG(index,"*","name") = ..%ConfigName
		set ^JMSLOG(index,"*","time") = ##class(%UTC).NowLocal()
		set ^JMSLOG(index,"messageId") = message.getMessageId()
		;
		set pResponse = ##class(Ens.StringRequest).%New("Message sent as "_message.getMessageId())
		;
	} catch {
		set tSC=$S($ZE["<ZJGTW>":%objlasterror,1:$$$SystemError)
	}
	;
	Quit tSC
}

}
