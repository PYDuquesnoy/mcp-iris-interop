/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.UDL.TextServices Extends %RegisteredObject
{

/// This method takes a namespace, classname and a file name. On success writes it to the named file
/// the text which represents a class definition in the UDL class definition language.
ClassMethod GetTextAsFile(pNamespace As %String = {$namespace}, pClassName As %String, pFileName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tTextStream As %Library.FileCharacterStream
	
	Try {
		#; Create an instance of a file stream
		Kill %objlasterror
		Set tTextStream=##class(%Library.FileCharacterStream).%New()
		If '$IsObject(tTextStream) {
			If $Get(%objlasterror)'="" {
				Set tSC=%objlasterror
			} else {
				Set tSC=$$$ERROR($$$FailedToNewClass,"%Library.FileCharacterStream")
			}
			Quit
		}
		
		#; Set the file name
		Set tTextStream.Filename=pFileName
		
		#; Retrieve the text and write to the stream
		Set tSC=..GetTextAsStream(pNamespace,pClassName,tTextStream)
		If $$$ISERR(tSC) Quit
		
		#; All ok, save the stream
		Set tSC=tTextStream.%Save()
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// This method takes the namespace and a name of a file which  contains text representing a class definition in the UDL
/// class definition language.
/// 
/// The method will parse the class representation and if it is syntactically valid will attempt to 
/// save the class definition. It returns $$$OK on success and a (possibly composite) error status on
/// failure. Note: a syntactically valid class represention may fail to save due to failure to obtain a lock.
/// 
/// It is important to realize that this method will replace the existing class definition if present and therefore
/// must contain a full representation of the class as can be obtained by calling the GetTextXXX() method(s) in
/// this class.  Note: The name of the class is derived from the name of the class defined within the text
ClassMethod SetTextFromFile(pNamespace As %String = {$namespace}, pClassName As %String, pFileName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tStream As %Library.FileCharacterStream
	Try {
		
		If '##class(%Library.File).Exists(pFileName) {
			Set tSC=$$$ERROR($$$FileDoesNotExist,pFileName)
			Quit
		}
		
		Kill %objlasterror
		Set tStream=##class(%Library.FileCharacterStream).%New()
		If '$IsObject(tStream) {
			If $Get(%objlasterror)'="" {
				Set tSC=%objlasterror
			} else {
				Set tSC=$$$ERROR($$$FailedToNewClass,"%Library.FileCharacterStream")
			}
			Quit
		}
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		#; Now process the stream
		Set tSC=..SetTextFromStream(pNamespace,pClassName,tStream)
		
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This method takes namespace and a classname and returns a character stream containing text which represents a
/// class definition in the UDL class definition language.
/// 
/// Note: you should supply your own instance of a character stream to write to. If you don't supply
/// one then a new instance of a %Stream.GlobalCharacter will be created and used
ClassMethod GetTextAsStream(pNamespace As %String = {$namespace}, pClassName As %String, ByRef pTextStream As %Stream.Object) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tTextArray As %String
	#dim tI As %Integer
	
	Try {
		
		#; Retrieve the text into an array
		Set tSC=..GetTextAsArray(pNamespace,pClassName,.tTextArray)
		If $$$ISERR(tSC) Quit
		
		If $IsObject($Get(pTextStream))'=1 Set pTextStream=##class(%Stream.GlobalCharacter).%New()
		
		#; Write the contents of the array to the stream
		For tI=1:1:tTextArray(0) Do pTextStream.WriteLine(tTextArray(tI))
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This method takes a namespace and a stream of text which represents a class definition in the UDL class definition language.
/// 
/// The method will parse the class representation and if it is syntactically valid will attempt to 
/// save the class definition. It returns $$$OK on success and a (possibly composite) error status on
/// failure. Note: a syntactically valid class represention may fail to save due to failure to obtain a lock.
/// 
/// It is important to realize that this method will replace the existing class definition if present and therefore
/// must contain a full representation of the class as can be obtained by calling the GetClassXXX() method(s) in
/// this class.  Note: The name of the class is derived from the name of the class defined within the text
ClassMethod SetTextFromStream(pNamespace As %String = {$namespace}, pClassname As %String, pTextStream As %Library.CharacterStream) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tTextArray,tLine As %String
	#dim tI,tLen As %Integer = 0
	
	Try {
		#; Ensure we are at the begining of the stream
		Set tSC=pTextStream.Rewind()
		If $$$ISERR(tSC) Quit
		
		#; While data remains
		While 'pTextStream.AtEnd {
			
			#; Read a line of text and place it in the document array
			Set tI=tI+1,tTextArray(tI)=pTextStream.ReadLine(,.tSC)
			If $$$ISERR(tSC) Quit
		}
		
		#; If we have errored, then exit early
		If $$$ISERR(tSC) Quit
		
		#; Fill in the line count
		Set tTextArray(0)=tI
		
		#; And call the parse/save method
		Set tSC=..SetTextFromArray(pNamespace,pClassname,.tTextArray)
		
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This method takes a namespace and a classname and returns a string which represnts the class definition in the UDL
/// class definition language
ClassMethod GetTextAsString(pNamespace As %String = {$namespace}, pClassName As %String, Output pTextString As %String, pDelimiter As %String = {$Char(13,10)}) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tI As %Integer
	#dim tTextArray As %String
	
	Try {
		#; Retrieve the text into an array
		Set tSC=..GetTextAsArray(pNamespace,pClassName,.tTextArray)
		If $$$ISERR(tSC) Quit
		
		#; Build the String
		Set pTextString="" For tI=1:1:tTextArray(0) {
			
			#; Add the delimiter
			Set pTextString=pTextString_tTextArray(tI)_pDelimiter
			
			#; Reclaim some space
			Kill tTextArray(tI)
		}
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// This method takes a namespace and a string of text which represents a class definition in the UDL class definition language.
/// 
/// The method will parse the class representation and if it is syntactically valid will attempt to 
/// save the class definition. It returns $$$OK on success and a (possibly composite) error status on
/// failure. Note: a syntactically valid class represention may fail to save due to failure to obtain a lock.
/// 
/// It is important to realize that this method will replace the existing class definition if present and therefore
/// must contain a full representation of the class as can be obtained by calling the GetClassXXX() method(s) in
/// this class.  Note: The name of the class is derived from the name of the class defined within the text
ClassMethod SetTextFromString(pNamespace As %String = {$namespace}, pClassname As %String, pTextString As %String, pDelimiter As %String = {$Char(13,10)}) As %Status
{
	#dim tI As %Integer
	#dim tTextArray As %String
	
	#; Construct the document array by dividing the string on the specified delimiter
	For tI=1:1:$l(pTextString,pDelimiter) Set tTextArray(tI)=$piece(pTextString,pDelimiter,tI)
	
	#; Fill in the count of lines
	Set tTextArray(0)=tI
	
	#; Dispatch to canonical method
	Quit ..SetTextFromArray(pNamespace,pClassname,.tTextArray)
}

/// This method takes a namespace and the name of a class and on success returns an integer subscripted array of text
/// representing the class definition. The 0 node contains the number of lines of text (n) and each line
/// of source is stored at the nodes 1 .. n.
ClassMethod GetTextAsArray(pNamespace As %String = {$namespace}, pClassName As %String, Output pDocumentText As %String) As %Status
{
	#dim tSC,tStatus As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tErrList,tOneErr,tLastPiece As %String
	#dim tResultCode,tI As %Integer
	
	Try {
		#; Swap namespace if necessary
		If pNamespace'=$namespace new $namespace Set $namespace=pNamespace
		
		#; Need to have ".cls" on the end of the name to distinguish source type
		If $zcvt($Piece(pClassName,".",$Length(pClassName,".")),"l")'="cls" Set pClassName=pClassName_".cls"
		
		#; Call the pre-processor
		Set tResultCode=$preprocess(pClassName,0,pDocumentText,tErrList)
		If tResultCode {
	        For tI=1:1:$ll(tErrList) {
	            Set tOneErr = $list(tErrList,tI),tStatus=$$$ERROR($$$ClassLoadError,$li(tOneErr,4),$li(tOneErr,1),$li(tOneErr,2),$li(tOneErr,6))
	         	If tSC=$$$OK {   
	            	Set tSC=tStatus
	         	} else {
		         	Set tSC=$$$ADDSC(tSC,tStatus)
	         	}
	        }
	    }
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This method takes a namespace an integer subscripted array containing lines of text which represent a
/// class definition in the UDL class definition language. Subscript value 0 should contain a count
/// of lines of text which are defined as subscript value 1 ... n in the array
/// 
/// The method will parse the class representation and if it is syntactically valid will attempt to 
/// save the class definition. It returns $$$OK on success and a (possibly composite) error status on
/// failure. Note: a syntactically valid class represention may fail to save due to failure to obtain a lock.
/// 
/// It is important to realize that this method will replace the existing class definition if present and therefore
/// must contain a full representation of the class as can be obtained by calling the GetClassXXX() method(s) in
/// this class.  Note: The name of the class is derived from the name of the class defined within the text
ClassMethod SetTextFromArray(pNamespace As %String = {$namespace}, pClassname As %String, ByRef pDocumentArray As %String) As %Status
{
	#dim tSC,tStatus As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tErrList,tOneErr As %String
	#dim tResultCode,tI As %Integer
	
	Try {
		#; TODO: make sure pClassname and classname within the text match, else throw an error
		#; Remember pClassname has .cls extension!
		
		#; Swap namespace if necessary
		If pNamespace'=$namespace new $namespace Set $namespace=pNamespace
		
		#; Compile (Save) the class definition
		Set tResultCode=$compile(pDocumentArray,128,tErrList)
		If tResultCode {
	        For tI=1:1:$ll(tErrList) {
	            Set tOneErr = $list(tErrList,tI),tStatus=$$$ERROR($$$ClassSaveError,$li(tOneErr,4),$li(tOneErr,1),$li(tOneErr,2),$li(tOneErr,6))
	         	If tSC=$$$OK {   
	            	Set tSC=tStatus
	         	} else {
		         	Set tSC=$$$ADDSC(tSC,tStatus)
	         	}
	        }
	    }
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

}
