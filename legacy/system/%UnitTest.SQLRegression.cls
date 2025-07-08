/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occJava, %External.language)

/// Extends <b>TestCase</b>.  Extend from this class to create a regression test
/// <br><br>
/// 
Class %UnitTest.SQLRegression Extends %UnitTest.TestCase [ Inheritance = right, System = 4 ]
{

/// Specifies the xml file running the test so it's not reloaded
Parameter TESTFILE As STRING;

/// Comma-delimited sql filenames overrides the sql file lookup by specifying which and in which order sql script files are to be tested
Parameter SQLFILE As STRING;

/// Specifies a result file for comparison use
Parameter REFFILE As STRING = "reference.log";

/// Set <PARAMETER>SHOWPLAN</PARAMETER>=1 to dump the access plans used by each test in the test script.
/// Use this feature when you need to verify plan stability from one release to the next, or when you
/// want to investigate the impact of creating, dropping, or altering an index.
/// 
/// Boolean value specifies if comparing sql plan should be executed.  Reference plan must exist in REFFILE. Dynamic Sql Plan created in Dynamic SQL test only.
Parameter SHOWPLAN As BOOLEAN = 0;

/// <PARAMETER>DISPLAYTESTNAME</PARAMETER> enables you to internationalize the display of the test name,
/// which may be specified after the #### delimiter in the test file, when <PARAMETER>TIMESCALE</PARAMETER> 
/// is a positive number.
/// 
Parameter DISPLAYTESTNAME = "Test ";

/// The <PARAMETER>TIMESCALE</PARAMETER> parameter enables you to control whether elapsed time information
/// is displayed for each SQL statement, and the number of significant digits used to display the time.  
/// This can be used to determine whether significant differences in elapsed time are consumed by any
/// individual query.  By default, TIMESCALE="", which will prevent elapsed time information from being
/// displayed at the end of each SQL statement in the test.  Setting DISPLAYSECONDS to 1 will display the result 
/// in seconds.  Setting DISPLAYSECONDS to 10 will display elapsed time in multiples of 10 seconds.  Setting
/// TIMESCALE to 0.1 will display elapsed time to the nearest tenth second.  By grouping together a set of
/// tests that each take about the same amount of time you can automate the process of determining if any
/// query takes "significantly" more or less time than it did previously.
/// 
Parameter TIMESCALE = 0;

/// <PARAMETER>DISPLAYELAPSEDTIME</PARAMETER> enables you to internationalize the display of elapsed time,
/// when <PARAMETER>TIMESCALE</PARAMETER> is a positive number.
/// 
Parameter DISPLAYELAPSEDTIME = " executed and fetched in ";

/// <PARAMETER>DISPLAYSECONDS</PARAMETER> enables you to internationalize the spelling of "seconds" in
/// the output of elapsed time when <PARAMETER>TIMESCALE</PARAMETER> is a positive number.
/// 
Parameter DISPLAYSECONDS = "seconds";

/// Method to clean up before each Test method is executed.
Method OnBeforeEachTest() As %Status
{
	;We MUST Reload classes and globals from XML to get clean copies!!! 
	set fileset="",sep=""
	if ..Manager.LoadXML Set fileset="*.xml;*.XML",sep=";"
	if ..Manager.LoadUDL Set fileset=fileset_sep_"*.cls;*.mac;*.int;*.inc;*.CLS;*.MAC;*.INT;*.INC"
	s sfs=##class(%ResultSet).%New("%File:FileSet")
	s sc=sfs.Execute(..Manager.CurrentDir,fileset)
	while(sfs.Next()) {
		if $system.Version.GetOS()["VMS" {
			s item=sfs.Data("ItemName")
			s item=$e(item,1,$f(item,";")-2)
			continue:(item= $zcvt(..#TESTFILE,"U"))
		}
		else {
			continue:(sfs.Data("ItemName")=..#TESTFILE)
		}
		s sc=$system.OBJ.Load(..Manager.CurrentDir_sfs.Data("ItemName"),"ck")
	}
	
	;Purge Cached Queries
	d $system.SQL.Purge()
	k $$$CQnsroot
	
	//...To Do
	q $$$OK
}

/// Method to clean up after each Test method is executed.
Method OnAfterEachTest() As %Status
{
	//clean up
	k %ROWCOUNT,%ROWID,%objlasterror,%sqlcontext,^CacheStream
	
	//...To Do
	q $$$OK
}

/// Method available to do any work before a Sql File begins execution.
Method OnBeforeSqlFile(sqlfile As %String) As %Status
{
	q $$$OK
}

/// Method available to do any work after a Sql File has finished execution.
Method OnAfterSqlFile(sqlfile As %String) As %Status
{
	q $$$OK
}

/// Method to display incorrect results in a more readable format.
Method processDiffFile(ByRef rslt As %Stream)
{
	while 'rslt.AtEnd {
			s str=rslt.ReadLine()
			d $$$LogMessage(str)
			d $$$LogMessage("SQL:"_$e(str,$f(str,":"),$f(str,"'")-2))
			d $$$LogMessage("SQL Length:"_$l($e(str,$f(str,":"),$f(str,"'")-2)))
			d $$$LogMessage("EXP:"_$e(str,$f(str,"'="),$l(str)))
			d $$$LogMessage("EXP Length:"_$l($e(str,$f(str,"'="),$l(str))))
		}
}

/// Test each line of SQL from <parameter>SQLFILE</parameter> using dynamic SQL.
/// If no <parameter>REFFILE</parameter> exists, it will be created from the dynamic results and that file will serve as the correct test results.
/// It is up to the test creator to confirm that the expected test results are correct.
Method TestDynamic()
{
	s sc=..OnBeforeEachTest()
	d $$$AssertStatusOK(sc,"Load test data & clean environment")
	//find all sql file(s) of calls to execute
	s sfs="",sfi=0,sfc=0,sff=""
	if ..#SQLFILE="" {
		s sfs=##class(%ResultSet).%New("%File:FileSet")
		d $$$AssertTrue(sfs'="","SQL File Set object opened")
		q:sfs=""
		s sc=sfs.Execute(..Manager.CurrentDir,"*.sql;*.SQL")
		d $$$AssertStatusOK(sc,"Lookup sql files")
	}
	else {
		s sfc=$l(..#SQLFILE,","),sfi=0,last=1
		f i=1:1:sfc {
			s $LIST(sff,i)=$e(..#SQLFILE,last,$s($f(..#SQLFILE,",",last)>0:$f(..#SQLFILE,",",last)-2,1:$l(..#SQLFILE)))
			s last=$f(..#SQLFILE,",",last)
		}
	}
	if sc {
		while((sfi<sfc)||((sfs'="")&&(sfs.Next()))) {
			//execute dynamic sql on each found sql file
			if sfs'="" {s testName=sfs.Data("ItemName")}
			else {s sfi=sfi+1 s testName=$lg(sff,sfi)}
			d $$$LogMessage("Execute SQL File "_testName)
			s sc=..OnBeforeSqlFile(testName)
			d $$$AssertStatusOK(sc,"Load environment for this sql file")
			s result=""
			set startTime = $zh
			;expected result file must be same name as SQL file appended by test method and with .ref or .log extension else default to .ukn
			s pre=$e(..Manager.CurrentDir_testName,1,$f(..Manager.CurrentDir_testName,".",1)-2)
			s expfn=$s(##class(%File).Exists(..Manager.CurrentDir_..#REFFILE):..Manager.CurrentDir_..#REFFILE,1:pre_..#REFFILE)
			if ((..#SHOWPLAN)&&('##class(%File).Exists(expfn))) {s result=##class(DSQL).runDSQL(..Manager.CurrentDir_testName,0,1)}
			else {s result=##class(DSQL).runDSQL(..Manager.CurrentDir_testName,0,0)}
			continue:result=""
			s expected=##class(%FileCharacterStream).%New()
			s expected.Filename=expfn
			//need to create reference.log?
			if ('##class(%File).Exists(expfn)){
				d $$$LogMessage("Creating new reference file: "_expected.Filename)
				s sc=expected.CopyFrom(result)
				d $$$AssertStatusOK(sc,"Copy result data")
				s sc=expected.%Save()
				d $$$AssertStatusOK(sc,"Save result file")
			}
			if ..#SHOWPLAN d $$$LogMessage("Verifing <plan> when verifying results")
			s delete=..verifyResults(.result,testName)
			if ..#TIMESCALE>0 { s elapsedTime=($zh-startTime) s elapsedTime=..#DISPLAYELAPSEDTIME_((elapsedTime+(..#TIMESCALE/2)\..#TIMESCALE)*..#TIMESCALE)_" "_..#DISPLAYSECONDS } else { s elapsedTime="" }
 			if ((testName'="") || (elapsedTime'="")) { d $$$LogMessage($s(testName'="":..#DISPLAYTESTNAME_testName,1:"")_elapsedTime)}
			s fn=result.Filename
			s result=""
			if ((delete)&&(##class(%File).Exists(fn))) {d ##class(%File).Delete(fn)}
			s expfn=""
			s sc=..OnAfterSqlFile(testName)
			d $$$AssertStatusOK(sc,"Clean environment after this sql file")
			} ;end while
		if sfs'="" {
			d sfs.Close()
		}
		s sfs=""
	}
	s sc=..OnAfterEachTest()
	d $$$AssertStatusOK(sc,"clean environment")
}

/// Test each line of SQL from <parameter>SQLFILE</parameter> using embedded SQL.
Method TestEmbedded()
{
	s macs=##class(%ListOfDataTypes).%New()
	s sc=..OnBeforeEachTest()
	d $$$AssertStatusOK(sc,"Load test data & clean environment")
	//find all sql file(s) of calls to execute
	s sfs="",sfi=0,sfc=0,sff=""
	if ..#SQLFILE="" {
		s sfs=##class(%ResultSet).%New("%File:FileSet")
		d $$$AssertTrue(sfs'="","SQL File Set object opened")
		q:sfs=""
		s sc=sfs.Execute(..Manager.CurrentDir,"*.sql;*.SQL")
		d $$$AssertStatusOK(sc,"Lookup sql files")
	}
	else {
		s sfc=$l(..#SQLFILE,","),sfi=0,last=1
		f i=1:1:sfc {
			s $LIST(sff,i)=$e(..#SQLFILE,last,$s($f(..#SQLFILE,",",last)>0:$f(..#SQLFILE,",",last)-2,1:$l(..#SQLFILE)))
			s last=$f(..#SQLFILE,",",last)
		}
	}
	if sc {
		while((sfi<sfc)||((sfs'="")&&(sfs.Next()))) {
			//execute dynamic sql on each found sql file
			if sfs'="" {s testName=sfs.Data("ItemName")}
			else {s sfi=sfi+1 s testName=$lg(sff,sfi)}
			d $$$LogMessage("Execute SQL File "_testName)
			s sc=..OnBeforeSqlFile(testName)
			d $$$AssertStatusOK(sc,"Load environment for this sql file")
			s result=""
			set startTime = $zh
			s result=##class(ESQL).runESQL(..Manager.CurrentDir_testName,0,.macs)
			continue:result=""
			//s delete=..verifyResults(.result,testName)
			s delete=1
			if ..#TIMESCALE>0 { s elapsedTime=($zh-startTime) s elapsedTime=..#DISPLAYELAPSEDTIME_((elapsedTime+(..#TIMESCALE/2)\..#TIMESCALE)*..#TIMESCALE)_" "_..#DISPLAYSECONDS } else { s elapsedTime="" }
 			if ((testName'="") || (elapsedTime'="")) { d $$$LogMessage($s(testName'="":..#DISPLAYTESTNAME_testName,1:"")_elapsedTime)}
			s fn=result.Filename
			s result=""
			if ((delete)&&(##class(%File).Exists(fn))) {d ##class(%File).Delete(fn)}
			s fn=""
			s expfn=""
			s sc=..OnAfterSqlFile(testName)
			d $$$AssertStatusOK(sc,"Clean environment after this sql file")
			} ;end while
		if sfs'="" {
			d sfs.Close()
		}
		s sfs=""
	}
	//delete generated mac files
	f i=1:1:macs.Size {
		if (##class(%Routine).Exists(macs.GetAt(i))) {
			d ##class(%Routine).Delete(macs.GetAt(i))
		}
	}
	s sc=..OnAfterEachTest()
	d $$$AssertStatusOK(sc,"clean environment")
}

/// Test each line of SQL from <parameter>SQLFILE</parameter> using an ODBC SQL Gateway connection.
/// Requires the existence of the User namespace DSN provided with InterSystems IRIS.
Method TestODBC()
{
	//verify OS
	if (($system.Version.GetOS()'="Windows")&&($zcvt($system.Version.GetOS(),"U")'="UNIX")){
		d $$$LogMessage("Test on Windows or Unix only, "_$system.Version.GetOS()_" not supported")
		q
	}

	s sc=..OnBeforeEachTest()
	d $$$AssertStatusOK(sc,"Load test data & clean environment")

	//find all sql file(s) of calls to execute
	s sfs="",sfi=0,sfc=0,sff=""
	if ..#SQLFILE="" {
		s sfs=##class(%ResultSet).%New("%File:FileSet")
		d $$$AssertTrue(sfs'="","SQL File Set object opened")
		q:sfs=""
		s sc=sfs.Execute(..Manager.CurrentDir,"*.sql;*.SQL")
		d $$$AssertStatusOK(sc,"Lookup sql files")
	}
	else {
		s sfc=$l(..#SQLFILE,","),sfi=0,last=1
		f i=1:1:sfc {
			s $LIST(sff,i)=$e(..#SQLFILE,last,$s($f(..#SQLFILE,",",last)>0:$f(..#SQLFILE,",",last)-2,1:$l(..#SQLFILE)))
			s last=$f(..#SQLFILE,",",last)
		}
	}
	
	s dsn=""
	
	if sc {
		while((sfi<sfc)||((sfs'="")&&(sfs.Next()))) {
			//execute dynamic sql on each found sql file
			if sfs'="" {s testName=sfs.Data("ItemName")}
			else {s sfi=sfi+1 s testName=$lg(sff,sfi)}
			d $$$LogMessage("Execute SQL File "_testName)
			s sc=..OnBeforeSqlFile(testName)
			d $$$AssertStatusOK(sc,"Load environment for this sql file")
			s result=""
			set startTime = $zh
			s result=##class(ODBCSQL).runODBCSQL(..Manager.CurrentDir_testName,.dsn,0)
			continue:result=""
			s delete=..verifyResults(.result,testName)
			if ..#TIMESCALE>0 { s elapsedTime=($zh-startTime) s elapsedTime=..#DISPLAYELAPSEDTIME_((elapsedTime+(..#TIMESCALE/2)\..#TIMESCALE)*..#TIMESCALE)_" "_..#DISPLAYSECONDS } else { s elapsedTime="" }
 			if ((testName'="") || (elapsedTime'="")) { d $$$LogMessage($s(testName'="":..#DISPLAYTESTNAME_testName,1:"")_elapsedTime)}
			s fn=result.Filename
			s result=""
			if ((delete)&&(##class(%File).Exists(fn))) {d ##class(%File).Delete(fn)}
			s fn=""
			s expfn=""
			s sc=..OnAfterSqlFile(testName)
			d $$$AssertStatusOK(sc,"Clean environment after this sql file")
			} ;end while
		if sfs'="" {
			d sfs.Close()
		}
		s sfs=""
	}
	s sc=..OnAfterEachTest()
	d $$$AssertStatusOK(sc,"clean environment")
}

/// Test each line of SQL from <parameter>SQLFILE</parameter> using a JDBC SQL Gateway connection.
Method TestJDBC()
{
	;verify system
	if (($system.Version.GetOS()'="Windows")&&($zcvt($system.Version.GetOS(),"U")'="UNIX")){
		d $$$LogMessage("Test on Windows or Unix only, "_$system.Version.GetOS()_" not supported")
		q
	}
	
	;verify Java is on system
	s jv=""
	set sc = $$$OK
	try {
	set jv = $system.external.getServerLanguageVersion($$$EXTERNALLANGUAGESERVERNAMEJDBC)
	} catch exc {
		set sc = exc.AsStatus()
	}
	if 'sc {
		d $$$LogMessage("Java not found installed on system, skipping JDBC testing")
		q
	}

	s sc=..OnBeforeEachTest()
	d $$$AssertStatusOK(sc,"Load test data & clean environment")
	
	//find all sql file(s) of calls to execute
	s sfs="",sfi=0,sfc=0,sff=""
	if ..#SQLFILE="" {
		s sfs=##class(%ResultSet).%New("%File:FileSet")
		d $$$AssertTrue(sfs'="","SQL File Set object opened")
		q:sfs=""
		s sc=sfs.Execute(..Manager.CurrentDir,"*.sql;*.SQL")
		d $$$AssertStatusOK(sc,"Lookup sql files")
	}
	else {
		s sfc=$l(..#SQLFILE,","),sfi=0,last=1
		f i=1:1:sfc {
			s $LIST(sff,i)=$e(..#SQLFILE,last,$s($f(..#SQLFILE,",",last)>0:$f(..#SQLFILE,",",last)-2,1:$l(..#SQLFILE)))
			s last=$f(..#SQLFILE,",",last)
		}
	}
	
	;find or make jdbc gateway connection
	s gcn=""
	s sc=##class(JDBCSQL).getJDBCGateway(.gcn)
	d $$$AssertStatusOK(sc,"Find or create JDBC Gateway")
	q:((gcn="")||('sc))
	d $$$LogMessage("Using SQL Gateway Connection: "_gcn)
	if sc {
		;$s(sfs'="":sfs.Next(),..#SQLFILE'="":sfi<sfc)
		while((sfi<sfc)||((sfs'="")&&(sfs.Next()))) {
			//execute dynamic sql on each found sql file
			if sfs'="" {s testName=sfs.Data("ItemName")}
			else {s sfi=sfi+1 s testName=$lg(sff,sfi)}
			d $$$LogMessage("Execute SQL File "_testName)
			s sc=..OnBeforeSqlFile(testName)
			d $$$AssertStatusOK(sc,"Load environment for this sql file")
			s result=""
			set startTime = $zh
			s result=##class(JDBCSQL).runJDBCSQL(..Manager.CurrentDir_testName,.gcn,0)
			continue:result=""
			s delete=..verifyResults(.result,testName)
			if ..#TIMESCALE>0 { s elapsedTime=($zh-startTime) s elapsedTime=..#DISPLAYELAPSEDTIME_((elapsedTime+(..#TIMESCALE/2)\..#TIMESCALE)*..#TIMESCALE)_" "_..#DISPLAYSECONDS } else { s elapsedTime="" }
 			if ((testName'="") || (elapsedTime'="")) { d $$$LogMessage($s(testName'="":..#DISPLAYTESTNAME_testName,1:"")_elapsedTime)}
			s fn=result.Filename
			s result=""
			if ((delete)&&(##class(%File).Exists(fn))) {d ##class(%File).Delete(fn)}
			s fn=""
			s expfn=""
			s sc=..OnAfterSqlFile(testName)
			d $$$AssertStatusOK(sc,"Clean environment after this sql file")
			} ;end while
		if sfs'="" {
			d sfs.Close()
		}
		s sfs=""
	}
	s sc=..OnAfterEachTest()
	d $$$AssertStatusOK(sc,"clean environment")
}

/// Compare dynamic results src against existing reference file
Method verifyResults(ByRef src As %FileCharacterStream, testName As %String = "") As %Status
{
	;compare src against REFFILE
	s ref=##class(%FileCharacterStream).%New()
	s pre=##class(%File).GetFilename(src.Filename)
	s pre=$e(pre,1,$f(pre,".")-6)
	s pretn=$e(testName,1,$f(testName,".")-2)
	if $system.Version.GetOS()["VMS" {
		if (##class(%File).Exists(..Manager.CurrentDir _pre_ $zcvt(..#REFFILE,"U"))) {
			s ref.Filename=..Manager.CurrentDir _pre_ $zcvt(..#REFFILE,"U")
		}
		elseif (##class(%File).Exists(..Manager.CurrentDir_  $zcvt(..#REFFILE,"U"))) {
			s ref.Filename=..Manager.CurrentDir_ $zcvt(..#REFFILE,"U")		}
		elseif (##class(%File).Exists(..Manager.CurrentDir_pretn_ $zcvt(..#REFFILE,"U"))) {
			s ref.Filename=..Manager.CurrentDir _pretn_ $zcvt(..#REFFILE,"U")
		}
		else {
			d $$$AssertTrue(0,"Unable to find reference file for comparison")
			q '$$$OK
		}
	}
	else {
		if (##class(%File).Exists(..Manager.CurrentDir _pre_ ..#REFFILE)) {
			s ref.Filename=..Manager.CurrentDir _pre_ ..#REFFILE
		}
		elseif (##class(%File).Exists(..Manager.CurrentDir_  ..#REFFILE)) {
			s ref.Filename=..Manager.CurrentDir_ ..#REFFILE
		}
		else {
			d $$$AssertTrue(0,"Unable to find reference file for comparison")
			q '$$$OK
		}
	}
	d ref.Rewind(),src.Rewind()
	s res=##class(Utility).crossVerify(.ref,.src)
	d $$$LogMessage("Comparing "_src.Filename_" to "_ref.Filename)
	d $$$AssertTrue(res.Size=0,"No differences found")
	if (res.Size>0) {
		d res.Rewind()
		while 'res.AtEnd {
			d $$$LogMessage(res.ReadLine())
		}
		q '$$$OK
	}
	q $$$OK
}

}
