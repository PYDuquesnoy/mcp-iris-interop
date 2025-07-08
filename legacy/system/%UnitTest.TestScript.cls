/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is an example of extending the <class>TestCase</class> class for your own testing needs.
/// It provides the <method>TestRunScript</method> method, which replays the script specified in the <parameter>TESTFILE</parameter> parameter, comparing it to a reference log of expected output.
/// <p>
/// To use this class for your tests, write a subclass that implements the <method>runScript</method> method to read a script and generate repeatable output.
/// Pass the string "reference" as the <b>userparam</b> parameter to the <b>RunTest</b> method to record the expected output to reference.log:
/// 
/// <example>
/// d ##class(%UnitTest.Manager).RunTest("example\suite",,"reference")
/// </example>
/// 
/// In subsequent runs, call <b>RunTest</b> without "reference" to compare the output to reference.log:
/// 
/// <example>
/// d ##class(%UnitTest.Manager).RunTest("example\suite")
/// </example>
/// 
/// See the <class>TestCacheScript</class> and <class>TestSqlScript</class> classes for examples.
Class %UnitTest.TestScript Extends %UnitTest.TestCase [ System = 3 ]
{

/// File that contains the test steps, in a format determined by the <method>runScript</method> method.
Parameter TESTFILE;

/// Set to 1 to call $$$AssertFilesSQLUnorderedSame rather than $$$AssertFilesSame
Parameter UNORDEREDFILESAME = 0;

/// This method, which is run automatically by <class>%UnitTest.Manager</class>, calls the implementation of <method>runScript</method> supplied by a subclass.
/// If the <parameter>TESTFILE</parameter> parameter is not specified, it uses <i>script.txt</i>.
/// <p>
/// When the "reference" parameter is specified, it writes expected output to reference.log.
/// Otherwise, it compares the output to reference.log using $$$AssertFilesSame (or $$$AssertFilesSQLUnorderedSame if the <parameter>UNORDEREDFILESAME</parameter> parameter is set).
Method TestRunScript()
{
 Set dir=..Manager.CurrentDir
 Set scriptfile=dir_$s(..#TESTFILE'="":..#TESTFILE,1:"script.txt")
 Set outputfile=dir_"output.log",compare=1
 If ..Manager.UserParam="reference" Set compare=0,outputfile=dir_"reference.log"
 If ..Manager.UserParam="screen"    Set compare=0,outputfile=""
 Do $$$AssertStatusOK(..runScript(scriptfile,outputfile))
 If compare {
	 if (..#UNORDEREDFILESAME) {
		 Do $$$AssertFilesSQLUnorderedSame(outputfile,dir_"reference.log")
	 } else {
		 Do $$$AssertFilesSame(outputfile,dir_"reference.log") 
	 }
 } 
 Quit
}

/// Override this method with an implementation that reads from <b>scriptfile</b>, writing the output to <b>outputfile</b>.
/// The output should be repeatable for a given script; not dependent on, e.g., the time or the system under test.
ClassMethod runScript(scriptfile As %String, outputfile As %String) [ Abstract ]
{
}

}
