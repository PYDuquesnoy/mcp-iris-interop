/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.Deleter Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Method to display a list of Results
ClassMethod DisplayResults(pList As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.result"))
{
	#dim tKey As %String
	#dim tResult As EnsLib.UDDI.uddi.result
	
	If pList.Count() = 0 {
		Write !,"No Results Found"
	} else {			
		Set tKey=pList.Next("")
		while tKey'="" {
				
			#; Get the Result object
			Set tResult=pList.GetAt(tKey) 
				
			#; Display it
			Do ..DisplayResult(tResult)
			
			Write !
					
			Set tKey=pList.Next(tKey)
		}
	}
}

/// Method to display a Result
ClassMethod DisplayResult(pResult As EnsLib.UDDI.uddi.result)
{
	Write !,"Result Errno:   ",pResult.errno
	Write !,"Result ErrCode: ",pResult.errInfo.errCode
}

}
