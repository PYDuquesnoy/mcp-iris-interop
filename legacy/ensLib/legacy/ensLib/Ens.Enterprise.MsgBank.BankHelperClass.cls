/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.MsgBank.BankHelperClass [ Abstract, System = 4 ]
{

/// A helper function that can be invoked from the Message Bank TCP Service (of type <class>Ens.Enterprise.MsgBank.TCPService</class>).
/// If the Message Bank TCP service is configured to use a subclass of this class as its BankHelperClass, then the service will
/// invoke this method for each incoming message header that also banks the message body.
/// The arguments to the method are as follows:
/// <ul><li><var>pHeader</var> - the <class>Ens.Enterprise.MsgBank.MessageHeader</class> object being banked,</li>
/// <li><var>pFullHeaderID</var> - the full ID of the header,</li>
/// <li><var>pBody</var> - the message body object being banked,</li>
/// <li><var>pFullBodyID</var> - the full ID of the message body, and</li>
/// <li><var>pService</var> - the <class>Ens.Enterprise.MsgBank.TCPService</class> instance. The service object is passed
/// in to allow the helper code to send data to other components in the production, especially asynchronously. If all the code
/// is executed directly within this method, the overall throughput of the service may be affected due to the extra processing overhead.</li></ul>
/// Users should override this implementation with their own as needed.
ClassMethod OnBankMsg(pHeader As Ens.Enterprise.MsgBank.MessageHeader, pFullHeaderID As %String, pBody As %RegisteredObject = "", pFullBodyID As %String, pService As Ens.Enterprise.MsgBank.TCPService) As %Status [ Abstract ]
{
}

}
