/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LANG11, MVERRNO, mvfioflags)

/// The class <class>%SYSTEM.MV</class> provides access to MV system level functions and elements for COS and MVBASIC
/// programmers. <p>This class should always be used in preference to direct access to the
/// internals of the MV implementation, as it is guranteed to be in sync with any underlying
/// structural changes.<p> NEVER try to access MV elements at their base system level as upward
/// compatiblity is not guranteed and this can in fact be dangerous.
/// <p>COS language methods and programs should access this class using the special <b>$System</b>
/// object:
/// <example>
/// Set cosName = $System.MV.validCacheName("MVFILE.$TRANGEN4M3")
/// </example>
/// <p>MVBASIC programmers should access this class using the "%SYSTEM.MV" method:
/// <example language="mvbasic">
/// cosName = "%SYSTEM.MV"->validCacheName("MVFILE.$TRANGEN4M3")
/// </example>
/// 
Class %SYSTEM.MV Extends Help [ Abstract, System = 4 ]
{

/// Call this method to get the next Item ID from the TCL II processed command line. 
/// <p>Note that you can enable TCL II (list, vs *, vs itemidlist) processing for
/// an MVBASIC cataloged program by editing the CATALOG pointer for the program
/// and adding '2' to Attribute 5:<br>
/// <example language="mvbasic">
///      MYNEWVERB
/// 0001 V
/// 0002 MVB.3ý%SYS
/// 0003 B
/// 0004
/// 0005 2
/// 0006
/// 0007 L
/// 0008 MYNEWVERB
/// 0009 BP
/// 0010 SYSPROG
/// </example>
/// 
/// You can additionaly add the the following letters to attribute 5:<br>
/// 'C' - will cause the item body to be copied into @RECORD.<br>
/// 'N' - will allow new items and not check for an item's existence.<br>
/// 'D' - will force an open of the DICT rather than DATA section.<br>
/// <br><br>
/// Returns:<br>
/// 1 - Success. The next Item Id has been placed in @ID and optionally the body has been copied into @RECORD<br>
/// 0 - End of Items or failure.<br>
///            
ClassMethod TCL2Next() As %Integer [ Final ]
{
	#; Please note that this code is not performance critical in any way
	#; and is therfore written for maintainability, clarity and ease of reading
	#; in studio. Please do not amalgamate lines, remove whitespace or reformat
	#; from 4 space tabs.
	#; 
	#; Trap any errors
	#; 
	#define TCL2GetNextItem $$TCL2GetNextItem^%SYS.MV
	#;
	Set ztrap="nexterr"
	Set rc = $$$TCL2GetNextItem()
	Quit:(rc = $$$MVFIOESelectFin) 0
	Quit 1
	#;
nexterr Set ztrap=""
		Quit 0
}

/// Parses the supplied DICT entry <var>record</var> as element <var>name</var>
/// into the public variable %dictionary using the open <var>dict</var> file variable
/// if it needs to reference other elements in the DICT.
/// 
/// If the method returns 0, then you can just exit your program
/// and the MV shell will display any ERRMSG that has occurred.
/// <p>
/// <table border="0" width="100%" id="table1">
/// 	<tr>
/// 		<td>Returns:</td>
/// 		<td>nnn</td>
/// 		<td>- Ordinal entry number in %dictionary</td>
/// 	</tr>
/// 	<tr>
/// 		<td>&nbsp;</td>
/// 		<td>0</td>
/// 		<td>- Could not open DICTionary or other error</td>
/// 	</tr>
/// </table>
///            
ClassMethod parseDict(dict As %MV.File, record As %String, name As %String) [ Final ]
{
	#define ParseDict	$$ParseDict^%SYS.MVQ
	#define evalMVDictDataType evalMVDictDataType^%SYS.MVI
	#;
	New %DictObj
	#;
    #; 'Open' %DictObj, so that ParseDict has it available.
    #;
    Set %DictObj = dict
    #;
    Set o = $$$ParseDict(record,name)
    #;
    Set pord = ""
    For {
    	Set pord = $Order(%dictionary(pord))
	    Quit:pord=""
    	Do $$$evalMVDictDataType(.%dictionary,pord)
    }
    Quit
    #;
parseerr 	Set ztrap=""
 			Quit
}

/// Build a cross reference of a MV class for maintenence purposes.
/// 
ClassMethod buildMVClassXref(classDef As %ObjectHandle, ByRef ClassXref As %Collection.AbstractArray) [ Final ]
{
	#define getMVClassXref getMVClassXref^%SYS.MVI
	
	Do $$$getMVClassXref(classDef,.ClassXref)
}

/// Method designed for use in PROTOCLASS to generate a property defined by the MV DICT item
/// that has been parsed and stored in %dictionary(pord)<BR>
/// 
ClassMethod createMVProperty(pname, pord, classDef As %ObjectHandle, ByRef ClassXref As %Collection.AbstractArray) [ Final ]
{
	#define createMVProperty createMVProperty^%SYS.MVI
	
	Do $$$createMVProperty(pname,pord,classDef,.ClassXref)
}

/// Method designed for use in PROTOCLASS to delete a property and maintain the cross reference.
/// 
ClassMethod deleteMVProperty(pname, classDef As %ObjectHandle, ByRef ClassXref As %Collection.AbstractArray) [ Final ]
{
	#define deleteMVProperty deleteMVProperty^%SYS.MVI
	
	Do $$$deleteMVProperty(pname,classDef,.ClassXref)
}

/// Given an open file descriptor in <var>fdsc</var>, this method will suggest a valid name for a
/// class or other ObjectScript identifier that can be used to name it outside the MV
/// environment.
/// 
ClassMethod fileDescClassName(fdsc As %MV.File) As %String [ Final ]
{
	Quit $$$FileVarClassName(fdsc)
}

/// Given a port number supplied by the caller, this function will set the 
/// current port number for this process. Should be called early on in the
/// start up of the process for predictability, but can be called any time
/// in practice.
/// 
ClassMethod setPortNumber(portNo As %Integer) As %Status [ Final ]
{
	Set $$$MVpPortNo($J)= portNo
	Set ^||%MVPortNo=portNo
	Quit 0
}

/// Given an open file descriptor, this method will return the fully qualified
/// name of the global that stores the data.
/// <p>Fully qualified means that it includes the NAMESPACE (account) within it
/// such as ^|"TESTACCOUNT"|JIM.DATA
/// 
ClassMethod fileDescDataGlobal(fdsc As %MV.File) As %String [ Final ]
{
	Quit $$$FileVarCOSName(fdsc)
}

/// Given an MV identifier name of some sort in <var>input</var>, such as a file name
/// this method will return a name that is valid as a class or
/// property name.
/// 
ClassMethod validCacheName(input As %String) As %String [ Final ]
{
	Quit $$$VALIDCPNAME(input)
}

/// Given an MV identifier name of some sort in <var>input</var>, such as a file name
/// this method will return a name that is valid as a class or
/// property name using Camel Case.
/// 
ClassMethod camelCaseName(input As %String) As %String [ Final ]
{
	Quit $$$CAMELCPNAME(input)
}

/// If an error occurred in a call to an object or class, you can
/// call this method and it will PRINT the error messages to the terminal.
/// 
ClassMethod decomposeStatus(sc As %Integer) [ Final ]
{
	Set err=""
	Do DecomposeStatus^%apiOBJ(sc, .err, "-d")
	For i=1:1:err MVP err(i),!
}

/// Supplies the next available unique global name using the same
/// mechanisms as CREATE-FILE. Calling this will reserve a global
/// name for you that is guranteed to be exclusive for your use.
/// Note that the name returned does not include any namespace
/// information and is unique across namespaces too. It is up to
/// you to decide where (namespace wise) the global will exist.
/// 
ClassMethod newUniqueGlobal(prefix As %String) As %String
{
	;# Use same counter as CREATE-FILE would when it can't construct
	;# a valid global name from the filename
	;# 
	Quit prefix_$ZH($I($$$DataCounter))
}

/// Given an open file descriptor, this method will return the class
/// associated with that file.<br>
/// If createFlg is set then the class will be created if it doesn't exist.<br>
/// If NewName is specified then that name willl be used to create the class.
ClassMethod getPrimaryMVClass(fdsc As %MV.File, createFlg As %Boolean, NewName As %String = "") As %ObjectHandle [ Final ]
{
	Quit $$$getPrimaryMVClass(fdsc,createFlg,NewName)
}

/// This method sets or clears a flag that controls whether INPUT commands
/// will read only stacked DATA or will also read from the input device.
/// The argument is a boolean value 0 or 1. If DataOnlyFlag is 1, only stacked
/// DATA will be available to INPUT commands.  An attempt to read beyond the
/// stacked DATA will result in an ABORT.  If DataOnlyFlag is 0, the Data Only
/// flag is cleared and INPUT commands will return to the default state of
/// reading both stacked DATA and directly from the input device.<br>
/// The return value is the previous state of the flag.  If no argument is
/// given, the current state of the flag is returned without changing it.
ClassMethod InputDataOnly(DataOnlyFlag As %Boolean) As %Boolean
{
	Set prev=$$$MVBInputDataOnly
	Set:$Data(DataOnlyFlag) $$$MVBInputDataOnly=DataOnlyFlag
	Quit prev
}

/// This method will search a class for properties that are defined as itypes and 
/// add implementations of the calc and calcsql metods for those itypes to the class 
ClassMethod generateItypeMethods(classDef As %ObjectHandle)
{
	Do GenItypeRoutines^%SYS.MVI(classDef)
}

/// Set the passed string as the COS shell recall stack
ClassMethod StackSetCOS(arg As %String = "") As %Boolean
{
	do $zu(195,4,arg)
	quit 1
}

/// Set the passed string as the MV shell recall stack
ClassMethod StackSetMV(arg As %String = "") As %Boolean
{
	set attrCount = $l(arg,$$$MVam),list1=$lb("")
	for attrNext=1:1:attrCount { set $list(list1,attrNext)=$MV(arg,attrNext) }
	set $list(%MVShellRecall,2) = list1
	quit 1
}

/// Get the COS shell recall stack
ClassMethod StackGetCOS() As %String
{
	quit $zu(195,3)
}

/// Get the MV shell recall stack
ClassMethod StackGetMV() As %String
{
	set list1 = $ListGet(%MVShellRecall,2),ctr1=$LL(list1),out=""
	for ctr2=1:1:ctr1 { set $MV(out,-1)=$lg(list1,ctr2) }
	quit out
}

/// The Initializer for iterating through values and subvalues in conjunction with A and F correlatives.
/// This clears the moreValues and moreSubValues flags
/// and sets the current value and current subvalue counters to 1.
ClassMethod IteratorInit()
{
	Set $mvnv=1
	Set $mvns=1
	Set $mvmorevalues=0
	Set $mvmoresubvalues=0
}

/// The method tests to see if there are more values to process as indicated by
/// the moreValues and moreSubValues flags and sets the current value and
/// current subvalue counters accordingly.
/// These flags and counters are used by the Conversion Processor to handle multi-values
/// in A and F correlatives.
ClassMethod IteratorTest() As %Boolean
{
	If $mvmoresubvalues {
	    Set $mvns=$mvns+1
	    Set $mvmoresubvalues = 0
	    Quit 1
	}
    If $mvmorevalues {
	    Set $mvnv=$mvnv+1
	    Set $mvns=1
	    Set $mvmorevalues = 0
	    Quit 1
    }
    Quit 0
}

/// The method gets contents of the specified attribute, current value, current subvalue from @Record.
/// Use to Iterate through all the (sub)values in conjunction with A or F correlatives.
/// If the specific attr,val,subval does not exist then the funtion will return an empty string. 
ClassMethod IteratorGet(attrNo As %Integer) As %String
{
}

/// The method passes a string to the conversion code compiler, checks for errors and returns a string of information.
/// The returned string is a series of comma separated numbers:<br>
/// 1. Status code:<br>
///         Negative value is a negated errmsg number.<br>
///         Positive value is data type of result.<br>
/// 				0 Unknown<br>
/// 				1 String<br>
/// 				2 Integer<br>
/// 				3 Numeric<br>
/// 				4 Boolean<br>
/// 	<br>			
/// 2. Bit values that show the types of computational codes found.<br>
/// 			1 Contains an A correlative<br>
/// 			2 Contains an F correlative<br>
/// 			4 Contains a Concatenate Correlative<br>
/// 			8 Contains a Substitute Correlative<br>
/// 		   16 Contains a Call or B; Correlative invoked for each value<br>
/// 		   32 Contains a Call or B: Correlative invoked once for an attribute<br>
/// <br>
/// 3+. If present, shows attributes referenced in the conversion code.<br>
/// 
ClassMethod ConvAnalyze(code As %String) As %String
{
}

}
