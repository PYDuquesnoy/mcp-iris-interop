/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occDS

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25SQL.Shell">Using the SQL Shell</a>.</p>
/// %SQL.Shell - Interactive SQL shell
///  
/// <p>The interactive SQL shell allows the user to execute SQL statements dynamically. There are two execution modes - immediate and
/// deferred. The execution mode can be set by executing a <var>set executemode</var> command with <var>immediate</var> or <var>deferred</var>
/// as the executemode value. If the execution mode is immediate, then SQL statements are prepared and executed immediately. If execute
/// mode is deferred, then a statement is only prepared and not executed until either a <var>#</var> or <var>go</var> command is entered.
/// The result of executing the statement is displayed on the current device after the statement is executed.</p>
/// <p>If <var>displaymode</var> is <var>currentdevice</var> and <var>messages</var> is <var>on</var> then the time taken to prepare the current
/// statement and the time taken to execute the current statement are displayed after the result is displayed. Execute time includes the time
/// to instantiate the result object and the time to display the statement.</p>
/// <p>SQL statements can span multiple lines. To enter a multiline statement, simply press the enter key to enter multiline mode. When
/// the statement is complete enter <var>go</var> to exit multiline mode. If execution mode is immediate the multiline statement will be
/// executed at that point, otherwise and additional <var>#</var> or <var>go</var> will cause the statement to execute.</p>
/// <p>The user is prompted to supply a value for each parameter defined in the statement each time the statement is executed. If the value entered begins
/// with a colon then the user is prompted to enter if the value is a literal or not. If the value is a literal the user must answer with <var>Y</var> or <var>y</var>.
/// The default is <var>N</var> and if that is the desired response simply press <var>Enter</var> and the value entered is assumed to be a ObjectScript expression or
/// host variable. Host variables are assumed to be public variables. Public variables can be set using the <var>! set var = value</var> command. Other
/// expressions can be entered, including function calls and class methods that return a value. The statement can be executed again by entering 'go'
/// resulting in prompts for new statement values. The expression used to execute the statement is
/// displayed just prior to executing the statement. If the statement does not contain any parameters then execution will proceed without any prompting.</p>
/// 
/// <p>The Shell supports statement recall. Any statement that is prepared may be recalled from the statement buffer by entering <b>#</b><var>nbr</nbr>
/// where <var>nbr</var> is the statement number in the buffer. Just entering <b>#</b> will list the statements currently in the buffer. Entering <b>#clear</b>
/// will clear the statement buffer on confirmation. Entering <b>#0</b> will recall the most recently prepared statement from the buffer. If <var>executemode</var>
/// is set to <var>immediate</var> then the recalled statement will also be executed.</p>
/// <p>Statements can also be saved in a statement pool. To save the current statement enter <b>save</b> <var>name</var>. That statement is saved in the pool
/// and can be later recalled by entering <b>open</b> <var>name</var>.<p>
/// <p>Statements can be deleted from the statement pool by entering <b>clear</b> <var>name</var>. If no <var>name</var> is specified then all statements are removed
/// from the pool on confirmation.</p>
/// <p>
/// Shell commands are entered in the first column and do not often conflict with executable statements. In some cases, such as <var>set</var>, a command and an SQL statement
/// can be ambiguous. This occurs most often in complex statements such as <var>CREATE PROCEDURE</var>. To eliminate confusion, the SQL Shell supports a command prefix
/// that can be set to any value. The command prefix allows the user to specify that all commands begin with a special character or character sequence. To set the command prefix
/// simply set <b>commandprefix</b> option using the <b>set</b> command:<br>
/// <pre>
/// 		USER>>set commandprefix = .
/// </pre>
/// <br>
/// Once the command prefix is set, all commands must be prefixed by the value of the commandprefix setting. There are three exceptions - <b>?</b>, <b>#</b> and <b>GO</b> do
/// not have to be prefixed.</p>
/// <p>
/// The <b>commandprefix</b> option is saved by the <b>set save</b> command and, if saved, will be restored automatically the next time the user starts the shell. By default there is no
/// <b>commandprefix</b>. To reset the command prefix back to the default once it has been set to something else, enter:<br>
/// <pre>
/// 		USER>>set commandprefix = ""
/// </pre>
/// </p>
/// <p>Shell context settings are set by the <b>set</b> command. Context settings can be retained and used by future instances of the shell by entering <b>set save</b> and
/// cleared by entering <b>set clear</b>. Entering <b>set</b> without any additional qualifiers will display the current shell context settings.</p>
/// 	<p>To execute an SQL statement, type it in and press ENTER.</p>
/// 	<p>To execute a multiline SQL statement, press ENTER to enter multiline mode, type in the statement, and enter <var>go</var>.</p>
/// 	<p>Available commands:</p>
/// <p><table cols=2 border=1>
/// 		<tr>
/// 				<td width="20%" valign="top">Press ENTER</td>
/// 				<td width="50%" valign="top">Enter multiline statement mode. While in multiline
/// 							statement mode, some basic commands are supported.
/// 							<p>
/// 								<table cols=2 border=1>
/// 									<tr><td width="20%" valign="top">c[lear]</td><td width="50%" valign="top">
/// 											Clear all statement lines entered.
/// 										</td>
/// 									</tr>
/// 									<tr><td width="20%" valign="top">c[lear] <var>line nbr</var></td><td width="50%" valign="top">
/// 											Clear line <var>line nbr</var>.
/// 										</td>
/// 									</tr>
/// 									<tr><td width="20%" valign="top">g[o]</td><td width="50%" valign="top">
/// 											Exit multiline statement mode. If <var>EXECUTEMODE</var>
/// 										is immediate then execute the statement. The result is displayed
/// 											after execution.
/// 										</td>
/// 									</tr>
/// 									<tr><td width="20%" valign="top">l[ist]</var></td><td width="50%" valign="top">
/// 											List the statement lines entered.
/// 										</td>
/// 									</tr>
/// 									<tr><td width="20%" valign="top">q[uit]</td><td width="50%" valign="top">
/// 											Exit multiline statement mode and discard any statement lines.
/// 										</td>
/// 									</tr>
/// 	 								<tr>
/// 	 									<td width="20%" valign="top">
/// 	 										<table cols=1 border=0>
/// 	 										<tr>
/// 	 											<td>?</td>
/// 	 											</tr>
/// 	 										<tr>
/// 	 											<td>help</td>
/// 	 											</tr>
/// 	 										</table>
/// 	 									</td>
/// 	 									<td width="50%" valign="top">
///  											Display statement mode help.
/// 							 			</td>
/// 									</tr>
/// 								</table>
/// 							</p>
/// 					</td>
/// 				</tr>
/// 	<tr><td width="20%" valign="top"><var>SQL Statement</var></td><td width="50%" valign="top">Prepare the statement. If <var>EXECUTEMODE</var>
/// is immediate then execute the statement. The result is displayed after execution.</td></tr>
/// 		<tr>
/// 			<td width="20%" valign="top">
/// 				<table cols=1 border=0>
/// 				<tr>
/// 					<td><b>?</b></td>
/// 					</tr>
/// 				<tr>
/// 					<td><b>help</b></td>
/// 					</tr>
/// 				</table>
/// 			</td>
/// 			<td width="50%" valign="top">
/// 				Display help.
/// 			</td>
/// 		</tr>
/// 	<tr><td width="20%" valign="top"><b>#</b></td><td width="50%" valign="top">List statements currently in the history buffer.</td></tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>#</b><var>nbr</var></td>
/// 			<td width="50%" valign="top">
/// 				Recall statement <var>nbr</var> from the statement history buffer. If <var>nbr</var> is zero then recall the most recent statement.
/// 				Recalled statements are executed if <var>EXECUTEMODE</var> is set to 'immediate'.
/// 				If <var>EXECUTEMODE</var> is set to 'deferred' then it is necessary to enter <var>GO</var> to execute the recalled statement.
/// 			</td>
/// 		</tr>
/// 	<tr><td width="20%" valign="top"><b>#?</b></td><td width="50%" valign="top">List statements currently in the history buffer.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>#clear</b></td><td width="50%" valign="top">Clear the statement history buffer.</td></tr>
/// 		<tr>
/// 			<td width="20%" valign="top">
/// 				<b>c[lear]</b> <var>name</var>
/// 			</td>
/// 			<td width="50%" valign="top">
/// 				Clear (delete) the statement identified by <var>name</var> from the statement pool.
/// 			</td>
/// 		</tr>
/// 	<tr><td width="20%" valign="top"><b>!</b> <var>objectscript_command</var></td><td width="50%" valign="top">Execute <var>objectscript_command</var>.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>g[o]</b></td><td width="50%" valign="top">Run the most recently executed or loaded statement.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>l[ist]</b></td><td width="50%" valign="top">List statements in the statement pool.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>load</b> <var>filename</var></td><td width="50%" valign="top">Load a statement from <var>filename</var>.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>m[etadata]</b></td><td width="50%" valign="top">Displays the metadata for the current statement.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>obj[ectscript]</b> <var>objectscript_command</var></td><td width="50%" valign="top">Execute <var>objectscript_command</var>.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>o[pen]</b> <var>name</var></td><td width="50%" valign="top">Open the statement name <var>name</var> from the statement pool. The retrieved statement
/// 		is prepared and executed (depending on the EXECUTEMODE setting).</td></tr>
/// 		<tr>
/// 			<td width="20%" valign="top">
/// 				<table cols=1 border=0>
/// 				<tr>
/// 					<td><b>q[uit]</b></td>
/// 					</tr>
/// 				<tr>
/// 					<td><b>e[xit]</b></td>
/// 					</tr>
/// 				</table>
/// 			</td>
/// 			<td width="50%" valign="top">
/// 				Exit the shell.
/// 			</td>
/// 		</tr>
/// 	<tr><td width="20%" valign="top"><b>run</b> [<var>filename</var>]</td><td width="50%" valign="top">Run an SQL script. If <filename> is not specified then the user will be prompted for the file name.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>saveglobal</b>|<b>sg</b> <var>name</var></td><td width="50%" valign="top">Save the currently prepared statement in the statement global using the given <var>name</var>.</td></tr>
/// 	<tr><td width="20%" valign="top"><b>s[ave]</b> <var>filename</var></td><td width="50%" valign="top">Save the currently prepared statement to <var>filename</var>.</td></tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set</b></td>
/// 				<td width="50%" valign="top">
/// 					Display the current context settings.</td>
/// 			</tr>
/// 		<tr>
/// 				<td width="20%" valign="top"><b>set clear</b></td>
/// 				<td width="50%" valign="top">
/// 					Clear the saved Shell settings for this user.
/// 				</td>
/// 			</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set colalign</b> [=] <var>delim[iter]</var> | <var>header</var> | <var>data</var></td>
/// 			<td width="50%" valign="top">
/// 				Set column alignment for the SQL Resultset. The context setting <var>colalign</var> can be set to one of the following values:
///                    <ul style="margin-top: 0px; margin-bottom: 0px">
///                       <li><var>delim[iter]</var> - The SQL Resultset header/data columns will be aligned based on the standard delimiter (tab).  [<b>Default</b>]</li>
///                       <li><var>header</var> - The SQL Resultset header/data columns will be aligned based on the length of the column header and the standard delimiter (tab).</li>
///                       <li><var>data</var> - The SQL Resultset header/data columns will be aligned based on the precision/length of the column data property and the standard delimiter (tab).</li>
///                    </ul>
/// 			</td>
/// 	</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set commandprefix</b> [=] <var>string value</var></td>
/// 				<td width="50%" valign="top">
/// 					Sets the command prefix to <var>string value</var>. To set the command prefix to nothing, enter <var>""</var> as the string value.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set dialect</b> [=] <var>sybase | mssql | IRIS</var></td>
/// 				<td width="50%" valign="top">
/// 					Sets the dialect to the desired SQL dialect. If <var>schemalist</var> is empty then IRIS SQL is assumed.
/// 					The dialect setting determines which dialect mode is used when preparing a statement.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set displayfile</b> [=] <var>file</var></td>
/// 			<td width="50%" valign="top">
/// 				Set the name of the file to be used for displaying the results of executing SQL statements. If no file name is specified
/// 					then a random file name will be generated for each statement execution. Additionally, a messages file may be produced. The
/// 					name of the file containing messages is either the <var>file</var> concatenated with "Messages" or it is a random file name
/// 					if <var>file</var> is set to nothing. To set the <var>file</var> setting to nothing after it was previously set, enter "".
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set displaymode</b> [=] <var>displaymode</var></td>
/// 			<td width="50%" valign="top">
/// 				Set the DISPLAYMODE. If <var>displaymode</var> is not specified, the current DISPLAYMODE setting is displayed on the current device.
/// 				<var>displaymode</var> values can be <b>cur[rentdevice]</b>,<b>xml</b>,<b>html</b>,<b>pdf</b>, or <b>txt</b>. When DISPLAYMODE is set to
/// 				CURRENTDEVICE, statement results are displayed on the current device. When XML, HTML, PDF or TXT are specified then statement results are written
/// 				to a temporary file using a ZEN Report that is generated from the statement metadata.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set displaypath</b> [=] <var>path</var></td>
/// 			<td width="50%" valign="top">
/// 				Set the path where files used to save statement results will be placed.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set displaytranslate[table]</b> [=] <var>translatetable</var></td>
/// 			<td width="50%" valign="top">
/// 				Set the translate table used for <var>displayfile</var> when writing output in 'csv' and 'txt' formats. 
/// 				For example, "UTF8". Values are case sensitive. 
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set executemode</b> [=] <var>executemode</var></td>
/// 			<td width="50%" valign="top">
/// 			Set EXECUTEMODE to <var>executemode</var>. Valid values are <b>immediate</b> and <b>deferred</b>.
/// 				If <var>immediate</var> then SQL statements are executed immediately. If <var>deferred</var> then the current statement
/// 				is executed by entering a 'go' command. If <var>executemode</var> is not specified then the current EXECUTEMODE
/// 				setting is displayed.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set log</b> [=] on | off | <var>file</var></td>
/// 			<td width="50%" valign="top">
/// 				Turn logging on or off. If a <var>file</var> is specified, logging is turned on and the log is written to the file specified.
/// 				The default file for logging is used if logging is simply turned 'on'.
/// 			</td>
/// 		</tr>
/// 	<tr>
/// 			<td width="20%" valign="top"><b>set messages</b> [=] on | off</td>
/// 			<td width="50%" valign="top">
/// 				Turn messages on or off. If <var>messages</var> is off then results are displayed without any additional information. Times are
/// 					not displayed.
/// 			</td>
/// 		</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set path</b> [=] <var>schemalist</var></td>
/// 				<td width="50%" valign="top">
/// 					Sets the current schema search path. If <var>schemalist</var> is empty then the current path is displayed.
/// 					To set PATH to the default schema then specify <var>schemalist</var> as """".
/// 					</td>
/// 		</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set save</b></td>
/// 				<td width="50%" valign="top">
/// 					Save the current Shell settings for this user. The settings are restored when the current user
/// 					starts another Shell session.
/// 				</td>
/// 		</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>set selectmode</b> [=] <var>selectmode</var></td>
/// 				<td width="50%" valign="top">
/// 					Sets the current SELECTMODE to <b>odbc</b>, <b>logical</b>, or <b>display</b>.
/// 					If <var>selectmode</var> is NULL the current setting is displayed.</td>
/// 			</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>show [pl[an]] [v[erbose]]</b></td><td width="50%" valign="top">
/// 					Show the execution plan for the current statement.
/// 					<br/>If the <b>verbose</b> qualifier is used, show all the module details for the current statement's execution plan; Otherwise, display only the top-level module details by default.</td>
/// 			</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>show planalt [v[erbose]]</b></td><td width="50%" valign="top">
/// 					Run the ShowPlanAlt() method on the the current statement which allows user to browse alternate execution plans.
/// 					<br/>If the <b>verbose</b> qualifier is used, show all the module details for the current statement's execution plan and all alternate plans; Otherwise, display only the top-level module details by default.</td>
/// 			</tr>
/// 	<tr>
/// 				<td width="20%" valign="top"><b>show st[atement]</b></td><td width="50%" valign="top">
/// 					Show the current statement text and other details such as the implementation class.</td>
/// 			</tr>
/// </table></p>
Class %SQL.Shell Extends %Library.RegisteredObject [ System = 4 ]
{

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(initvalue As %RawString) As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set ..Statement = ..StatementNewObject()
	if $Data(^IRIS.SQL.Shell($Username,0))#10 {
		set ..ExecuteMode = $Listget(^IRIS.SQL.Shell($Username,0),1)
		set ..SelectMode = $Listget(^IRIS.SQL.Shell($Username,0),2)
		set ..Path = $Listget(^IRIS.SQL.Shell($Username,0),3)
		set ..DisplayMode = $Listget(^IRIS.SQL.Shell($Username,0),4)
		set ..Dialect = $Listget(^IRIS.SQL.Shell($Username,0),5)
		set ..EchoMode = $Listget(^IRIS.SQL.Shell($Username,0),6,1)
		set ..MessageMode = $Listget(^IRIS.SQL.Shell($Username,0),7,1)
		set ..CommandPrefix = $Listget(^IRIS.SQL.Shell($Username,0),8,"")
		set ..DisplayFile = $Listget(^IRIS.SQL.Shell($Username,0),9,"")
		set ..DisplayPath = $Listget(^IRIS.SQL.Shell($Username,0),10,"")
		set ..ColAlign = $Listget(^IRIS.SQL.Shell($Username,0),11,"")
		set ..DisplayDelimiter=$Listget(^IRIS.SQL.Shell($Username,0),12,"")
	} else {	// If no user saved settings for this namespace, load the system default settings
		set ..ColAlign=$g(^%SYS("sql","shell","ColAlign"),0)
		set ..CommandPrefix=$g(^%SYS("sql","shell","CommandPrefix"))
		set ..Dialect=$g(^%SYS("sql","shell","Dialect"),"IRIS")
		set ..DisplayFile=$g(^%SYS("sql","shell","DisplayFile"))
		set ..DisplayMode=$g(^%SYS("sql","shell","DisplayMode"),-1)
		set ..DisplayPath=$g(^%SYS("sql","shell","DisplayPath"))
		set ..DisplayTranslateTable=$g(^%SYS("sql","shell","DisplayTranslateTable"),"UTF8")
		set ..DisplayDelimiter=$g(^%SYS("sql","shell","DisplayDelimiter"),",")
		set ..EchoMode=$g(^%SYS("sql","shell","EchoMode"),1)
		set ..ExecuteMode=$g(^%SYS("sql","shell","ExecuteMode"),1)
		set ..MessageMode=$g(^%SYS("sql","shell","MessageMode"),1)
		set ..Path=$g(^%SYS("sql","shell","Path"),"SQLUser")
		set ..SelectMode=$g(^%SYS("sql","shell","SelectMode"),0)
	}
	set ..EscapeCondition=$g(^%SYS("sql","shell","EscapeCondition"),1)
	set:..EscapeCondition="" ..EscapeCondition=1
	new %EscapeAllowed
	set %EscapeAllowed=0
	try { xecute "if "_..EscapeCondition_" { set %EscapeAllowed = 1 }"
	} catch { }
	set ..EscapeAllowed=%EscapeAllowed
	if ..Path = "" { set ..Path = $$$DefaultSchema }
	Quit $$$OK
}

Property Statement As %SQL.Statement;

Property StatementNbr As %Integer;

/// <p>
/// <property>ColAlign</property> represents the column alignment for the SQL Resultset, and can be set to one of the following values:
///    <ul style="margin-top: 0px; margin-bottom: 0px">
///       <li><var>delim[iter]</var> - The SQL Resultset header/data columns will be aligned based on the standard delimiter (tab).  [<b>Default</b>]</li>
///       <li><var>header</var> - The SQL Resultset header/data columns will be aligned based on the length of the column header and the standard delimiter (tab).</li>
///       <li><var>data</var> - The SQL Resultset header/data columns will be aligned based on the precision/length of the column data property and the standard delimiter (tab).</li>
///    </ul>
/// <pre>
/// USER>>set colalign [=] delim[iter]
/// USER>>set colalign [=] header
/// USER>>set colalign [=] data
/// </pre>
Property ColAlign As %Integer(DISPLAYLIST = ",delimiter,header,data", VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

Property StatementText As %Library.String(MAXLEN = "") [ MultiDimensional ];

/// <p>CommandPrefix is the string value used to indicate that a command is being entered. The default value is null, meaning
/// that no command prefix is in use. If CommandPrefix is set to a non-empty value then that prefix must be entered as a prefix
/// to most commands.  There are three commands that do not require a prefix: <var>?</var>, <var>#</var> and <var>GO</var>.</p>
/// <pre>
/// USER>>set commandprefix = /
/// USER>>/set save
/// USER>>/quit
/// </pre>
Property CommandPrefix As %String(MAXLEN = 10);

/// Dialect is the dialect of SQL to be used when preparing a statement. Supported dialects are IRIS (default), Sybase and MS SQL Server.
Property Dialect As %Library.String;

Method DialectSet(pValue As %String = "") As %Status
{
	if pValue = i%Dialect quit $$$OK
	set tDialect = $ListFind($$$SQLDIALECTALLUPPER,$zconvert(pValue,"U"))
	if tDialect { set i%Dialect = $ListGet($$$SQLDIALECTALL,tDialect) quit $$$OK } else { quit $$$ERROR($$$GeneralError,"Invalid dynamic statement dialect mode: '"_pValue_"'") }
}

/// DisplayMode is the format in which results are displayed.
Property DisplayMode As %Integer(DISPLAYLIST = ",currentdevice,xml,html,pdf,txt,csv", VALUELIST = ",-1,0,1,2,99,100") [ InitialExpression = -1 ];

Property DisplayDelimiter As %String;

Property DisplayPath As %Library.String(MAXLEN = "");

Property DisplayFile As %Library.String(MAXLEN = "");

Property DisplayTranslateTable As %Library.String(MAXLEN = "");

/// EchoMode is either on (not zero) or off (zero). If on, statements and results are echoed to the current device.
/// This setting does not impact logging.
Property EchoMode As %Integer(DISPLAYLIST = ",off,on", VALUELIST = ",0,1") [ InitialExpression = 1 ];

/// EscapeCondition is the argument to an ObjectScript IF condition which must evaluate to TRUE in order to execute ObjectScript commands from the shell
/// The process running the SQL Shell must also be in programmer mode, not application mode.
/// When IF <EscapeCondition> evaluation results in an error, executing ObjectScript commands will not be allowed.
Property EscapeCondition As %String(MAXLEN = "");

Property EscapeAllowed As %Boolean [ Internal, Private ];

/// ExecuteMode defines when the current statement will be executed. If ExecuteMode is 'immediate' then each statement is executed as
/// so as it is prepared. If ExecuteMode is 'deferred' then the statement is prepared but not executed until a 'GO' command is entered.
Property ExecuteMode As %Integer(DISPLAYLIST = ",deferred,immediate", VALUELIST = ",0,1") [ InitialExpression = 1 ];

/// executeStartTime is the time the statement execute started. This is reset during execute() after parameter values are entered.
/// The execute time is computed after %Display() is complete and displayed after the rowcount and SQLCODE.
Property executeStartTime As %Time;

/// Used to compute how many lines this query executes, global reads and disk latency
Property executeStats As %List;

/// Log instance. This is an oref that references a log object to be used when logging statements, messages, and results.
Property Log As %XSQL.Log;

/// Either on or off. If on then statements, messages and results will be logged using the current Log value.
Property LogMode As %Integer(DISPLAYLIST = ",off,on", VALUELIST = ",0,1") [ InitialExpression = 0 ];

/// MessageMode is either on (not zero) or off (zero). If on, messages will be displayed on the current device.
/// This does not impact the LogMode setting.
Property MessageMode As %Integer(DISPLAYLIST = ",off,on", VALUELIST = ",0,1") [ InitialExpression = 1 ];

/// Path is the schema search path used when resolving unqualified names.
Property Path As %String(MAXLEN = "");

/// prepareTime is the time is took to prepare the most recent statement.
Property prepareTime As %Time;

/// Used to compute how many lines this query executes, global reads and disk latency
Property prepareStats As %List;

/// SelectMode defines the format of literals and column values when executing an SQL statement.
Property SelectMode As %Integer(DISPLAYLIST = ",logical,odbc,display", VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

/// %Go() - instantiate the shell and prompt for commands.
ClassMethod %Go(pDialect As %String) [ PublicList = SQLCODE ]
{
	new SQLCODE, %ROWID, %ROWCOUNT, %objqacn, %protocol, %classname
	$$$StackObjectState($system.Context.SQL())
	set tShell = ..%New()
	set tSC = $$$OK
	set tTrace = 0

	write $$$Text("SQL Command Line Shell","%SQL.Shell"),!
	write "----------------------------------------------------",!
	write !,$$$Text("The command prefix is currently set to: ","%SQL.Shell"),$Select(tShell.CommandPrefix="":"<<nothing>>.",1:tShell.CommandPrefix),!
	write $$$FormatText($$$Text("Enter %1<command>, 'q' to quit, '?' for help.","%SQL.Shell"),tShell.CommandPrefix),!
	if ($Data(pDialect)) {
		set tSC = tShell.DialectSet(pDialect)
		if $$$ISERR(tSC) { write !,$$$FormatText($$$Text("Dialect override failed, requested '%1'.","%SQL.Shell"),pDialect) }
		else { write !,"dialect = ",tShell.DialectLogicalToDisplay(tShell.Dialect),! }
	}
	set tTime=0
	do {
		set tRS = ""
		write ..getPrompt(tTime)
		for {
			try { read tInput } catch { if $ze["<INTERRUPT>" { continue } throw }
			quit
		}
		if tInput = "" {
			set tContinue = 1
			write $$$Text("  << entering multiline statement mode, 'GO' to execute >>","%SQL.Shell")
			do tShell.EnterStatement(.tInput)
			if tInput { set tTime=$zh do tShell.cmdProcessStatement(.tInput) set tTime=$zh-tTime }
		}
		else {
			write !
			set tShell.StatementNbr = 0
			set tTime=$zh
			set tContinue = tShell.dispatcher(.tInput)
			set tTime=$zh-tTime 
		}
		kill tInput
	} while tContinue
	quit
}

Method dispatcher(ByRef pInput As %Library.String = "") [ PublicList = SQLCODE ]
{
	try {
		set tContinue = 1
Dispatch	
		set tInputLC = $tr($zconvert(pInput,"l"),$c(9)," ")
		while tInputLC["  " { set tInputLC=$replace(tInputLC,"  "," ") }
		if (((..CommandPrefix '= "") && ($Extract(tInputLC,1,$Length(..CommandPrefix)) = ..CommandPrefix)) || ($Extract(tInputLC,1) = "?") || ($Extract(tInputLC,1) = "#") || ($Extract(tInputLC,1,2) = "go"))
		   || ((..CommandPrefix = "") && (($Find(",?,#,set,show,trace,e,exit,g,go,m,metadata,l,load,run,s,save,sg,saveglobal,o,open,l,list,c,clear,!,cos,obj,objectscript,q,quit,p,purge,browse,zp,",","_$Piece(tInputLC," ",1)_",")) || ($e(tInputLC,1) = "!"))) {
				// Strip the command prefix if present
			if (..CommandPrefix '= "") && ($Extract(tInputLC,1,$Length(..CommandPrefix)) = ..CommandPrefix) { set tInputLC = $Extract(tInputLC,$Length(..CommandPrefix)+1,*),pInput = $Extract(pInput,$Length(..CommandPrefix)+1,*) }
			if $e(tInputLC,1)="!" { set tCommand = "!",tInputLC=$e(tInputLC,2,*),pInput=$e(pInput,2,*) } else { set tCommand = $Piece(tInputLC," ",1) }
			// test for commands
			if ((tCommand="?") && ($Extract($ZStrip($Extract(tInputLC,2,*),"<W")) '= "="))||(tCommand="help") {
				do ..Help()
				write !,$$$FormatText($$$Text("The command prefix is currently set to: %1.","%SQL.Shell"),$Select(..CommandPrefix="":"<<nothing>>.",1:..CommandPrefix)),!
			}
			elseif (tCommand="") { quit }
			elseif (tCommand = "cos") || (tCommand = "!") || (tCommand="objectscript") || (tCommand="obj") {
				if $zb($ZJOB,1,1) {
					if ..EscapeCondition {
						if tCommand="cos" { set pInput=$e(pInput,4,*) }
						elseif tCommand="obj" { set pInput=$e(pInput,4,*) }
						elseif tCommand="objectscript" { set pInput=$e(pInput,13,*) }
						do ..cmdObjectScript(.pInput)
						write !
					} else {
						write !,$$$Text("Execution of ObjectScript commands not allowed for this configuration.","%SQL.Shell"),!
					}
				} else {
					write !,$$$Text("Execution of ObjectScript commands not supported when the current process is not in programmer mode.","%SQL.Shell"),!
				}
			}
			elseif (tCommand = "browse") {
				do Browse^%qTable(1)
				write !!
			}
				#; QUIT the shell - QUIT, Q, EXIT or E.
			elseif ((tCommand="q")||(tCommand="quit"))||(tCommand="exit")||(tCommand="e") {
				set tContinue = 0
			}
			elseif tCommand="set",$case($p(tInputLC," ",2),"ml":0,"option":0,"transaction":0,"ansi_nulls":0,"datefirst":0,"identity_insert":0,"nocount":0,"quoted_identifier":0,"rowcount":0,:1) {
				do ..cmdSet(.tInputLC,.pInput)
			}
			elseif tCommand = "show" {
				do ..cmdShow(.tInputLC)
			}
			elseif (tCommand="trace on") {
				set tTrace = 1
				quit
			}
			elseif (tCommand="trace off") {
				set tTrace = 0
				quit
			}
			elseif (tCommand="zp") {
				if $zb($ZJOB,1,1),..EscapeCondition {
					set rtn=$p($zstrip($e(pInput,3,*),"<W")," ")
					if rtn="",$get(%classname)'="" set rtn=$p(%classname," ")_".1"
					if rtn'="" xecute "zl "_rtn_" zp"
				} else {
					write !,$$$Text("Execution of ObjectScript commands not supported.","%SQL.Shell"),!
				}
				quit
			}
			elseif ($extract(tCommand)="#") {
				do ..processCache(.pInput,.tCommand)
				if ($Extract(pInput) '= "#") && ($Extract(pInput,$Length(..CommandPrefix)+1) '= "#") { goto Dispatch }
				quit
			}
			elseif ((tCommand="g")||(tCommand="go")) {
				do ..cmdGo()
				quit
			}
			elseif (tCommand = "m") || (tCommand = "metadata") {
				do ..cmdMetadata(.tInputLC)
				quit
			}
				#; Load a statement from a file
			elseif (tCommand = "load"), $piece(pInput," ",3) = "" {
				kill tStatement
				do ..cmdLoad(.pInput,.tStatement)
				if $Data(tStatement) {
					kill pInput
					merge pInput = tStatement
					goto Dispatch
				}
				else {
					write !,$$$Text("Statement file invalid or empty.","%SQL.Shell"),!
					quit
				}
			}
			elseif (tCommand = "run") {
				do ..cmdRun(.pInput)
				quit
			}
				#; Save the current statement to the statement global
			elseif (tCommand="s")||(tCommand="save") {
				// save current statement
				if '$Data(..StatementText) {
					write $$$Text("There is no statement to save.","%SQL.Shell"),!
					quit
				}
				else { set tStatus = ..cmdSave(.pInput) }
				quit
			}
				#; Save the current statement to the statement global
			elseif (tCommand="sg")||(tCommand="saveglobal") {
				do ..cmdSaveGlobal(.pInput)
				quit
			}
			elseif (tCommand = "c") || (tCommand = "clear") {
				set tName = $Piece(tInputLC," ",2)
				if tName '= "" {
					if '$Data(^IRIS.SQL.Shell($username,1,tName)) { write $$$FormatText($$$Text("Saved statement not found: %1","%SQL.Shell"),tName),! }
					else {
						kill ^IRIS.SQL.Shell($username,1,tName)
						write !,$$$FormatText($$$Text("'%1' deleted.","%SQL.Shell"),tName),!
					}
				}
				else {
					write !,$$$FormatText($$$Text("Clearing the statement pool for user '%1'. Are you sure? [y|n]:","%SQL.Shell"),$Username)
					read tYN
					if $zconvert($Extract(tYN),"l") = "y" {
						kill ^IRIS.SQL.Shell($Username,1)
						write $$$Text("...cleared","%SQL.Shell"),!
					}
					else { write $$$Text("...not cleared","%SQL.Shell"),! }
				}
				quit
			}
			elseif (tCommand = "o")||(tCommand = "open") {
				do ..cmdOpen(.pInput)
				quit
			}
			elseif (tCommand="l")||(tCommand="list") {
					#; list queries
				set tFound = 0
				write !,$$$Text("Saved statements: ","%SQL.Shell")
				set tName = $order(^IRIS.SQL.Shell($username,1,""))
				while (tName '= "") {
					set tFound = 1
					write "---------------------------------",!
					write tName,":",!
					write $get(^IRIS.SQL.Shell($username,1,tName)),!
					set tName = $order(^IRIS.SQL.Shell($username,1,tName))
				}
				if 'tFound { write $$$Text("No statements saved in ^IRIS.SQL.Shell($username)","%SQL.Shell"),! }
				quit
			}
			elseif pInput="purge"||(pInput="p") {
				write !,$$$Text("Purging cached queries","%SQL.Shell"),!
				Do Purge^%apiSQL()
			}
			else {
				do ..cmdProcessStatement(.pInput)
			}
		}
		else {
			do ..cmdProcessStatement(.pInput)
		}
	}
	catch tException {	
		write !,$$$Text("Exception caught: ","%SQL.Shell"),tException.DisplayString(),!!
	}
	quit tContinue
}

Method processCache(ByRef pInput As %Library.String = "", pCommand As %Library.String(MAXLEN="") = "")
{
		// run historic query
	set tValue = $extract(pCommand,2,*)
	if $zconvert(tValue,"l") = "clear" {
		write !,$$$Text("Clearing the statement history. Are you sure? [y|n]:","%SQL.Shell")
		read tYN
		if $zconvert($Extract(tYN),"l") = "y" {
			kill ^||isc.sqlshell
			write $$$Text("...cleared","%SQL.Shell"),!
		}
		else { write $$$Text("...not cleared","%SQL.Shell"),! }
		quit
	}
	elseif (tValue = "?") || (tValue = "") {
		set n = $order(^||isc.sqlshell(0))
		if 'n { write !,$$$Text("No statements logged.","%SQL.Shell"),! }
		else {
			while n {
				set tIndentFirst = $justify(n,6,0)_". "
				merge tCachedStatement = ^||isc.sqlshell(n)
					// The user entered a command to display these statements. Do it and ignore MessageMode.
				do ..displayStatement(.tCachedStatement,tIndentFirst,"        ")
				set n = $order(^||isc.sqlshell(n))
			}
			write !
		}
		quit
	}
	elseif (tValue = +tValue) {
		set ..StatementNbr = +tValue
		if (..StatementNbr = 0) { set ..StatementNbr = $get(^||isc.sqlshell,0) }
		if '$data(^||isc.sqlshell(..StatementNbr)) {
			write $$$Text("No statement found: ","%SQL.Shell"),..StatementNbr,!
			quit
		}
		merge pInput = ^||isc.sqlshell(..StatementNbr)
		do ..displayStatement(.pInput)
		if ($Extract(pInput) = "#") || ($Extract(pInput,$Length(..CommandPrefix)+1) = "#") { write !,$$$Text("Recalled command is command recall - invalid.","%SQL.Shell"),! }
	}
	else { write !,$$$FormatText($$$Text("Invalid cached statement option: '%1'","%SQL.Shell"),tValue),! }
}

/// cmdObjectScript will execute a object script command
Method cmdObjectScript(ByRef pInput As %Library.String(MAXLEN="") = "")
{
	set tObjectScript = $zstrip(pInput,"<=W")
	if tObjectScript '= "" { xecute tObjectScript }
}

Method cmdGo()
{
		// run current statement
	set tPriorMode = $Zutil(115,5,..SelectMode)
	new %SNGetQueryStats
	s %SNGetQueryStats=1
	set tResult = ..execute(..Statement)
	if ..MessageMode { write ! }
	do ..displayResult(tResult)
	set tExecuteTime = $zh - ..executeStartTime
	if ..MessageMode {
		set $listbuild(tGlobals,tCommands,tDiskRead)=..executeStats
		set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences-tGlobals,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted-tCommands,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds-tDiskRead
		write !,$$$Text("statement prepare time(s)/globals/cmds/disk: ","%SQL.Shell"),$Justify(..prepareTime,0,4),"s/",$fnumber($list(..prepareStats,1),","),"/",$fnumber($list(..prepareStats,2),","),"/",$fnumber($list(..prepareStats,3),","),"ms"
		write !,$$$Text("          execute time(s)/globals/cmds/disk: ","%SQL.Shell"),$Justify(tExecuteTime,0,4),"s/",$fnumber(tGlobals,","),"/",$fnumber(tCommands,","),"/",$fnumber(tDiskRead,","),"ms"
		do ..Statement.%GetImplementationDetails(.classname,,,,.pRuntimeClassName)
		if $g(%classname)'="" { 
			write !,$$$Text("                                query class: ","%SQL.Shell"),%classname 
			write:$g(pRuntimeClassName)'="" ", ",pRuntimeClassName 
		}
		write !,$translate($justify("-",75)," ","-"),!
	}
	elseif ..DisplayMode = -1 { write ! }
	set ..prepareTime = 0
	quit
}

/// Display the current statement's metadata.
Method cmdMetadata(ByRef pInputLC As %Library.String(MAXLEN="") = "")
{
	set tMetadata = ..Statement.%Metadata
	if $Isobject(tMetadata) { do tMetadata.%Display() }
	else { write !,$$$Text("No prepared statement.","%SQL.Shell"),! }
}

/// Open (retrieve) a statement from the SQL statement pool.
Method cmdOpen(ByRef pInput As %Library.String(MAXLEN="") = "")
{
		// open statement
	set tName = $piece(pInput," ",2)
	if (tName = "") {
		write $$$Text("Please provide the name of the statement to load.","%SQL.Shell"),!
		quit
	}
	merge pInput = ^IRIS.SQL.Shell($username,1,tName)
	if ($Get(pInput) = "") {
		write $$$Text("Saved statement not found: ","%SQL.Shell"),tName,!
		quit
	}
	do ..cmdProcessStatement(.pInput)
}

Method cmdProcessStatement(ByRef pInput As %Library.String(MAXLEN="") = "")
{
		// Prepare a new statement. Only replace the shell Statement property if
		// prepare is successful.
	try {
		set tStatement = ##class(%SQL.Statement).%New(..SelectMode,..Path)
		set tStatement.%Dialect = ..Dialect
		do ##class(%SYSTEM.Process).EnableDiskReadTiming()
		set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds
		set tTime = $zh
		do tStatement.prepare(.pInput)
		set ..prepareTime = $zh - tTime
		set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences-tGlobals,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted-tCommands,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds-tDiskRead
		set ..prepareStats=$lb(tGlobals,tCommands,tDiskRead)
		set ..Statement = tStatement, tStatement = ""
			// remember statement
		kill ..StatementText
		merge ..StatementText = pInput
		if '..StatementNbr {
			set ..StatementNbr = $increment(^||isc.sqlshell)
			merge ^||isc.sqlshell(..StatementNbr) = pInput
		}
		if ..MessageMode {
			write ..StatementNbr,"."
			do ..displayStatement(.pInput)
		}
		if $Isobject(..Log) { do ..Log.logStatementSource(.pInput,0,2) }
		if ..ExecuteMode {
			if ..MessageMode { write ! }
			new %SNGetQueryStats
			s %SNGetQueryStats=1
			set tResult = ..execute(..Statement)
			do ..displayResult(tResult)
			set tExecuteTime = $zh - ..executeStartTime
			if ..MessageMode {
				set $listbuild(tGlobals,tCommands,tDiskRead)=..executeStats
				set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences-tGlobals,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted-tCommands,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds-tDiskRead
				write !,$$$Text("statement prepare time(s)/globals/cmds/disk: ","%SQL.Shell"),$Justify(..prepareTime,0,4),"s/",$fnumber($list(..prepareStats,1),","),"/",$fnumber($list(..prepareStats,2),","),"/",$fnumber($list(..prepareStats,3),","),"ms"
				write !,$$$Text("          execute time(s)/globals/cmds/disk: ","%SQL.Shell"),$Justify(tExecuteTime,0,4),"s/",$fnumber(tGlobals,","),"/",$fnumber(tCommands,","),"/",$fnumber(tDiskRead,","),"ms"
				do ..Statement.%GetImplementationDetails(.%classname,,,,.pRuntimeClassName)
				if $g(%classname)'="" { 
					write !,$$$Text("                                query class: ","%SQL.Shell"),%classname 
					write:$g(pRuntimeClassName)'="" ", ",pRuntimeClassName 
				}
			}
			set ..prepareTime = 0
		}
		if ..MessageMode { write !,$translate($justify("-",75)," ","-"),! }
		elseif ..DisplayMode = -1 { write ! }
	}
	catch tException {
		if ..MessageMode {
			do $system.Status.DisplayError(tException.AsStatus())
			write !
		}
		if $Isobject(..Log) { do ..Log.logException(tException) }
	}
	quit
}

Method cmdSaveGlobal(ByRef pInput As %Library.String(MAXLEN="") = "")
{
	// save current statement
	if '$Data(..StatementText) {
		write $$$Text("There is no statement to save.","%SQL.Shell"),!
		quit
	}
	set tName = $piece(pInput," ",2)
	if (tName = "") {
		write $$$Text("Please provide a name of the statement to save.","%SQL.Shell"),!
		quit
	}
	if $Data(^IRIS.SQL.Shell($username,1,tName)) {
		write !,$$$FormatText($$$Text("A statement named '%1' already exists. Do you want to overwrite it? [y|n]:","%SQL.Shell"),tName)
		read tYN
		if $zconvert($Extract(tYN),"l") = "y" {
			kill ^IRIS.SQL.Shell($username,1,tName)
			merge ^IRIS.SQL.Shell($username,1,tName) = ..StatementText
			write !,$$$Text("...statement saved as: ","%SQL.Shell"),tName,!
		}
		else { write !,$$$Text("...statement was not saved.","%SQL.Shell"),! }
	}
	else {
		kill ^IRIS.SQL.Shell($username,1,tName)
		merge ^IRIS.SQL.Shell($username,1,tName) = ..StatementText
		write !,$$$Text("...statement saved as: ","%SQL.Shell"),tName,!
	}
	quit
}

Method cmdSet(ByRef pInputLC As %Library.String(MAXLEN="") = "", pInput As %Library.String(MAXLEN=""))
{
		// Various set options
		// set <option> [=] <value>
		// invoke a tokenizer to return tOption and tValue
	do ..parseSet(pInputLC,.tOption,.tValue)
	if tOption = "clear" {
		kill ^IRIS.SQL.Shell($Username,0)
		write !,$$$Text("...settings cleared.","SQL.Shell"),!
	}
	elseif tOption = "colalign" {
			// Set the ColAlign context variable...
		if tValue = "" { write !,"colalign = ",..ColAlignLogicalToDisplay(..ColAlign),! quit }
		set tColAlign = $case(tValue,"data":2,"header":1,"delim":0,"delimiter":0,:"")
		if tColAlign = "" { write !,$$$FormatText($$$Text("Invalid 'colalign' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..ColAlign = tColAlign
		write !,"colalign = ",..ColAlignLogicalToDisplay(..ColAlign),!
	}
	elseif tOption = "commandprefix" {
			#; Set the CommandPrefix...
		if tValue = "" { write !,"commandprefix = ",..CommandPrefixLogicalToDisplay(..CommandPrefix),! quit }
		set ..CommandPrefix = $Select(tValue'="""""":tValue,1:"")
		write !,"commandprefix = ",$Select(..CommandPrefix'="":..CommandPrefix,1:""""""),!
	}
	elseif tOption = "dialect" {
			#; Set the Dialect context variable...
		if tValue = "" { write !,"dialect = ",..DialectLogicalToDisplay(..Dialect),! quit }
		if '$Case(tValue,"":1,"iris":1,"sybase":1,"mssql":1,:0) { write !,$$$FormatText($$$Text("Dialect '%1' is not supported.","SQL.Shell"),tValue),! quit }
		set ..Dialect = tValue
		write !,"dialect = ",..DialectLogicalToDisplay($Select(..Dialect="":$$$SQLDIALECTIRIS,1:..Dialect)),!
	}
	elseif tOption = "displayfile" {
			#; Set the DISPLAYFILE context variable...
			#; support "cur" as an abbreviation for "currentdevice"
		if tValue '= "" {
			if tValue '= """""" { do ..parseSet(pInput,.tOption,.tValueAE) } else { set tValueAE = "" }
			if tValueAE '= "" {
				set tValueAEV = ##class(%Library.File).NormalizeFilename(tValueAE,"")
				if tValueAEV = "" {
					write !,$$$FormatText($$$Text("'%1' is not a valid file name.","%SQL.Shell"),tValueAE),!
					quit
				}
			}
			set ..DisplayFile = $Case($Extract(tValueAE),"/":$Extract(tValueAE,2,*),"\":$Extract(tValueAE,2,*),:tValueAE)
		}
		write !,"displayfile = ",..DisplayFileLogicalToDisplay(..DisplayFile),!
	}
	elseif tOption = "displaymode" {
			#; Set the DISPLAYMODE context variable...
			#; support "cur" as an abbreviation for "currentdevice"
	    if $Extract(tValue,1,3) = "cur" { set tValue = "currentdevice" }
		if tValue = "" { write !,"displaymode = ",..DisplayModeLogicalToDisplay(..DisplayMode),! quit }
		set tDisplayMode = ..DisplayModeDisplayToLogical(tValue) // $case(tValue,"xml":0,"html":1,"pdf":2,"txt":99,"currentdevice":-1,:"")
		if tDisplayMode = "" { write !,$$$FormatText($$$Text("Invalid 'displaymode' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..DisplayMode = tDisplayMode
		write !,"displaymode = ",..DisplayModeLogicalToDisplay(..DisplayMode),!
	}
	elseif tOption = "displaypath" {
			#; Set the DISPLAYPATH context variable...
			#; support "cur" as an abbreviation for "currentdevice"
		if tValue = "" { write !,"displaypath = ",..DisplayPathLogicalToDisplay(..DisplayPath),! quit }
		do ..parseSet(pInput,.tOption,.tValueAE)
		if tValueAE '= "" {
			set tValueAEV = ##class(%Library.File).NormalizeDirectory(tValueAE)
			if tValueAEV = "" {
				write !,$$$FormatText($$$Text("'%1' is not a valid display path.","%SQL.Shell"),tValueAEV)
			}
			else {
				set ..DisplayPath = tValueAEV
			}
		}
		else { set ..DisplayPath = "" }
		write !,"displaypath = ",..DisplayPathLogicalToDisplay(..DisplayPath),!
	}
	elseif $Extract(tOption,1,16) = "displaytranslate" {
			#; Set the DISPLAYTRANSLATE context variable...
		if tValue = "" { write !,"displaytranslatetable = ",..DisplayTranslateTableLogicalToDisplay(..DisplayTranslateTable),! quit }
		do ..parseSet(pInput,.tOption,.tValueAE)
			// tValueAE = value as entered, preserves original casing.
		set ..DisplayTranslateTable = tValueAE
		write !,"displaytranslatetable = ",..DisplayTranslateTableLogicalToDisplay(..DisplayTranslateTable),!
	}
	elseif $extract(tOption,1,16)="displaydelimiter" {
		#; Set the DisplayDelimiter context variable
		do ..parseSet(pInput,.tOption,.tValueAE)
		#; If it looks like an expression try to parse it (because it may be displayed this way from $$Quote^%qcr
		if tValue["$c(" {
			try {
				New %val
				Xecute "Set %val="_$zstrip(tValueAE,"<>W")
			} catch {
				Set %val=tValueAE
			}
			Set tValueAE=%val
		}
		if tValueAE = "" { write !,"displaydelimiter = ",..DisplayDelimiter,! quit }
			// tValueAE = value as entered, preserves original casing.
		set ..DisplayDelimiter = tValueAE,display=$$Quote^%qcr(tValueAE)
		write !,"displaydelimiter = ",display,!
	}
	elseif tOption = "echo" {
			// Set the ECHOMODE context variable...
		if tValue = "" { write !,"echomode = ",..EchoModeLogicalToDisplay(..EchoMode),! quit }
		set tEchoMode = $case(tValue,"on":1,"off":0,:"")
		if tEchoMode = "" { write !,$$$FormatText($$$Text("Invalid 'echomode' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..EchoMode = tEchoMode
		write !,"echo = ",..EchoModeLogicalToDisplay(..EchoMode),!
	}
	elseif tOption = "executemode" {
	        #; Set the EXECUTEMODE context variable...
		if tValue = "" { write !,"executemode = ",..ExecuteModeLogicalToDisplay(..ExecuteMode),! quit }
		set tExecuteMode = $case(tValue,"deferred":0,"immediate":1,:tValue)
		if (tExecuteMode '= 0) && (tExecuteMode '= 1) { write !,$$$FormatText($$$Text("Invalid 'Executemode' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..ExecuteMode = tExecuteMode
		write !,"Executemode = ",..ExecuteModeLogicalToDisplay(..ExecuteMode),!
	}
	elseif tOption = "log" {
			#; Set the LOG context variable...
			#; support "on" and "off", "on" meaning to activate logging using the default file name
			#; "off" means turn off logging and close the current log file
			// <file> means activate logging and use <file> for the log file.
		if tValue = "" {
				// display the current log status
			write !,"log = ",$Select($Isobject(..Log):..Log.logFile,1:"off"),!
		}
		elseif tValue = "on" {
				// activate logging
			if $Isobject(..Log) { write !,$$$FormatText($$$Text("logging is already activated, current log output is '%1'","%SQL.Shell"),..Log.logFile),! }
			else {
				set ..Log = ..LogNewObject()
				write !,"log = ",$Select($Isobject(..Log):..Log.logFile,1:"off"),!
			}
		}
		elseif tValue = "off" {
			if $Isobject(..Log) {
				write !,$$$FormatText($$$Text("logging to '%1' is now suspended.","%SQL.Shell"),..Log.logFile),!
				set ..Log = ""
			}
			else {
				write !,"log = off",!
			}
		}
		else {
				// activate logging
			do ..parseSet(pInput,,.tValueOC)
			if $Isobject(..Log) {
				write !,$$$FormatText($$$Text("logging is active, current log output is '%1'","%SQL.Shell"),..Log.logFile),!
				if ..Log.logFile '= tValueOC {
					write $$$Text("closing current log...","%SQL.Shell")
					set ..Log = ""
					write !,$$$Text("opening new log...","%SQL.Shell")
					set ..Log = ##class(%XSQL.Log).%New(tValueOC)
					if '$Isobject(..Log) { write $$$Text("failed.","%SQL.Shell"),! }
					else { write $$$Text("activated","%SQL.Shell"),! }
				}
			}
			else {
				write !,$$$Text("opening new log...","%SQL.Shell")
				set ..Log = ##class(%XSQL.Log).%New(tValueOC)
				if '$Isobject(..Log) { write $$$Text("failed.","%SQL.Shell"),! }
				else { write $$$Text("activated","%SQL.Shell"),! }
			}
			write !,"log = ",$Select($Isobject(..Log):..Log.logFile,1:"off"),!
		}
	}
	elseif tOption = "messages" {
			// Set the MESSAGEMODE context variable...
		if tValue = "" { write !,"messages = ",..MessageModeLogicalToDisplay(..MessageMode),! quit }
		set tMessageMode = $case(tValue,"on":1,"off":0,:"")
		if tMessageMode = "" { write !,$$$FormatText($$$Text("Invalid 'messagemode' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..MessageMode = tMessageMode
		write !,"messages = ",..MessageModeLogicalToDisplay(..MessageMode),!
	}
	elseif tOption = "path" {
		if tValue '= "" {
			if tValue = """""" { set tValue = $$$DefaultSchema }
			set ..Path = tValue
		}
		write !,"path = ",$Select(..Path'="":..Path,1:"<<empty>>"),!
	}
	elseif tOption = "save" {
		set ^IRIS.SQL.Shell($Username,0) = $ListBuild(..ExecuteMode,..SelectMode,..Path,..DisplayMode,..Dialect,..EchoMode,..MessageMode,..CommandPrefix,..DisplayFile,..DisplayPath,..ColAlign,..DisplayDelimiter)
		write !,$$$Text("current settings saved.","%SQL.Shell"),!
	}
	elseif tOption = "selectmode" {
	        #; Set the SELECTMODE context variable...
		if tValue = "" { write !,"selectmode = ",..SelectModeLogicalToDisplay(..SelectMode),! quit }
		set tSelectMode = $case(tValue,"logical":0,"odbc":1,"display":2,:"")
		if tSelectMode = "" { write !,$$$FormatText($$$Text("Invalid 'selectmode' value... (%1)","%SQL.Shell"),tValue),! quit }
		set ..SelectMode = tSelectMode
		write !,"selectmode = ",..SelectModeLogicalToDisplay(..SelectMode),!
	}
	elseif tOption = "" {
		write !
		write "colalign = ",..ColAlignLogicalToDisplay(..ColAlign),!
		write "commandprefix = ",$Select(..CommandPrefix'="":..CommandPrefix,1:""""""),!
		write "dialect = ",..DialectLogicalToDisplay($Select(..Dialect="":$$$SQLDIALECTIRIS,1:..Dialect)),!
		write "displayfile = ",..DisplayFileLogicalToDisplay(..DisplayFile),!
		write "displaymode = ",..DisplayModeLogicalToDisplay(..DisplayMode),!
		write "displaypath = ",..DisplayPathLogicalToDisplay(..DisplayPath),!
		write "displaytranslatetable = ",..DisplayTranslateTableLogicalToDisplay(..DisplayTranslateTable),!
		write "displaydelimiter = ",..DisplayDelimiter,!
		write "echo = ",..EchoModeLogicalToDisplay(..EchoMode),!
		write "executemode = ",..ExecuteModeLogicalToDisplay(..ExecuteMode),!
		write "log = ",$Select($Isobject(..Log):..Log.logFile,1:"off"),!
		write "messages = ",..MessageModeLogicalToDisplay(..MessageMode),!
		write "path = ",..Path,!
		write "selectmode = ",..SelectModeLogicalToDisplay(..SelectMode),!
	}
	else {
		write !,$$$Text("Invalid option: '","%SQL.Shell"),tOption,"'",!
	}
	quit
}

Method cmdShow(ByRef pInputLC As %Library.String(MAXLEN="") = "", pCommand As %Library.String = "")
{
		// Various "show" options
	set verbose=$CASE($p(pInputLC," ",3),"verbose":1,"v":1,:0)
	set tCommandOption = $Piece(pInputLC," ",2)
	if (tCommandOption = "planalt") {
		if '$Data(..StatementText) {
			write $$$Text("There is no query to analyze.","%SQL.Shell"),!
			quit
		}
			#;  Function:     ShowPlanAlt^%apiSQL(sql,arr,forTest,showstats,package,schemapath,preparse,idList,silent)
			#;  Description:  Generate a plan description for a given query text
			#;				  Then list other Query Costs the user can select to see alternate Plans
			#;  Parameters:
			#;     1.  sql - Passed by reference.  sql(1:sql) are lines of SQL query text
			#;     2.  arr - 1 or 0 ("").  If 1, leave the resulting plan lines in the
			#;               array %AltPlan(CostID,1:%plan), otherwise output the plan using WRITE
			#;     3.  forTest - NOT USED, just a place holder to keep in line with ShowPlan^%apiSQL()
			#;     4.  showstats - (0,1,2,3).  0 default - do not show stats as part of the plan
			#;								   1 run the SQL query to generate stats and output the stats as part of the plan text
			#;								   2 means lookup the stats in %SYS.PTools.SQLStats
			#;								   3 means generate alternate plan for the Portal
			#;     5.  packages = $List of package names that will be used as default packages/schemas
			#;     6.  schemapath.  If '="", set this value into %sqlSchemaPath, overriding any currently defined %sqlSchemPath
			#;     7.  preparse = 1 or 0.  If 1 first preparse the SQL statement to perform literal replacement.
			#;                    The default is 0, but the ShowPlan call from the SMP will call with preparse=1 so the
			#;                    Plan reflects the same execution path as the Execute Query will.
			#;     8.  idList = list of cost ids you want to generate stats for, Used by SMP, Alternate Show Plans
			#;     9.  silent - 1 or 0 (""). If 1, don't perform any writes within this method
			#;    10.  p10    - Placeholder Parameter for JSL (ignoreoutliers)
			#;    11.  p11    - Placeholder Parameter for JSL (dynargs)
			#;    12.  verbose - 0 = Populate the %plan() array with ONLY top-level module details
			#;                   1 = Populate the %plan() array with all module details
			#;                   NOTE: If the %plan() array is to be used as the input to the
			#;                         planHTML^%qaqplan() method, then the 'verbose' parameter 
			#;                         must be equal to one (1)
		if +..StatementText '= ..StatementText { set tSQL = 1, tSQL(1) = ..StatementText } else { merge tSQL = ..StatementText }
		 	#; If this is a SELECT query, add on a "DECLARE CURSOR QRS FOR " so the showplan will match the statement index for a dynamic query that may have already been executed and had it's plan frozen.
		 	#; This will allow the statment to match and use the frozen plan
		 if $$$UPPER($e($$$StripLeadingWhiteSpace(tSQL(1)),1,6))="SELECT" {
			 set tSQL(1)="DECLARE QRS CURSOR FOR "_tSQL(1)
		 }
		if ..Path '= "" {
			set tCurrentPath = $g(%sqlSchemaPath)
			set tSchemaPath = $$$UPPER(..Path)
			for tPtr = 1:1:$l(tSchemaPath,",") {
				set tSchema=$p(tSchemaPath,",",tPtr)
				if tSchema = "" { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SqlCompileBadMode)) }
				set:tSchema="CURRENT_PATH" $p(tSchemaPath,",",tPtr) = tCurrentPath
				#; TODO: How do we determine the code container? It is either contextless (server based or command line based), in a routine or in a class. We are only interested
				#; 		if we are in a class. This code, from the MPP, knows the code container:
						;	set:tSchema="CURRENT_SCHEMA" $p(tSchemaPath,",",tPtr)=$s($g(%classname)'="":$$$UPPER($$DetermineSchemaName^%qarmac(%classname)),1:$$$DEFAULTSCHEMA)
			}
		}
		else { set tSchemaPath = "" }
		do ShowPlanAlt^%apiSQL(.tSQL,,,,,$listfromstring(tSchemaPath),1,,,,,verbose)
		write !
	} elseif ((tCommandOption = "plan") || (tCommandOption = "")) || ($Extract(tCommandOption,1,2) = "pl") {
		if '$Data(..StatementText) {
			write $$$Text("There is no query to analyze.","%SQL.Shell"),!
			quit
		}
			#;-------------------------------------------------------------------
			#;  Function:     ShowPlan^%apiSQL(sql,arr)
			#;  Description:  Generate a plan description for a given query text
			#;  Parameters:
			#;     1.  sql - Passed by reference.  sql(1:sql) are lines of SQL query text
			#;     2.  arr - 1 or 0 ("").  If 1, leave the resulting plan lines in the
			#;               array %plan(1:%plan), otherwise output the plan using WRITE
			#;     3.  forTest - 1 or 0 ("").  If 1, generate regression test output
			#;     4.  showstats - 1 or 0.  If 1 the run the SQL query to generate stats
			#;                     and output the stats as part of the plan text
			#;     5.  packages = $List of package names that will be used as default packages/schemas
			#;-------------------------------------------------------------------
		if +..StatementText '= ..StatementText { set tSQL = 1, tSQL(1) = ..StatementText } else { merge tSQL = ..StatementText }
		 	#; If this is a SELECT query, add on a "DECLARE CURSOR QRS FOR " so the showplan will match the statement index for a dynamic query that may have already been executed and had it's plan frozen.
		 	#; This will allow the statment to match and use the frozen plan
		 if $$$UPPER($e($$$StripLeadingWhiteSpace(tSQL(1)),1,6))="SELECT" {
			 set tSQL(1)="DECLARE QRS CURSOR FOR "_tSQL(1)
		 }
		if ..Path '= "" {
			set tCurrentPath = $g(%sqlSchemaPath)
			set tSchemaPath = $$$UPPER(..Path)
			for tPtr = 1:1:$l(tSchemaPath,",") {
				set tSchema=$p(tSchemaPath,",",tPtr)
				if tSchema = "" { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SqlCompileBadMode)) }
				set:tSchema="CURRENT_PATH" $p(tSchemaPath,",",tPtr) = tCurrentPath
				#; TODO: How do we determine the code container? It is either contextless (server based or command line based), in a routine or in a class. We are only interested
				#; 		if we are in a class. This code, from the MPP, knows the code container:
						;	set:tSchema="CURRENT_SCHEMA" $p(tSchemaPath,",",tPtr)=$s($g(%classname)'="":$$$UPPER($$DetermineSchemaName^%qarmac(%classname)),1:$$$DEFAULTSCHEMA)
			}
		}
		else { set tSchemaPath = "" }
		do ShowPlan^%apiSQL(.tSQL,0,0,0,"",$listfromstring(tSchemaPath),1,"RUNTIME",,,,,verbose)
		write !
	} elseif ($Extract(tCommandOption,1,2) = "st") || (tCommandOption = "statement") {
		do ..Statement.%Display()
	}
	quit
}

Method execute(pStatement As %SQL.Statement) As %SQL.StatementResult
{
	try {
		new %tResult,%tStatement,%tValue
		set %tResult = ""
		set %tStatement = pStatement
		if pStatement.%Metadata.parameters.Count() > 0 {
			set tExecute = "set %tResult=%tStatement.%Execute("
			set tExecuteDisplay = tExecute
			for tParm = 1:1:pStatement.%Metadata.parameters.Count() {
				set tParameter = pStatement.%Metadata.parameters.GetAt(tParm)
					// The default parameter expression is %tValue<n>. This changes
					// if the value entered by the user for an input directed parameter
					// begins with a <colon>.
				set tParmExpr = "%tValue"_tParm
				if (tParameter.columnType = 1) || (tParameter.columnType = 2) {
					write !,$$$FormatText($$$Text("Enter the value for parameter '%1': ","%SQL.Shell"),tParm)
					read tParmVal
					if $Extract(tParmVal) = ":" {
						write $$$Text("...is this a literal (Y/N)?  [N]:","%SQL.Shell")
						read tLiteral
						if $$$ucase(tLiteral) '= "Y" {
							set tParmExpr = $Extract(tParmVal,2,*)
						set tExecuteDisplay = tExecuteDisplay _ tParmExpr _","
						}
						else {
							set tParmExpr = "%tValue"_tParm
							set @("%tValue"_tParm) = tParmVal
							set tExecuteDisplay = tExecuteDisplay _ $ZUtil(144,1,tParmVal) _","
						}
					}
					else {
						set @tParmExpr = tParmVal
						set tExecuteDisplay = tExecuteDisplay _ $ZUtil(144,1,tParmVal) _","
					}
					set tExecute = tExecute _ tParmExpr _ ","
				}
				elseif tParameter.columnType > 3 {
						// Output only (4) or Return value (5)
					set tExecuteDisplay = tExecuteDisplay _","
					set tExecute = tExecute _ ","
				}
			}
			set tExecute = $Select($Extract(tExecute,*)'="(":$Extract(tExecute,1,*-1)_")",1:tExecute _ ")")
			write !,$$$Text("executing statement with parameter values: ","%SQL.Shell"),$Select($Extract(tExecuteDisplay,*)'="(":$Extract(tExecuteDisplay,1,*-1)_")",1:tExecuteDisplay_")"),!
			set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds
			set ..executeStats=$lb(tGlobals,tCommands,tDiskRead)
			set ..executeStartTime = $zh
			xecute tExecute
		}
		else {
			set tGlobals = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences,tCommands=$zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted,tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds
			set ..executeStats=$lb(tGlobals,tCommands,tDiskRead)
			set ..executeStartTime = $zh
			set %tResult = pStatement.%Execute()
		}
	}
	catch tException {
		write !,$$$Text("Exception occurred during statement execution","%SQL.Shell")
		do $system.OBJ.DisplayError(tException.AsStatus())
	}
	quit %tResult
}

ClassMethod cmdLoad(pInput As %String(MAXLEN=""), ByRef pStatement As %String(MAXLEN=""))
{
	set tFileName = $zstrip($Piece(pInput," ",2,*),"<=W")
	write !,$$$FormatText($$$Text("Loading statement from '%1'...","%SQL.Shell"),tFileName)
	try {
		set tBatch = ##class(%Stream.FileCharacter).%New()
		set tStatus = tBatch.LinkToFile(tFileName)
		if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
		set tBatch.LineTerminator = $Char(13,10)
		set tSourceLine = tBatch.ReadLine()
		write !,$Char(9),tSourceLine
		set pStatement = 1, pStatement(pStatement) = tSourceLine
			#; Now read the input stream to the end
		do {
			set tSourceLine = tBatch.ReadLine()
			set pStatement = pStatement + 1, pStatement(pStatement) = tSourceLine
			write !,$Char(9),tSourceLine
		} while 'tBatch.AtEnd
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
		do $system.OBJ.DisplayError(tStatus)
		kill pStatement
	}
	quit tStatus
}

Method cmdSave(pInput As %String(MAXLEN=""))
{
	try {
		new %objlasterror
		set tFileName = $zstrip($Piece(pInput," ",2,*),"<=W")
		if ##class(%Library.File).Exists(tFileName) {
			write !,$$$FormatText($$$Text("File '%1' already exists. Overwrite? (Y/N)? ","%SQL.Shell"),tFIleName)
			read tYN
			if $zconvert($Extract(tYN),"l") '= "y" {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"File '"_tFileName_"' already exists"))
			}
		}
		set tBatch = ##class(%Stream.FileCharacter).%New()
		if tBatch = $$$NULLOREF { throw ##class(%Exception.StatusException).CreateFromStatus($Get(%objlasterror)) }
		set tStatus = tBatch.LinkToFile(tFileName)
		if ..StatementText = +..StatementText {
			for tLine = 1:1:..StatementText {
				set tStatus = tBatch.WriteLine(..StatementText(tLine))
				if $$$ISERR(tStatus) { quit }
			}
		}
		else { set tStatus = tBatch.WriteLine(..StatementText) }
		if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
		set tStatus = tBatch.%Save()
		if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
		write !,$$$Text("...statement saved as: ","%SQL.Shell"),tFileName,!
	}
	catch tException {
		set tStatus = tException.AsStatus()
		write !,$$$Text("...error occurred during file write. Not saved: ","%SQL.Shell")
		do $system.OBJ.DisplayError(tStatus)
		write !
	}
	quit tStatus
}

/// EnterStatement - multi-line statement entry
Method EnterStatement(ByRef pInput As %Library.String(MAXLEN="") = "")
{
	write !
	set pInput = 0
	do {
		write $Char(9),pInput+1,">>"
		#; Ignore Ctrl+C
		for {
			try { read tInput } catch { if $ze["<INTERRUPT>" { continue } throw }
			quit
		}
		write !
Dispatch
		set tInputLC = $zconvert(tInput,"l")
		if (((..CommandPrefix '= "") && ($Extract(tInputLC,1,$Length(..CommandPrefix)) = ..CommandPrefix)) || ($Extract(tInputLC,1) = "?") || ($Extract(tInputLC,1) = "#") || ($Extract(tInputLC,1,2) = "go"))
		   || ((..CommandPrefix = "") && (($Find("?,q,quit,c,clear,!,cos,obj,objectscript,g,go,l,list,load,",$Piece(tInputLC," ",1)_",")) || ($e(tInputLC,1) = "!"))) 
		   || (tInput = "") {
				// Strip the command prefix if present
			if (..CommandPrefix '= "") && ($Extract(tInputLC,1,$Length(..CommandPrefix)) = ..CommandPrefix) { set tInputLC = $Extract(tInputLC,$Length(..CommandPrefix)+1,*),tInput = $Extract(tInput,$Length(..CommandPrefix)+1,*) }
			if $e(tInputLC,1)="!" { set tCommand = "!",tInputLC=$e(tInputLC,2,*),tInput=$e(tInput,2,*) } else { set tCommand = $Piece(tInputLC," ",1) }

				// test for commands
			if ((tCommand = "?") && ($Extract($ZStrip($Extract(tInputLC,2,*),"<W")) '= "="))||(tCommand="help") {
				do ..HelpStatementMode()
				continue
			}
			if (tCommand = "") {
				if tInput '= "" { set pInput = pInput + 1, pInput(pInput) = tInput }
				continue
			}
			if (tCommand = "c") || (tCommand = "clear") {
				set tLine = $Piece(tInputLC," ",2)
				if tLine '= "" {
					if tLine > pInput { write $$$Text("Line not defined: ","%SQL.Shell"),tLine,! }
					else {
						kill pInput(tLine)
						for tPtr = tLine:1:pInput-1 { set pInput(tPtr) = pInput(tPtr+1) }
						kill pInput(pInput)
						set pInput = pInput - 1
						write !,$$$FormatText($$$Text("Line '%1' cleared.","%SQL.Shell"),tLine),!
					}
				}
				else {
					write !,$$$Text("Clearing the entire statement. Continue? [y|n]:","%SQL.Shell")
					read tYN
					if $zconvert($Extract(tYN),"l") = "y" {
						kill pInput
						set pInput = 0
						write $$$Text("...cleared","%SQL.Shell"),!
					}
					else { write $$$Text("...not cleared","%SQL.Shell"),! }
				}
				continue
			}
			if (tCommand = "cos") || (tCommand = "!") || (tCommand="objectscript") || (tCommand="obj"){
				if $zb($ZJOB,1,1) {
					if ..EscapeCondition {
						if tCommand="cos" { set tInput=$e(tInput,4,*) }
						elseif tCommand="obj" { set tInput=$e(tInput,4,*) }
						elseif tCommand="objectscript" { set tInput=$e(tInput,13,*) }
						do ..cmdObjectScript(.tInput)
						write !
					} else {
						write !,$$$Text("Execution of ObjectScript commands not allowed for this configuration.","%SQL.Shell"),!
					}
				} else {
					write !,$$$Text("Execution of ObjectScript commands not suported when the current process is not in programmer mode.","%SQL.Shell"),!
				}
				continue
			}
			if ((tCommand="g")||(tCommand="go")) {
				quit
			}
			if (tCommand="l")||(tCommand="list") {
					#; list the current statement
				write "---------------------------------",!
				for tPtr = 1:1:pInput { write $Char(9),pInput(tPtr),! }
				write "---------------------------------",!
				continue
			}
				#; QUIT - clear the statement buffer and return
			if ((tCommand="q")||(tCommand="quit")) {
				kill pInput
				set pInput = ""
				quit
			}
		}
		set pInput = pInput + 1, pInput(pInput) = tInput
	} while 1
	quit
}

ClassMethod parseSet(pCommand As %String(MAXLEN="") = "", ByRef pOption As %String(MAXLEN="") = "", ByRef pValue As %String(MAXLEN="") = "") As %Status [ Internal ]
{
		// pCommand is expected to be all lower case and it begins with "set ".
		
		// First task is to remove the "set "
	set tCommand = $Piece($tr(pCommand,$c(9)," ")," ",2,*)
		// Now extract the option from tCommand. The assignment operator is optional. If not present, a space is required.
	if tCommand [ "=" {
		set pOption = $Piece(tCommand,"=",1), pValue = $Piece(tCommand,"=",2,*)
	} else {
		set pOption = $Piece($zstrip(tCommand,"<W")," ",1), pValue = $Piece($zstrip(tCommand,"<W")," ",2,*)
	}
		// Strip any leading/trailing whitespace from the option and value
	set pOption = $Zstrip(pOption,"<>W")
	set pValue = $Zstrip(pValue,"<>W")
	RETURN $$$OK
}

ClassMethod displayStatement(ByRef pStatement As %Library.String(MAXLEN=""), pIndentFirst As %Library.String = {$Char(9)}, pIndent As %Library.String = {$Char(9)})
{
	if +pStatement '= pStatement { write pIndentFirst,pStatement,! }
	else { write pIndentFirst,$Get(pStatement(1)),! for tPtr = 2:1:pStatement { write pIndent,pStatement(tPtr),! } }
}

ClassMethod Help()
{
	#;          12345678901234567890123456789012345678901234567890123456789012345678901234567890   // The last 0 is 80'th character of display output
		#; Print the command set with hints to the screen
	write !,$$$Text("Interactive SQL Shell - Multiline Statement Mode","%SQL.Shell"),!
	write "----------------------------------------------------",!
	write $$$Text("To execute an SQL statement, type it in and press ENTER.","%SQL.Shell"),!
	write $$$Text("To execute a multiline SQL statement, press <enter> to enter","%SQL.Shell"),!
	write $$$Text("multiline statement mode, enter the each statement line and","%SQL.Shell"),!
	write $$$Text("enter GO to exit multiline statement mode and execute the statement.","%SQL.Shell"),!
	write !,$$$Text("Available commands:","%SQL.Shell"),!
	write !,?3,"<enter>"              do ..display($$$Text("Enter multiline statement mode.","%SQL.Shell"))
	write !,?3,"#[?]"                 do ..display($$$Text("List statements currently in the history buffer.","%SQL.Shell"))
	write !,?3,"#<n>"                 do ..display($$$Text("Recall statement <n> from the statement history buffer","%SQL.Shell"))
	                                  do ..display($$$Text("If <n> is zero then recall the most recent statement.  Recalled statements are executed if EXECUTEMODE is set to 'immediate'.  If EXECUTEMODE is set to 'deferred' then it is necessary to enter 'go' to execute the recalled statement.","%SQL.Shell"))
	write !,?3,"browse"               do ..display($$$Text("Browse the schemas, tables, views, fields, and map definitions in this namespace.","%SQL.Shell"))
	write !,?3,"#clear"               do ..display($$$Text("Clear the statement history buffer.","%SQL.Shell"))
	write !,?3,"c[lear] <name>"       do ..display($$$Text("Clear (delete) the statement identified by <name> from the statement pool.","%SQL.Shell"))
	write !,?3,"! <objscr command>"   do ..display($$$Text("Execute <ObjectScript command>.  Note, there must be at least one space between the '!' and the beginning of the ObjectScript command(s)","%SQL.Shell"))
	write !,?3,"obj[ectscript] <objscr command>" do ..display($$$Text("Execute <ObjectScript command>.","%SQL.Shell"))
	write !,?3,"g[o]"                 do ..display($$$Text("Run the most recently executed or loaded statement.","%SQL.Shell"))
	write !,?3,"l[ist]"               do ..display($$$Text("List saved queries.","%SQL.Shell"))
	write !,?3,"load <filename>"      do ..display($$$Text("Load a statement from a file.","%SQL.Shell"))
	write !,?3,"m[etadata]"           do ..display($$$Text("Displays the statement metadata of the current statement.","%SQL.Shell"))
	write !,?3,"o[pen] <name>"        do ..display($$$Text("Open the statement name <name> from the statement pool.  The retrieved statement is prepared and executed (depending on the EXECUTEMODE setting).","%SQL.Shell"))
	write !,?3,"p[urge]"              do ..display($$$Text("Purge all cached queries in this namespace.","%SQL.Shell"))
	write !,?3,"q[uit] or e[xit]"     do ..display($$$Text("Exit the shell.","%SQL.Shell"))
	write !,?3,"run [<filename>]"     do ..display($$$Text("Run an SQL script. If <filename> is not specified then the user will be prompted for the file name.","%SQL.Shell"))
	write !,?3,"saveglobal <name>"    do ..display($$$Text("Save the current statement using the given name in the statement global.","%SQL.Shell"))
	write !,?3,"s[ave] <filename>"    do ..display($$$Text("Save the current statement to a file.","%SQL.Shell"))
	write !,?3,"set"                  do ..display($$$Text("Displays the current context settings.","%SQL.Shell"))
	write !,?3,"set clear"            do ..display($$$Text("Clear saved Shell settings for this user.","%SQL.Shell"))
	write !,?3,"set colalign [=] delim[iter] | header | data",! do ..display($$$Text("Set column alignment for the SQL Resultset.  The context setting 'colalign' can be set to one of the following values:","%SQL.Shell"))
	   do ..display($$$Text("   delim[iter] - The SQL Resultset header/data columns will be aligned based on the standard delimiter (tab).  [Default]","%SQL.Shell"))
	   do ..display($$$Text("   header      - The SQL Resultset header/data columns will be aligned based on the length of the column header and the standard delimiter (tab).","%SQL.Shell"))
	   do ..display($$$Text("   data        - The SQL Resultset header/data columns will be aligned based on the precision/length of the column data property and the standard delimiter (tab).","%SQL.Shell"))
	write !,?3,"set commandprefix [=] <value>",! do ..display($$$Text("Sets the commandprefix to <value>.","%SQL.Shell"))
	write !,?3,"set dialect [=] IRIS | sybase | mssql",! do ..display($$$Text("Sets the dialect to the desired SQL dialect.  If dialect is empty then IRIS SQL is assumed.  The dialect setting determines which dialect mode is used when preparing a statement.","%SQL.Shell"))
	write !,?3,"set displayfile [=] <file>",! do ..display($$$Text("Set the name of the file to be used for displaying the results of executing SQL statements.  If no file name is specified then a random file name will be generated for each statement execution.  Additionally, a messages file may be produced. The name of the file containing messages is either the <file> concatenated with ""Messages"" or it is a random file name if <file> is set to nothing. To set the <file> setting to nothing after it was previously set, enter """".","%SQL.Shell"))
	write !,?3,"set displaymode [=] <displaymode>",! do ..display($$$Text("Set the DISPLAYMODE.  If <var>displaymode</var> is not specified, the current DISPLAYMODE setting is displayed on the current device. <displaymode> values can be cur[rentdevice],xml,html,pdf, txt or csv.  When DISPLAYMODE is set to CURRENTDEVICE, statement results are displayed on the current device. When XML, HTML, PDF or TXT are specified then the statement results are written to a file using a ZEN Report that is generated from the statement metadata.","%SQL.Shell"))
	write !,?3,"set displaypath [=] <path>",! do ..display($$$Text("Set the path where files used to save statement results will be placed.","%SQL.Shell"))
	write !,?3,"set displaytranslate[table] [=] <translatetable>",! do ..display($$$Text("Set the translate table used for displayfile when writing output in 'csv' and 'txt' formats. For example, ""UTF8"".  Values are case sensitive.","%SQL.Shell"))
	write !,?3,"set echo [=] on | off",! do ..display($$$Text("Turn echo mode on or off.  If on, statements and results are echoed to the current device.  This setting does not impact logging.","%SQL.Shell"))
	write !,?3,"set executemode [=] immediate|deferred",! do ..display($$$Text("Sets the execute mode.  If immediate then SQL statements are executed immediately.  If deferred then that current statement is executed by entering a 'go' command.","%SQL.Shell"))
	write !,?3,"set log [=] on | off | <filename>",! do ..display($$$Text("Turn logging on or off.  If a file name is specified, logging is turned on and the log is written to the file specified.  The default file for logging is used if logging is simply turned 'on'.","%SQL.Shell"))
	write !,?3,"set messages [=] on | off",! do ..display($$$Text("Turn messages on or off.  If <var>messages</var> is off then results are displayed without any additional information and prepare and execute times are not displayed.","%SQL.Shell"))
	write !,?3,"set path [=] <schemalist>",! do ..display($$$Text("Sets the current schema search path.  If <schemalist> is empty then the current path is displayed.  To set PATH to the default schema then specify <schemalist> as """".","%SQL.Shell"))
	write !,?3,"set save"             do ..display($$$Text("Save the current Shell settings for this user.  The settings are restored when the current user starts another Shell session.","%SQL.Shell"))
	write !,?3,"set selectmode [=] <selectmode>",! do ..display($$$Text("Sets the current select mode to odbc, logical, or display.  If <selectmode> is NULL the current setting is displayed.","%SQL.Shell"))
	write !,?3,"show"                 do ..display($$$Text("Show the execution plan for the current statement.","%SQL.Shell"))
	write !,?3,"show pl[an] [v[erbose]]",!   do ..display($$$Text("Shows the current statement execution plan.             If the verbose qualifier is used, show all the module details for the current statement's execution plan; Otherwise, display only the top-level module details by default.","%SQL.Shell"))
	write !,?3,"show planalt [v[erbose]]",!  do ..display($$$Text("Shows the current statement alternate execution plans.  If the verbose qualifier is used, show all the module details for the current statement's execution plan and all alternate plans; Otherwise, display only the top-level module details by default.","%SQL.Shell"))
	write !,?3,"show st[atement]"     do ..display($$$Text("Shows the current statement and details regarding the statement.","%SQL.Shell"))
	write !,?3,"<SQL Statement>"      do ..display($$$Text("Prepares and executes the statement. The result is displayed after execution.","%SQL.Shell"))
	quit
}

ClassMethod HelpStatementMode()
{
		#; Print the command set with hints to the screen
	write !,$$$Text("Interactive SQL Shell - Multiline Statement Mode","%SQL.Shell"),!
	write "----------------------------------------------------",!
	write !,$$$Text("Multline statement mode.","%SQL.Shell"),!
	write ! do ..display($$$Text("To enter a multiline statement, enter each line followed by <enter>. The prompt indicates the current line number. When the statement is complete, enter GO (must appear on its own line) to exit multiline mode. If the execution mode is immediate the statement will be executed.","%SQL.Shell"),0,80)
	write !,$$$Text("Available commands in multiline mode:","%SQL.Shell"),!
	write !,?3,"c[lear]"               do ..display($$$Text("Clear (delete) the statement lines entered thus far.","%SQL.Shell"))
	write !,?3,"c[lear] <linenbr>"     do ..display($$$Text("Clear (delete) line <linenbr> from the statement line buffer.","%SQL.Shell"))
	write !,?3,"! <objscr command>"    do ..display($$$Text("Execute <ObjectScript command>.  Note, there must be at least one space between the '!' and the beginning of the ObjectScript command(s)","%SQL.Shell"))
	write !,?3,"obj[ectscript] <objscr command>"  do ..display($$$Text("Execute <ObjectScript command>.","%SQL.Shell"))
	write !,?3,"g[o]"                  do ..display($$$Text("Exit multiline statement mode and, if execute mode is immediate, execute the statement.","%SQL.Shell"))
	write !,?3,"l[ist]"                do ..display($$$Text("List the statement lines.","%SQL.Shell"))
	write !,?3,"q[uit]"                do ..display($$$Text("Exit multiline statement mode.","%SQL.Shell"))
	write !,?3,"<SQL Statement line>"  do ..display($$$Text("Enter a new line into the statement line buffer.","%SQL.Shell"))
	quit
}

/// cmdRun will run a SQL script file - Currently only Sybase is supported.
Method cmdRun(ByRef pInput As %Library.String(MAXLEN="") = "")
{
	set tFileName = $zstrip($Piece(pInput," ",2,*),"<=W")
	do ##class(%SQL.Util.Import).interactive(..Dialect,tFileName,..MessageMode,..EchoMode)
}

/// This method displays the result produced by executing the current statement. DISPLAYMODE determines how the statement is displayed
/// and ECHOMODE suppresses the results display on the current device.
Method displayResult(pResult As %SQL.StatementResult = "")
{
#define NewFileRoot					$translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")
#define TempFilePath				##class(%File).NormalizeDirectory(##class(%ZEN.Report.reportPage).%GetTempDir())
	try {
			// Get the OS. If the OS is not Windows or Unix then deliver the message that the file cannot
			// be automatically displayed.
		set tOS = $system.Version.GetBuildOS()
		if ..DisplayMode = -1 { 
			if ..EchoMode { 
				if pResult.%Extends("%SQL.IResultSet") {
					if '..ColAlign {
						do pResult.%DisplayMarkDown()
					} else {
						do pResult.%Display(,..ColAlign)
					}
				} else {
					do pResult.%Display()
				}
			} elseif ..MessageMode {
				#; If MessageMode iterate over results so we can display cmd/gbl counts for this query
				set sc=$$$OK
				while pResult.%Next(.sc) {
					If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) QUIT
				}
			}
		}
		else {
			set tMessages = ##class(%SQL.Manager.Messages).%New()
			if (..DisplayMode '= -1) && (..SelectMode = 0) {
				do tMessages.Insert("WARNING: Formatted display of results in LOGICAL mode might fail if the results contain control characters!")
				do tMessages.Insert("         A common result column containing a $List value, such as a list collection, will contain control characters")
				do tMessages.Insert("         and an empty result file will be displayed.")
			}
			set tDisplayPath=$select(..DisplayPath="":$$$TempFilePath,1:..DisplayPath)
			set tFileRoot = ##class(%Library.File).NormalizeFilename($select(..DisplayFile="":$$$NewFileRoot,1:..DisplayFile),tDisplayPath)
			try { do pResult.%DisplayFormatted(..DisplayMode,tFileRoot,tMessages,.tFiles,..DisplayTranslateTable,..DisplayDelimiter) }
			catch tExceptionInner {
				set tSQLCODE = tExceptionInner.AsSQLCODE()
				set tSQLMessage = tExceptionInner.AsSQLMessage()
				if ..MessageMode {
					write !!,"[SQLCODE: <",tSQLCODE,">:<",$$sqlcode^%apiSQL(tSQLCODE),">]",!
					if tSQLMessage'="" { write "[%msg: <",tSQLMessage,">]",! }
				}
				if ..LogMode { do ..Log.logException(tExceptionInner) }
			}
			if tMessages.Count() > 0 { do tMessages.%DisplayFormatted(..DisplayMode,tFileRoot_"Messages",,.tFiles,..DisplayTranslateTable,..DisplayDelimiter) }
			if tFiles { for tFile = 1:1:tFiles { write !,tFiles(tFile) } write ! }
		}
			// Note that result sets have already been consumed by the time we log the result unless ECHOMODE is off:
		if $Isobject(..Log) { do ..Log.logStatementResult(pResult) }
	}
	catch tException {
		if ..MessageMode {
			set tSQLCODE = tException.AsSQLCODE()
			set tSQLMessage = tException.AsSQLMessage()
			write !!,"[SQLCODE: <",tSQLCODE,">:<",$$sqlcode^%apiSQL(tSQLCODE),">]",!
			if tSQLMessage'="" { write "[%msg: <",tSQLMessage,">]",! }
		}
		if $Isobject(..Log) { do ..Log.logException(tException) }
	}
}

/// getPrompt() returs the string to use for the prompt based on the configured Terminal Prompt settings
ClassMethod getPrompt(lasttime As %Library.String = "0.0")
{
	set promptOptions=$zu(186)
	set prompt="[SQL]"
		#; options 4, 7, and 8 can change with each prompt
	for position=1:1 {
		set option=$p(promptOptions,",",position) quit:option=""
		if option=1 { set prompt=prompt_$zu(54,0)_":" }                             // Host name
		elseif option=2 { set prompt=prompt_$namespace_":" }                        // namespace
		elseif option=3 { set prompt=prompt_$p($zu(86),"*",*)_":" }                 // Config name
		elseif option=4 { set prompt=prompt_$zt($p($h,",",2),1)_":" }               // current time
		elseif option=5 { set prompt=prompt_$job_":" }	                            // PID
		elseif option=6 { set prompt=prompt_$username_":" }                         // username
		elseif option=7 { set prompt=prompt_lasttime_":" }                          // Elapsed time executing the last command
		elseif option=8 { set prompt=prompt_$s('$tlevel:"",1:"TL"_$tlevel_":") }    // transaction level
	}
	set:$e(prompt,*)=":" prompt=$e(prompt,1,*-1)
	QUIT prompt_">>"
}

/// Given a string, display the string on this, and as many lines needed, between the given margins.
ClassMethod display(str As %String, lmargin As %Integer = 25, rmargin As %Integer = 80)
{
	set dispLength=rmargin-lmargin
	if $l(str)'>dispLength { write ?lmargin,str,! QUIT }
		// we need to display the str on multiple lines, find a good place to split the line
	while $l(str) {
		set position=dispLength
		while " .,;:?!"_$c(9)'[$e(str,position) { set position=position-1 if position=1 { set position=dispLength quit }}
		write ?lmargin,$e(str,1,position),!
		set $e(str,1,position)="",str=$$$StripLeadingWhiteSpace(str)
	}
	QUIT
}

}
