/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used as the super class for all the classes that implement SASchema interface.
Class %Studio.SASchema [ Abstract, System = 3 ]
{

/// Output the SASchema definition to a file.
/// This method does not need to be overriden by subclasses.
ClassMethod OutputToFile(pFilename) As %Status
{
	set tStream=##class(%FileCharacterStream).%New()
	set tStream.Filename=pFilename
	set tSC=..OutputToStream(tStream) quit:$$$ISERR(tSC) tSC
	set tSC=tStream.%Save() quit:$$$ISERR(tSC) tSC
	quit $$$OK
}

/// Subclass should override this method.
/// The method is passed a stream object to which the output should be written.
/// Subclass can also return a checksum for the output.  
/// Ths checksum is used to check to see the output is up-to-date.
ClassMethod OutputToStream(pStream As %Stream.Object, Output pChecksum As %String, pParameter As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Subclass should override this method.
/// Return a boolean to indicate whether the output associated with the pChecksum is still up-to-date or not.
ClassMethod IsUpToDate(pChecksum As %String, pParameter As %String) As %Boolean
{
	Quit 0
}

}
