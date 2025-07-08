/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%SYSTEM.OBJ.FM2Class</class> class provides an interface for mapping 
/// FileMan files to InterSystems classes.
/// <p>You can use it via the special <b>$system</b> object:
/// <example>
/// Do $system.OBJ.FM2Class.All(,.count)
/// </example>
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %SYSTEM.OBJ.FM2Class Extends %SYSTEM.Help [ Abstract, System = 4 ]
{

/// Maps all FileMan files in the current namespace to class definitions.
/// <p>For example:
/// <example>
/// Do $System.OBJ.FM2Class.All(.fmSettings,.classCount)
/// </example>
ClassMethod All(ByRef fmSettings, ByRef classCount As %Integer)
{
	do all^%fm2class(.fmSettings,.classCount,"$SYSTEM.OBJ.FM2Class.All")
	QUIT
}

/// Maps a single FileMan file in the current namespace to a class definition.
/// <p>Arguments:
/// <p><var>fileNumber</var> = The FileMan File number of the file you want to map to a class
/// <p><var>fmSettings</var> = FileMan configuration settings to use for this call.  This is an array passed by reference.  
/// Defaults for the settings come from the FileMan-to-Class configuration settings.
/// <p><var>fmFields</var> = If defined, limits the fields in the file that will be mapped.  This is an array of the form 
/// <var>fmFields(file-number,field-number)</var>.  Any required fields and fields defined in this array will be mapped
/// in the class definition.  If this array is empty or not defined, all fields in the file will be mapped.  
/// This array is passed by reference.
/// <p><var>classCount</var> = This parameter is passed by reference and will return a count of the classes created.
/// <p>Depending on the arguments passed in, this API may actually result in the generate of multiple
/// classes.  We might generate reference classes for pointer fields and child classes for Sub-Files/Multiples.
/// <p>Some examples:
/// <example>
/// Set fmSettings("recursion")=0	// Only map this file
/// Set fmSettings("display")=1		// Short screen display
/// Set fmSettings("logFile")="C:\Map\NEW PERSON.log"
/// // Map only the following fields from the "NEW PERSON" file:
/// //	NAME, STREET ADDRESS 1, STREET ADDRESS 2, STREET ADDRESS 3
/// //	CITY, STATE, ZIP CODE, PHONE (HOME), OFFICE PHONE, EMAIL ADDRESS
/// //	(Plus any required fields in the NEW PERSON file)
/// For n=.01,.111,.112,.113,.114,.115,.116,.131,.132,.151 { Set fmFields(200,n)=0 }
/// Do $System.OBJ.FM2Class.One(200,.fmSettings,.fmFields)
/// </example>
/// <example>
/// Set fmSettings("compile")=0
/// Set fmSettings("recursion")=2
/// // Map all fields and all related files for the NEW PERSON file
/// Do $System.OBJ.FM2Class.One(200,.fmSettings,,.count)
/// Write !,count," classes mapped."
/// </example>
ClassMethod One(fileNumber As %Numeric = "", ByRef fmSettings, ByRef fmFields, ByRef classCount As %Integer)
{
	QUIT:fileNumber=""
	do ConvertFiles^%fm2class(fileNumber,.fmSettings,.fmFields,.classCount,"$SYSTEM.OBJ.FM2Class.One")
	QUIT
}

/// Maps a list of FileMan files in the current namespace to a class definition.
/// <p>Arguments:
/// <p><var>fileList</var> = The FileMan File numbers of the files you want to map to a classes.  
/// <var>fileList</var> is a comma delimited list of file number or ranges of file numbers.
/// <p><var>fmSettings</var> = FileMan configuration settings to use for this call.  This is an array passed by reference.  
/// Defaults for the settings come from the FileMan-to-Class configuration settings.
/// <p><var>fmFields</var> = If defined, limits the fields in the file that will be mapped.  This is an array of the form 
/// <var>fmFields(file-number,field-number)</var>.  Any required fields and fields defined in this array will be mapped
/// in the class definition.  If this array is empty or not defined, all fields in the file will be mapped.  
/// This array is passed by reference.
/// <p><var>classCount</var> = This parameter is passed by reference and will return a count of the classes created.
/// <p>Depending on the arguments passed in, this API may actually result in the generate of more
/// classes that files specified.  We might generate reference classes for pointer fields and child classes for Sub-Files/Multiples.
/// <p>Some examples:
/// <example>
/// Set fmSettings("recursion")=0	// Only map this file
/// Set fmSettings("display")=1		// Short screen display
/// Set fmSettings("logFile")="C:\Map\NEW PERSON and DENTAL.log"
/// // Map only the following fields from the "NEW PERSON" file:
/// //	NAME, STREET ADDRESS 1, STREET ADDRESS 2, STREET ADDRESS 3
/// //	CITY, STATE, ZIP CODE, PHONE (HOME), OFFICE PHONE, EMAIL ADDRESS
/// //	(Plus any required fields in the NEW PERSON file)
/// // All fields from the DENTAL* files will be mapped
/// For n=.01,.111,.112,.113,.114,.115,.116,.131,.132,.151 { Set fmFields(200,n)=0 }
/// Do $System.OBJ.FM2Class.Some("200,220:226,727.806",.fmSettings,.fmFields)
/// </example>
ClassMethod Some(fileList As %String = "", ByRef fmSettings, ByRef fmFields, ByRef classCount As %Integer)
{
	QUIT:fileList=""&&($d(fileList)<10)
	do ConvertFiles^%fm2class(.fileList,.fmSettings,.fmFields,.classCount,"$SYSTEM.OBJ.FM2Class.Some")
	QUIT
}

/// Displays the version of the FM2Class utility
ClassMethod Version() As %Library.String
{
	QUIT $$Version^%fm2class()
	QUIT
}

/// Returns the version of the FM2Class utility
ClassMethod GetVersion() As %Library.String
{
	QUIT $$GetVersion^%fm2class()
}

}
