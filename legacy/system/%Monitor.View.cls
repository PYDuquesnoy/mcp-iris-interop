/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Monitor object for viewing sample data
Class %Monitor.View Extends %RegisteredObject [ System = 3 ]
{

/// ID for sample group being viewed
Property SampleId As %String;

ClassMethod Display(mclass As %String) As %Status
{
 // Execute the query on the sample to get the data
 Set rspec = ##class(%ResultSet).%New("Monitor.Sample:LatestSample")
 Do rspec.Execute(mclass)
 // Get all the data
 While rspec.Next(.sc) {
	 If '$SYSTEM.Status.IsOK(sc) Quit
	 // Get ID
	 Set id= rspec.GetData(1)
	 Set data = ##class(Monitor.Sample).%OpenId(id)
	 If data = "" s sc=0 q
	 Do data.DisplayDetails()
	 k data
 }
 k rspec

 Q sc
}

}
