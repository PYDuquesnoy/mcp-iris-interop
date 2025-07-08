/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <CLASS>%SYNC.ObjectLog</CLASS> class is used for retrieval of the collection of 
/// <CLASS>%Library.ObjectJournalRecord</CLASS> entries related to a given class instance modifications ( 
/// the corresponding class should be both GUID enabled and journalled).  The <METHOD>%New</METHOD> method accepts three arguments:
/// the guid, start time and end time.  Only the modifications occured in a specified interval are included in the collection.
/// 
/// <EXAMPLE>
/// s ol=##class(%SYNC.ObjectLog)%New(guid,startTtransaction,endTransaction)
/// Write ol.log.Size
/// </EXAMPLE>
Class %SYNC.ObjectLog Extends %RegisteredObject [ System = 4 ]
{

Property StartTransaction As %Integer;

Property EndTransaction As %Integer;

Property guid As %String;

Property log As %ListOfObjects;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(guid, StartTransaction, EndTransaction) As %Status [ Private, ProcedureBlock = 1 ]
{
	set ..guid= $g(guid) //$lg(initvalue,1)
	set ..StartTransaction=$g(StartTransaction)           //+$lg(initvalue,2)
	set ..EndTransaction=+$g(EndTransaction)             //+$lg(initvalue,3)
	if ..guid="" QUIT $$$OK
	set ct=$o(^OBJ.GUID(0,..guid,..StartTransaction-1))

	while (ct '= "") && ('..EndTransaction || (ct '> ..EndTransaction)  ) {
		
		set trnid = $Order(^OBJ.JournalT(ct),-1)
		if ..EndTransaction && (trnid>..EndTransaction)  QUIT 
		set jrnrec=##class(%ObjectJournalRecord).IDKeyOpen(trnid,ct)
		d ..log.Insert(jrnrec)
		set ct=$o(^OBJ.GUID(0,..guid,ct))
	}

	//^OBJ.GUID(0,<guid>,<jrnid>)=<fileop>
	//set trnid = $Order(^OBJ.JournalT(<jrnid>),-1)
	//set jrnrec=##class(%ObjectJournalRecord).IDKeyOpen(trnid,jrnid)

	Quit $$$OK
}

}
