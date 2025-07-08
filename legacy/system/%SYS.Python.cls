/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides utilities for loading and using Python modules, running Python commands,
/// and starting the Python shell. For information on working with Python within IRIS,
/// see <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25SYS.Python">Using Embedded Python</a>.
Class %SYS.Python Extends %Library.SystemBase [ Final ]
{

Parameter %MODULENAME [ Internal ] = 13;

/// Loads a Python module and returns a handle to that module. On failure, this method returns 0.
/// Typically you use this method to bind the module to a variable, which you then use
/// to call code within the module. For example:
/// <example>
///  set mypython = ##class(%SYS.Python).Import("package.subpackage.name")
///  write mypython.helloWorld()
/// </example>
ClassMethod Import(name As %String) As %CPP.LongLong [ Language = cpp ]
{
}

/// Get a python object attribute.
Method %DispatchGetProperty(name As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Get a python object attribute.
Method %DispatchSetProperty(propName As %Library.String, value As %Library.String) [ Internal, Language = cpp ]
{
}

/// Runs one or more Python commands; to run multiple commands, separate the commands
/// with a new line, $char(10). This method returns 0 on success or -1 on failure.
ClassMethod Run(cmd As %String) As %Integer [ Language = cpp ]
{
}

/// Get current run time setting for PythonPath, if a new value is specified it
/// overwrites the run time value (used by config mgr).
ClassMethod Path() As %Integer [ Internal, Language = cpp ]
{
}

/// An API that affects just the current process.
/// The specified string argument will be added to sys.path relative to the instance dir on the next load of embedded python.
/// Without args, returns the current string.
/// With a string argument, this also loads OS Default libpython after it sets sys.path.
/// This API is used in IML classes with "lib/automl" to reflect where the numpy is in ML enabled kits.
/// Blocks IML from working if a non default python is already in the process (Also see AllowAutoML() ).
/// 
ClassMethod ConfigureAutoML(pathelement As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Set an integer in system memory. 
/// Without args, return the current integer.
/// If the integer is 1, AutoML ( ConfigureAutoML() ) will be allowed to start trying to run a non default python 
/// like the one in the CPF, for example.
/// This is quite likely to result in AutoML errors unless what you are doing has been integrated by Intersystems.
/// 
ClassMethod AllowAutoML(allow As %Integer) As %Integer [ Internal, Language = cpp ]
{
}

/// FT counter of irispython activations
/// 
ClassMethod IRISInsidePython() As %Integer [ Internal, Language = cpp ]
{
}

/// FT counter of libpython.so/.dll activations
/// 
ClassMethod PythonInsideIRIS() As %Integer [ Internal, Language = cpp ]
{
}

/// Returns platform (kit) identifier used in creation of IRIS kits and also in EP iris_site.py
/// 
ClassMethod IrisPlatform() As %String [ Language = cpp ]
{
}

/// Returns descriptive general information about process and system wide python and python related CPF settings.
/// Informational names/API compatibility not guaranteed.
/// 
ClassMethod GetPythonInfo(ByRef info) As %Integer
{
 k info
 s info("RunningLibrary")=..GetRunningLibrary()
 s info("RunningVersion")=..GetPythonVersion()
 s info("SystemVersion")=..GetCompileTimeVersionFull()
 s info("SystemVersionShort")=..GetCompileTimeVersion()
 s info("SystemPath")=..GetCompileTimePath()
 s cpfpp = $DATA(^|"%SYS"|CONFIG("config","PythonPath"))
 s cpfprl = $DATA(^|"%SYS"|CONFIG("config","PythonRuntimeLibrary"))
 s cpfprlv = $DATA(^|"%SYS"|CONFIG("config","PythonRuntimeLibraryVersion"))
 s info("CPF_PythonPath")=$case(cpfpp,0:"Not Set in CPF",:^|"%SYS"|CONFIG("config","PythonPath"))
 s info("CPF_PythonRuntimeLibrary")=$case(cpfprl,0:"Not Set in CPF",:^|"%SYS"|CONFIG("config","PythonRuntimeLibrary"))
 s info("CPF_PythonRuntimeLibraryVersion")=$case(cpfprlv,0:"Not Set in CPF",:^|"%SYS"|CONFIG("config","PythonRuntimeLibraryVersion"))
 s info("AllowNonSystemPythonForIntegratedML")=..AllowAutoML()
 s info("iris_site.py_platform")=..IrisPlatform()
 s info("PythonInsideIRIS")=..PythonInsideIRIS()
 s info("IRISInsidePython")=..IRISInsidePython()
 q
}

/// Returns descriptive version information about the python currently loaded in the process.
/// Example: "3.10.12 (main, Jun 11 2023, 05:26:28) [GCC 11.4.0]" on Ubuntu 22.
/// If python is not loaded it will return "Not Loaded".
/// Does not Load Python.
/// 
ClassMethod GetPythonVersion() As %String
{
	if "" = ..GetRunningLibrary() {q "Not Loaded"}
	else {
		set sys=##class(%SYS.Python).Import("sys")
		s version = sys.version
		s version = $TR(version,$C(10),"")
		q version
	}
}

/// Returns short form python version present on the build machine used to compile IRIS
/// 
ClassMethod GetCompileTimeVersion() As %Integer [ Internal, Language = cpp ]
{
}

/// Returns full form python version present on the build machine used to compile IRIS
/// 
ClassMethod GetCompileTimeVersionFull() As %Integer [ Internal, Language = cpp ]
{
}

/// Returns python runtime library path on the build machine used to compile IRIS
/// 
ClassMethod GetCompileTimePath() As %Integer [ Internal, Language = cpp ]
{
}

/// Version of Python used by PythonRuntimeLibrary in Major.Minor format: 3.9, 3.11, etc.
/// <br/>Used in properly loading PythonRuntimeLibrary into IRIS.
/// 
ClassMethod PythonRuntimeLibraryVersion(location As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// The full path (including library name) of the alternate python that you want IRIS to use
/// in %SYS.Python.Shell() and [Language=python] for all new processes.
/// <br/>For example, if you install the optional python 3.11 on Ubuntu 20.04 use:
/// <br/>/lib/x86_64-linux-gnu/libpython3.11.so.1.0
/// <br/>If you install the optional python 3.8 on RH 7.9 use:
/// <br/>/opt/rh/rh-python38/root/usr/lib64/libpython3.8.so
/// <br/>If you do not use a setting here, you'll get the default OS vendor system python.
/// 
ClassMethod PythonRuntimeLibrary(location As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// After libpython has been loaded, by whatever means, this returns the actual libpython in use by this process.
/// 
ClassMethod GetRunningLibrary() As %Integer [ Internal, Language = cpp ]
{
}

/// Use this to specify what libpython you want to be loaded for just this process by a future 
/// PerProcessRuntimeLibraryStart("UserPerProcess") call. Without arguments, it returns the value that you previously set.
/// 
ClassMethod PerProcessRuntimeLibrarySet(location As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Loads libpython into the current process
/// <br/>"UserPerProcess" will load the libpython you specified with PerProcessLibpythonSet()
/// <br/>"UserSystemWide" will load the libpython you specified with PythonRuntimeLibrary()
/// <br/>"CPF" will load the libpython you specified in the CPF
/// <br/>"OSDefault" will load the default libpython of the OS vendor that was compiled into IRIS
/// <br/>Any other argument acts as "OSDefault"
/// <br/>Without args it returns current flag (a number)
/// 
ClassMethod PerProcessRuntimeLibraryStart(mode As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Set a string in process memory. 
/// Without args, return the current string.
/// When libpython loads in the future, the specified string will be added to sys.path.
/// 
ClassMethod PerProcessRuntimeLibrarySetPathElement(element As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Set a string in process memory. 
/// Without args, return the current string.
/// When libpython loads in the future, the specified string will be added to sys.path relative to the instance dir.
/// 
ClassMethod PerProcessRuntimeLibrarySetRelativePathElement(element As %String) As %Integer [ Internal, Language = cpp ]
{
}

/// Given an ObjectScript string, returns a Python object of type bytes. 
/// The input string cannot contain any wide character.
ClassMethod Bytes(cmd As %String) As %CPP.LongLong [ Language = cpp ]
{
}

/// An internal methods, finish "callin" initialization
/// 
ClassMethod CallInInit() [ Internal, Language = cpp ]
{
}

/// Returns the Python <code><b>None</b></code> value.
ClassMethod None() As %CPP.LongLong [ Language = cpp ]
{
}

/// Returns the Python <code><b>True</b></code> value.
ClassMethod True() As %CPP.LongLong [ Language = cpp ]
{
}

/// Returns the Python <code><b>False</b></code> value.
ClassMethod False() As %CPP.LongLong [ Language = cpp ]
{
}

/// Validate the internal state session, returns the number of active python
/// objs. return -<num> if python is not inited or an invalid object is found.
/// 
ClassMethod Validate() As %Integer [ Internal, Language = cpp ]
{
}

/// Set the signal handling state 0 - swap, 1 - disable swapping iris will notify,
/// to python signal handling
/// 
ClassMethod ChangeSignalState(state As %Integer) As %Integer [ Internal, Language = cpp ]
{
}

/// If passed true, it doesn't reset the error context before invoking any python
/// feature (enable this before invoking any pdb method).
/// 
ClassMethod Debugging(state As %Integer) As %Integer [ Internal, Language = cpp ]
{
}

/// Loads the Python <code>builtins</code> module and returns a handle to that module. 
/// On failure, this method returns 0.
/// Using this method is equivalent to using <method>Import</method> to load the Python builtins module.
ClassMethod Builtins(flags As %Integer) As %CPP.LongLong
{
	return ..Import("builtins")
}

/// if flags bit 1 is set, the stderr (fd 2) output will be redirected to stdout (fd 1) if there is a current COS primary device, otherwise it will behave the original way and log it in messages.log
/// 
ClassMethod SetStdIOMode(flags As %Integer) As %Integer [ Internal, Language = cpp ]
{
}

/// This is deprecated. Please use the pip3 command line to install packages.
/// 
ClassMethod Install(packages As %String, dir As %String = "") As %Status [ Deprecated, Internal ]
{
	Write !
	Write "DEPRECATED:  Please use the pip3 command line to install Python packages",!
	Write "                 pip3 install ",$S(dir'="":"--target="_dir_" ",1:""),packages,!
	Write !
	Quit $$$ERROR($$$NotImplemented)
}

/// Starts the interactive Python shell. 
/// To use this method, you must have USE permission on the %Developer resource.
/// To exit the shell, type the command <code>quit()</code>
/// <p>If <var>vars</var> is 1, then any OREF variables present in the ObjectScript
/// shell are also available in the Python shell; the reverse is not true.</p>
ClassMethod Shell(vars As %Integer = 0) As %Status
{
	#dim status As %Status = $$$OK
	#dim signalstate As %Integer = ""
	#dim stdiomode As %Integer = ""
	#dim locals As %Integer = ""
	Try {
		// Must have %Developer:USE to use Shell()
		If '$system.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
			Set status = $$$ERROR($$$OperationRequires,$$$DevelopmentResourceName_":"_$$$PermUseName)
			Quit
		}

		// Set command line recall context for Python.  Note when in PY mode, the command line
		// recall will treat Ctrl-D on an empty line as a termination character (it will not if
		// there are characters in the line).
		Do $system.Process.NewLineRecallContext("PY")

		// Enable signal/stdio processing
		Set signalstate = ..ChangeSignalState(0)
		Set stdiomode   = ..SetStdIOMode(3)

		Set sys      = ..Import("sys")
		Set code     = ..Import("code")
		Set builtins = ..Import("builtins")
		Set locals   = ..Builtins().dict()


		// Copy top level locals objects into the python space
		If vars {
			Set locals = ..Builtins().dict()
		    Set var=""
			For {
				Set var = $ORDER(@var)
				Quit:var=""

				If $Data(@var)#2,$IsObject(@var) {
					Do locals."__setitem__"(var,@var)
				}
			}
		}

		Write !,"Python ",$REPLACE(sys.version,$C(10),$C(13,10))," on ",sys.platform,!
		Write "Type quit() or Ctrl-D to exit this shell.",!

		Set interpreter = code.InteractiveInterpreter(locals)
		Do interpreter.runsource("import iris")
		Set more = 0
		Set buffer = ""
		For {
			Write $S(more:"...",1:">>>")," "
			Read ln,!

			// Exit on Ctrl-D on an empty line
			Quit:$ZB=$C(4)

			Set buffer = buffer _ $LB(ln)
			Set src = $LTS(buffer,$C(10))
			#; Use $xecute so global write requests will not be seen as
			#; coming from a %SYS routine. If this is moved to a non-%
			#; routine, it can be restored to the original:
			#; Set more = interpreter.runsource(src)
			Set more = $xecute("(int,src) quit int.runsource(src)",interpreter,src)
			If 'more {
				// Reset the buffer when done with multi-line statements
				Set buffer = ""
			}
		}

	} Catch ex {
		// The shell might throw a SystemExit if the user calls quit(), so we ignore it
		If ex.Data'["'SystemExit'" {
			Set status = ex.AsStatus()
		}
	}
	
	If locals'="" {
	    do locals.clear()
	}

	// Restore previous signal state and stdio mode
	Do:signalstate'="" ..ChangeSignalState(signalstate)
	Do:stdiomode'="" ..SetStdIOMode(stdiomode)

	// Report any errors we encountered (this is an interactive shell after all)
	If $$$ISERR(status) {
	    Do $system.OBJ.DisplayError()
		Write !
	}

	Quit status
}

/// Set the mode of python to Interactive meaning that signal handling state swaps will be allowed.
/// Interactive mode has a performance cost, but enables useful features like saving/restoring terminal state and generating better documentation.
/// Returns previous signal state: 0 - swapping allowed, 1 - swapping disabled, -1 - Swapping unapplicable to your platform.
/// 
ClassMethod SetInteractiveMode(state As %Integer) As %Integer
{
 Quit ..ChangeSignalState(state)
}

/// Given two ObjectScript <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">lists</a>, 
/// returns a Python list that contains the same data as <var>contentList</var>, 
/// with each member of the list having the data type specified in <var>typeList</var>.
/// For example, the following code returns a Python list where each member of the list has the value 42, 
/// but is represented as ODBCTYPEbit(SQLBIT), ODBCTYPEnumeric(SQLNUMERIC), ODBCTYPEdecimal(SQLDECIMAL), and ODBCTYPEinteger(SQLINTEGER), respectively.
/// More info on the type values can be found in  %occODBC.inc as well as:<br>
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_datatype#RSQL_datatype_intcodes">the docs</a><br>
/// <br>
/// <example>
/// Include %occODBC
/// set clist = $lb(42, 42, 42, 42)
/// set tlist = $lb(-7, 2, 3, 4)
/// [or]
/// set tlist = $lb($$$ODBCTYPEbit,$$$ODBCTYPEnumeric,$$$ODBCTYPEdecimal,$$$ODBCTYPEinteger)
/// set plist = ##class(%SYS.Python).ToListTyped(clist, tlist)
/// </example>
/// <br>
/// This type translation obeys Intersystems SQL Rules, so for the string and binary ODBC types,
/// $C(0) will turn into Python "". For all ODBC types, $lb(,"") will be 2 Python "None" elements.
/// 
ClassMethod ToListTyped(contentList As %CPP.BinList, typeList As %CPP.BinList) As %CPP.LongLong [ Language = cpp ]
{
}

/// Takes in a 2D ObjectScript $LIST, and another $LIST with type info for each column in the first $LIST.<br>
/// Returns a copy of the first $LIST as a python list with matching python types.<br>
/// <br>
/// The types are the same as for ToListTyped.<br>
/// <example>
/// set plist = $system.Python.To2DListTyped($lb($lb("philip",21,"electrician"),$lb("mary",22,"plumber")), $lb(12,4,12))
/// </example>
/// 
ClassMethod To2DListTyped(contentList As %Integer, typeList As %Integer) As %CPP.LongLong [ Internal, Language = cpp ]
{
}

/// Given <var>contentList</var> (an ObjectScript <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">list</a>),
/// this method returns a Python list that contains the same data. For example:
/// <example>
///  set clist = $lb(123, 456.789, "hello world")
///  set plist = ##class(%SYS.Python).ToList(clist)
/// </example>
/// <br>Warning:
/// <br>Don't pass binary data via this API, Use ToListTyped with one of the binary ODBC types instead.
/// <br>If you put binary data in this API, IRIS will try to translate it as a UTF8 string.
/// 
ClassMethod ToList(contentList As %CPP.BinList) As %CPP.LongLong [ Language = cpp ]
{
}

Property ModDesc As %CPP.LongLong [ Internal, Private ];

Property UID As %CPP.Integer [ Internal, Private ];

}
