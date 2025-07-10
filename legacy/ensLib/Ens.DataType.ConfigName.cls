/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Datatype for a config name (i.e. a configuration or class name)
Class Ens.DataType.ConfigName Extends %String [ System = 4 ]
{

/// The maximum number of characters a classname can contain.
Parameter MAXLEN = 128;

/// Parse a config name spec using the specified delimiter and quote mark.  Returns the results byref in pResults
/// which contains each individual configname indexed in the order of appearance.  Returns $$$OK on success, or
/// an error if the spec string had problems (such as unbalanced quotes).
ClassMethod ParseConfigNameSpec(pSpec As %String, pSeparator As %String, ByRef pResults, pQuote As %String = """", pStrip As %Boolean = 1) As %Status
{
	#dim tSC As %Status = $$$OK
	Set $ZT="Trap"
	Do {
		#dim tIndex  As %Integer
		#dim tDelim  As %Integer
		#dim tStart  As %Integer
		#dim tLength As %Integer
		#dim tQuote  As %Integer
		#dim tQuote2 As %Integer
		#dim tName   As %String
	
		Kill pResults
	
		Set (tStart,tIndex)=1
		Set tLength=$LENGTH(pSpec)
	
		While (tIndex'>tLength) {
		
			// Look for both the delimiter and the quote mark and take
			// whichever is first.
			
			If $L(pSeparator) {
				Set tDelim = $FIND(pSpec, pSeparator, tIndex)
				Set tDelim = $CASE(tDelim,0:tLength,:tDelim-($L(pSeparator)+1))
			} Else {
				// No separator allowed
				Set tDelim = tLength
			}
		
			If $L(pQuote) {
				Set tQuote = $FIND(pSpec, pQuote, tIndex)
				Set tQuote = $CASE(tQuote,0:0,:tQuote-$L(pQuote))
			} Else {
				// No quote allowed
				Set tQuote = 0
			}
		
			If tQuote,tQuote'>tDelim {
				// If we found a quote and it is before (or at) the delimiter, then
				// we need to find the closing quote ignoring any further delimiters
				// until we see that quote.  Note that we may encounter doubled 
				// quotes which we should handle.
			
				Set tQuote2 = tQuote + $L(pQuote)
				For {
					Set tQuote2 = $FIND(pSpec, pQuote, tQuote2)
					If 'tQuote2 {
						// We haven't found a closing quote ... error!
						Set tSC = $$$ERROR($$$UnbalancedQuotes)
						Quit
					}

					// We must advance tIndex to cover what we've scanned so far
					Set tIndex = tQuote2
				
					// Quit if there's not another quote immediately following this one
					If $FIND(pSpec, pQuote, tIndex) '= (tIndex + $L(pQuote)) Quit
				}
				
				// If we encountered an error, quit out
				If $$$ISERR(tSC) Quit
			
				// At this point, tIndex either points to the end of the string (i.e.
				// we're done) or just beyond the last quote.  At this point
				// we can go back to looking for a delimiter
				If tIndex<tLength Continue
				
				// Note, reset tDelim to point at the end of the string ...
				Set tDelim = tLength

			} Else {
				// No quote, use the delimiter
			}
			
			// Extract and strip leading and trailing whitespace (if requested)
			Set tName = $E(pSpec, tStart, tDelim)
			Set:pStrip tName = $ZSTRIP(tName,"<>W")
		
			// Store the result (don't bother with empty strings)
			If tName'="" {
				Set pResults($I(pResults)) = tName
			}
			
			// Move to the next element
			Set (tStart,tIndex) = tDelim + $L(pSeparator) + 1
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
