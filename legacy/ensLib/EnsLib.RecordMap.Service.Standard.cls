/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for Business Services which process streams containing data mapped to RecordMaps.
Class EnsLib.RecordMap.Service.Standard Extends EnsLib.RecordMap.Service.Base [ Abstract, System = 4 ]
{

Parameter SETTINGS = "UseSingleSession,HeaderCount";

/// Control whether all requests from a single input source should be sent in the same session.
/// The default behaviour is to have each new message in its own session.
Property UseSingleSession As %Boolean [ InitialExpression = 0 ];

/// Number of prefix lines to ignore in incoming documents to permit parsing of
/// reports and CSV exports with column headers.
Property HeaderCount As %Integer [ InitialExpression = 0 ];

/// The Record Terminator to use if <property>HeaderCount</property> is non-zero.
/// The property is used when calling the chunkRecord method of EnsLib.RecordMap.RecordMap
/// from <method>ReadHeaders</method>().
Property RecordTerminator As %String;

/// If <property>HeaderCount</property> is non-zero and the RecordMap is fixed-width,
/// this property is used when calling the chunkRecord method of EnsLib.RecordMap.RecordMap
/// from <method>ReadHeaders</method>(). 
Property RecordLength As %Integer;

/// Send the generated object to the requested targets.
Method SendRequest(pRequest As %Persistent, pAsync As %Boolean = 1, Output pResponse As %ListOfObjects) As %Status
{
	Set tStatus = $$$OK
	If '..UseSingleSession {
		Set ..%SessionId = ""
		Set tStatus = ..ForceSessionId()
		If $$$ISERR(tStatus) Quit tStatus
	}
	Quit ##super(pRequest, pAsync, .pResponse)
}

/// Method to read a certain number of header records from an incoming stream before creating objects.
Method ReadHeaders(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1) As %Status
{
	Set tStatus = $$$OK
	For i=1:1:..HeaderCount {
		Set tRecTerm = ..RecordTerminator
		Set tStatus = ##class(EnsLib.RecordMap.RecordMap).chunkRecord(pIOStream,,,..RecordLength,pTimeout,tRecTerm)
		If $$$ISERR(tStatus) Quit
		$$$sysTRACE("Ignoring record/line #"_i_" from input stream "_pIOStream.Name)
	}
	Quit tStatus
}

/// If <property>HeaderCount</property> is non-zero, ensure that we correctly
/// initialise the <property>RecordTerminator</property> and <property>RecordLength</property>
/// properties for use in <method>ReadHeaders</method>().
Method OnInit() As %Status
{
	Set tStatus = ##super()
	If $$$ISERR(tStatus) Quit tStatus
	
	If ..HeaderCount {
		Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(..recordMapFull,.tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		Set ..RecordTerminator = ##class(EnsLib.RecordMap.RecordMap).getChars(##class(EnsLib.RecordMap.Generator).getLogicalChars(tModel.recordTerminator))
		If tModel.type = "fixedwidth" {
			Set tStatus = ##class(EnsLib.RecordMap.Generator).getStructure(tModel,.tStruc)
			If $$$ISERR(tStatus) Quit tStatus
		
			Set tLastStart = $order(tStruc("parse","struc",""), -1)
			If tLastStart '= "" {
				Set tLastWidth = $get(tStruc("parse","struc",tLastStart,"width"))
				If tLastWidth '= "" {
					Set ..RecordLength = tLastStart + tLastWidth - 1
				}
			}
		}
	}
	Quit tStatus
}

}
