/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %TSQL.sys.procedure Extends %Persistent [ StorageStrategy = oddproc, System = 4 ]
{

Property idSCHEMA As %String(MAXLEN = 256);

Property idPROC As %String(MAXLEN = 256);

Property schema As %String(MAXLEN = 256);

Property name As %String(MAXLEN = 256);

Property class As %String(MAXLEN = 256);

Property description As %String(MAXLEN = "");

Property execute As %String(MAXLEN = 4096);

/// Sybase execution modes associated with stored procedures.
/// Values are "chained", "unchained", and "anymode", for transaction modes, and '[No] Dynamic Ownership Chain'
/// At this time, ownership chains are not supported
/// This is only used for TSQL stored procedures with Dialect = Sybase
Property procxmode As %String [ Calculated, SqlComputeCode = { set {*}=$case($g(^rINDEXSQL("tsql","procxmode",{class},{procedure})),1:"chained",2:"anymode",:"unchanged")}, SqlComputed ];

/// 	interface
/// 		-2	function procedure with a return value that may return result sets
/// 		-1	function procedure without a return value that may return result sets
/// 		0	function procedure without a return value, no result sets
/// 		1	query (single result set)
/// 		2	function with a return value, no result sets
Property interface As %Integer;

Property procedure As %String;

Index ID On (idSCHEMA, idPROC) [ IdKey ];

ClassMethod inc()
{

#define cPROCcolumn              "c"
#define cPROCcontextclass				25
#define cPROChidden              5
#define cPROCidcolumn            6
#define cPROCidextent			23
#define cPROCinputparms          7

#define cPROCmethod              9 
#define cPROCname                10
#define cPROCodbccatalog         11
#define cPROCodbcinfo            12
#define cPROCoutputparms         13
	#; cPROCparmsdirection is a string of 0|1 where a 1 value corresponds to a parm that is output or IO (indicate an output 'direction') Return values are not represented here.
#define cPROCparmsdirection      15
#define cPROCparmsobjectcat      24
#define cPROCprocedure           14
#define cPROCremarks             16
#define cPROCresultsets          17
#define cPROCreturnval           18
#define cPROCroutine             19
#define cPROCsignature           21
#define cPROCstatementtype			23
#define cPROCsubquery			"s"
#define cPROCtype                22
 
#define cPROCCOLparm       "P"
#;											21
#define cPROCCOLattribute       	1
#define cPROCCOLbitstring			21
#define cPROCCOLcaption				15
#define cPROCCOLclass				16
#define cPROCCOLclientdatatypeenum	17
#define cPROCCOLcolinfo         	2
#define cPROCCOLdatatype			3
#define cPROCCOLlength          	4
#define cPROCCOLname            	5
#define cPROCCOLnullable        	6
#define cPROCCOLodbctype        	7
#define cPROCCOLodbctypename    	8
#define cPROCCOLprecision       	9
#define cPROCCOLprocinfo        	10
#define cPROCCOLradix           	11
#define cPROCCOLremarks         	12
#define cPROCCOLscale           	13
#define cPROCCOLschema				18
#define cPROCCOLsubquery			20
#define cPROCCOLtablename			19
#define cPROCCOLtype            	14
 
#define cPROCSUBQUERYcardinality	1
 
#; ENUM values
#define cPROCTYPEFUNCTION       "function"
#define cPROCTYPEQUERY			"query"
#;
#define pPROC(%schema,%proc)                                  ^oddPROC(%schema,%proc
#define PROC(%ref,%schema,%proc)                              %ref(%schema,%proc))
#define PROCxxx(%ref,%schema,%proc,%keyword)                  %ref(%schema,%proc),%keyword)
#define PROCclass(%ref,%schema,%proc)                         %ref(%schema,%proc),$$$cPROCclass)
#define PROCcolumn(%ref,%schema,%proc)                        %ref(%schema,%proc),$$$cPROCcolumn)
#define PROCcontextclass(%ref,%schema,%proc)				%ref(%schema,%proc),$$$cPROCcontextclass)
#define PROCdescription(%ref,%schema,%proc)                   %ref(%schema,%proc),$$$cPROCdescription)
#define PROCexecute(%ref,%schema,%proc)                       %ref(%schema,%proc),$$$cPROCexecute)
#define PROChidden(%ref,%schema,%proc)                        %ref(%schema,%proc),$$$cPROChidden)
#define PROCidcolumn(%ref,%schema,%proc)					%ref(%schema,%proc),$$$cPROCidcolumn)
#define PROCidextent(%ref,%schema,%proc)					%ref(%schema,%proc),$$$cPROCidextent)
 
#define PROCinputparms(%ref,%schema,%proc)                    %ref(%schema,%proc),$$$cPROCinputparms)
#define PROCinterface(%ref,%schema,%proc)                     %ref(%schema,%proc),$$$cPROCinterface)
#define PROCmethod(%ref,%schema,%proc)                        %ref(%schema,%proc),$$$cPROCmethod)
#define PROCname(%ref,%schema,%proc)                          %ref(%schema,%proc),$$$cPROCname)
#define PROCodbccatalog(%ref,%schema,%proc)                   %ref(%schema,%proc),$$$cPROCodbccatalog)
#define PROCodbcinfo(%ref,%schema,%proc)                      %ref(%schema,%proc),$$$cPROCodbcinfo)
#if 1	; DLP831+
#define PROCodbcinfoV(%ref,%schema,%proc,%version)            %ref(%schema,%proc),$$$cPROCodbcinfo,%version)
#endif	; DLP831-
#define PROCoutputparms(%ref,%schema,%proc)                   %ref(%schema,%proc),$$$cPROCoutputparms)
#define PROCparmsdirection(%ref,%schema,%proc)                %ref(%schema,%proc),$$$cPROCparmsdirection)
#define PROCparmsobjectcat(%ref,%schema,%proc)                %ref(%schema,%proc),$$$cPROCparmsobjectcat)
#define PROCprocedure(%ref,%schema,%proc)                     %ref(%schema,%proc),$$$cPROCprocedure)
#define PROCremarks(%ref,%schema,%proc)                       %ref(%schema,%proc),$$$cPROCremarks)
#define PROCresultsets(%ref,%schema,%proc)                    %ref(%schema,%proc),$$$cPROCresultsets)
#define PROCreturnval(%ref,%schema,%proc)                     %ref(%schema,%proc),$$$cPROCreturnval)
#define PROCschema(%ref,%schema,%proc)                        %ref(%schema,%proc),$$$cPROCschema)
#define PROCsignature(%ref,%schema,%proc)                     %ref(%schema,%proc),$$$cPROCsignature)
#define PROCstatementtype(%ref,%schema,%proc)                 %ref(%schema,%proc),$$$cPROCstatementtype)
#define PROCsubquery(%ref,%schema,%proc)                      %ref(%schema,%proc),$$$cPROCsubquery)
#define PROCtype(%ref,%schema,%proc)                          %ref(%schema,%proc),$$$cPROCtype)
 
#define PROCCOL(%ref,%schema,%proc,%column)						%ref(%schema,%proc),$$$cPROCcolumn,%column)
#define PROCCOLattribute(%ref,%schema,%proc,%column)			%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLattribute)
#define PROCCOLbitstring(%ref,%schema,%proc,%column)			%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLbitstring)
#define PROCCOLcaption(%ref,%schema,%proc,%column)				%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLcaption)
#define PROCCOLclass(%ref,%schema,%proc,%column)				%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLclass)
#define PROCCOLclientdatatypeenum(%ref,%schema,%proc,%column) %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLclientdatatypeenum)
#define PROCCOLcolinfo(%ref,%schema,%proc,%column)            %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLcolinfo)
#define PROCCOLdatatype(%ref,%schema,%proc,%column)           %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLdatatype)
#define PROCCOLlength(%ref,%schema,%proc,%column)             %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLlength)
#define PROCCOLname(%ref,%schema,%proc,%column)               %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLname)
#define PROCCOLnullable(%ref,%schema,%proc,%column)           %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLnullable)
#define PROCCOLodbctype(%ref,%schema,%proc,%column)           %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLodbctype)
#define PROCCOLodbctypename(%ref,%schema,%proc,%column)       %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLodbctypename)
#define PROCCOLprecision(%ref,%schema,%proc,%column)          %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLprecision)
#define PROCCOLprocinfo(%ref,%schema,%proc,%column)           %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLprocinfo)
#define PROCCOLradix(%ref,%schema,%proc,%column)              %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLradix)
#define PROCCOLremarks(%ref,%schema,%proc,%column)            %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLremarks)
#define PROCCOLscale(%ref,%schema,%proc,%column)              %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLscale)
#define PROCCOLschema(%ref,%schema,%proc,%column)				%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLschema)
#define PROCCOLsubquery(%ref,%schema,%proc,%column)				%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLsubquery)
#define PROCCOLtablename(%ref,%schema,%proc,%column)			%ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLtablename)
#define PROCCOLtype(%ref,%schema,%proc,%column)               %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLtype)
#define PROCCOLparm(%ref,%schema,%proc,%column)               %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLparm)
 
#define PROCCOLPARM(%ref,%schema,%proc,%column,%parm)         %ref(%schema,%proc),$$$cPROCcolumn,%column,$$$cPROCCOLparm,%parm)
 
#define PROCSUBQUERY(%ref,%schema,%proc,%subquery)				%ref(%schema,%proc),$$$cPROCsubquery,%subquery)
#define PROCSUBQUERYcardinality(%ref,%schema,%proc,%subquery)	%ref(%schema,%proc),$$$cPROCsubquery,%subquery,$$$cPROCSUBQUERYcardinality)
}

Storage oddproc
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="master">
<Data name="class">
<Node>1</Node>
</Data>
<Data name="description">
<Node>2</Node>
</Data>
<Data name="execute">
<Node>3</Node>
</Data>
<Data name="interface">
<Node>8</Node>
</Data>
<Data name="name">
<Node>10</Node>
</Data>
<Data name="procedure">
<Node>14</Node>
</Data>
<Data name="schema">
<Node>20</Node>
</Data>
<Global>^oddPROC</Global>
<Subscript name="1">
<Expression>{idSCHEMA}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{idPROC}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%TSQL.sys.procedureS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
