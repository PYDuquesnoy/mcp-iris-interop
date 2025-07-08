/// Loan Approval Business Process for Find Rate.
/// This process passes on a Loan Application to 
/// 3 other bank and finds the best available rate.
Class Demo.Loan.FindRateDecisionProcessBPL Extends Ens.BusinessProcessBPL [ ClassType = persistent, ProcedureBlock ]
{

Parameter DOMAIN = "EnsDemo";

/// 2 modes: Queue, InProc
Parameter INVOCATION = "Queue";

Method GetText(context As Ens.BP.Context) As %String
{
	Set tSessionId=..%SessionId
	&sql(Select MessageBodyId into :tRecordNum from Ens.MessageHeader where ID=:tSessionId)
	If $Get(tRecordNum)="" set tRecordNum ="??"
	
	If context.IsApproved {
		Set tText = $$FormatMessage^%occMessages(,"EnsDemo","FindRateContext1","Your loan application with record number %1 was approved.",tRecordNum)_$c(13,10)
		Set tText = tText_$$FormatMessage^%occMessages(,"EnsDemo","FindRateContext2","The lowest interest rate available is at %1 percent offered by %2.",context.InterestRate,context.BankName)_$c(13,10)
	} Else {
		Set tText = $$FormatMessage^%occMessages(,"EnsDemo","FindRateIsDenied","Your loan application was denied.",tRecordNum)_$c(13,10)
	}
	Set tText=tText_$$FormatMessage^%occMessages(,"EnsDemo","FindRateThankyou","Thank you for applying with FindRate.")_$c(13,10)
	Quit $ZCVT(tText,"O","HTML")
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Demo.Loan.Msg.Application' height='2000' width='2635' >
<context>
<property name='BankName' type='%String' instantiate='0' />
<property name='IsApproved' type='%Boolean' instantiate='0' />
<property name='InterestRate' type='%Numeric' instantiate='0' />
<property name='TheResults' type='Demo.Loan.Msg.Approval' collection='list' instantiate='0' />
<property name='Iterator' type='%String' instantiate='0' />
<property name='ThisResult' type='Demo.Loan.Msg.Approval' instantiate='0' />
</context>
<sequence xend='200' yend='1600' >
<trace name='Trace' value='"received application for "_request.Name' xpos='200' ypos='250' />
<code xpos='200' ypos='350' >
<![CDATA[ set context.BankName=$j("X",60)
 $$$TRACE("First Test")
 set sc=context.%Save(1)
 set code=$SYSTEM.Status.GetErrorCodes(sc)
 $$$TRACE("ERRORS:"_code)
 set text=$SYSTEM.Status.GetOneErrorText(sc)
 $$$TRACE("Error Text:"_text)
]]>
</code>
<call name='BankUS' target='Demo.Loan.BankUS' async='1' xpos='200' ypos='450' >
<annotation><![CDATA[Send an asynchronous request to Bank US.]]></annotation>
<request type='Demo.Loan.Msg.Application' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Demo.Loan.Msg.Approval' >
<assign property="context.TheResults" value="callresponse" action="append" />
</response>
</call>
<call name='BankSoprano' target='Demo.Loan.BankSoprano' async='1' xpos='200' ypos='550' >
<annotation><![CDATA[Send an asynchronous request to Bank Soprano.]]></annotation>
<request type='Demo.Loan.Msg.Application' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Demo.Loan.Msg.Approval' >
<assign property="context.TheResults" value="callresponse" action="append" />
</response>
</call>
<call name='BankManana' target='Demo.Loan.BankManana' async='1' xpos='200' ypos='650' >
<annotation><![CDATA[Send an asynchronous request to Bank Manana.]]></annotation>
<request type='Demo.Loan.Msg.Application' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Demo.Loan.Msg.Approval' >
<assign property="context.TheResults" value="callresponse" action="append" />
</response>
</call>
<call name='BankEven' target='Demo.Loan.BankEven' async='1' xpos='200' ypos='750' >
<annotation><![CDATA[Send an asynchronous request to Bank Even.]]></annotation>
<request type='Demo.Loan.Msg.Application' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Demo.Loan.Msg.Approval' >
<assign property="context.TheResults" value="callresponse" action="append" />
</response>
</call>
<sync name='Wait for Banks' calls='BankUS,BankSoprano,BankManana,BankEven' timeout='5' type='all' xpos='200' ypos='850' >
<annotation><![CDATA[Wait for the response from the banks. Wait for up to 5 seconds.]]></annotation>
</sync>
<trace value='"sync complete"' xpos='200' ypos='950' />
<foreach name='Loop through Results' property='context.TheResults' key='context.Iterator' xpos='200' ypos='1050' xend='200' yend='1250' >
<annotation><![CDATA[Loop over the results received from the banks.
Drill into this shape to see the details of the loop.
]]></annotation>
<assign name="ThisResult" property="context.ThisResult" value="context.TheResults.GetAt(context.Iterator)" action="set" xpos='200' ypos='250' />
<trace value='"processing reply from "_context.ThisResult.BankName' xpos='200' ypos='350' />
<if name='Approved?' condition='context.ThisResult.IsApproved' xpos='200' ypos='450' xend='200' yend='1150' >
<annotation><![CDATA[Were we approved by this bank?]]></annotation>
<true>
<if name='BetterRate?' condition='(&apos;context.IsApproved)||(context.InterestRate&gt;context.ThisResult.InterestRate)' xpos='335' ypos='600' xend='335' yend='1050' >
<annotation><![CDATA[Is this a better rate?
Compare rate with current best rate.]]></annotation>
<true>
<assign name="BankName" property="context.BankName" value="context.ThisResult.BankName" action="set" xpos='470' ypos='750' >
<annotation><![CDATA[This is the best rate so far;
Copy the details into the context object.]]></annotation>
</assign>
<assign name="IsApproved" property="context.IsApproved" value="context.ThisResult.IsApproved" action="set" xpos='470' ypos='850' />
<assign name="InterestRate" property="context.InterestRate" value="context.ThisResult.InterestRate" action="set" xpos='470' ypos='950' />
</true>
</if>
</true>
</if>
</foreach>
<switch name='Response' xpos='200' ypos='1150' xend='200' yend='1400' >
<annotation><![CDATA[Determine which type of response was requested.]]></annotation>
<case condition='request.BusinessOperationType="mail"' name='Mail' >
<call name='SendApproval' target='Demo.Loan.FindRateEMailOperation' async='1' xpos='335' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<case condition='request.BusinessOperationType="file"' name='File' >
<call name='SendApproval' target='Demo.Loan.FindRateFileOperation' async='1' xpos='605' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<case condition='request.BusinessOperationType="term"' name='Terminal' >
<call name='SendApproval' target='My Terminal Output' async='1' xpos='875' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<case condition='request.BusinessOperationType="tcp"' name='TCP' >
<call name='SendApproval' target='Demo.Loan.FindRateTCPOperation' async='1' xpos='1145' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<case condition='request.BusinessOperationType="msmq"' name='MSMQ' >
<call name='SendApproval' target='Demo.Loan.FindRateMSMQOperation' async='1' xpos='1415' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<case condition='request.BusinessOperationType="mqseries"' name='MQSeries' >
<call name='SendApproval' target='Demo.Loan.FindRateMQSeriesOperation' async='1' xpos='1685' ypos='1300' >
<request type='Demo.Loan.Msg.SendReply' >
<assign property="callrequest.Text" value="process.GetText(context)" action="set" />
<assign property="callrequest.Destination" value="request.Destination" action="set" />
</request>
</call>
</case>
<default/>
</switch>
<trace value='"application is "_$s(context.IsApproved:"approved for "_context.InterestRate_"% by "_context.BankName,1:"denied")' xpos='200' ypos='1500' />
</sequence>
</process>
}

}
