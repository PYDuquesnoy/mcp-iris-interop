/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <style type="text/css">
///    arg { font-style: italic; font-weight: bold; }
///    table.parm-format { border-collapse: collapse; border-width: 1px; margin-top: 20px; }
///    table.parm-format TD { border: 1px solid black; padding: 0px 10px 0px 10px; }
/// </style>
/// 
/// The InterSystems IRIS UnitTest framework is composed of several classes that have the package name (prefix) <b>%UnitTest</b>. 
/// Of these classes, the <class>%UnitTest.Manager</class> class is the superclass of the UnitTest infrastructure, and is 
/// primarily responsible for the following tasks:
/// <ul>
///   <li>Individual UnitTest Invocations</li>
///   <li>Pre/Post Test Processing</li>
///   <li>Runtime Processing & Reporting</li>
///   <li>Test/Error Processing & Analysis</li>
///   <li>Statistics Collection & Aggregation</li>
///   <li>etc.</li>
/// </ul>
/// Developers familiar with the <i>xUnit</i> framework should notice a passing resemblance, as
/// these two frameworks share a common testing philosophy.
/// </br></br>
/// Prior to invoking any of the methods within this class, you must first perform the following setup instructions:
/// <ul>
///   <li>Set the global <b>^UnitTestRoot</b> to a valid root directory that contains all of the UnitTest classes from which 
///       all UnitTests will be invoked </br>
///       <h3>Example:</h3>
///       <example>
///         set ^UnitTestRoot="C:\MyUnitTests"  ; Adding a final slash is optional
///       </example>
///   </li>
/// </ul>
/// Once the setup has been completed, launching a UnitTest is as simple as invoking one the following methods:
/// <ul>
///   <li><method>RunTest</method> - Run all tests specified by the <b><i>testspec</i></b> parameter and delete all associated test classes after 
///       invocation (Unless otherwise specified).</li>
///   <li><method>DebugRunTestCase</method> - Run all tests specified by the <b><i>testspec</b></i> parameter without deleting the corresponding 
///       test classes after invocation. </br>
///       This method requires that all test classes must first be loaded before the first invocation, which 
///       can be accomplished by initially invoking the <method>DebugLoadTestSuite</method> method.
/// </ul>
/// The RunTest(<b><i>testspec</i></b>, <b><i>spec</i></b>, <b><i>userparam</i></b>) method, more specifically, performs the following tasks: </br>
/// <ol type=1>
///   <li>Evaluate all of the qualifiers specified by the <b><i>qspec</i></b> parameter
///     <ul type=square>
///       <li>If this parameter contains the qualifiers <b>/cleanup/run/delete</b>, without the <b>/debug</b> qualifier, 
///       then all globals, classes, and routines within the current namespace will be recorded before each invocation 
///       of the <method>RunOneTestSuite</method> method.  After each invocation of this method, the namespace will be purged 
///       of all globals, classes and routines, other than those previously recorded</li> 
///     </ul>
///   </li>
///   <li>Evaluate all of the user parameters specified by the <b><i>userparam</i></b> parameter
///     <ul type=square>
///       <li>If this parameter contains the value <b>/log</b>, then all processing information will be logged to the <b>UNITTEST.LOG</b> file 
///       which is located in the <b>mgr</b> directory of the IRIS Instance (e.g. $ZU(12))</li>
///     </ul>
///   </li>
///   <li>Invoke the following method before any UnitTests are run: <method>OnBeforeAllTests</method></li>
///   <li>Collect all UnitTest <i>testsuites</i> (directories) specified by the <b><i>testspec</i></b> parameter, and recursively all associated <i>sub-testsuites</i> (sub-directories)
///       (assuming that the <b>/recursive</b> qualifier is on (the default)), whilst skipping all sub-directories whose names begins with an underscore </br>
///       See the notes within the <method>RunTest</method> method for additional details</li>
///   <li>For each UnitTest's <i>testsuites</i> collected in the previous step, invoke the <method>RunOneTestSuite</method> method which performs the following tasks:</li>
///     <ol type=A>
///       <li>Collect all UnitTest classes specified by the <b><i>dir</i></b> parameter, along with each class's corresponding test methods 
///           when the <b><i>testspec</i></b> parameter is defined with the following nomenclature: </br>
///           [-]<i>testsuite [ :[testcase] [ :testmethod ] [ ;[testcase] [ :testmethod ] ]<sup>*</sup> ]</i>
///       </li>
///       <li>Record the start of the testing process based on the specified <b><i>suite</i></b> parameter </br>
///           See item (3) in the <i>Important Notes</i> section below for addition details
///       </li>
///       <li>Load and compile all relevant files in the directory specified by the <b><i>dir</i></b> parameter
///         <ul type=square>
///           <li>If the <b>/loadxml</b> qualifier is true (the default), then all XML files (<b>*.xml, *.XML</b>) will be loaded</li>
///           <li>If the <b>/loadudl</b> qualifier is true (the default), then all UDL files (<b>*.cls, *.mac, *.int, *.inc, *.CLS, *.MAC, *.INT, *.INC</b>) will be loaded</li>
///           To see the current qualifier values, invoke the following method: <i>do $SYSTEM.OBJ.ShowQualifiers()</i>
///         </ul>
///       </li>
///       <li>For each UnitTest class collected in step (5A) above, invoke the <method>RunOneTestCase</method> method which performs the following tasks:</li>
///         <ol type=I>
///           <li>Record the start of the testing process based on the specified <b><i>suite</i></b> and <b><i>class</i></b> parameters </br>
///           See item (3) in the <i>Important Notes</i> section below for addition details
///           </li>
///           <li>Instantiate the UnitTest class specified by the <b><i>class</i></b> parameter</li>
///           <li>Record the current Process Values</li>
///           <li>Invoke the following method: <method>OnBeforeTestCase</method></li>
///           <li>Invoke the following method: <method>class.OnBeforeAllTests</method></li>
///           <li>Collect all UnitTest methods from the specified <b><i>class</i></b> parameter, which have the following nomenclature: Test* (e.g. Test1 or TestSQL)</li>
///           <li>For each method collected in the previous step, perform the following steps:
///             <ol type=a>
///               <li>Record the start of the testing process based on the <b><i>suite</i></b>, <b><i>class</i></b> and <b><i>method</i></b> parameters </br>
///                   See item (3) in the <i>Important Notes</i> section below for addition details
///               </li>
///               <li>Invoke the following method: <method>OnBeforeOneTest</method></li>
///               <li>Invoke the following method: <method>class.OnBeforeOneTest</method></li>
///               <li>Invoke the specified UnitTest method (e.g. Test1 or TestSQL)
///               <li>Invoke the following method: <method>class.OnAfterOneTest</method></li>
///               <li>Invoke the following method: <method>OnAfterOneTest</method></li>
///               <li>Record the end of the testing process based on the <b><i>suite</i></b>, <b><i>class</i></b> and <b><i>method</i></b> parameters </br>
///                   See item (3) in the <i>Important Notes</i> section below for addition details
///               </li>
///             </ol>
///           </li>
///           <li>Repeat the previous steps (a) through (g) for all of the methods collected in step (VI) above</li>
///           <li>Invoke the following method: <method>class.OnAfterAllTests</method></li>
///           <li>Invoke the following method: <method>OnAfterAllTests</method></li>
///           <li>Cleanup and Restore any modified Process Values</li>
///         </ol>
///       </li>
///       <li>Repeat the previous steps (I) through (XI) for all of the classes collected in (5A) above 
///       <li>Delete all the classes loaded in step (5C) above
///       <li>Record the end of the testing process based on the <b><i>suite</i></b> parameter </br>
///           See item (3) in the <i>Important Notes</i> section below for addition details
///       </li>
///     </ol>
///   <li>Repeat the previous steps (A) through (G) for all <i>testsuites</i> (directories) and all <i>sub-testsuites</i> (sub-directories) collected in step (4) above</li>
/// </ol>
/// <b><u>IMPORTANT NOTES</u></b><br/>
/// <ol>
///   <li>Throughout this class, the terms <b>qspec</b> and <b>qualifier</b> will be used interchangeably, as many methods in this class use the 
///       <b>qspec</b> parameter, which is a concatenated list of supported system flags and qualifiers documented on the following page: </br>
///       <a href="https://docs.intersystems.com/irislatest/csp/docbook/Doc.Results.cls?docs%5Bquery%5D=qspec" target="_blank">System Flags and Qualifiers</a>
///       </br/></br>
///       The <b>qspec</b> parameter can specify qualifiers in the following format: 
///        <i>/[no]&lt;qualifier&gt;[=&lt;value&gt;][/[no]&lt;qualifier&gt;[=&lt;value&gt;]]*</i>
///   </li>
///   </br>
///   <li>The loading, running and deletion tasks can each be skipped by specifying the following qualifiers respectively: </br>
///       <b>/noload</b>, <b>/norun</b> and <b>/nodelete</b>
///   </li>
///   </br>
///   <li>UnitTest results are saved to the following globals.  The first global is used by the <i>UnitTest Results CSP Pages</i>, while 
///       the second global is used for status processing and debugging:
///     <ul type=square>
///       <li><i>^|ns|UnitTest.Result(id,suite[,class[,method]])=$LIST(...) of Runtime Information</i> </br>
///           <b>ns</b> - The Namespace in which the UnitTest is being invoked (e.g. "USER") </br>
///           <b>id</b> - The value of the Name/Value pair <i>Index</i> within the result URL
///       </li>
///       <li><i>^IRIS.Temp.UnitState=$LB(suit[,class[,method]])</i></li>
///     </ul>
///   </li>
/// </ol>
/// <br><br>
Class %UnitTest.Manager Extends %RegisteredObject [ System = 3 ]
{

/// ------------------------------------------------------------------------------
/// DESCRIPTION:
///    This method, which always resides at the top of each class, will be used
///    similar to an INCLUDE file where MACRO definitions can be defined for
///    the entire class.
/// ------------------------------------------------------------------------------
Method %INCLUDE()
{
#DEFINE GetMessagesLogFile $ZU(9,"")
#DEFINE GetReDirectIOSwitch $ZU(82,12)
#DEFINE SetReDirectIOSwitch(%val) $ZU(82,12,%val)
#DEFINE GetMnemonicRoutine $ZU(96,12)
#DEFINE GetpzuintsVal(%index) $ZU(115,%index)
#DEFINE SetpzuintsVal(%index,%val) $ZU(115,%index,%val)
#DEFINE GetSQLRuntimeModeFlag $$$GetpzuintsVal(5)
#DEFINE SetSQLRuntimeModeFlag(%val) $$$SetpzuintsVal(5,%val)

#DEFINE GetTestState(%level) $CASE(%level,1:"passed",2:"skipped",:"failed")

#DEFINE ResetProcessState do $$$ZuSetState(40,$$$ZuGetDefault(40)),$$$ZuSetPzuints(5,0),$$$ZuFixDate

/// While the following two MACRO groupings are semantically equivalent, the
/// first MACRO of each grouping should be used within this class's 'Method' code
/// and the second MACRO should be used within this class's 'ClassMethod' code:

#DEFINE IsParallel $s(..Debug:0,(..UserParam_"/")["/noparallel/":0,1:1)
#DEFINE IsParallelCM(%obj) $s(%obj.Debug:0,(%obj.UserParam_"/")["/noparallel/":0,1:1)

#DEFINE IsParallelWorker ((..UserParam_"/")["/isparworker/")
#DEFINE IsParallelWorkerCM(%obj) ((%obj.UserParam_"/")["/isparworker/")

/// ------------------------------------------------------------------------------
}

/// <b>DEPRECATED</b>. Use the <property>ResultId</property> property.
Property LogIndex [ Deprecated ];

/// A Boolean flag that is set to true (1) if the <b>/debug</b> qualifier is enabled (1).
Property Debug;

/// A Boolean flag that is set to true (1) if the <b>/display=all</b> qualifier is enabled (1).
Property Display;

/// A Boolean flag that is set to true (1) if unexpected public variables should trigger an error.
Property ReportVariableLeaks;

/// A Boolean flag that is set to true (1) if the <b>/loadxml</b> qualifier is enabled (1).
Property LoadXML;

/// A Boolean flag that is set to true (1) if the <b>/loadudl</b> qualifier is enabled (1). </br>
/// UDL files: *.cls, *.mac, *.int, *.inc, *.CLS, *.MAC, *.INT, *.INC
Property LoadUDL;

/// The directory that contains the current UnitTest.
Property CurrentDir;

/// Set to the <method>RunTest</method> method's third parameter <b>userparam</b>, if specified as a string.
Property UserParam As %String;

/// Set to the <method>RunTest</method> method's third parameter <b>userparam</b>, if specified as an array.
/// This array is populated from the first level subscripts of the <b>userparam</b> parameter. </br>
/// Allow users to store additional information, like platform, product version, etc. for each UnitTest.
/// This information can be later cross-referenced in the result.
Property UserFields As array Of %String;

/// Private property for <b>InterSystems INTERNAL USE ONLY!</b>
Property TheStack [ MultiDimensional, Private ];

/// Private property to hold information about the UnitTest's Namespace.
Property NSInfo [ Internal, MultiDimensional, Private ];

/// Private property set primarily in the <method>%OnNew</method> method to hold information 
/// about the environment's Process Values.  These original values can be restored if changed 
/// during the invocation of the UnitTest.
Property Environment [ Internal, MultiDimensional, Private ];

/// Private property to hold parallel harness when in use.
Property Parallel As %UnitTest.Parallel [ Internal, Private ];

/// Property to hold the Result ID (instance slot) in the <b>^UnitTest.Manager</b> global.
Property ResultId As %Integer;

/// Internal property to hold the Namespace in which the UnitTest was run.
Property OriginNS As %String [ Internal ];

/// <p>This method invokes all of the UnitTest methods contained within the classes specified
/// by the <i>testspec</i> parameter.  During the invocation of these methods, a running log
/// is maintained within the following global so that it can be inspected by other processes:
/// <b>^UnitTest.Result</b><br> </p>
/// <p><b>Parameters:</b>
/// <dl>
/// <dt><i>testspec</i></dt>
/// <dd><i>&lt;testspec list&gt;</i> used to invoke UnitTests; passed in as one of the following formats:<br/>
///   <dl><dd>
///     <b>String</b>:  testspec=<i>&lt;testspec list&gt;</i><br/>
///     <b>Array</b>:   testspec(<i>&lt;testspec list&gt;</i><sup>*</sup>)="" <i><b>OR</b></i> testspec(#<sup>*</sup>)=<i>&lt;testspec list&gt;</i> <br/>
///     <b>Global</b>:  testspec="^global"  (e.g. ^global(<i>&lt;testspec list&gt;</i><sup>*</sup>)="" <i><b>OR</b></i> ^global(#<sup>*</sup>)=<i>&lt;testspec list&gt;</i>)
///   </dl>
/// <b>Syntax</b><br/><br/>
/// <dd><i>&lt;testspec data&gt;</i> ::= [-]<i>testsuite [ :[testcase] [ :testmethod ] [ ;[testcase] [ :testmethod ] ]<sup>*</sup> ]</i>
/// <dd><i>&lt;testspec list&gt;</i> ::= "<i>&lt;testspec data&gt;</i> [ ,<i>&lt;testspec data&gt;</i> ]<sup>*</sup>"
/// <dd><i>&lt;testsuite root&gt;</i> ::= // The first instance of the <i>testsuite</i> value within the <i>&lt;testspec list&gt;</i>
///   <dl>
///     <dd><i>testsuite</i>
///     <dl><dd>
///       A directory (and possibly all of its sub-directories) that's a child of the directory referenced in the
///       <b>^UnitTestRoot</b> global.  This directory contains all of the UnitTest classes from which all UnitTests will be invoked.
///       <dl><dd>
///         <u>NOTE-1</u><br/>
///         The <b>^UnitTestRoot</b> global must specify a valid directory whose existence is checked during the invocation of the <b>RunTest(...)</b> method.
///       </dl>
///       <dl><dd>
///         <u>NOTE-2</u><br/>
///         By default, the <b>RunTest(...)</b> method will recursively process all sub-directories unless
///         the <b>/norecursive</b> qualifier is passed to the <b><i>qspec</i></b> parameter.
///       </dl>
///       <dl><dd>
///         <u>NOTE-3</u><br/>
///         If a negative-sign (-) precedes the <i>testsuite</i>, then this directory (and all of its sub-directories)
///         will be excluded from UnitTest invocations.<br/>
///         A <i>&lt;testsuite root&gt;</i> (without a negative-sign) must first be included before a -<i>testsuite</i>
///         can be excluded, as in the following example:<br/>
///       <dl><dd>
///         <i>&lt;testspec list&gt;</i> = "SQL,-SQL\Embedded"
///       </dl>
///       </dl>
///     </dl>
///     <dd><i>testcase</i> (Optional)
///     <dl><dd>
///       A class, specified in the following format, which extends one of the testing classes (e.g. <b>%UnitTest.TestCase</b>) and contains testing methods: <i>package.class</i> (e.g. Sample.Person)
///     </dl>
///     <dd><i>testmethod</i> (Optional)
///     <dl><dd>
///       A testing method name in the following format: <i>Test*</i>  (e.g. Test1 or TestFirst)
///     </dl>
///   </dl>
///   <dl>
///     <dd><b><u>NOTE</u></b><br/>
///     If no value is specified for the <i>testspec</i> parameter, then the directory referenced
///     in the <b>^UnitTestRoot</b> global will be used for the <i>testsuite</i> value.<br/>
///     Any subdirectory whose name begins with an underscore ( _ ) will be skipped.
///   </dl>
/// <dt><i>qspec</i>
/// <dd>This parameter has a name/term that is used interchangeably with the term <b>qualifier</b>, and a value
///     that is a concatenated list of supported system flags and qualifiers documented on the following page: 
///       <a href="https://docs.intersystems.com/irislatest/csp/docbook/Doc.Results.cls?docs%5Bquery%5D=qspec" target="_blank">System Flags and Qualifiers</a>
///     </br/></br>
///     This parameter allows the specification of qualifiers in the following format: 
///        <i>/[no]&lt;qualifier&gt;[=&lt;value&gt;][/[no]&lt;qualifier&gt;[=&lt;value&gt;]]*</i>
///     </br></br>
///     Example: <b>/noload/norecursive</b>
///     </br></br>
///     The first four qualifiers below (<b>debug</b>, <b>load</b>, <b>run</b>, and <b>recursive</b>) are negatable Booleans,
///     which can be enabled by explicitly specifying the qualifier name (e.g. <b>/debug</b>) or disabled by either
///     adding the prefix <b>no</b>, or by adding the value zero <b>=0</b>, as in the following respective examples: 
///     <b>/nodebug</b> OR <b>/debug=0</b>
///     </br></br>
///     <b>/debug</b>: Run in debug mode, which causes an execution <i>BREAK</i> if a UnitTest fails. Default is <b>/nodebug</b>.
///     </br></br>
///     <b>/load</b>: Load the corresponding UnitTest classes for the specified <b><i>testspec</i></b> parameter. Default is <b>/load</b>. 
///     If both the <b>/load</b> and <b>/run</b> qualifiers are enabled (true), then all loaded classes, routines, and CSP files will be deleted after 
///     all UnitTests have finished running. To prevent the post-deletion task, invoke the <method>DebugLoadTestSuite</method> method to first load all
///     appropriate UnitTest classes and then invoke the <b>DebugRunTestCase</b> method to actually run the corresponding UnitTests.
///     </br></br>
///     <b>/run</b>: Run all UnitTests specified by the <b><i>testsuite</i></b> parameter.  Use the <b>/norun</b> qualifier if you only want to load, 
///     but not run, all corresponding UnitTest classes specified by the <b><i>testsuite</i></b> parameter. Default is <b>/run</b>.
///     </br></br>
///     <b>/recursive</b>: Recurse the specified directory when loading UnitTest classes. Default is <b>/recursive</b>.
///     </br></br>
///     <b>/display=all</b>: Display extended information when loading and running UnitTest classes and tests. <b>/display=none</b> displays limited information. Default is <b>/display=all</b>.
///     </br></br>
///     <b>/autoload</b>: Automatically load sub-directories with the given name when loading test classes.
///     Default is <b>/autoload=_autoload</b>.
///     When this qualifier is specified, classes are loaded from the given sub-directory of the current directory and its ancestors.
///     This makes it possible to use a class in multiple test suites without copying it to each of their descendant directories.
///     </br></br>
///     <b>/nodelete</b>: Do not delete loaded classes when the UnitTest has finished running.
///     </br></br>
/// </dd> 
/// 
/// <dt><i>userparam</i> 
/// <dd>An arbitrary argument passed in by the caller, which allows for the storage of additional 
///     information, like platform, product version, etc. </br>
///     If this parameter is passed a string, then it becomes the value for the <property>UserParam</property> property. </br>
///     If this parameter is passed an array, then the first level subscripts and their values are used to populate the <property>UserFields</property> array property. </br>
///     This information can be later cross-referenced in the result.
/// </dd></dl>
/// <h3>Examples:</h3>
/// <example language="COS">
///  // --- RunTest(...) Examples ---
///  
///  // --- Setup ---
///  set ^UnitTestRoot="C:\UnitTests\"
///  
///  // --- UnitTest Directories ---
///  // C:\UnitTests\SQL\Embedded
///  // C:\UnitTests\SQL\Dynamic
///  // C:\UnitTests\SQL\ODBC
///  // C:\UnitTests\SQL\JDBC
///  
///  // --- Passing 'testspec' as a String ---
///  set tSC=##class(%UnitTest.Manager).RunTest("SQL\Embedded,SQL\Dynamic")
///  
///  // --- Passing 'testspec' as an Array ---
///  set utSpecs("SQL\Embedded")=""   // Alternatively:  set utSpecs(1)="SQL\Embedded"
///  set utSpecs("SQL\Dynamic")=""    //                 set utSpecs(2)="SQL\Dynamic"
///  set tSC=##class(%UnitTest.Manager).RunTest(.utSpecs)
///  
///  // --- Passing 'testspec' as a Global ---
///  set ^utSpecs("SQL\Embedded")=""  // Alternatively:  set ^utSpecs(1)="SQL\Embedded"
///  set ^utSpecs("SQL\Dynamic")=""   //                 set ^utSpecs(2)="SQL\Dynamic"
///  set tSC=##class(%UnitTest.Manager).RunTest("^utSpecs")
///  
///  // --- Passing 'testspec' as an Array (Complex Example) ---
///  set utSpecs("SQL\Embedded:SQL.Embedded:Test1;:Test2")=""
///  set utSpecs("SQL\Dynamic::Test1;:Test2")=""
///  set tSC=##class(%UnitTest.Manager).RunTest(.utSpecs,"/recursive=0")
///  
///  // --- Passing 'testspec' as a String (With Exclusions) ---
///  set tSC=##class(%UnitTest.Manager).RunTest("SQL,-SQL\ODBC,-SQL\JDBC")
/// </example>
/// <b><u>NOTE</u></b><br/>
/// If any of your code needs to run in the <b>%SYS</b> namespace, change to the <b>%SYS</b> namespace
/// to run that specific code (e.g. ZN "%SYS"), then return to the original namespace for continued code processing.
/// 
ClassMethod RunTest(ByRef testspec As %String, qspec As %String, ByRef userparam) As %Status
{
	set tSC=$$$OK
	
 try {
	merge testspecCopy=testspec            // Copy the 'testspec' parameter to avoid returning an altered value by reference!
	
	set tSC=..RunTestSuites(.testspecCopy,.qspec,.userparam)
	$$$THROWONERROR(tSC,tSC)
 }
 catch tException {
	set tSC=tException.AsStatus()
	$$$ISINTERRUPTTHROW(tSC) // Throw Hard Error on <INTERRUPT>!
	do $SYSTEM.Status.DisplayError(tSC)
 }
	RETURN tSC
}

/// <p>
/// This method is used to load, but not run, all corresponding UnitTest classes specified by the
/// <b><i>testsuite</i></b> parameter. </br>
/// Once the UnitTest classes are loaded by this method, the <method>DebugRunTestCase</method> method
/// can be invoked to run all of the corresponding UnitTests over and over again, without having to reload the UnitTest classes. 
/// </br></br> 
/// Developers should use the <method>DebugLoadTestSuite</method> method in conjunction with the <method>DebugRunTestCase</method> method
/// to load all UnitTest classes once, and then run all corresponding UnitTests as often as necessary during the development, debugging 
/// and testing process.
/// </p>
ClassMethod DebugLoadTestSuite(testsuite As %String = "", qspec As %String = "") As %Status
{
	Quit ..RunTest(testsuite,"/norecursive"_qspec_"/load/norun/nodelete")
}

/// <p>
/// This method is used to run all UnitTests that were previously loaded by the <method>DebugLoadTestSuite</method> method. </br>
/// Both the <b><i>testsuite</i></b> and <b><i>testcase</i></b> parameters are required. </br>
/// The <b><i>testcase</i></b> parameter is in the form <i>package.class</i> and the <i>testmethod</i> parameter
/// is a method within the UnitTest class. 
/// </br></br>
/// Developers should refer to the <method>DebugLoadTestSuite</method> method to see how these two methods are used
/// in conjunction during the development, debugging and testing process.
/// </p>
ClassMethod DebugRunTestCase(testsuite As %String = "", testcase As %String = "", qspec As %String = "", testmethod As %String = "", ByRef userparam) As %Status
{
	s test = $p(testsuite,"^",1)
	s:$find(testsuite,"^")>0 options = $e(testsuite,$find(testsuite,"^"),$l(testsuite))
	Quit:$g(options)'="" ..RunTest(test_":"_testcase_":"_testmethod_"^"_options,"/norecursive"_qspec_"/noload/run/nodelete",.userparam)
	Quit:$g(options)="" ..RunTest(test_":"_testcase_":"_testmethod,"/norecursive"_qspec_"/noload/run/nodelete",.userparam)
}

ClassMethod PurgeLog() As %Status
{
	Quit ..PurgeResult()
}

ClassMethod PurgeResult() As %Status
{
	Lock +^UnitTest.Result
	Kill ^UnitTest.Result,^UnitTest.ResultI
	Lock -^UnitTest.Result
	Quit $$$OK
}

/// <p>
/// This method will wipe all data from this Namespace in addition to all PPG information. This method
/// is useful in cleaning a Namespace before running all UnitTests. 
/// </br></br>
/// This should <b>never</b> be invoked on a production system!
/// </p>
ClassMethod WipeNamespace()
{
	If $namespace="%SYS" Write "Not in %SYS namespace",! Quit
	#; Free any locks we have
	Lock
	Set manager=..%New()
	do manager.CleanupGeneralProcVals()  // Cleanup & Restore General Process Values!
	Set manager.Display="log,error"
	Set manager.NSInfo("$zs")=$zs
	Set manager.NSInfo("gbl","UnitTestRoot")="", manager.NSInfo("gbl","UnitTest.Result")="",manager.NSInfo("gbl","UnitTest.ResultI")=""
	Set sc=manager.CleanNamespace() If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc)
	Write !,"Rebuilding Extent Index...",!
	Set sc=$SYSTEM.OBJ.RebuildExtentIndex()  If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc)
}

/// <p>
/// This is a private and internal method that is invoked via the <method>RunTest</method> method, but requires a 
/// value for each of its three parameters, be it the empty-string ("") or otherwise.
/// </p>
ClassMethod RunTestSuites(%testspec As %String, %qspec, ByRef %userparam) As %Status
{
	Set allowedvars=..ReturnAllowedPublicVariables()
	Do
	. New @($listtostring(allowedvars))
	. Set sc=..realRunTestSuites(.%testspec,.%qspec,.%userparam)
	RETURN sc
}

/// <p>
/// This is a private and internal method that is invoked via the <method>RunTestSuites</method> method in order to push 
/// an extra frame on the stack so that variables can be <i>new</i>ed before performing the bulk of the tasks associated
/// with the <method>RunTest</method> method.
/// </p>
ClassMethod realRunTestSuites(ByRef testspec As %String, qspec, ByRef userparam) As %Status [ Internal ]
{
	Set manager=..%New()
	If manager=$$$NULLOREF Quit %objlasterror
	;
	Set sc=$$$qualifierParseAlterDefault("UnitTest","/keepsource",.qspec,.qstruct) q:$$$ISERR(sc) sc
	
 try {
	
	set SQLStatsFlagSYS=$SYSTEM.SQL.SetSQLStatsFlag(0)     // Turn OFF SQLStats-flag (SYSTEM)
	set SQLStatsFlagJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(0)  // Turn OFF SQLStats-flag (JOB)
	
	Kill ^IRIS.Temp.UnitState
	set cleanup=0,parallelOpen=0  // Initialize flags!
	Set manager.Debug=$$$qualifierGetValue(qstruct,"debug")
	Set manager.Display=$s($$$qualifierGetValue(qstruct,"displaylog"):"log",1:"")_","_$s($$$qualifierGetValue(qstruct,"displayerror"):"error",1:"")
	Set manager.ReportVariableLeaks=$$$qualifierGetValue(qstruct,"findleakedvariables")
	Set manager.LoadUDL=$$$qualifierGetValue(qstruct,"loadudl")
	Set manager.LoadXML=$$$qualifierGetValue(qstruct,"loadxml")
	Set manager.UserParam=$g(userparam)
	if $$$IsParallelCM(manager) { set manager.Parallel=##class(Parallel).%New(),testspecParallel="",parallelOpen=1 }
	Set key="" For  Set key=$o(userparam(key)) Quit:key=""  do manager.UserFields.SetAt($g(userparam(key)),key)
	If $$$qualifierGetValue(qstruct,"cleanup"),$$$qualifierGetValue(qstruct,"run"),$$$qualifierGetValue(qstruct,"delete"),'manager.Debug {
		Set sc=manager.RecordNamespace()
		$$$THROWONERROR(sc,sc)
		Set cleanup=1
	}
	;
	Set root=..Root()
	;
	if ($g(testspec)'="")||($d(testspec)\10) { // --- Process 'testspec' in one of the following formats: String, Array(...) or ^Global ---
		set testspecSub="",testspecList="",testspecRoot=""
		for iter=1:1 { // --- Process All 'testspecList' Values ---
			if $e($g(testspec))="^" { // --- Process 'testspec' ^Global ---
				set:iter=1 testspecType="global"
				set testspecSub=$o(@testspec@(testspecSub),1,testspecList)
				QUIT:testspecSub=""  // No more 'testspecSub' values!
				
				// --- 'testspecList' can either be a Global subscript or Global data ---
				set:testspecList="" testspecList=testspecSub
			}
			elseif $g(testspec)'="" { // --- Process 'testspec' String ---
				set:iter=1 testspecType="string"
				QUIT:testspecList'=""  // 'testspec' already processed!
				
				set testspecList=testspec
			}
			else { // --- Process 'testspec(...)' Array(...) ---
				set:iter=1 testspecType="array"
				if '$d(testspecOrig) { merge testspecOrig=testspec kill testspec } // Save original array and clear it!
				set testspecSub=$o(testspecOrig(testspecSub),1,testspecList)
				QUIT:testspecSub=""  // No more 'testspecSub' values!
				
				// --- 'testspecList' can either be an Array subscript or Array data ---
				set:testspecList="" testspecList=testspecSub
			}
			for pos=1:1:$l(testspecList,",") { // --- Process All 'testspecData' Values ---
				set testspecData=$zstrip($p(testspecList,",",pos),"<>W")
				CONTINUE:testspecData=""  // No more 'testspecData' values!
				
				set testspecDataNorm=$zstrip($tr(testspecData,"\","/"),"<","*-")  // Normalized 'testspecData' value!
				set testsuiteNorm=$p($zstrip(testspecDataNorm,">","/"),":",1)     // Normalize 'testsuit' value!
				
				if $e(testspecData)="-" { // --- Process 'testspecData' (testsuit) Exclusions ---
					
					if pos=1 { // --- Prime 'testspecRoot' Accordingly for pos=1 ONLY ---
						set:testspecType="string" testspecRoot=""  // Allow special case -exclusions for subsequent 'testspecSub' values for 'testspec' = { Array(...) or ^Global(...) }!
					}
					
					if testspecRoot="" { // --- No 'testspecData' (testsuit) Root ---
						set sc=$$$ERROR($$$UTMMsgGenInvalidExclusion,testspecList)
						$$$THROWONERROR(sc,sc)
					}
					// --- Record 'testspecData' values to exclude ---
					set testspec(testspecRoot,testsuiteNorm)=""
					CONTINUE
				}
				elseIf $e(testspecData)="*",$$$IsParallelCM(manager) { // --- Record 'testspecDataNorm' to process via the Work Queue Manager (WQM) ---
					set testspecParallel(testspecDataNorm)=""
				}
				else { // --- Record 'testspecDataNorm' to process via Interactive UnitTest Manager ---
					set testspec(testspecDataNorm)=""
				}
				set:pos=1 testspecRoot=testspecDataNorm  // Keep track of the root 'testspecData' (testsuit) exclusions!
			}
		}
	}
	elseIf $data(testspec)\10=0 { // --- No 'testspec' Specified - Process everything under the directory referenced in the ^UnitTestRoot OR ^%SYS("SourceRoot",...) global ---
		set testspec(" ")=""
	}
	
	if $d(testspec)\10=0 { // --- Nothing to test since no data was passed to the 'testspec' parameter ---
		set sc=$$$ERROR($$$UTMMsgGenParamNoData,"testspec")
		$$$THROWONERROR(sc,sc)
	}
	;
	if ($g(userparam)_"/")["/log/" { // --- Start Logging all Processing Information to the 'UNITTEST.LOG' File located in the 'MGR' Directory (e.g. $ZU(12)) ---
		#;-------------------------------------------------------------------------------
		#; After the invocation of the 'StartLog^%unitutil()' method below, the value
		#; of the '$SYSTEM.Device.GetMnemonicRoutine()' property will be changed from 
		#; "%X364" to "%unitutil" so that the I/O for this class's methods can redirect 
		#; the processing information to the 'UNITTEST.LOG' file, which is located in
		#; the 'MGR' directory (e.g. $ZU(12)).  Additionally, it's important to note
		#; that the following instance variable, which is part of an array, contains 
		#; the original 'I/O Redirection' information that will be used for processing
		#; during UnitTest invocations:
		#;
		#;   manager.Environment("procVals","redirection")=$LIST Pieces:
		#;     1) $$$GetReDirectIOSwitch
		#;     2) $s($$$GetMnemonicRoutine="%X364":"",1:$$$GetMnemonicRoutine)
		#;-------------------------------------------------------------------------------
		do StartLog^%unitutil()  // Change $SYSTEM.Device.GetMnemonicRoutine() from "%X364" to "%unitutil"!
		set manager.Environment("log")=1
	}
	Set zhBegin=$zh
	Set suite=""
	Set suiteOption=""
	Set sc = ..OnBeforeAllTests(manager,root,.qstruct,.userparam)
	If $$$ISERR(sc) {
		Set tDummySuite = $classname()_":OnBeforeAllTests"
		Do manager.LogStateBegin(tDummySuite)
		Do manager.LogStateStatus(sc,tDummySuite)
		Do manager.LogStateEnd(0)
	} Else {
		For {
			Set suiteOption=$order(testspec(suiteOption)) Quit:suiteOption=""
			If $extract(suiteOption)="-" Continue
			Kill subdirs
			Set suite=$piece(suiteOption,"^"),options=$piece(suiteOption,"^",2,*)
			Set testsuite=$p(suite,":",1)
			Set testsuite=$zstrip($tr(testsuite,"/.","\\"),"<>W")
			Set dir=..AddSubDirectoryNames(root,testsuite)
			Set sc=$$$OK
			If $$$qualifierGetValue(qstruct,"recursive")=0 {
				If ##class(%File).DirectoryExists(dir)=0 {
					Set sc=$$$ERROR($$$DirectoryNameInvalid,dir)
				} Else {
					Set subdirs(dir)=$lb(dir,testsuite)
				}
			} Else {
				Kill testskip Merge testskip=testspec(suiteOption) ZKill testskip
			 	Set sc=..GetSubDirectories(root,dir,1,testsuite,.subdirs,.qstruct,.testskip)
			}
			If $$$ISERR(sc) {
				Do manager.LogStateBegin(testsuite)
				Do manager.LogStateStatus(sc,"Finding directories")
				Set status(" "_$tr(testsuite,"\","/"))=""
				Set status=manager.LogStateEnd(0)
				Continue
			}
			;
			do:options'="" ..BeforeRunTest(options)
			Set dir=""
			For {
				Set dir=$o(subdirs(dir),1,data) Quit:dir=""
				#; If we have already run this directory no need to do it again
				If $data(haverun(dir)) Continue
				Set haverun(dir)=""
				if $$$IsParallelCM(manager),$d(testspecParallel(suiteOption)) { // --- Run UnitTest 'suite' via the Work Queue Manager (WQM) ---
					Set sc = manager.QueueSuiteForParallel(suite, $g(qspec), $g(userparam))
					Set status=$select(sc'=$$$OK:0,1:sc)
				}
				Else {
					if $p(suite,":",2,*)'="",testsuite=$LG(data,2) { // --- Only Run the Fully Qualified 'suite' WHEN testsuite=$LG(data,2) ---
						set status=manager.RunOneTestSuite($LG(data,1),$LG(data,2),suite,.qstruct)
					}
					else { // --- Only Run 'testsuite' WHEN testsuite'=$LG(data,2) ---
						set status=manager.RunOneTestSuite($LG(data,1),$LG(data,2),testsuite,.qstruct)
					}
				}
				If status=0 {
					Set:$g(options)="" status(" "_$tr($li(data,2),"\","/"))=""
					Set:$g(options)'="" status(" "_$tr($li(data,2),"\","/")_"^"_options)=""
				}
			}
			If cleanup {
				Do manager.CleanNamespace()
			}
			do:options'="" ..AfterRunTest(options)
		}
	}
	
	Set sc = ..OnAfterAllTests(manager,root,.qstruct,.userparam)
	If $$$ISERR(sc) {
		Set tDummySuite = $classname()_":OnAfterAllTests"
		Do manager.LogStateBegin(tDummySuite)
		Do manager.LogStateStatus(sc,tDummySuite)
		Do manager.LogStateEnd(0)
	}
	if $$$IsParallelCM(manager) { // --- Finish Processing Parallel Jobs ---
		do manager.WaitForAllSuitesForParallel(.status)
		set parallelOpen=0
	}
	
	#; Need to make a list of suites that failed and report these at the end. Is this logged under suite or testsuite from the loop above?
	if $$$qualifierGetValue(qstruct,"run") {
		do manager.SaveResult($zh-zhBegin,.userparam)
		set manager.Display="log,error"
		do:'$$$IsParallelWorkerCM(manager) manager.PrintURL()
	} else {
		do ClearResult^%SYS.UNITTEST(manager.OriginNS,manager.ResultId)
	}
	if $g(manager.Environment("log")) { // --- Stop Logging all Processing Information to the 'UNITTEST.LOG' File located in the 'MGR' Directory (e.g. $ZU(12)) ---
		do EndLog^%unitutil($g(manager.Environment("procVals","redirection")))
		set manager.Environment("log")=0
		kill manager.Environment("procVals","redirection")
	}
	if $$$IsParallelWorkerCM(manager) { } // Don't emit overall output in a worker job!
	elseif $data(status)\10 {
		do manager.PrintLine("Some tests FAILED in suites:")
		set status="",list=""
		for { // --- Process All 'status(status)' Values ---
			set status=$order(status(status))
			QUIT:status=""  // No more 'status' values!
			set list=list_$extract(status,2,*)_","
			if $length(list)>10000 {
				do manager.PrintLine("  "_$extract(list,1,*-1))
				do manager.PostSwarmReviewComment("FAILED tests:  "_$extract(list,1,*-1),1)
				set list=""
			}
		}
		if list'="" { do manager.PrintLine("  "_$extract(list,1,*-1)),manager.PostSwarmReviewComment("FAILED tests:  "_$extract(list,1,*-1),1) }
	} else {
		do manager.PrintLine("All PASSED")
	}
 }
 catch tException {
	set sc=tException.AsStatus()
 }
	do:parallelOpen manager.WaitForAllSuitesForParallel() // Finish Processing Parallel Jobs!
	set SQLStatsFlagSYS=$SYSTEM.SQL.SetSQLStatsFlag(0)    // Turn OFF SQLStats-flag (SYSTEM)
	set SQLStatsFlagJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(0) // Turn OFF SQLStats-flag (JOB)
	do $SYSTEM.SQL.SetSQLStatsSaveFlag(1)                 // Reset SQLStatsSave-flag (System) to 1 - Optimal (new)
	do $SYSTEM.SQL.SetSQLStatsSaveFlagJob(0)              // Reset SQLStatsSave-flag (Job) to 0 - (Use 'System' flag)
	Kill ^IRIS.Temp.UnitState
	
	RETURN sc
}

ClassMethod AddSubDirectoryNames(root As %String, testsuite As %String) As %String [ Private ]
{
	Set dir=root
	For i=1:1:$l(testsuite,"\") Set test=$Piece(testsuite,"\",i),dir=##Class(%File).SubDirectoryName(dir,test)
	set dir=##class(%File).NormalizeDirectory(dir)
	Quit dir
}

ClassMethod LastSubDirectoryName(dir As %String) As %String [ Private ]
{
	Set rs=##class(%ResultSet).%New("%File:ParseDirectory")
	Set sc=rs.Execute(dir)
	If $$$ISERR(sc) Quit sc
	Set lastdir=""
	while rs.Next() {
		Set lastdir=rs.GetData(1)
	}
	Quit lastdir
}

ClassMethod GetSubDirectories(root, topdir As %String, level As %Integer, suite As %String, ByRef subdirs As %String, qspec As %String, ByRef testskip As %String) As %Status
{
	set tSC=$$$OK

 try {
	#; --- Process the Current Directory ---
	$$$qualifierParseDirect(tSC,qspec)
	$$$THROWONERROR(tSC,tSC)
	set topdir=##Class(%File).NormalizeDirectory(topdir)
	if '##class(%File).DirectoryExists(topdir) { // --- Invalid Directory Name ---
		set tSC=$$$ERROR($$$DirectoryNameInvalid,topdir)
		$$$THROWONERROR(tSC,tSC)
	}
	
	set rs=##class(%ResultSet).%New("%File:FileSet")
	set fileset="",sep=""
	set:$$$qualifierGetValue(qspec,"loadxml") fileset="*.xml;*.XML",sep=";"
	set:$$$qualifierGetValue(qspec,"loadudl") fileset=fileset_sep_"*.cls;*.mac;*.int;*.inc;*.CLS;*.MAC;*.INT;*.INC"
	set tSC=rs.Execute(topdir,fileset,"")
	$$$THROWONERROR(tSC,tSC)
 
 	#; --- Check/Process 'utPath' Exclusions ---
 	set excludeThisUTPath=0
	try {
		set excludeGloRef="",utPath=$REPLACE($tr(suite,"/","\"),"\\","\"),utPathPLen=$l(utPath,"\")-($p(utPath,"\",*)="")
		if utPath'="",$s(utPathPLen>2:$d(^||UnitTest.exclude(0,$p(utPath,"\",1),$p(utPath,"\",2),$p(utPath,"\",3))),utPathPLen>1:$d(^||UnitTest.exclude(0,$p(utPath,"\",1),$p(utPath,"\",2))),1:$d(^||UnitTest.exclude(0,$p(utPath,"\",1)))) { // --- Possible UnitTest Exclusion ---
			set excludeGloRef="^||UnitTest.exclude(0"  // Prime UnitTest Exclusion Global Master Map Reference!
			for pos=1:1 { // --- Spin Through All "\" Pieces of 'utPath' ---
				set sub=$p(utPath,"\",pos)
				QUIT:sub=""  // No more pieces!

				#; --- Build Full UnitTest Exclusion Global Master Map Reference for Existence Testing ---
				set excludeGloRef=excludeGloRef_","""_sub_""""
			}
			set excludeThisUTPath=($g(@(excludeGloRef_")"))'="")
		}
	} catch { // --- Fall Through UnitTest Exclusion Test ---
	}	
 	#; --- If the given UnitTest Path (topdir) is the dir that contains the UT Class [rs.Next()] & is Valid & is Not-Excluded, then recored it in the 'subdirs(topdir)' array ---
	set:$$$ISOK(tSC)&&(rs.Next())&&('excludeThisUTPath) subdirs(topdir)=$lb(topdir,suite)
	kill rs  // Close Current '%File:FileSet' Result-Set!
	
	#; --- Process the Current Directory's Sub-Directories with Recursive Tree-Dive ---
	set rs=##class(%ResultSet).%New("%File:FileSet")
	set tSC=rs.Execute(topdir,"*.*","",1)
	$$$THROWONERROR(tSC,tSC)
	
	for { // --- Spin Through Full Directory Tree ---
		QUIT:'rs.Next()  // No more directories!
		CONTINUE:rs.Data("Type")'="D"  // Skip non-directory types!
		
		set dir=##Class(%File).NormalizeDirectory(rs.Data("Name"))
		set lastSub=..LastSubDirectoryName(dir)
		CONTINUE:(lastSub=".")||(lastSub="..")||($e(lastSub)="_")  // Skip any sub-directories that starts with: { . | .. | _ }
        try { CONTINUE:(excludeGloRef'="")&&($g(@(excludeGloRef_","""_lastSub_""")"))'="") } catch { }  // Skip Excluded UnitTest Path; Fall Through on Error!

		set newSuite=$replace($s(suite="":"",1:suite_"\")_lastSub,"\\","\")
		If $data(testskip($tr(newSuite,"\","/"))) Continue
		set tSC=..GetSubDirectories(root,dir,level+1,newSuite,.subdirs,.qspec,.testskip)
		QUIT:$$$ISERR(tSC)  // Quit <for-loop> on error!
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

Method RunOneTestSuite(dir As %String, suite As %String, testspec As %String, qstruct)
{
	do $$$SetSQLRuntimeModeFlag(0) // Reset the SQL Runtime Mode to 0 (LOGICAL Mode) between each test!
	Set ..CurrentDir=##Class(%Library.File).NormalizeDirectory(dir)
	Set testcase=$p(testspec,":",2)
	#; Build an array of all classes to run and methods in those classes
	#define AllClassesSub "_ALL"
	Set testclassmethod = $PIECE(testspec,":",2,*)
	If testclassmethod[";" {
		For i=1:1:$LENGTH(testclassmethod,";") {
			Set tcc = $PIECE($PIECE(testclassmethod,";",i),":"), tcm = $PIECE($PIECE(testclassmethod,";",i),":",2,*)
			If tcc = "" {
				If tcm '= "" {
					#; Add this method to the list to run for all classes
					Set clsMthd($$$AllClassesSub,tcm) = ""
				}
				Continue
			}
			Set tccd = $DATA(clsMthd(tcc))
			If tccd = 10 {
				If tcm = "" {
					#; Run all methods
					Kill clsMthd(tcc)
					Set clsMthd(tcc) = ""
				} Else {
					#; Add this method to the list to run
					Set clsMthd(tcc,tcm) = ""
				}
			} ElseIf tccd = 0 {
				If tcm = "" {
					#; Run all methods
					Set clsMthd(tcc) = ""
				} Else {
					#; Only run this method
					Set clsMthd(tcc,tcm) = ""
				}
			}
		}
	} ElseIf testclassmethod '= "" {
		If testcase = "" {
			If $PIECE(testspec,":",3) '= "" Set clsMthd($$$AllClassesSub,$PIECE(testspec,":",3)) = ""
		} Else {
			If $PIECE(testspec,":",3) = "" {
				Set clsMthd(testcase) = ""
			} Else {
				Set clsMthd(testcase,$PIECE(testspec,":",3)) = ""
			}
		}
	}
	Do ..PrintLine("===============================================================================",0)
	Do ..PrintLine("Directory: "_dir,0)
	Do ..PrintLine("===============================================================================",0)
	;
	Set zhsBegin=$zh
	Do ..LogStateBegin(suite)
	Set ^IRIS.Temp.UnitState=$lb(suite)
	; Check internal ISC naming conventions if ^ISC.CheckUnitNames is true
	If $g(^ISC.CheckUnitNames),$$$qualifierGetValue(qstruct,"load") {
		Do ..CheckNameStructure(dir)
	}
	;
	Set flags="c"_$s(..Debug:"k/generatemap",1:$s($$$IAmSuperUser:"/journal=0",1:""))_"/nodisplay"
	If ..Display["log" Set flags=flags_"/display=log"
	If ..Display["error" Set flags=flags_"/display=error"
	If $$$qualifierAmend("Compiler",.qstruct,flags,.qstructLoad)
	Set sc=$$$OK
	;
	Set fileset="",sep=""
	If ..LoadXML Set fileset="*.xml;*.XML",sep=";"
	If ..LoadUDL Set fileset=fileset_sep_"*.cls;*.mac;*.int;*.inc;*.CLS;*.MAC;*.INT;*.INC"
	;
	if $$$qualifierGetValue(qstruct,"deleteleftoverclasses") { // --- Record All Pre-Loaded/Invocation Classes in the 'preLoadedClasses()' Array ---
 		set glcSC=..getLoadedClass(.preLoadedClasses)
	}
	Set sc = ..OnBeforeAutoLoad(dir, suite, testspec, .qstruct)
	If $$$ISERR(sc) Do ..LogStateStatus(sc,$classname()_":OnBeforeAutoLoad") Goto exit
	If $$$qualifierGetValue(qstruct,"load") {
		If $$$qualifierGetValue(qstruct,"autoload")]"" {
			Set sc=..AutoLoad(..CurrentDir,$$$qualifierGetValue(qstruct,"autoload"),.autoloadArray,.qstructLoad)
			If $$$ISERR(sc) Do ..LogStateStatus(sc,"$system.OBJ.ImportDir") Goto exit
		}
		Set sc=$system.OBJ.ImportDir(dir,fileset,.qstructLoad,,0,.classLoaded,0)
	} Else {
		If testcase="" {
			Set sc=$system.OBJ.ImportDir(dir,fileset,.qstructLoad,,0,.classLoaded,1)
		} Else {
			Set tCls = $ORDER(clsMthd(""))
			While tCls '= "" {
				If tCls '= $$$AllClassesSub Set classLoaded(tCls_".cls") = ""
				Set tCls = $ORDER(clsMthd(tCls))
			}
		}
	}
	If $$$ISERR(sc) Do ..LogStateStatus(sc,"$system.OBJ.ImportDir") Goto exit
	;
	Set key="" For {
		Set key=$o(classLoaded(key)) Quit:key=""
		If ($p(key,".",*)="cls") Set classArray($p(key,".",1,*-1))=""
	}
	;
	If $d(classArray)=0 Do ..PrintLine("No classes found for testsuite "_suite,1) Goto exit
	If testcase'="" {
		Set tCls = $ORDER(clsMthd(""))
		While tCls '= "" {
			If tCls = $$$AllClassesSub Set tCls = $ORDER(clsMthd(tCls)) Continue
			If $DATA(classArray(tCls))=0 {
				Do ..LogStateStatus($$$ERROR($$$GeneralError,"TestCase '"_tCls_"' does not exist in TestSuite"),"RunOneTest")
			} ElseIf $$$comClassDefined(tCls)=0 {
				Do ..LogStateStatus($$$ERROR($$$CompiledClassDoesNotExist,tCls),"RunOneTest")
			}
			Set tCls = $ORDER(clsMthd(tCls))
		}
	}
	;
	Set sc=..OnBeforeTestSuite(dir, suite, testspec, .qstruct)
	If $$$ISERR(sc) Do ..LogStateStatus(sc,$classname()_":OnBeforeTestSuite") Goto exit
	If $$$qualifierGetValue(qstruct,"run")=0 {
		Do ..PrintLine("Skipping running testsuite "_suite,1)
	} Else {
		#; Clear SQL stats
		Do $system.Context.SQL().ClearStats()
		Set class="" For {
			Set class=$o(classArray(class)) Quit:class=""
			If testcase'="",$DATA(clsMthd(class))=0 Continue
			If $system.CLS.IsMthd(class,"%Extends") && $classmethod(class,"%Extends","%UnitTest.TestCase") && '$$$comClassKeyGet(class,$$$cCLASSabstract) {
				Kill methods Merge methods = clsMthd(class)
				If $DATA(clsMthd($$$AllClassesSub)) = 10 Merge methods = clsMthd($$$AllClassesSub)
				Do ..RunOneTestCase(suite,class,.methods)
			}
		}
	}
	;
	Set ^IRIS.Temp.UnitState=$lb(suite)
	Set sc=$$$OK	
	;
exit
	if $$$qualifierGetValue(qstruct,"deleteleftoverclasses") { // --- Record All Post-Loaded/Invocation Classes in the 'utLoadedArray()' Array ---
		merge skipClasses=preLoadedClasses,skipClasses=classLoaded,skipClasses=autoloadArray  // Create 'skipClasses()' array to skip classes already represented in other class-loaded arrays!
 		set glcSC=..getLoadedClass(.utLoadedArray,.skipClasses)  // Retrieve classes loaded in the current namespace into the 'utLoadedArray()' array, minus those specified in the 'skipClasses()' array!
	}
	if '$$$qualifierGetValue(qstruct,"delete") { // --- Skip Deleting Loaded Classes/Possibly Delete UT-Loaded Classes ---
		do ..PrintLine("Skipping deleting classes ",1)
		set:$d(utLoadedArray) dlcSC=..deleteLoadedClasses(,,.utLoadedArray)
	}
	else { // --- Delete All UnitTest Loaded Classes/Possibly Keep All Pre-Loaded Classes ---
		set dlcSC=..deleteLoadedClasses(.classLoaded,.autoloadArray,.utLoadedArray)
	}
	Set sc=..OnAfterTestSuite(dir, suite, testspec, .qstruct)
	If $$$ISERR(sc) Do ..LogStateStatus(sc,$classname()_":OnAfterTestSuite")
	Set status=..LogStateEnd($zh-zhsBegin)
	Do ..PrintLine("",0)
	Set ..CurrentDir=""
	;
	Quit status
}

/// <p>
/// This method will return all of classes that are loaded in the current namespace into the <i>classes()</i> array...
/// </p>
/// <p>
/// <b>Invocation:</b> </br>
/// This method can be invoked in the following ways:
/// <ul>
///   <li>ObjectScript: ##class(%UnitTest.Manager).getLoadedClass(...)</li>
///   <li>SQL: N/A</li>
/// </ul>
/// </p>
/// <p>
/// <b>Parameters:</b>
/// <dl>
///   <dt><i>classes</i></dt>
///     <dd>A Pass By Reference array of classes that are loaded in the current namespace. 
///         This array will be populated with classes in the following format: </br>
///         <pre>
///    classes=# of classes
///    classes(&lt;class-name&gt;.cls)=""
///   
///    NOTE: The &lt;class-name&gt; and suffix (.cls) are case-sensitive
///         </pre>
///     </dd>
///   <dt><i>skipClasses</i></dt>
///     <dd>A Pass By Reference array of classes that should not be added to the 'classes()' 
///         array if found loaded in the current namespace.  This array has the following format: </br>
///         <pre>
///    skipClasses(&lt;class-name&gt;.cls)=""
///   
///    NOTE: The &lt;class-name&gt; and suffix (.cls) are case-sensitive
///         </pre>
///         <h3>Example:</h3>
///         <example>
///           set skipClasses("Sample.Person.cls")=""
///           set skipClasses("MRP.Test.cls")=""
///         </example>
///     </dd>
/// </dl>
/// <p>
/// <b>Return Value:</b> </br>
///    The status from the invocation of this method
/// </p>
ClassMethod getLoadedClass(ByRef classes, ByRef skipClasses) As %Status
{
	new %objlasterror
	set tSC=$$$OK
	kill classes  // Tabula Rasa
	
 try {
	set rtnDB=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^ROUTINE("DemoRtn")))

	set class=""
	for { // --- Spin All Local Classes ---
		set class=$order(^|rtnDB|rINDEXCLASS(class))
		QUIT:class=""  // No more classes!
		
		set className=$LG(^|rtnDB|rINDEXCLASS(class),2)_".cls"
		set:'$d(^|rtnDB|rINDEXCLASS("cls",class))&&'$d(skipClasses(className))&&$i(classes) classes(className)=""
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

/// <p>
/// This method deletes all of the classes provided in the following parameter arrays:
/// <ul>
///   <li>classLoaded()</li>
///   <li>autoloadArray()</li>
///   <li>utLoadedArray()</li>
/// </ul>
/// </p>
/// <p>
/// <b>Invocation:</b> </br>
/// This method can be invoked in the following ways:
/// <ul>
///   <li>ObjectScript: ..deleteLoadedClasses(...)</li>
///   <li>SQL: N/A</li>
/// </ul>
/// </p>
/// <p>
/// <b>Parameters:</b>
/// <dl>
///   <dt><i>classLoaded</i></dt>
///     <dd>A Pass By Reference array of classes that have been loaded into the namespace by 
///         the invocation of a given UnitTest
///     </dd>
///   <dt><i>autoloadArray</i></dt>
///     <dd>A Pass By Reference array of classes that have been auto-loaded into the namespace 
///         by the invocation of a given UnitTest
///     </dd>
///   <dt><i>utLoadedArray</i></dt>
///     <dd>A Pass By Reference array of classes that have been loaded into the namespace by 
///         the UnitTest during its invocation
///     </dd>
/// </dl>
/// </p>
/// <p>
/// <b>Return Value:</b> </br>
///    The status from the invocation of this method
/// </p>
Method deleteLoadedClasses(ByRef classLoaded, ByRef autoloadArray, ByRef utLoadedArray) As %Status [ PublicList = SQLCODE ]
{
	new %objlasterror,%qrc,SQLCODE
 	set tSC=$$$OK 
	
 try {
	// --- Delete Loaded Classes ---
	merge classLoaded=autoloadArray
	merge classLoaded=utLoadedArray

	set class=""
	for {  // --- Spin Through All Loaded Classes & Delete Each Class Extent ---
		set class=$o(classLoaded(class)) 
		QUIT:class=""  // No more loaded classes!
		CONTINUE:$p($$$UPPER(class),".",*)'="CLS"  // Skip non-class extensions!

		set className=$p(class,".",1,*-1)
		if $SYSTEM.CLS.IsMthd(className,"%DeleteExtent") {  // --- Invoke '%DeleteExtent()' Method ---
			CONTINUE:($PARAMETER(className,"CONNECTION")'="")&&$$$SQLStorageIsSQL($$$EXTtype($$$pEXT,className))  // Skip linked class, as it won't delete extent!

			try {
				set deSC=$CLASSMETHOD(className,"%DeleteExtent")
			} catch exception {
				set deSC=exception.AsStatus()
			}
			
			set:$$$ISOK(deSC) deSC=##class(%ExtentMgr.Util).DeleteExtentDefinitionIfExists(className)
			do:$$$ISERR(deSC) ..PrintLine("Could not delete extent of "_className)
		}
	}
	
	set class="" 
	for {  // --- Spin Through All Loaded Classes & Delete Each Class ---
		set class=$o(classLoaded(class))
		QUIT:class=""  // No more loaded classes!

		set ext=$p($$$UPPER(class),".",*)
		set dSC=$s(ext="CLS":$$Delete^%apiOBJ(class,"-d",,1),$$IsCSPName^%occXMLExport(class):##class(%RoutineMgr).Delete(class),",INC,MAC,INT,OBJ,BAS,"[(","_ext_","):##class(%Routine).Delete(class,,1),1:$$$OK)
		
		do:$$$ISERR(dSC) ..PrintLine("Could not delete "_class)
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

Method RunOneTestCase(suite As %String, class As %String, ByRef test As %String = "")
{
	new
	new $NAMESPACE
	new $ETRAP
	
 try {
	set startROTC=$ZHOROLOG,sc=$$$OK,startIO=$IO
	do ..LogStateBegin(suite,class)
	set debug=..Debug
	try {
		set testcase=$classmethod(class,"%New",$this)
	}
	catch callException {
		set sc=callException.AsStatus()
	}
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..LogStateStatus(sc,"InstantiateTestClass")
		$$$ThrowStatus(sc)
	}
	set testcase.Debug=..Debug
	
	if ..CurrentDir="" { // --- Set ..CurrentDir based on ^UnitTestRoot or ^%SYS("SourceRoot",...) ---
		set root=..Root()
		set currentDir=..AddSubDirectoryNames(root,$g(suite)_"\")
		if ##class(%File).DirectoryExists(currentDir) { // --- Directory Exists ---
			set ..CurrentDir=currentDir
			do ..PrintLine("Setting Manager.CurrentDir = '"_currentDir_"'",2)
		}
		else { // --- Directory Doesn't Exist ---
			do ..PrintLine("Not Setting Manager.CurrentDir; Directory '"_currentDir_"' does not exist",2)
		}
	}
	set ^IRIS.Temp.UnitState=$LB(suite,class)  // Record the current UnitTest information!
	
	set mnemonicRoutine=$$$GetMnemonicRoutine  // $SYSTEM.Device.GetMnemonicRoutine()=$$$GetMnemonicRoutine=$ZU(96,12)
	set procValsROTC("redirection")=$LB($$$GetReDirectIOSwitch,$s(mnemonicRoutine="%X364":"",1:mnemonicRoutine))  // Retrieve current 'I/O Redirection' information  // $$$GetReDirectIOSwitch=$ZU(82,12)
	
	set $ECODE="",$ZE="" $$$ResetProcessState  // Clear All Errors and Reset the Process State!
	
	// --- Invoke all of the 'OnBefore*(...)' Pre-processing Methods ---
	set sc=..OnBeforeTestCase(suite,class,testcase)
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..LogStateStatus(sc,$classname()_":OnBeforeTestCase")
		$$$ThrowStatus(sc)
	}
	
	try {
		set sc=testcase.OnBeforeAllTests()
	}
	catch callException {
		set sc=callException.AsStatus()
		USE startIO
	}
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..LogStateStatus(sc,"OnBeforeAllTests")
		$$$ThrowStatus(sc)
	}
	
	set sc=..getTestMethods(class,.methods) // Get all 'Test*' methods for the given 'class'!
	
	set methodID=""
	for { // --- Process All 'methodID' Values within the 'methods(methodID)' array ---
		set methodID=$o(methods(methodID),1,method)
		QUIT:methodID=""  // No more 'TestN*' Methods!
		
		if $d(test)>=10 {  // --- 'test' can be a subscripted array of methods ---  //BES157
			CONTINUE:'$d(test(method))
		}
		elseIf test'="",method'=test { CONTINUE }
		CONTINUE:'$system.CLS.IsMthd(class,method)  // Not a valid 'method' of the specified 'class'!
		
		set ^IRIS.Temp.UnitState=$LB(suite,class,method)  // Record the current UnitTest information!
		do ..LogStateBegin(suite,class,method)
		set success=0,durationTestMeth=0
		do:..ReportVariableLeaks ..GetCurrentPublicVariableSet(.preTestVars)
		
		set sc=..OnBeforeOneTest(suite,class,method)
		if $$$ISERR(sc) { // --- Invocation Error ---
			do ..LogStateStatus(sc,$classname()_":OnBeforeOneTest")
		}
		else { // --- Invocation Success; Now Invoke 'testcase.OnBeforeOneTest(method)' ---
			try {
				set sc=testcase.OnBeforeOneTest(method)
			}
			catch callException {
				set sc=callException.AsStatus()
				USE startIO
			}
			if $$$ISERR(sc) || (testcase.SkipTest) { // --- Invocation Error OR Skip ---
				do ..LogStateStatus(sc,"OnBeforeOneTest")
			}
			else { // --- Invocation Success; Now Invoke '$method(testcase,method)' ---
				set startTestMeth=$ZHOROLOG,sc=$$$OK
				try {
					do $method(testcase,method)
				}
				catch callException {
					set sc=callException.AsStatus()
					USE startIO
				}
				set durationTestMeth=$ZHOROLOG-startTestMeth
				if $$$ISERR(sc) { // --- Invocation Error ---
					do ..LogStateStatus(sc,method)
				}
				else { // --- Invocation Success ---
					Do ..LogMessage("Duration of execution: "_durationTestMeth_" sec.")
				}
				
				// --- Invoke all of the 'OnAfter*(...)' Post-processing Methods ---
				try {
					set sc=testcase.OnAfterOneTest(method)
				}
				catch callException {
					set sc=callException.AsStatus()
					USE startIO
				}
				if $$$ISERR(sc) { // --- Invocation Error ---
					do ..LogStateStatus(sc,"OnAfterOneTest")
				}
			}
		}
		set sc=..OnAfterOneTest(suite, class, method)
		if $$$ISERR(sc) { // --- Invocation Error ---
			do ..LogStateStatus(sc,$classname()_":OnAfterOneTest")
		}
		
		set testcase.SkipTest=0
		do ..LogStateEnd(durationTestMeth)
		If ..ReportVariableLeaks {
			do ..GetCurrentPublicVariableSet(.postTestVars)
			do ..ValidateVariables(.preTestVars, .postTestVars)
		}
	}
	set ^IRIS.Temp.UnitState=$LB(suite,class)  // Record the current UnitTest information!
	
	try {
		set sc=testcase.OnAfterAllTests()
	}
	catch callException {
		set sc=callException.AsStatus()
		USE startIO
	}
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..LogStateStatus(sc,"OnAfterAllTests")
	}
 }
 catch tException {
	set sc=tException.AsStatus()
    #; Re-throw errors that should cause the termination of test running
    $$$ISINTERRUPTTHROW(sc)
 }
exit
	if $isobject($g(testcase)) { // --- 'testcase' Object Instantiated ---
		if $$$ISERR(sc) { // --- If Error on 'testcase.OnBeforeAllTests' Invoke the 'testcase.OnAfterAllTests()' Method ---
			try {
				set sc=testcase.OnAfterAllTests()
			}
			catch callException {
				set sc=callException.AsStatus()
				USE startIO
			}
			do:$$$ISERR(sc) ..LogStateStatus(sc,"OnAfterAllTests")
		}
		set sc=..OnAfterTestCase(suite,class,testcase)
		if $$$ISERR(sc) { // --- Invocation Error ---
			do ..LogStateStatus(sc,,$classname()_":OnAfterTestCase")
		}
	}
	set durationROTC=$ZHOROLOG-startROTC
	merge procVals=i%Environment("procVals")  // Retrieve the Original Process Values!
	merge procVals("redirection")=procValsROTC("redirection")  // Reset to current 'I/O Redirection' information!
	set sc=..CleanupAllProcVals(.procVals,1)  // Cleanup & Restore all of the Original Process Values: System Settings | Locking Info | $ZU(115,...) | etc.
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..LogStateStatus(sc,"CleanupAllProcVals")
		do ..PrintLine("Restored all Process Values/Settings that have changed to their original value/setting!")
	}
	do ..LogStateEnd(durationROTC)
}

/// <p>
/// This internal method spins through all of the methods defined for the given <b><i>class</i></b> parameter, 
/// which start with the prefix <b>Test</b>, and records/returns this information in the Pass By Reference (PBR)
/// parameter <b><i>methods</i></b> as an array sorted/collated in Canonical Order:
/// <pre>
///    methods=# of Methods
///    methods(1..n)=Method Name
/// </pre>
/// </p>
ClassMethod getTestMethods(class As %String, ByRef methods) As %Status
{
	set tSC=$$$OK
	
 try {
	set method="Tess" ; One before 'Test' which we are searching for
	// --- Collate 'TestN*' Methods in Canonical Order: Step 1 ---
	for {
		set method=$$$comMemberNext(class,$$$cCLASSmethod,method)
		QUIT:(method="")||($e(method,1,4)]"Test")  // Only Collect Methods of the form: Test*
		
		set methodSuffix=$e(method,5,*)
		if methodSuffix?1.n.e { // --- Numerically Collated Method ---
			set methodSuffixP1=+methodSuffix,methodSuffixP2=$p(methodSuffix,methodSuffixP1,2,*)
			set:methodSuffixP2="" methodSuffixP2="*"
			set methodsOrder(methodSuffixP1,methodSuffixP2)=method
		}
		else { set methodsOrder("*",method)=method } // --- String Collated Method ---
	}
	
	// --- Collate 'TestN*' Methods in Canonical Order: Step 2 ---
	set sub1=""
	for {
		set sub1=$o(methodsOrder(sub1))
		QUIT:sub1=""  // No more 'TestN*' Method Prefixes!
		
		set sub2=""
		for {
			set sub2=$o(methodsOrder(sub1,sub2),1,method)
			QUIT:sub2=""  // No more 'TestN*' Method Suffixes!
			
			set methods($i(methods))=method  // Collate Methods
		}
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

ClassMethod GetCurrentPublicVariableSet(ByRef GetCurrentPublicVariableSetset) [ Internal, Private ]
{
	Kill GetCurrentPublicVariableSetset
	Set %="%"
	For  {
		Set % = $ORDER(@%) QUIT:%=""
		If $L(%, "GetCurrentPublicVariableSet") = 1 Set GetCurrentPublicVariableSetset(%) = ""
	}
}

ClassMethod SubtractVariableSet(ByRef c, ByRef a, ByRef b) [ Internal, Private ]
{
	Kill c
	Merge c = a
	Set var = ""
	For  {
		Set var = $o(b(var)) QUIT:var=""
		Kill c(var)
	}
}

Method ValidateVariables(ByRef preTestVars, ByRef postTestVars) [ Internal, Private ]
{
	Do ..SubtractVariableSet(.newVars, .postTestVars, .preTestVars)
	Set allowedvars=..ReturnAllowedPublicVariables(.prefix)
	Set var = ""
	For  {
		Set var = $O(newVars(var)) QUIT:var=""
		If $listfind(allowedvars,var) CONTINUE
		Set prefix="",matched=0
		For {
			Set prefix=$order(prefix(prefix)) Quit:prefix=""
			If $extract(var,1,$length(prefix))=prefix Set matched=1 QUIT
		}
		If matched CONTINUE
		Set qval = $$Quote^%qcr($g(@var))
		Do ..LogStateStatus($$$ERROR($$$GeneralError,"Unexpected new public variable introduced: " _ var _ ". $d("_var_") = " _ $d(@var) _ " $g("_var_") = " _ $e(qval,1,256) _ $select($l(qval) > 256:"...",1:"")),"RunOneTestCase")
	}
}

/// <p>
/// This internal method returns a $LIST(...) of allowable public variables, in addition to the 
/// Pass By Reference (PBR) parameter <b><i>prefix</i></b> as an as array.
/// </p>
ClassMethod ReturnAllowedPublicVariables(ByRef prefix As %String) As %List [ Internal, Private ]
{
	Set prefix("%SQLGateway")=""
	RETURN $lb("%SAX","%objlasterror","SQLCODE","%msg","%ROWCOUNT","%ROWID","%qrc","%sqlcontext","%JDBCGateway","%objsync")
}

/// <p>
/// This <i>original</i> internal method is retained for backward compatibility...
/// </p>
Method Record(ByRef procVals As %String) As %Status
{
	RETURN ..RecordProcVals(.procVals)
}

/// <p>
/// This method records all of the current Process Values within the Pass By Reference (PBR) array
/// parameter <b><i>procVals</i></b>...
/// </p>
Method RecordProcVals(ByRef procVals As %String) As %Status
{
	set tSC=$$$OK
	
 try {
	kill procVals  // Tabula Rasa!
	
	// --- Record all Locks Retained for the Current Process ($JOB) ---
	set rSet=##class(%ResultSet).%New("%SYS.LockQuery:List")
	set tSClock=rSet.Execute("P"_$JOB)
	for { // --- Process All 'LockQuery' Rows ---
		QUIT:'rSet.Next(.tSClock)  // No more 'LockQuery' Rows!
		
		set lock=rSet.Data("LockString")
		set:lock'="" procVals("lock",lock)=""
	}
	// --- Record I/O Redirection Flag for Current Device ---
	set mnemonicRoutine=$$$GetMnemonicRoutine  // $SYSTEM.Device.GetMnemonicRoutine()=$$$GetMnemonicRoutine=$ZU(96,12)
	set procVals("redirection")=$LB($$$GetReDirectIOSwitch,$s(mnemonicRoutine="%X364":"",1:mnemonicRoutine))  // $$$GetReDirectIOSwitch=$ZU(82,12)
	// --- Record Current User Login Info: $LIST($USERNAME,$ROLES (login),$ROLES (current),$SYSTEM.Security.Users.GetSecurityLevel(),<signature value>) ---
	set procVals("SecurityContext")=$SYSTEM.Security.Users.ExportSecurityContext()
	// --- Record Process-Specific Values (pzuints[] array) [SEE: .../internal/docs/zu/zu115.txt] ---
	set procVals("zu115")=$$$GetpzuintsVal(0)
#IF 0	//MRP1376+ [No longer need to record this value since it's recorded in 'procVals("zu115")']
	// --- Record General Lock Timeout ---
	set procVals("LockTimeout")=$$$LockTimeout
#ENDIF	//MRP1376-
	// --- Record the File Size of the 'messages.log' File (in 'bytes') ---
	set procVals("MessageLogFileSize")=##class(%Library.File).GetFileSize($$$GetMessagesLogFile)
	
	// --- SQL Configuration Option Values ---
	
	// --- Record SQL Configuration Option: AdaptiveMode - Run Time Plan Choice (RTPC), Automatic Parallelized Query Execution, etc. ---
	set procVals("RawAdaptive")=$$$AdaptiveMode
	
	// --- Record SQL Configuration Option: ANSIPrecedence - Determines whether or not the ANSI Operator Precedence is Applied ---
	set procVals("RawANSIPrecedence")=$$$RawANSIPrecedence
	// --- Record %SYSTEM.Context.SQLCompile Object for the SQL Configuration Option 'ANSIPrecedence' ---
	set procVals("ANSIPrecedence")=$$$ANSIPrecedence
	
	// --- Record SQL Configuration Option: AutoParallel - Determines whether or not the Auto Hinting %PARALLEL is Applied ---
	set procVals("RawAutoParallel")=$$$AutoParallel
	
	// --- Record SQL Configuration Option: AutoParallelThreshold - Determines the Threshold of Auto Hinting %PARALLEL ---
	set procVals("RawAutoParallelThreshold")=$$$AutoParallelThreshold
	
	// --- Record SQL Configuration Option: CachedQueryLockTimeout - Cached Queries Lock Timeout (in seconds) ---
	set procVals("RawCQLockTimeout")=$$$RawCQGetLockTO
	// --- Record %SYSTEM.Context.SQL Object for the SQL Configuration Option 'CachedQueryLockTimeout' ---
	set procVals("CQLockTimeout")=$$$CQGetLockTO
	
	// --- Record SQL Configuration Option: CachedQuerySaveSource - Determines whether or not the Cached Query Source Code is Retained ---
	set procVals("RawCQSaveMAC")=$$$CQSaveMAC
	
	// --- Record SQL Configuration Setting: Default Schema (Global Setting) ---
	set procVals("RawDefaultSchema")=$$$RawSchemaExpression
	// --- Record %SYSTEM.Context.SQLCompile Object for the SQL Configuration Setting 'SchemaExpr' ---
	set procVals("DefaultSchema")=$$$SchemaExpression
	
	// --- Record SQL Configuration Option: RetainSQL - Determines whether or not the Embedded SQL Statements are Retained as Comments in the .INT Routine ---
	set procVals("RawRetainSQL")=$$$RetainSQLTextAsComments
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

/// <p>
/// This <i>original</i> internal method is retained for backward compatibility...
/// </p>
Method Cleanup(ByRef procVals As %String, kill = 0) As %Status
{
	RETURN ..CleanupAllProcVals(.procVals,kill)
}

/// <p>
/// This internal method will cleanup all General & Specific Process Values that have 
/// changed during the invocation of methods within this class, report any differences, and 
/// restore those Process Values that have changed to their original value...
/// </p>
Method CleanupAllProcVals(ByRef procVals As %String, kill = 0) As %Status
{
	set tSC=..CleanupGeneralProcVals('$d(procVals))
	set cspvSC=..CleanupSpecificProcVals(.procVals,kill)
	set:$$$ISERR(cspvSC) tSC=$$$ADDSC(tSC,cspvSC)
	
	RETURN tSC
}

/// <p>
/// This internal method will cleanup all General Process Values that have changed during 
/// the invocation of methods within this class, report any differences, and restore those 
/// Process Values that have changed to their original value...
/// </p>
Method CleanupGeneralProcVals(checkLocks = 1) As %Status
{
	set tSC=$$$OK
	
 try {
	if checkLocks { // --- Check for any leftover Locks Retained in the Current Process ($JOB) - Report & Delete any that exist ---
		set rSet=##class(%ResultSet).%New("%SYS.LockQuery:List"),locks="",lockCnt=0
		set tSClock=rSet.Execute("P"_$JOB)
		for { // --- Process All 'LockQuery' Rows ---
			QUIT:'rSet.Next(.tSClock)  // No more 'LockQuery' Rows!
			
			set lock=rSet.Data("LockString")
			CONTINUE:lock["%UnitTest.Manager.Sentry"  // Skip locks taken out by '%UnitTest.Manager.Sentry'!
			
			set:($l(locks)'>512) locks=locks_$s(locks'="":",",1:"")_lock,lockCnt=lockCnt+1
			set tSCdel=$$DeleteOneLock^%SYS.UNITTEST(rSet.Data("DelKey"),"",1)  // Reset the Original Value of the Lock Table by deleting leftover entries!
		}
		if locks'="" {
			set diffSC=$$$ERROR($$$GeneralError,"A UnitTest left the following global"_$s(lockCnt>1:"s",1:"")_" locked after invocation: "_locks_$s($l(locks)>512:",...",1:""))
			set tSC=$$$ADDSC(tSC,diffSC)
		}
	}
	
	if $TLEVEL { // --- Check for OPEN Transactions & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest left OPEN "_$TLEVEL_" transaction"_$s($TLEVEL>1:"s",1:"")_" after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
		for { // --- COMMIT All Open Transactions ---
			QUIT:'$TLEVEL  // No more OPEN Transactions!
			
			TCOMMIT  // Reset the Original Value: $TLEVEL
		}
	}
	
	if $$$TransSuspended { // --- Check for Suspended Transactions & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest left a Transactions Suspended after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
		$$$ResumeTrans  // Reset the Original Value: Transaction Suspension Flag to 0 (Resume Transaction)
	}
	
	if $$CURRENT^%SYS.NOJRN()'=1 { // --- Check for Disabled Journaling & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest disabled Journalling in the Current Process ($JOB) after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
		do ENABLE^%SYS.NOJRN()  // Reset the Original Value: Journaling
	}
	
	set sortend=$sortend(,0)  // Reset the Original Value: $sortbegin(...)
	if sortend { // --- Check for OPEN $sortbegin(...) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest left OPEN $sortbegin(...) after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
	}
	
	if ##class(%SYS.NLS.Format).UseLocale() { // --- Check '##class(%SYS.NLS.Format).UseLocale()' Flag (Which indicates whether date/time/number functions should use the locale format by default) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest enabled the '##class(%SYS.NLS.Format).UseLocale()' flag and did not restore it after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
		do ##class(%SYS.NLS.Format).UseLocale(0)  // Reset the Original Value: ##class(%SYS.NLS.Format).UseLocale()
	}
	
	If '..DoesHoldSentryLock() { // --- Check UnitTest Sentry Lock & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest released Sentry Lock (naked 'Lock' command?) after invocation")
		set tSC=$$$ADDSC(tSC,diffSC)
		do ..AcquireSentryLock()  // Reset the Original Value: UnitTest Sentry Lock
	}
	
	set $ECODE="",$ZE="" $$$ResetProcessState  // Clear All Errors and Reset the Original Value: Process State //MRP1406: '$$$ResetProcessState' replaces 'do resetProcessState^%SYS.cspServer2()'
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

/// <p>
/// This internal method will cleanup all Specific Process Values that have changed after the 
/// invocation of each UnitTest, which is handled within the <method>RunOneTestCase</method> method, via 
/// the following steps: </br>
/// <ul>
///   <li>Before any UnitTest invocations, Record/Collect the Process Values at the beginning
///       of the <method>RunOneTestCase</method> method by calling the <method>RecordProcVals</method> method
///   </li>
///   <li>Compare all Process Values recorded/collected within the array passed to the
///       <method>RecordProcVals</method> method with their current Process Values
///   </li>
///   <li>For each recorded value that differs from its current value, perform the following
///       steps:
///       <ul>
///         <li>Create an <b>$$$ERROR($$$GeneralError,<error>)</b> of the Process Value differences</li>
///         <li>Restore the Process Value to its originally recorded value</li>
///       </ul>
///   </li>
/// </ul>
/// </p>
Method CleanupSpecificProcVals(ByRef procVals As %String, kill = 0) As %Status
{
	set tSC=$$$OK
	
 try {
	kill:kill (tSC,procVals)  // Conditionally remove any public variables and close any open objects!
	
	if $g(procVals("redirection"))'="" { // --- Check I/O Redirection Flag for Current Device & Reset Accordingly ---
		set $LG(redirect,routine)=procVals("redirection"),redirectCurr=$$$GetReDirectIOSwitch  // $$$GetReDirectIOSwitch=$ZU(82,12)
		if redirect'=redirectCurr { // --- I/O Redirection Flag Differs ---
			set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the 'Device Redirect Flag' from '"_redirect_"' to '"_redirectCurr_"'")
			set tSC=$$$ADDSC(tSC,diffSC)
			do $$$SetReDirectIOSwitch(redirect)  // Reset the Original Value: I/O Redirection Flag!  // $$$SetReDirectIOSwitch(%val)=$ZU(82,12,%val)
		}
		set mnemonicRoutine=$$$GetMnemonicRoutine  // $SYSTEM.Device.GetMnemonicRoutine()=$$$GetMnemonicRoutine=$ZU(96,12)
		if routine'=$s(mnemonicRoutine="%X364":"",1:mnemonicRoutine) { // --- Check Device Mnemonic Routine & Reset Accordingly ---
			if redirectCurr { // --- Only Report an Error if Redirection is ON (1) ---
				set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the 'Device Mnemonic Routine' from '"_$CASE(routine,"":"""""",:routine)_"' to '"_mnemonicRoutine_"'")
				set tSC=$$$ADDSC(tSC,diffSC)
			}
			USE 0::$s(routine="":"",1:"^"_routine)  // Reset the Original Value: Device Mnemonic Routine!
		}
	}
	
	// --- Check for any leftover Locks Retained in the Current Process ($JOB) - Report & Delete any that exist ---
	try { set lockParallelWQMGroup=$s(..Parallel="":"",1:"^IRIS.WorkQueue(""Group"","_..Parallel.WQM.group_")") }
	catch { set lockParallelWQMGroup="" }
	set rSet=##class(%ResultSet).%New("%SYS.LockQuery:List"),locks="",lockCnt=0
	set tSClock=rSet.Execute("P"_$JOB)
	for { // --- Process All 'LockQuery' Rows ---
		QUIT:'rSet.Next(.tSClock)  // No more 'LockQuery' Rows!
		
		set lock=rSet.Data("LockString")
		CONTINUE:$data(procVals("lock",lock))  // Skip if lock previously existed!
		CONTINUE:lock["%UnitTest.Manager.Sentry"  // Skip locks taken out by '%UnitTest.Manager.Sentry'!
		CONTINUE:lock=lockParallelWQMGroup        // Skip locks taken out by '%UnitTest.Manager.Parallel'!

		set:($l(locks)'>512) locks=locks_$s(locks'="":",",1:"")_lock,lockCnt=lockCnt+1
		set tSCdel=$$DeleteOneLock^%SYS.UNITTEST(rSet.Data("DelKey"),"",1)  // Reset the Original Value of the Lock Table by deleting leftover entries!
	}
	if locks'="" {
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest left the following global"_$s(lockCnt>1:"s",1:"")_" locked after invocation: "_locks_$s($l(locks)>512:",...",1:""))
		set tSC=$$$ADDSC(tSC,diffSC)
	}
		
	if $g(procVals("SecurityContext"))'="" { // --- Check Current User Login Info & Reset Accordingly ---
		if $LG(procVals("SecurityContext"),1,3)'=$LG($SYSTEM.Security.Users.ExportSecurityContext(),1,3) { // --- Login Info Differences: $LIST($USERNAME,$ROLES (login),$ROLES (current)) ---
			set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the 'Security Context' from '"_$LTS(procVals("SecurityContext"))_"' to '"_$LTS($SYSTEM.Security.Users.ExportSecurityContext())_"'")
			set tSC=$$$ADDSC(tSC,diffSC)
		}
		//MRP1376: ***TODO: Reset the Original Value: Security Context! ***
	}
	if $g(procVals("zu115"))'="" { // --- Check Process-Specific $ZU(115,n) Values (pzuints[] array) & Reset Accordingly ---
		if procVals("zu115")'=$zu(115,0) { // --- Process-Specific Value Differs ---
			for pos=1:1:$l($zu(115,0))\2 { set procVals("zu115",pos)=$zu(115,pos) }  // Record Original Values!
			do $zu(115,0,procVals("zu115"))  // Reset the Original Value: Process-Specific Values (pzuints[] array)
			for pos=1:1:$l($zu(115,0))\2 { // --- Check All Process-Specific Values for Differences ---
				if procVals("zu115",pos)'=$zu(115,pos) { // --- Report Process-Specific Value Differences
					set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the process-specific value for $zu(115,"_pos_")"_$CASE(pos,4:" (General Lock Timeout) ",:" ")_"from '"_$zu(115,pos)_"' to '"_procVals("zu115",pos)_"'")
					set tSC=$$$ADDSC(tSC,diffSC)
				}
			}
		}
	}
	
#IF 0	//MRP1376+ [No longer need to check this value since it's checked in 'procVals("zu115")']
	if $g(procVals("LockTimeout"))'="",procVals("LockTimeout")'=$$$LockTimeout { // --- Check General Lock Timeout & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the 'Lock Timeout' from '"_procVals("LockTimeout")_"' to '"_$$$LockTimeout_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
	}
#ENDIF	//MRP1376-
	
	if $g(procVals("MessageLogFileSize"))'="" { // --- Check File Size of the 'messages.log' File (in 'bytes') & Reset Accordingly ---
		set msglogFile=$$$GetMessagesLogFile
		if ##class(%Library.File).GetFileSize(msglogFile)>procVals("MessageLogFileSize") { // --- File Size of the 'messages.log' File Differs - Report any Fatal Errors Added to the 'message.log' File ---
			OPEN msglogFile:"R":1 
			if $T { // --- Process the 'message.log' File ---
				set prevSetZEOF=$SYSTEM.Process.SetZEOF(0)
				USE msglogFile:procVals("MessageLogFileSize")
				set readError=0
				for {
					QUIT:readError  // Stop Processing after a READ Error!
					
					try {
						READ line:0
					} 
					catch readErr {
						if readErr.Name'="<ENDOFFILE>" {
							set diffSC=$$$ERROR($$$GeneralError,"Error reading 'messages.log' file: "_readErr.Name_readErr.Location)
							set tSC=$$$ADDSC(tSC,diffSC)
						} 
						CLOSE msglogFile
						set readError=1  // Mark READ Error!
					}
					if line?2N1"/"2N1"/"2N1"-"2N1":"2N1":"2N1":"3N.E,$p(line," ",3)=3 {
						set diffSC=$$$ERROR($$$MsgLogFatalError,line) 
						set tSC=$$$ADDSC(tSC,diffSC)
					}
				}
				do $SYSTEM.Process.SetZEOF(prevSetZEOF)  // Reset the Original Value: ZEOF Flag
			}	
		}
	}
	
	
	// --- SQL Configuration Option Values ---
	
	if $g(procVals("RawAdaptive"))'="",procVals("RawAdaptive")'=$$$AdaptiveMode { // --- Check SQL Configuration Option 'AdaptiveMode' (Run Time Plan Choice (RTPC), Automatic Parallelized Query Execution, etc.) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'AdaptiveMode' from '"_procVals("RawAdaptive")_"' to '"_$$$AdaptiveMode_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("AdaptiveMode",procVals("RawAdaptive"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	
	if $g(procVals("RawANSIPrecedence"))'="",procVals("RawANSIPrecedence")'=$$$RawANSIPrecedence { // --- Check SQL Configuration Option 'ANSIPrecedence' (Determines whether or not the ANSI Operator Precedence is Applied) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'ANSIPrecedence' from '"_procVals("RawANSIPrecedence")_"' to '"_$$$RawANSIPrecedence_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("ANSIPrecedence",procVals("RawANSIPrecedence"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	// NOTE: It's unlikely that the following 'ANSIPrecedence' code will ever get invoked due to
	//       the fact that the first reference to the '$SYSTEM.Context.SQLCompile().ANSIPrecedence'
	//       attribute via the initial if-condition will reinstantiate the correct value set 
	//       directly above via the '$SYSTEM.SQL.Util.SetOption(...)' method!
	if $g(procVals("ANSIPrecedence"))'="",procVals("ANSIPrecedence")'=$$$ANSIPrecedence { // --- Check %SYSTEM.Context.SQLCompile Object for the SQL Configuration Option 'ANSIPrecedence' & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the %SYSTEM.Context.SQLCompile Object for the SQL Configuration Option 'ANSIPrecedence' from '"_procVals("ANSIPrecedence")_"' to '"_$$$ANSIPrecedence_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set $SYSTEM.Context.SQLCompile().ANSIPrecedence=procVals("ANSIPrecedence")  // Reset the Original Value of the %SYSTEM.Context.SQLCompile Object for the SQL Configuration Option!
	}
	
	if $g(procVals("RawAutoParallel"))'="",procVals("RawAutoParallel")'=$$$AutoParallel { // --- Check SQL Configuration Option 'AutoParallel' (Determines whether or not the Auto Hinting %PARALLEL is Applied) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'AutoParallel' from '"_procVals("RawAutoParallel")_"' to '"_$$$AutoParallel_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("AutoParallel",procVals("RawAutoParallel"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	
	if $g(procVals("RawAutoParallelThreshold"))'="",procVals("RawAutoParallelThreshold")'=$$$AutoParallelThreshold { // --- Check SQL Configuration Option 'AutoParallelThreshold' (Determines the Threshold of Auto Hinting %PARALLEL)' & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'AutoParallelThreshold' from '"_procVals("RawAutoParallelThreshold")_"' to '"_$$$AutoParallelThreshold_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("AutoParallelThreshold",procVals("RawAutoParallelThreshold"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	
	if $g(procVals("RawCQLockTimeout"))'="",procVals("RawCQLockTimeout")'=$$$RawCQGetLockTO { // --- Check SQL Configuration Option 'CachedQueryLockTimeout' (Cached Queries Lock Timeout (in seconds)) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'CachedQueryLockTimeout' from '"_procVals("RawCQLockTimeout")_"' to '"_$$$RawCQGetLockTO_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("CachedQueryLockTimeout",procVals("RawCQLockTimeout"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	// NOTE: It's unlikely that the following 'CQLockTimeout' code will ever get invoked due to
	//       the fact that the first reference to the '$SYSTEM.Context.SQL().CQLockTimeout'
	//       attribute via the initial if-condition will reinstantiate the correct value set 
	//       directly above via the '$SYSTEM.SQL.Util.SetOption(...)' method!
	if $g(procVals("CQLockTimeout"))'="",procVals("CQLockTimeout")'=$$$CQGetLockTO { // --- Check %SYSTEM.Context.SQL Object for the SQL Configuration Option 'CachedQueryLockTimeout' & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the %SYSTEM.Context.SQL Object for the SQL Configuration Option 'CachedQueryLockTimeout' from '"_procVals("CQLockTimeout")_"' to '"_$$$CQGetLockTO_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set $SYSTEM.Context.SQL().CQLockTimeout=procVals("CQLockTimeout")  // Reset the Original Value of the %SYSTEM.Context.SQL Object for the SQL Configuration Option!
	}
	
	if $g(procVals("RawCQSaveMAC"))'="",procVals("RawCQSaveMAC")'=$$$CQSaveMAC { // --- Check SQL Configuration Option 'CachedQuerySaveSource' (Determines whether or not the Cached Query Source Code is Retained) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'CachedQuerySaveSource' from '"_procVals("RawCQSaveMAC")_"' to '"_$$$CQSaveMAC_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("CachedQuerySaveSource",procVals("RawCQSaveMAC"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	
	if $g(procVals("RawDefaultSchema"))'="",procVals("RawDefaultSchema")'=$$$RawSchemaExpression { // --- Check SQL Configuration Setting 'Default Schema' (Global Setting) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Setting 'Default Schema' from '"_procVals("RawDefaultSchema")_"' to '"_$$$RawSchemaExpression_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Schema.SetDefault(procVals("RawDefaultSchema"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Setting!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
	// NOTE: It's unlikely that the following 'DefaultSchema' code will ever get invoked due to
	//       the fact that the first reference to the '$SYSTEM.Context.SQLCompile().SchemaExpr($NAMESPACE," "_$USERNAME)'
	//       attribute via the initial if-condition will reinstantiate the correct value set 
	//       directly above via the '$SYSTEM.SQL.Schema.SetDefault(...)' method!
	if $g(procVals("DefaultSchema"))'="",procVals("DefaultSchema")'=$$$SchemaExpression { // --- Check %SYSTEM.Context.SQLCompile Object for the SQL Configuration Setting 'Default Schema' & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the %SYSTEM.Context.SQLCompile Object for the SQL Configuration Setting 'Default Schema' from '"_procVals("DefaultSchema")_"' to '"_$$$SchemaExpression_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set $SYSTEM.Context.SQLCompile().SchemaExpr($NAMESPACE," "_$USERNAME)=procVals("DefaultSchema")  // Reset the Original Value of the %SYSTEM.Context.SQLCompile Object for the SQL Configuration Setting!
	}
	
	if $g(procVals("RawRetainSQL"))'="",procVals("RawRetainSQL")'=$$$RetainSQLTextAsComments { // --- Check SQL Configuration Option 'RetainSQL' (Determines whether or not the Embedded SQL Statements are Retained as Comments in the .INT Routine) & Reset Accordingly ---
		set diffSC=$$$ERROR($$$GeneralError,"A UnitTest changed the value of the SQL Configuration Option 'RetainSQL' from '"_procVals("RawRetainSQL")_"' to '"_$$$RetainSQLTextAsComments_"'")
		set tSC=$$$ADDSC(tSC,diffSC)
		set setOptSC=$SYSTEM.SQL.Util.SetOption("RetainSQL",procVals("RawRetainSQL"),.sqlOldVal)  // Reset the Original Value of the SQL Configuration Option!
		set:$$$ISERR(setOptSC) tSC=$$$ADDSC(tSC,setOptSC)
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

Method SaveResult(duration, ByRef userparam)
{
	Set i%LogIndex = ..ResultId
	Set userfields="",key="" for  {
		Set value=..UserFields.GetNext(.key) Quit:key=""  Set userfields=userfields_$lb($lb(key,value))
	}
	Do SaveResult^%SYS.UNITTEST(..OriginNS,..ResultId,duration,..UserParam,userfields)
	; temporarily comment out the building of indices due to large amount of disk usage
	Do ##class(%UnitTest.Result.TestInstance).FileIndicesRecursive(..ResultId)
	Do ..OnAfterSaveResult(.userparam)
	Quit
}

Method LogStateBegin(testsuite, testcase, testmethod)
{
	If $g(testsuite)="" Set testsuite="(root)"
	Set i%TheStack=$g(i%TheStack)+1
	Set i%TheStack(i%TheStack,"suite")=$g(testsuite)
	Set i%TheStack(i%TheStack,"case")=$g(testcase)
	Set i%TheStack(i%TheStack,"method")=$g(testmethod)
	Do LogStateBegin^%SYS.UNITTEST(..OriginNS,..ResultId,testsuite,$GET(testcase),$GET(testmethod),.msg,.level)
	Do ..PrintLine(msg,level)
	Quit
}

/// <p>
/// This method records the end of a UnitTest and returns the status of its invocation. 
/// </p>
Method LogStateEnd(duration) As %Integer
{
	Set suite=i%TheStack(i%TheStack,"suite")
	Set case=i%TheStack(i%TheStack,"case")
	Set method=i%TheStack(i%TheStack,"method")
	Kill i%TheStack(i%TheStack)
	Set i%TheStack=i%TheStack-1
	Set status = $$LogStateEnd^%SYS.UNITTEST(..OriginNS,..ResultId,suite,case,method,duration,.msg,.level)
	Do ..PrintLine(msg,level)
	Quit status
}

ClassMethod GetTestState(level) As %String
{
	RETURN $$$GetTestState(level)
}

Method LogStateStatus(status, action)
{
	If $$$ISOK(status) Quit
	Do $system.Status.DecomposeStatus(status,.errorarray,"-d")
	Set errortext=""
	For i=1:1:$g(errorarray) Set errortext=errortext_$s(i=1:" ",1:$C(13,10)_"+  ")_$g(errorarray(i))
	Set testsuite=i%TheStack(i%TheStack,"suite")
	Set testcase=i%TheStack(i%TheStack,"case")
	Set testmethod=i%TheStack(i%TheStack,"method")
	Set message="0:"_action_":"_errortext
	Do LogStateStatus^%SYS.UNITTEST(..OriginNS,..ResultId,testsuite,testcase,testmethod,action,errortext)
	If ..Display["error" {
		Do ..PrintErrorLine("LogStateStatus:"_message)
	} Else {
		Do ..PrintLine("LogStateStatus:"_message)
	}
	BREAK:..Debug  // BREAK when '/debug' qualifier specified!
    #; Re-throw errors that should cause the termination of test running
    $$$ISINTERRUPTTHROW(status)
	RETURN
}

Method LogAssert(success, action, description, extra, location)
{
	Set testsuite=i%TheStack(i%TheStack,"suite")
	Set testcase=i%TheStack(i%TheStack,"case")
	Set testmethod=i%TheStack(i%TheStack,"method")
	If testmethod="" Quit
	Do LogAssert^%SYS.UNITTEST(..OriginNS,..ResultId,testsuite,testcase,testmethod,success,action,description,$GET(location))
	Set line=action_":"_description_" ("_$$$GetTestState(success)_")"
	If 'success,..Display["error" {
		Do ..PrintErrorLine(line,.extra)
	} Else {
		Do ..PrintLine(line,4)
	}
}

Method LogMessage(message, location)
{
	Set testsuite=i%TheStack(i%TheStack,"suite")
	Set testcase=i%TheStack(i%TheStack,"case")
	Set testmethod=i%TheStack(i%TheStack,"method")
	If testmethod="" Quit
	Do LogMessage^%SYS.UNITTEST(..OriginNS,..ResultId,testsuite,testcase,testmethod,$GET(message),$GET(location))
	Do ..PrintLine("LogMessage:"_$g(message),4)
}

Method PrintLine(text, level = 0)
{
	If ..Display'["log" Quit
	Write !
	Write $j("",level*2)
	Write $g(text)
}

Method PrintErrorLine(text, extra)
{
	If ..Display'["error" RETURN
	set str = $get(text)_"  <<==== **FAILED**   "_$tr(i%TheStack(i%TheStack,"suite"),"\","/")_":"_i%TheStack(i%TheStack,"case")_":"_i%TheStack(i%TheStack,"method")_$s($get(extra)'="":$c(13,10)_extra,1:"")
	Write !,str
	do ..PostSwarmReviewComment(str)
	RETURN
}

Method PrintURL()
{
	#; No need for URL in tut environment
	If $get(^ISC.TutCheckTest) RETURN
	Set s = ##class(%RoutineMgr).GetWebServerPort(.p, .h, .up, .url)
	if $E(url,*)="/" {
		set url=$E(url,1,*-1)
	}
	If ($$$ISERR(s)) || ($G(url)="") Set url = "http://127.0.0.1:57772"
	set url=url_$$getDefaultApp^%SYS.cspServer2("%SYS")
	Do ..PrintLine("Use the following URL to view the result:")
	Do ..PrintLine(url_"/%25UnitTest.Portal.Indices.cls?Index="_..ResultId_"&$NAMESPACE="_$zconvert($namespace,"O","URL"))
	Quit
}

/// <p>
/// This method is <b>obsolete</b>; Use the <method>GetTestStatus</method> method instead!
/// </p>
Method IsSuccess(suite, case, method, action) As %Boolean
{
	quit ..GetTestStatus(.suite,.case,.method,.action)=1
}

/// <p>
/// This method returns result for a given <b><i>suite</i></b>, <b><i>case</i></b>, <b><i>method</i></b>, and <b><i>action</i></b>.
/// </p>
Method GetTestStatus(suite, case, method, action) As %Integer [ CodeMode = expression ]
{
$$GetTestStatus^%SYS.UNITTEST(..OriginNS,..ResultId,suite,case,method,action)
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	#; Record information we will reset when exiting to make sure we are not changing the environment
	Merge i%Environment("sql-sys")=^%SYS("sql","sys")
	#; We will restore this when restoring sql-sys settings in %OnClose
	Set i%Environment("stat-col")=$system.Context.SQL().DisableStatCollection
	Set $system.Context.SQL().DisableStatCollection=1
	Set i%Environment("callererrorinfo")=$lb(^%oddENV($$$cENVcallererrorinfo))
	Set i%Environment("uselocale")=##class(%SYS.NLS.Format).UseLocale(0)
	ZKill ^%oddENV($$$cENVcallererrorinfo)
	do ..RecordProcVals(.procVals)            // Record all of the current Process Values!
	merge i%Environment("procVals")=procVals  // Store the current Process Values within the class property 'Environment'!
	#; Take a "sentry" lock to guard against argumentless locks during tests
	Do ..AcquireSentryLock()
	Set ..OriginNS = $NAMESPACE
	Do ..ReserveResultId()
	Do ..CreateSwarmReviewSSL()
	RETURN $$$OK
}

Method AcquireSentryLock() [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Lock +^%UnitTest.Manager.Sentry(+$j,$this)
}

Method ReleaseSentryLock() [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Lock -^%UnitTest.Manager.Sentry(+$j,$this)
}

Method DoesHoldSentryLock() As %Boolean [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Return $lg($lg(^$LOCK("^%UnitTest.Manager.Sentry("_+$j_","""_$this_""")","COUNTS",+$j)),2) > 0
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $g(i%Environment("log")) { // --- Stop Logging all Processing Information to the 'UNITTEST.LOG' File located in the 'MGR' Directory (e.g. $ZU(12)) ---
		do EndLog^%unitutil($g(i%Environment("redirection")))
	}
	If $ld(i%Environment("callererrorinfo"),1) {
		Set ^%oddENV($$$cENVcallererrorinfo)=$list(i%Environment("callererrorinfo"))
	} Else {
		ZKill ^%oddENV($$$cENVcallererrorinfo)
	}
	Set sqlcontext=$system.Context.SQL()
	If $isobject(sqlcontext)=1 Set sqlcontext.DisableStatCollection=i%Environment("stat-col")
	Do ##class(%SYS.NLS.Format).UseLocale(i%Environment("uselocale"))
	Merge env=i%Environment("sql-sys")
	#; Look through these values one at a time rather than just doing a kill and merge in case other processes are running at this same time
	Set i=""
	For {
		Set i=$order(env(i)) Quit:i=""
		Set data=$data(env(i),val)
		If data#10=1 {
			If val'=$get(^%SYS("sql","sys",i)) Set ^%SYS("sql","sys",i)=val
		}
		If data\10=1 {
			Set j=""
			For {
				Set j=$order(env(i,j),1,val) Quit:j=""
				If val'=$get(^%SYS("sql","sys",i,j)) Set ^%SYS("sql","sys",i,j)=val
			}
		}
	}
	Set i=""
	For {
		Set i=$order(^%SYS("sql","sys",i)) Quit:i=""
		If '$data(env(i)) Kill ^%SYS("sql","sys",i) Continue
		Set j=""
		For {
			Set j=$order(^%SYS("sql","sys",i,j)) Quit:j=""
			If '$data(env(i,j)) Kill ^%SYS("sql","sys",i,j)
		}
	}
	#; --- If the process is HALTing, no need to restore the process settings below! ---
	RETURN:($zu(41,-2)["|HALT") $$$OK
	
	merge procVals=i%Environment("procVals")  // Retrieve the Original Process Values!
	set sc=..CleanupAllProcVals(.procVals)    // Cleanup & Restore all of the Original Process Values: System Settings | Locking Info | $ZU(115,...) | etc.
	if $$$ISERR(sc) { // --- Invocation Error ---
		do ..PrintLine("Restored all Process Values/Settings that have changed to their original value/setting!")
		write !,"ERROR closing ",$classname(),! do DisplayError^%apiOBJ(sc)
	}
	#; To make sure current process picks up any restored values
	Do $System.CLS.ClearContext("SQLCompile")
	#; Release sentry lock
	Do ..ReleaseSentryLock()
	#; Remove the swarm review SSL if it is newly created by CreateSwarmReviewSSL
	Do ..DeleteSwarmReviewSSL()
	RETURN $$$OK
}

/// <p>
/// This method returns the root directory of the UnitTest hierarchy, which is typically the value
/// stored in the following global: <b>^UnitTestRoot</b>
/// </p>
ClassMethod Root() As %String
{
	Set root=$g(^UnitTestRoot)
	If root="" Set root=##class(%File).NormalizeDirectory($$$envSourceDir)_"internal/testing/unit_tests/"
	Quit ##class(%File).NormalizeDirectory(root)
}

/// <p>
/// This method imports the contents of each sub-directory <b><i>sub</i></b> for each directory
/// specified by the <method>Root</method> method down to the <b><i>dir</i></b> parameter, and
/// return all of the corresponding classes in the Pass By Reference (PBR) array parameter <b><i>classArray</i></b>.
/// </br></br>
/// This method is part of the implementation for the <b>/autoload</b> qualifier.
/// </p>
ClassMethod AutoLoad(dir As %String, sub As %String, ByRef classArray As %String, qstruct As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	Set root=..Root(),pwd=dir,prev="",dirlist=""
	Set listonly=($$$qualifierGetValue(qstruct,"load")=0)
	; walk up the directory tree looking for /autoload directories
	For {
		Quit:prev=root!(pwd=prev)
		Set setup=##class(%File).SubDirectoryName(pwd,sub)
		Set:$$$FileDirectoryExists(setup) dirlist=$lb(setup)_dirlist
		Set prev=pwd,pwd=##class(%File).ParentDirectoryName(pwd)
	}
	; walk back down the directory tree loading /autoload directories
	Set fileset="",sep=""
	If $$$qualifierGetValue(qstruct,"loadxml") Set fileset="*.xml;*.XML",sep=";"
	If $$$qualifierGetValue(qstruct,"loadudl") Set fileset=fileset_sep_"*.cls;*.mac;*.int;*.inc;*.CLS;*.MAC;*.INT;*.INC"
	For i=1:1:$ll(dirlist) {
		Kill tmpClassArray
		Set sc=$system.OBJ.ImportDir($lg(dirlist,i),fileset,.qstruct,,1,.tmpClassArray,listonly)
		If $$$ISERR(sc) {
			$$$ISINTERRUPTTHROW(sc)
			RETURN sc
		}
		Merge classArray=tmpClassArray
	}
	RETURN $$$OK
}

/// <p>
/// This method converts old format data in the <b>^UnitTestLog</b> global to the new format
/// stored in the <b>^UnitTest.Result</b> global.
/// </p>
/// <p><b>Parameters:</b>
/// <dl>
///   <dt><i>pLogIndex</i></dt>
///   <dd>This is the test instance index in the <b>^UnitTestLog</b> global.</dd>
///   <dt><i>pResultNamespace</i></dt>
///   <dd>This is the namespace for the <b>^UnitTest.Result</b> global.</dd>
///   <dt><i>pMachine</i>, <i>pConfiguration</i>, <i>pVersion</i>, <i>pUserParam</i></dt>
///   <dd>The new information collected in the <b>^UnitTest.Result</b> global, but no longer in the <b>^UnitTestLog</b> global.</dd>
/// </dl>
/// This information can be provided manually when doing the conversion.<br>
/// The <b><i>pUserParam</i></b> parameter is used the same way as the <b><i>userparam</i></b> parameter
/// of the <method>RunTest</method> method. </br>
/// The top node of the <b><i>pUserParam</i></b> parameter becomes the value of the <property>UserParam</property>
/// property, and the first level subscripts, along with their values, are used to populate the <property>UserFields</property>
/// array property.
/// </p>
ClassMethod ConvertLogData(pLogIndex, pResultNamespace = "", pMachine = "", pConfiguration = "", pVersion = "", pUserParam = "", pKillLog = 0) As %Status
{
	if pResultNamespace="" set pResultNamespace=$namespace
	lock +^|pResultNamespace|UnitTest.Result
	set tResultIndex=$o(^|pResultNamespace|UnitTest.Result(""),-1)+1
	lock -^|pResultNamespace|UnitTest.Result
	;
	write !,"Converting ^UnitTestLog("_pLogIndex_") to ^UnitTest.Result("_tResultIndex_") ... "
	;
	set iduration=0
	set suite="" for  {
		set suite=$o(^UnitTestLog(pLogIndex,suite),1,sdata) quit:suite=""
		set sduration=0
		set case="" for  {
			set case=$o(^UnitTestLog(pLogIndex,suite,case),1,cdata) quit:case=""
			set cduration=0
			set method="" for  {
				set method=$o(^UnitTestLog(pLogIndex,suite,case,method),1,mdata) quit:method=""
				set assert="" for  {
					set assert=$o(^UnitTestLog(pLogIndex,suite,case,method,assert),1,adata) quit:assert=""
					set status=$p(adata,":",1)
					set action=$p(adata,":",2)
					set message=$p(adata,":",3,999)
					set ^|pResultNamespace|UnitTest.Result(tResultIndex,suite,case,method,assert)=$lb(status,action,message)
				}
				set status=$p(mdata,":",1)
				set duration=+$p(adata,"1:LogMessage:Duration of execution: ",2)
				set action=$p($p(mdata,":",2),"()",1)
				set description=$p(mdata,":",3,999)
				set ^|pResultNamespace|UnitTest.Result(tResultIndex,suite,case,method)=$lb(status,duration,action,description)
				set cduration=cduration+duration
			}
			set status=$p(cdata,":",1)
			set action=$p($p(cdata,":",2),"()",1)
			set description=$p(cdata,":",3,999)
			set ^|pResultNamespace|UnitTest.Result(tResultIndex,suite,case)=$lb(status,cduration,action,description)
			set sduration=sduration+cduration
		}
		set status=$p(sdata,":",1)
		set action=$p($p(sdata,":",2),"()",1)
		set description=$p(sdata,":",3,999)
		set ^|pResultNamespace|UnitTest.Result(tResultIndex,suite)=$lb(status,sduration,action,description)
		set iduration=iduration+sduration
	}
	set datetime=$zdatetime(^UnitTestLog(pLogIndex),3)
	set userfieldslist="",key="" for  {
		set key=$o(pUserParam(key)) quit:key=""
		set userfieldslist=userfieldslist_$lb($lb(key,$g(pUserParam(key))))
	}
	set ^|pResultNamespace|UnitTest.Result(tResultIndex)=$lb(datetime,iduration,pMachine,pConfiguration,pVersion,$namespace,$g(pUserParam),userfieldslist)
	if pKillLog kill ^UnitTestLog(pLogIndex)
	;
	do ..ConvertStatus(tResultIndex,pResultNamespace)
	;
	quit $$$OK
}

/// <p>
/// This method updates the status at each level recursively based on the status of the children. </br>
/// If the <b><i>pIndex</i></b> parameter is omitted or passed the empty-string (""), then all of
/// the nodes within the <b>^|pNamespace|UnitTest.Result(...)</b> global will be converted.
/// </p>
ClassMethod ConvertStatus(pIndex, pNamespace) As %Status
{
	If $g(pNamespace)="" Set pNamespace=$namespace
	If $g(pIndex)="" {
		Set tIndex="" For  {
			Set tIndex=$o(^|pNamespace|UnitTest.Result(tIndex)) Quit:tIndex=""
			Do ..ConvertStatus(tIndex,pNamespace)
		}
	} Else {
		Write !,"Converting Status for TestInstance "_pIndex_" ..."
		Do ..setRecursiveStatus(pNamespace,pIndex)
	}
	Quit $$$OK
}

ClassMethod setRecursiveStatus(pNamespace, pIndex, pSuite, pCase, pMethod) As %Integer
{
	; status precedence order: failed, skipped, passed
	set sp(0)=3,sp(2)=2,sp(1)=1,sphighest=3,status=1
	If $g(pMethod)'="" {
		Set status=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,pMethod),1) Quit:status=sphighest status
		Set duration=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,pMethod),2)
		Set altered=0,action="" For  {
			Set action=$o(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,pMethod,action)) Quit:action=""
			Set one=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,pMethod,action),1) if sp(one)>sp(status) set status=one,altered=1
			Quit:status=sphighest
		}
		If altered {
			Set ^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,pMethod)=$lb(status,duration,"","There are "_$$$GetTestState(status)_" TestAsserts")
			Write !,"  altered status for ",pIndex,":"_pSuite_":"_pCase_":"_pMethod_" to "_$$$GetTestState(status)
		}
		Quit status
	} Elseif $g(pCase)'="" {
		Set status=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase),1) Quit:status=sphighest status
		Set duration=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase),2)
		Set altered=0,tMethod="" For  {
			Set tMethod=$o(^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase,tMethod)) Quit:tMethod=""
			Set one=..setRecursiveStatus(pNamespace,pIndex,pSuite,pCase,tMethod) if sp(one)>sp(status) set status=one,altered=1
		}
		If altered {
			Set ^|pNamespace|UnitTest.Result(pIndex,pSuite,pCase)=$lb(status,duration,"","There are "_$$$GetTestState(status)_" TestMethods")
			Write !,"  altered status for ",pIndex,":"_pSuite_":"_pCase_" to "_$$$GetTestState(status)
		}
		Quit status
	} Elseif $g(pSuite)'="" {
		Set status=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite),1) Quit:status=sphighest status
		Set duration=$li(^|pNamespace|UnitTest.Result(pIndex,pSuite),2)
		Set altered=0,tCase="" For  {
			Set tCase=$o(^|pNamespace|UnitTest.Result(pIndex,pSuite,tCase)) Quit:tCase=""
			Set one=..setRecursiveStatus(pNamespace,pIndex,pSuite,tCase) if sp(one)>sp(status) set status=one,altered=1
		}
		If altered {
			Set ^|pNamespace|UnitTest.Result(pIndex,pSuite)=$lb(status,duration,"","There are "_$$$GetTestState(status)_" TestCases")
			Write !,"  altered status for ",pIndex,":"_pSuite_" to "_$$$GetTestState(status)
		}
		Quit status
	} Else {
		Set tSuite="" For  {
			Set tSuite=$o(^|pNamespace|UnitTest.Result(pIndex,tSuite)) Quit:tSuite=""
			Set one=..setRecursiveStatus(pNamespace,pIndex,tSuite) if sp(one)>sp(status) set status=one
		}
		Quit status
	}
	Quit 0
}

/// <p>
/// <b>InterSystems INTERNAL USE ONLY!</b>
/// </br></br>
/// This method checks UnitTest file names against internal source control requirements. </br>
/// You should not make direct use of this method within your applications. </br>
/// There is no guarantee made about either the behavior or future operation of this method!
/// </p>
Method CheckNameStructure(dir As %String) [ Internal, Private ]
{
	try {
		s basenm=..Root()
		s rs=##class(%ResultSet).%New("%File:FileSet")
		Set fileset="",sep=""
		If ..LoadXML Set fileset="*.xml;*.XML",sep=";"
		If ..LoadUDL Set fileset=fileset_sep_"*.cls;*.CLS"
		s sc=rs.Execute(dir,fileset)
		if $$$ISERR(sc){
			d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
			q
		}
		for {
			q:'rs.Next()
			s file=rs.Data("Name")
			//If Emacs-style *.xml~ backup files are present on a Windows system, they are found by the FileSet query.  Skip them here.
			continue:$case($zcvt($e(file,*-3,*),"l"),".xml":0,".cls":0,:1)
			s sc=$system.OBJ.Load(file,"-d",,.elmntlst,1)
			if $$$ISERR(sc) {
				d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
				continue
			}
			s elmntcnt=0
			s hasclass=0
			s shortfile=$e(file,$l(basenm)+1,*-4)
			s shortfile=$tr(shortfile,"_\/]","%...")
			//Check to see if the file name corresponds to a syntactically valid class name - if it does, we want it to contain a class.
			s validfilename=$ZNAME(shortfile,4)
			s idx=$o(elmntlst(""))
			for {
				q:idx=""
				s elmntcnt=elmntcnt+1
				//If any of the elements in the file is a class, check that the class name matches the file name.
				if $zcvt($e(idx,*-3,*),"l")=".cls" {
					s hasclass=1
					s clsnm=$e(idx,1,*-4)
					if shortfile'=clsnm {
						s sc=$$$ERROR($$$GeneralError,"Expected "_file_" to contain a class named "_$tr(shortfile,"_","%")_" rather than "_clsnm)
						d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
					}
				}
				s idx=$o(elmntlst(idx))
			}
			//Expect that a file with a file name that corresponds to a syntactically correct class name should contain a class.
			if validfilename,'hasclass {
				s sc=$$$ERROR($$$GeneralError,"Expected "_file_" to contain a class element because it corresponds to a valid class name")
				d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
			}
			//Expect each file that contains a class to have exactly one element.
			if hasclass,elmntcnt'=1 {
				s sc=$$$ERROR($$$GeneralError,"More than one element, including at least one class, found in "_file)
				d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
			}
		}
	}
	catch excpt {
		s sc=excpt.AsStatus()
		d ..LogStateStatus(sc,"Source Control Naming Convention Check Failed")
	}
}

/// <p>
/// This is a private and internal method that collects and records all of the globals and
/// routines in the current namespace so that a cleanup can be performed after the UnitTest
/// finished running.
/// </p>
Method RecordNamespace() As %Status [ Private ]
{
	New %gbl
	Set rtndb=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^ROUTINE("DemoRtn")))
	Set datadb=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^X))
	Set sc=$$GetGlobalDirectoryInfo^%SYS.DATABASE(datadb,$name(%gbl)) If $$$ISERR(sc) Quit sc
	#; Make sure we do not clean up the test results
	Set i%NSInfo("gbl","UnitTest.Result")="",i%NSInfo("gbl","UnitTest.ResultI")="",i%NSInfo("gbl","UnitTestRoot")=""
	#; Also leave the ^ERRORS global
	Set i%NSInfo("gbl","ERRORS")=""
	Set i=""
	For {
		Set i=$order(%gbl(i)) Quit:i=""
		If $data(@("^|"""_datadb_"""|"_i)) {
			Set i%NSInfo("gbl",i)=""
		}
	}
	Set i=""
	For {
		Set i=$order(^oddEXT(i)) Quit:i=""
		Set i%NSInfo("ext",i)=""
	}
	Merge i%NSInfo("rtn")=^|rtndb|rINDEX,i%NSInfo("cls")=^|rtndb|rINDEXCLASS
	Set i%NSInfo("$zs")=$zs
	
	#; Get list of existing PPGs
	#dim rset As %Library.ResultSet
	set rset=##class(%ResultSet).%New()
	set rset.ClassName="%SYS.ProcessQuery"
	set rset.QueryName="PPG"
	set sc=rset.Execute("*",-1,"N")
	if $$$ISERR(sc) Quit sc
	While rset.Next() {
		set ppg=rset.Data("key")
		Set i%NSInfo("ppg",ppg)=""
	}
	Quit $$$OK
}

/// <p>
/// This is a private and internal method that cleans the current namespace after the
/// UnitTest finished running. </br>
/// This method will not remove any globals or routines that were recorded during the
/// invocation of the <method>RecordNamespace</method> method.
/// </p>
Method CleanNamespace() As %Status [ Private ]
{
	New %gbl
	Set rtndb=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^ROUTINE("DemoRtn")))
	Set datadb=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^X))
	#; In case partition size was changed
	Set $zs=i%NSInfo("$zs")
	#; Delete any DocDB databases
	Do dropAllDatabases^%DocDB.Document()
	#; Remove routine/classes first
	Set cls=""
	For {
		Set cls=$order(^|rtndb|rINDEXCLASS(cls)) Quit:cls=""
		If '$data(i%NSInfo("cls",cls)) {
			Set name=$listget(^|rtndb|rINDEXCLASS(cls),2)
			Set remove(name)=""
			Do ..PrintLine("Calling %KillExtent on class left after test run: "_name)
			try { set sc=$classmethod(name,"%KillExtent",1,1) } catch {}
		}
	}
	If $data(remove) {
		Do ..PrintLine("Removing classes left after test run:")
		Do Delete^%apiOBJ(.remove,"d")
	}
	Kill remove
	Set rtn="",first=1
	For {
		Set rtn=$order(^|rtndb|rINDEX(rtn)) Quit:rtn=""
		#; Assume that the UnitTest did not change the type of 'rtn'
		If '$data(i%NSInfo("rtn",rtn)) {
			For type="MAC","INT","MVI","BAS","INC","OBJ" {
				If '$data(^|rtndb|rINDEX(rtn,type)) Continue
				If '$data(i%NSInfo("rtn",rtn,type)) {
					If first {
						Set first=0
						Do ..PrintLine("Removing routines left after test run:")
					}
					Do ..PrintLine(rtn_"."_type,2)
					Set sc=$$Delete^%apiRTN(rtn_"."_type,0,0,0,0)
				}
			}
		}
	}
	If 'first Do ..PrintLine("")
	
 	kill ^||UnitTest.exclude // Kill UnitTest Exclude Global!
	#; Now remove any new globals
	Set sc=$$GetGlobalDirectoryInfo^%SYS.DATABASE(datadb,$name(%gbl)) If $$$ISERR(sc) Quit sc
	Set i="",first=1
	For {
		Set i=$order(%gbl(i)) Quit:i=""
		If $extract(i,1,$length("DeepSee"))="DeepSee" Continue
        If $extract(i,1,$length("IRIS.SM"))="IRIS.SM" Continue
		Set upper=$zconvert(i,"U")
		If $extract(upper)="Z"||($extract(upper,1,2)="%Z"),$extract(upper,1,3)'="ZEN",$extract(upper,1,4)'="%ZEN" Continue
		If '$data(i%NSInfo("gbl",i)) {
			If $data(@("^|"""_datadb_"""|"_i)) {
				If first {
					Set first=0
					Do ..PrintLine("Globals left after suite ran, killing them:")
				}
				Do ..PrintLine("^"_i,2)
			}
			Set $sequence(@("^|"""_datadb_"""|"_i))=""   ; In case we are using $sequence on any of the globals that were left
			Kill @("^|"""_datadb_"""|"_i)
		}
	}
	Set timestamp=$ztimestamp
	Set ^rINDEX=timestamp,^rINDEXCLASS=timestamp
	If 'first Do ..PrintLine("")
	#; Take care of PPG's
	#dim rset As %Library.ResultSet
	set rset=##class(%ResultSet).%New(),first=1
	set rset.ClassName="%SYS.ProcessQuery"
	set rset.QueryName="PPG"
	set sc=rset.Execute("*",-1,"N")
	if $$$ISERR(sc) Quit sc
	While rset.Next() {
		set ppg=rset.Data("key")
		If $data(i%NSInfo("ppg",ppg)) Continue
		If ppg="%IRIS.WorkQueue"||(ppg="%ISCQueryTemp") Continue
		If first {
			Set first=0
			Do ..PrintLine("Removing PPGs left after suite ran:")
		}
		Do ..PrintLine("^||"_ppg,2)
		Kill @("^||"_ppg)
	}
	If $data(i%NSInfo("ext")) {
		Set i=""
		For {
			Set i=$order(^oddEXT(i)) Quit:i=""
			If '$data(i%NSInfo("ext",i)) {
				Kill ^oddEXT(i)
			}
		}
	}
	#; Purge all cached queries and unfreeze all frozen plan and clear SQL stats
	do $SYSTEM.SQL.SetSQLStatsFlag(0)				// Turn OFF SQLStats-flag (SYSTEM)
	do $SYSTEM.SQL.SetSQLStatsFlagJob(0)			// Turn OFF SQLStats-flag (JOB)
	do $SYSTEM.SQL.SetSQLStatsSaveFlag(1)			// Reset SQLStatsSave-flag (System) to 1 - Optimal (new)
	do $SYSTEM.SQL.SetSQLStatsSaveFlagJob(0)		// Reset SQLStatsSave-flag (Job) to 0 - (Use 'System' flag)
	Do Purge^%SYS.SQLSRV()
	Do $SYSTEM.SQL.FreezePlans(0,1,,.Errors)
	do clearStatsSQLOLD^%SYS.PToolsUtil($NAMESPACE,,,,,,,,1)	// Clear All Original (backward-compatible) PTools SQL Stats - MRP963/MRP1103  [DEPRECATED]
	do clearStatsSQLNEW^%SYS.PToolsUtil($NAMESPACE,,,,,,,1)		// Clear All Optimal (new) PTools SQL Stats - MRP1103
	Quit $$$OK
}

/// <p>
/// This method runs the UnitTests that are listed within the specified <b><i>fileName</i></b> parameter.  
/// The tests within this file have the following format:<br/>
/// </p>
/// <div style="margin-top: 10px; margin-left: 40px;">
///   [<arg>#</arg> | <arg>//</arg>] | [&ltsection&gt#] | [<arg>-</arg>]<arg>utPath</arg>
/// 
///   <table class="parm-format">
///     <tr>
///       <td><arg>#</arg> | <arg>//</arg></td>
///       <td><i>Optional</i> - Specifies a comment line</td>
///     </tr>
///     <tr>
///       <td><arg>[&ltsection&gt#] </arg></td>
///       <td><i>Optional</i> - Specifies the beginning of a section of tests.  For example [1] or [15]</td>
///     </tr>
///     <tr>
///       <td><arg>-</arg></td>
///       <td><i>Optional</i> - Specifies that the <arg>utPath</arg> will be excluded from running</td>
///     </tr>
///     <tr>
///       <td><arg>utPath</arg></td>
///       <td>The directory path of the UnitTest to run, or a path prefix (e.g. SQL\SQLStats) to run all UnitTests within this directory and all sub-directories</td>
///     </tr>
///   </table>
/// </div>
/// 
/// <h3>Example:</h3>
/// <example language="none">
///   utFile_with_exclusions.txt
///     // This file contains the following two lists:
///     //   1) A list of UnitTests to exclude from running
///     //   2) A list of UnitTests to run
/// 
///     // List all of the excluded UnitTest Paths (utPath) first:
///     //   NOTE: The negative-sign (-utPath) is the exclusion indicator!
///     -SQL\dynamicSQL\DocBookTests
///     -SQL\dynamicSQL\privilege
///     -Classes\Atelier
///     -Classes\Debugger
/// 
///     // List all of the UnitTest Paths (utPath) to run last:
///     SQL\dynamicSQL
///     Classes
///   
///   Invocation
///     USER>set tSC=##class(%UnitTest.Manager).RunTestsFromFileList(,"C:\ut\SQLStats_with_exceptions.txt")
/// </example>
/// <dl>
/// <dt>
/// <var>globalName</var>
/// <dd>
///   A optional global name, when specified, will be populated with each <arg>utPath</arg> from the
///   given <i>fileName</i>, which is then passed as the first parameter to the 
///   <method>RunTest</method> method for execution.  If specified, the 
///   value passed to the <i>globalName</i> parameters must have the following format:
///   <pre>
///      INPUT:   "^utGlobal"           // Where <i>^utGlobal</i> is a valid IRIS Global Name
///      OUTPUT:  ^utGlobal(utPath)=""  // e.g.  ^utGlobal("SQL\dynamicSQL")=""
///                                              ^utGlobal("Classes")=""
///   </pre>
/// </dd>
/// </dt>
/// <dt>
/// <var>fileName</var>
/// <dd>A file path and name, which contains lines of tests in the following format, as specified above: [<arg>#</arg> | <arg>//</arg>][<arg>-</arg>]<arg>utPath</arg><br/><br/></dd>
/// </dt>
/// <dt><i>qspec</i>
/// <dd>This parameter has a name/term that is used interchangeably with the term <b>qualifier</b>, and a value
///     that is a concatenated list of supported system flags and qualifiers documented on the following page: 
///       <a href="https://docs.intersystems.com/irislatest/csp/docbook/Doc.Results.cls?docs%5Bquery%5D=qspec" target="_blank">System Flags and Qualifiers</a>
///     </br/></br>
///     This parameter allows the specification of qualifiers in the following format: 
///        <i>/[no]&lt;qualifier&gt;[=&lt;value&gt;][/[no]&lt;qualifier&gt;[=&lt;value&gt;]]*</i>
///     </br></br>
///     Example: <b>/noload/norecursive</b>
///     </br></br>
///     The first four qualifiers below (<b>debug</b>, <b>load</b>, <b>run</b>, and <b>recursive</b>) are negatable Booleans,
///     which can be enabled by explicitly specifying the qualifier name (e.g. <b>/debug</b>) or disabled by either
///     adding the prefix <b>no</b>, or by adding the value zero <b>=0</b>, as in the following respective examples: 
///     <b>/nodebug</b> OR <b>/debug=0</b>
///     </br></br>
///     <b>/debug</b>: Run in debug mode, which causes an execution <i>BREAK</i> if a UnitTest fails. Default is <b>/nodebug</b>.
///     </br></br>
///     <b>/load</b>: Load the corresponding UnitTest classes for the specified <b><i>testspec</i></b> parameter. Default is <b>/load</b>. 
///     If both the <b>/load</b> and <b>/run</b> qualifiers are enabled (true), then all loaded classes, routines, and CSP files will be deleted after 
///     all UnitTests have finished running. To prevent the post-deletion task, invoke the <method>DebugLoadTestSuite</method> method to first load all
///     appropriate UnitTest classes and then invoke the <b>DebugRunTestCase</b> method to actually run the corresponding UnitTests.
///     </br></br>
///     <b>/run</b>: Run all UnitTests specified by the <b><i>testsuite</i></b> parameter.  Use the <b>/norun</b> qualifier if you only want to load, 
///     but not run, all corresponding UnitTest classes specified by the <b><i>testsuite</i></b> parameter. Default is <b>/run</b>.
///     </br></br>
///     <b>/recursive</b>: Recurse the specified directory when loading UnitTest classes. Default is <b>/recursive</b>.
///     </br></br>
///     <b>/display=all</b>: Display extended information when loading and running UnitTest classes and tests. <b>/display=none</b> displays limited information. Default is <b>/display=all</b>.
///     </br></br>
///     <b>/autoload</b>: Automatically load sub-directories with the given name when loading test classes.
///     Default is <b>/autoload=_autoload</b>.
///     When this qualifier is specified, classes are loaded from the given sub-directory of the current directory and its ancestors.
///     This makes it possible to use a class in multiple test suites without copying it to each of their descendant directories.
///     </br></br>
///     <b>/nodelete</b>: Do not delete loaded classes when the UnitTest has finished running.
///     </br></br>
/// </dd> 
/// 
/// <dt><i>userparam</i> 
/// <dd>An arbitrary argument passed in by the caller, which allows for the storage of additional 
///     information, like platform, product version, etc. </br>
///     If this parameter is passed a string, then it becomes the value for the <property>UserParam</property> property. </br>
///     If this parameter is passed an array, then the first level subscripts and their values are used to populate the <property>UserFields</property> array property. </br>
///     This information can be later cross-referenced in the result.
/// </dd></dl>
/// <dt><i>sections</i> 
/// <dd>An options, comma-delimited list of file sections this call should test.  This will not run all the tests listed in the file, but only the tests within the specified [section#] within the file.
/// 	For example, suppose you file has sections [1], [2], [3], [4], [5], and [6].  If sections="2,4,6" only tests within sections [2], [4], and [6] will be run.
/// </dd></dl>
/// <br><br>
ClassMethod RunTestsFromFileList(globalName As %String = "", fileName As %String = "", qspec As %String, ByRef userparam, sections As %String = "") As %Status
{
	RETURN:"^"'[$e(globalName) $$$ERROR($$$InvalidGlobalName,globalName)	// Invalid Global Name!
	
	new %t1,%t2,%objlasterror
	set tSC=$$$OK
	try {
		set file=##class(%FileCharacterStream).%New()
		set file.Filename=fileName
		if $g(%objlasterror)'="",$$$ISERR(%objlasterror) { RETURN %objlasterror }	// report error if file location is bad
		kill ^||UnitTest.exclude // Kill UnitTest Exclude Global!
			// If insection=1 this means we are within a section of the file that we eant to include
		set insection=(sections="")
		
		for { // --- Process UnitTest File ---
			quit:file.AtEnd  // End of UnitTest File!
			
			set utPath=file.ReadLine()
			set utPath=$$$StripLeadingAndTrailingWhiteSpace(utPath)
			continue:utPath=""	// empty line

			if $e(utPath,1)="[",$e(utPath,*)="]" {
				if sections'="" { set insection=(","_sections_",")[(","_$e(utPath,2,*-1)_",") }
				continue
			}
			continue:'insection
				
			if $e(utPath,1)'="#",$e(utPath,1,2)'="//" { // --- Not a # or // Comment ---
				if $e(utPath)="-" { 
					set sc=..addToExcludeGlobal($e(utPath,2,*))
					if $$$ISERR(sc) { set tSC=$$$ADDSC(tSC,sc) }
				} else { 
					if globalName="" { // --- Execute Each 'utPath' Directly From The File ---
						set sc=..RunTest(utPath,.qspec,.userparam)
						if $$$ISERR(sc) { set tSC=$$$ADDSC(tSC,sc) }
					} else { // --- Trasfer Each 'utPath' to a Global Before Executing UnitTests ---
						set @globalName@($i(line))=utPath
					}
				}
			}
		}
		set:globalName'="" tSC=..RunTest(globalName,.qspec,.userparam)
	}
	catch tException {
		set tSC=tException.AsStatus()
	}
	kill ^||UnitTest.exclude // Kill UnitTest Exclude Global!
	RETURN tSC
}

/// <p>
/// This method adds the given <b><i>excludeUTPath</i></b> to the exclusion global:
/// <pre>
///    ^||UnitTest.exclude(0,...)                        // Master Map
///    ^||UnitTest.exclude("x",$$$UPPER(excludeUTPath))  // Index Map
/// </pre>
/// </p>
/// <p>
/// <b>Invocation:</b> </br>
/// This method can be invoked in the following ways:
/// <ul>
///   <li>ObjectScript: ##class(%UnitTest.Manager).addToExcludeGlobal(...)</li>
///   <li>SQL: N/A</li>
/// </ul>
/// </p>
/// <p>
/// <b>Parameters:</b>
/// <dl>
///   <dt><i>excludeUTPath</i></dt>
///     <dd>The directory path of the UnitTest to exclude from running, or a path prefix 
///         (e.g. SQL\SQLStats) to exclude all UnitTests within this directory and all 
///         sub-directories from running
///     </dd>
/// </dl>
/// </p>
/// <p>
/// <b>Return Value:</b> </br>
///    The status of this method's invocation; </br>
///    Otherwise, return an error message if an error occurred
/// </p>
ClassMethod addToExcludeGlobal(excludeUTPath As %String = "") As %Status
{
	set tSC=$$$OK
	
 try {
	set excludeUTPathOrig=excludeUTPath
	set excludeUTPath=$$$StripLeadingAndTrailingWhiteSpace(excludeUTPath)
	QUIT:excludeUTPath=""  // Empty Exclude Name!
	
	set excludeUTPath=$REPLACE($TR(excludeUTPath,"/","\"),"\\","\")
	set gloRef="^||UnitTest.exclude("
	set gloMasterRef=gloRef_"0"
	set gloIndexRef=gloRef_"""x"","""_$$$UPPER(excludeUTPath)_""")"
	RETURN:$d(@gloIndexRef) $$$OK  // 'excludeUTPath' Already Exists!
	
	for pos=1:1 { // --- Spin Through All "\" Pieces of 'excludeUTPath' ---
		set sub=$p(excludeUTPath,"\",pos)
		QUIT:sub=""  // No more pieces!
		
		set gloMasterRef=gloMasterRef_","""_sub_""""
	}
	
	if $e(gloMasterRef,*-1)'="(" { // --- // Mark UnitTest Exclusion Globals ---
		set @(gloMasterRef_")")=excludeUTPathOrig	// Master Map
		set @(gloIndexRef)=excludeUTPathOrig		// Index Map
	}
 }
 catch tException {
	set tSC=tException.AsStatus()
 }
	RETURN tSC
}

/// <p>
/// This method is called after the invocation of the <method>SaveResult</method> method
/// to perform any result aggregation tasks required by subtasks.
/// </p>
Method OnAfterSaveResult(ByRef userparam)
{
}

/// <p>
/// This method is called before any UnitTests are run. 
/// If an error status is returned, then no UnitTests are run.
/// </p>
ClassMethod OnBeforeAllTests(manager As %UnitTest.Manager, dir As %String, ByRef qstruct, ByRef userparam) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called after all UnitTests are run.
/// If an error status is returned, then it is logged.
/// </p>
ClassMethod OnAfterAllTests(manager As %UnitTest.Manager, dir As %String, ByRef qstruct, ByRef userparam) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called before autoload, which occurs before each test suite is run.
/// If an error status is returned, then it is logged and the test suite is not run.
/// </p>
Method OnBeforeAutoLoad(dir As %String, suite As %String, testspec As %String, ByRef qstruct) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called before a test suite is run.
/// If an error status is returned, it is logged and the test suite is not run.
/// This is called after autoload.
/// </p>
Method OnBeforeTestSuite(dir As %String, suite As %String, testspec As %String, ByRef qstruct) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called after a test suite is run.
/// If an error status is returned, it is logged.
/// </p>
Method OnAfterTestSuite(dir As %String, suite As %String, testspec As %String, ByRef qstruct) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called before a test case (class extending <class>%UnitTest.TestCase</class>) is run.
/// If an error status is returned, it is logged and the test case is not run.
/// </p>
Method OnBeforeTestCase(suite As %String, class As %String, ByRef testcase As %UnitTest.TestCase) As %Status
{
	//Filter out and ignore whitespaces; test writers may wish to use them
	//as separators for readability.
	Set UserNames=$ZSTRIP(testcase.#AutoUserNames,"*W")
	If UserNames '= "" {
		Try {
			//Get parameter information from the test case
			Set UserResources=$ZSTRIP(testcase.#AutoUserResources,"*W")
			Set UserRoles=$ZSTRIP(testcase.#AutoUserRoles,"*W")
			Set NSAccess = testcase.#AutoGiveUsersNSAccess
			
			Set AdditionalResources=""
			If NSAccess = 1 {
				//The test might ask that all users have read-write access to the current namespace
				//and database. If so, we need to retrieve the namespace resource information before
				//switching to %SYS.
				Kill CurrNSInfo
				Do ##class(%SYS.Namespace).GetAllNSInfo($NAMESPACE,.CurrNSInfo)
				Set AdditionalResources=CurrNSInfo("GlobalDB","Resource")_":RW"
				If CurrNSInfo("RoutineDB","Resource")'=CurrNSInfo("GlobalDB","Resource") {
					Set AdditionalResources=AdditionalResources_","_CurrNSInfo("RoutineDB","Resource")_":RW"
				}
				Set AdditionalResources=AdditionalResources_",%Service_Terminal:U,%Service_Console:U"
			}
			
			//Generate a randomized password for the test users to share.
			//Password is 20 characters in length, and characters can be
			//A-Z, a-z, 0-9, +, or /.
			Set testcase.AutoPassword = $system.Encryption.GenCryptRand(32)
			Set testcase.AutoPassword = $system.Encryption.Base64Encode(testcase.AutoPassword)
			Set testcase.AutoPassword = $extract(testcase.AutoPassword,1,20)
			
			//Now to create each user...
			New $NAMESPACE
			Set $NAMESPACE = "%SYS"
			Set numusers = $length(UserNames,";")
			For usr=1:1:numusers {
				Set username = $piece(UserNames,";",usr)
				If username = "" Continue
				
				//Create a test role for the user that contains the test-specified resources.
				Set rolename = username_"Role"
				
				//If test asked to give all users read-write access to the namespace,
				//then some additional resources are needed.
				Set resources = AdditionalResources
				
				// Check that each listed resource for the test user has real 
				// permissions attached (Read, Write, Use, or some combination
				// thereof).
				//
				// The Security.Roles.Create() method silently assigns resources 
				// without permissions if the test author forgets to specify them, 
				// misformats them, or misspells them. These are plausible mistakes, 
				// so we'll check for those cases here and make them easier to
				// identify.
				Set listedresources = $piece(UserResources,";",usr)
				For i=1:1:$length(listedresources,",") {
					Set rsrc = $piece(listedresources,",",i)
					If rsrc="" Continue
					
					Set permissions=$ZCONVERT($piece(rsrc,":",2),"U")
					Set errmsg = ""
					
					//Check that permissions are not empty.
					If (permissions="") {
						Set errmsg = "Test User Autocreation: Resource list must include permissions. Use the format <resource>:<permissions>."
					}
					//Check that no more than one colon (":") is used.
					Set numcolons=$length(rsrc,":") - 1
					If (numcolons > 1) {
						Set errmsg = "Test User Autocreation: Resource-permission pair has excess colons ("":""). Use the format <resource>:<permissions>."
					}
					//Confirm that the permissions are READ, WRITE, USE, or some combination of R,W,U.
					If (errmsg = "") && (permissions'="READ") && (permissions'="WRITE") && (permissions'="USE") {
						for j=1:1:$length(permissions) {
							Set letter = $extract(permissions,j)
							If ("RWU" '[ letter) {
								Set errmsg = "Test User Autocreation: Resource has an unidentifiable set of permissions attached."
							}
					    }
					}
					
					//If an error message was set during the above permissions checks,
					//construct an error status and return it.
					If (errmsg '= "") {
						Set errstatus=$system.Status.Error(5001,errmsg)
						Return errstatus
					}
					
					//Otherwise, add the resource to the list.
					If resources '= "" Set resources=resources_","
					Set resources=resources_rsrc
				}
				
				//Roles specified in the test case will be granted along with the test role.
				Set grantedroles=$piece(UserRoles,";",usr)
				Do ##class(Security.Roles).Delete(rolename)
				Set sc = ##class(Security.Roles).Create(rolename,"Test role for user "_username,resources,grantedroles)
				$$$ThrowOnError(sc)
				
				
				//Finally, create the user.
				Kill userprops
				Set userprops("Name")=username
				Set userprops("Roles")=rolename
				Set userprops("Enabled")=1
				Set userprops("Password")=testcase.AutoPassword
				Do ##class(Security.Users).Delete(username)
				Set sc = ##class(Security.Users).Create(username,.userprops)
				$$$ThrowOnError(sc)
			}
		}
		Catch(err) {
			Return err.AsStatus()
		}
	}
	Quit $$$OK
}

/// <p>
/// This method is called after a test case (class extending <class>%UnitTest.TestCase</class>) is run.
/// If an error status is returned, it is logged.
/// </p>
Method OnAfterTestCase(suite As %String, class As %String, ByRef testcase As %UnitTest.TestCase) As %Status
{
	Try {
		Set UserNames=testcase.#AutoUserNames
		//Filter out and ignore spaces; test writers may wish to use them
		//as separators for readability.
		Set UserNames=$ZSTRIP(UserNames,"*W")
	
		If UserNames'="" {
			New $NAMESPACE
			Set $NAMESPACE="%SYS"
			Set numusers = $length(UserNames,";")
			For i=1:1:numusers {
				Set username = $piece(UserNames,";",i)
				If username = "" Continue
				Do ##class(Security.Users).Delete(username)
				Do ##class(Security.Roles).Delete(username_"Role")
			}
		}
	}
	Catch(err) {
		Return err.AsStatus()
	}
	Quit $$$OK
}

/// <p>
/// This method is called before a test (method starting with "Test" in a class extending 
/// <class>%UnitTest.TestCase</class>) is run.
/// If an error status is returned, it is logged and the test is not run.
/// </p>
Method OnBeforeOneTest(suite As %String, class As %String, method As %String) As %Status
{
	Quit $$$OK
}

/// <p>
/// This method is called after a test (method starting with "Test" in a class extending 
/// <class>%UnitTest.TestCase</class>) is run.
/// If an error status is returned, it is logged.
/// </p>
Method OnAfterOneTest(suite As %String, class As %String, method As %String) As %Status
{
	Quit $$$OK
}

ClassMethod BeforeRunTest(Test As %String) [ Internal ]
{
	for i=1:1:$l(Test,"^"){
		s options = $p(Test,"^",i)
		s before = $zstrip($p(options,"*",1),"<>W")
		s after =  $zstrip($p(options,"*",2),"<>W")
		d:before'="" @before
	}
}

ClassMethod AfterRunTest(Test As %String) [ Internal ]
{
	for i=1:1:$l(Test,"^"){
		s options = $p(Test,"^",i)
		s before = $zstrip($p(options,"*",1),"<>W")
		s after =  $zstrip($p(options,"*",2),"<>W")
		d:after'="" @after	
	}
}

ClassMethod UpdateOptions() [ Internal ]
{
        do $system.SQL.SetAutoParallel(0,.old)
        s ^IRIS.Temp.Options("auto hinting for %parallel") = old
}

ClassMethod RestoreOptions() [ Internal ]
{
        do $system.SQL.SetAutoParallel(^IRIS.Temp.Options("auto hinting for %parallel"))
        kill ^IRIS.Temp.Options("auto hinting for %parallel")
}

/// <p>
/// This is a private and internal method which reserves the UnitTest.Result ID from the <b>^|$NAMESPACE|UnitTest.Result</b> global. 
/// Test suites run under the /parallel option use this value to directly write back their results.
/// </p>
Method ReserveResultId() [ Internal, Private ]
{
    Try {
        $$$SuspendAllTrans(tflag)
        If $g(^|..OriginNS|UnitTest.Result)="" Lock +^|..OriginNS|UnitTest.Result Set ^|..OriginNS|UnitTest.Result=$o(^|..OriginNS|UnitTest.Result(""),-1) Lock -^|..OriginNS|UnitTest.Result
        $$$ResumeAllTrans(tflag) Kill tflag
    } Catch err {
        If $GET(tflag) $$$ResumeAllTrans(tflag)
        Throw err
    }
	Set ..ResultId = $i(^|..OriginNS|UnitTest.Result)
}

/// <p>
/// This is a private and internal method that returns a Boolean value {0|1} which indicates if 
/// this %UnitTest.Manager is configured to run suites in parallel?
/// </p>
Method IsParallel() As %Boolean [ Internal, Private ]
{
	RETURN $$$IsParallel
}

/// <p>
/// This is a private and internal method that returns a Boolean value {0|1} which indicates if 
/// this %UnitTest.Manager is inside a worker job running suites in parallel?
/// </p>
Method IsParallelWorker() As %Boolean [ Internal, Private ]
{
	RETURN $$$IsParallelWorker
}

/// <p>
/// This is a private and internal method that queues <b><i>suite</i></b> for parallel execution. 
/// The parameters <b><i>qspec</i></b> and <b><i>userparam</i></b> are similar to those in the 
/// <method>RunTestSuites</method> method, except that the <b><i>userparam</i></b> parameter will 
/// not be Passed By Refence (PBR) into the worker job.
/// </p>
Method QueueSuiteForParallel(suite, qspec, userparam) As %Status [ Internal, Private ]
{
	//Don't pass through the /parallel option
	Set noparparam = "/isparworker"
	For i=1:1:$l(userparam,"/parallel") {
		Set param = $p(userparam,"/parallel",i)
		Set noparparam = noparparam _ param
	}
	Return ..Parallel.QueueSuite(..ResultId, suite, qspec, noparparam)
}

/// <p>
/// This is a private and internal method that waits for all suites queued by <method>QueueSuiteForParallel</method> method
/// to complete.  The %UnitTest.Manager expects failed suites to be collected in the
/// Pass By Reference (PBR) array parameter <b><i>status</i></b> after the suites have finished
/// running.  The <b>^UnitTest.Result</b> global is scanned for failed suites, which are added
/// as subscripts to the <b><i>status</i></b> parameter.
/// </p>
Method WaitForAllSuitesForParallel(ByRef status) As %Status [ Internal, Private ]
{
	Set sc = ..Parallel.WaitForAllSuites()
	Set ..Parallel = ""
	//Collect results directly from global
	Set suite = ""
	For  {
		Set suite = $o(^|..OriginNS|UnitTest.Result(..ResultId,suite),1,result) QUIT:suite=""
		If $lg(result) = 0 Set status(" "_$tr(suite,"\","/")) = ""
	}
	Return sc
}

Method CreateSwarmReviewSSL() As %Status [ Internal, Private ]
{
	set sc = $$$OK
	RETURN:$System.Util.GetEnviron("SWARM_REVIEW_ID")="" sc

	new $NAMESPACE
	set $NAMESPACE="%SYS"

	set SSLName="SwarmReviewUnitTest",newSSL=0
	If '(##class(Security.SSLConfigs).%ExistsId(SSLName)) {
		Set cfg=##class(Security.SSLConfigs).%New()
		Set cfg.Description="SSL configuration to be used for POST any UnitTest failures to the corresponding Swarm Review as comments"
		Set cfg.Name=SSLName
		Set newSSL=1
	} Else { 
		Set cfg=##class(Security.SSLConfigs).%OpenId(SSLName,,.sc)
	}
	Set:$$$ISOK(sc) sc=cfg.%Save()
	if 'sc {
		write !,"Cannot establish SSL config to POST any UnitTest failures to the corresponding Swarm Review as comments: "_$SYSTEM.Status.GetErrorText(sc),!
		RETURN sc	
	}
	set i%Environment("swarm-review-ssl")="SwarmReviewUnitTest"
	set i%Environment("swarm-review-ssl","new")=newSSL
	set stream=##class(%Stream.FileCharacter).%New()
	set file=$System.Util.GetEnviron("HOME")_"/.netrc"
	if '##class(%File).Exists(file) {
		write !,file_" does not exist!",!
		RETURN sc	
	}
  	Set sc=stream.LinkToFile(file)
  	if 'sc {
		write !,"Cannot read "_file_" to get server, username, and password for build machine: "_$SYSTEM.Status.GetErrorText(sc),!
		RETURN sc	
	}
  	While 'stream.AtEnd {
  		set line=stream.Read()
  		set i%Environment("swarm-review-ssl","server")=$p(line," ",2)
  		set i%Environment("swarm-review-ssl","username")=$p(line," ",4)
  		set password=$p(line," ",6)
  		set:$e(password,*)=$c(10) password=$e(password,1,*-1)
  		set i%Environment("swarm-review-ssl","password")=password
  		quit
  	}
	set i%Environment("swarm-review-id")=$System.Util.GetEnviron("SWARM_REVIEW_ID")
	RETURN sc
}

Method PostSwarmReviewComment(comment As %String, ignoreCounter As %Boolean = 0) As %Status [ Internal, Private ]
{
	set sc = $$$OK,maxComment=10
	RETURN:($g(i%Environment("swarm-review-id"))="")||($g(i%Environment("swarm-review-ssl"))="") sc
	RETURN:('ignoreCounter)&&($g(i%Environment("swarm-review-ssl","comment-counter"))>maxComment) sc
	if ('ignoreCounter)&&($g(i%Environment("swarm-review-ssl","comment-counter"))=maxComment) {
		set comment = "There are more than "_maxComment_" failures, please refer to the UnitTest log file for details."	
	}
	Set httpRequest=##class(%Net.HttpRequest).%New()
	set httpRequest.Server = i%Environment("swarm-review-ssl","server")
  	set httpRequest.Username = i%Environment("swarm-review-ssl","username")
  	set httpRequest.Password = i%Environment("swarm-review-ssl","password")
	do httpRequest.InsertFormData("topic","reviews/"_i%Environment("swarm-review-id"))
	do httpRequest.InsertFormData("body",comment)
	Set httpRequest.Https = 1
    Set httpRequest.SSLConfiguration = i%Environment("swarm-review-ssl")
    
	set sc = httpRequest.Post("/api/v9/comments")
	if 'sc {
		write !,"Cannot POST this UnitTest failures to the corresponding Swarm Review as comments: "_$SYSTEM.Status.GetErrorText(sc),!
		RETURN sc
	}
	if httpRequest.HttpResponse.StatusCode'=200 {		
		write !,"The POST request was not successful: "_httpRequest.HttpResponse.StatusCode_" "_httpRequest.HttpResponse.ReasonPhrase,!
		RETURN 0
	}
	do:('ignoreCounter) $I(i%Environment("swarm-review-ssl","comment-counter"))
	RETURN sc
}

Method DeleteSwarmReviewSSL() As %Status [ Internal, Private ]
{
	set sc = $$$OK
	RETURN:'$g(i%Environment("swarm-review-ssl","new")) sc
	
	new $NAMESPACE
	set $NAMESPACE="%SYS"
	set SSLName=i%Environment("swarm-review-ssl")
	if ##class(Security.SSLConfigs).%ExistsId(SSLName){
		set sc=##class(Security.SSLConfigs).%DeleteId(SSLName)
		write:'sc !,"Cannot delete SSL config to POST any UnitTest failures to the corresponding Swarm Review as comments: "_$SYSTEM.Status.GetErrorText(sc),!
	}
	RETURN sc
}

}
