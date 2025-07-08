/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This page process Link Table/Procedure Wizard Result.
Class %CSP.UI.SQL.LinkWizardResultPage Extends %CSP.Page [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Set Wizard = $G(%request.Data("Wizard",1),"LinkTable")
	Set $$$IRISTempMgt($Username,Wizard,"Filter") = $G(%request.Data("SchemaFilter",1))_"^"_$G(%request.Data("TableFilter",1))
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

ClassMethod OnPage() As %Status
{
	
	Set tMode = $G(%request.Data("Wizard",1),"LinkTable")
	Set msgTable = $$$TextHTML("Link Table Result")
	Set msgProcedure = $$$TextHTML("Link Procedure Result")
	Set msgMigration = $$$TextHTML("Data Migration Result")
	Set cmdClose = $$$TextHTML("Close")
	Set tTitle = $Case(tMode,"LinkTable":msgTable,"LinkProcedure":msgProcedure,:msgMigration)
	&html<<html>
	<head>
	<title>#(tTitle)#</title>
	<link rel="stylesheet" type="text/css" href="#(..Link("/csp/sys/intersystems.css"))#">
	<style type="text/css">
	#centerbox {
		color: darkblue;
		width: 90%;
		height: 200px;
		padding: 10px;
		font-size: 1.0em;
		float: center;
		margin: 10px;
	}
	</style>
	<script language="javascript">
	function popupClose()
	{
		window.close();
	}
	</script>
	</head>>
	Set msg1 = $$$TextHTML("This task will be run in the background.")
	Set msg2 = $$$TextHTML("Click here to view the background tasks page.")
	Set linkpage = ..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskListPopup.zen")
	// need to do this because otherwise Close Window does not work on the UtilExpBackgroundTasks.csp page on Safari.
	// JYL637: this doesn't seem to be true any more, at least on Windows. Commenting out for now.
	//If %request.UserAgent["Safari" Set linkpage = ..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen")
	Kill tParms
	Set tParms("Wizard") = tMode
	Set tParms("NAMESPACE") = $G(%request.Data("$NAMESPACE",1))
	Set tParms("DataSource") = $G(%request.Data("DataSource",1))
	Set tParms("Schema") = $G(%request.Data("Schema",1))
	Set tParms("PrimaryKey") = $G(%request.Data("PrimaryKey",1))
		// For multi-select, NewTableName is New package
	Set tParms("NewTableName") = $G(%request.Data("NewTableName",1))
	Set tParms("NewClassName") = $G(%request.Data("NewClassName",1),"NewClassName")
	Set tParms("ProcedureName") = $G(%request.Data("ProcedureName",1))
	Set tParms("MethodName") = $G(%request.Data("MethodName",1))
	Set tParms("Description") = $G(%request.Data("Description",1))
	Set tParms("DataType") = $G(%request.Data("DataType",1))
	Set tParms("NoCheck") = $S($G(%request.Data("NoCheck",1))'="":1,1:0)
	Set tParms("NoJournal") = $S($G(%request.Data("NoJournal",1))'="":1,1:0)
	Set tParms("DeferIndices") = $S($G(%request.Data("DeferIndices",1))'="":1,1:0)
	Set tParms("NoTrigger") = $S($G(%request.Data("NoTrigger",1))'="":1,1:0)
	Set tParms("TuneTable") = $S($G(%request.Data("TuneTable",1))'="":1,1:0)
	Set tParms("DeleteExistingData") = $S($G(%request.Data("DeleteExistingData",1))'="":1,1:0)
	Set tParms("MaxErrors") = $G(%request.Data("MaxErrors",1),30)

	$$$editClassKill(tParms("NewClassName"))
    Set i = 1
    Set column = $G(%request.Data("selList",i))
	While column '= "" {
 	    Set cap = "newCaption"_column
     	Set colname = "newColName"_column
     	Set Propname = $G(%request.Data(cap,1),column)
     	Set newPropname = ..ValidateColName(tParms("NewClassName"),Propname)
       	Set newColname = $G(%request.Data(colname,1),column)
       	#; If column name passed in is the same as property name passed in, then use the new validated property name 
       	#; (the validated property name could be the same as the original property name as long as it is unique)
       	#; Else validate the column name also.
  		#;YSD2511 If Colname = Propname Set newColname = newPropname
  		#;YSD3098 If Colname = Propname Set newColname = Colname
		#;YSD3098 Else  Set newColname = ..ValidateColName(tParms("NewClassName"),Colname)
       	Set readonly = $S($G(%request.Data("readonly"_column,1),0)="on":1,1:0)
		Set tItems("Columns",i) = column
		Set tItems(i,"newPropname") = newPropname
		Set tItems(i,"newColName") = newColname
		Set tItems(i,"readonly") = readonly
		Set i = i + 1
		Set column = $G(%request.Data("selList",i))
	}
 	Set tParms("TotalColumns") = i - 1
	Set tRow = $O(%request.Data("Table","")),i=0
	While tRow '= "" {
			Set tname = $G(%request.Data("Table",tRow))
			If tname '= "_" {  // skip blank row just in case
				Set i = i + 1
				Set tItems("Tables",i) = $zstrip(tname,"<>W")
				If tMode = "DataMigration" {
					Set tItems(i,"TType") = $G(%request.Data("TType",tRow))
					Set tItems(i,"newSchema") = $G(%request.Data("newSchema"_tname,1),tParms("Schema"))
					Set tItems(i,"copyDef") = $G(%request.Data("copyDef"_tname,1))
					Set tItems(i,"copyData") = $G(%request.Data("copyData"_tname,1))
				}
			}
		Set tRow = $O(%request.Data("Table",tRow))
	}
 	Set tParms("TotalTables") = i
 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask(tMode,tParms("NAMESPACE"),.tParms,.tItems,.tJob)
	If $$$ISERR(status) Do ##class(%CSP.UI.SQL.ExImWizardResultPage).LogMsg($System.Status.GetErrorText(status))
	Do ##class(%CSP.Util.AutoPage).DrawTitle($$$Text("Background Job"))

	&html<
	<body onload="self.focus();">
	<div id="centerbox">
 		<h2>#(msg1)#</h2>
 		<h2><a href="#(linkpage)#">#(msg2)#</a></h2>
		<form>
		<input type="button" name="btnClose" value="#(cmdClose)#" onclick="popupClose();">
		</form>
		</div>
		</body>
		</html>
		>
	Quit $$$OK
}

/// Create Link Table Process Start
ClassMethod CreateLinkTable(DataSource As %String, SchemaName As %String, ByRef pParms As %String, ByRef tItems As %String)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set tSkipMsg = $$$Text("This table is skipped because no primary keys.")
	Set HasError = 0
	Do {	
  		Set EventDesc = "Link Table"
		Set EventData = ""
		Set p1 = ""
		For  Set p1 = $O(pParms(p1)) Quit:p1=""  Set EventData = EventData_p1_": "_pParms(p1)_$$$CRLF
		Set EventData = EventData_"Tables: "_$$$CRLF
		For  Set p1 = $O(tItems("Tables",p1)) Quit:p1=""  Set EventData = EventData_p1_": "_$G(tItems("Tables",p1))_$$$CRLF				
		Set EventData = EventData_"Columns: "_$$$CRLF
		For  Set p1 = $O(tItems("Columns",p1)) Quit:p1=""  Set EventData = EventData_p1_": "_tItems("Columns",p1)_" newPropname: "_tItems(p1,"newPropname")_" newColName: "_tItems(p1,"newColName")_" readonly: "_tItems(p1,"readonly")_$$$CRLF						
		$$$SMPAuditChange
		Set tIsMulti = (pParms("TotalTables") > 1)
		Set i = $O(tItems("Tables",""))
		While i '= "" {
			Set tname = tItems("Tables",i)
			Set primarykeys = pParms("PrimaryKey")
     		If primarykeys = ""!(tIsMulti) set primarykeys = ..GetPrimaryKeys(DataSource,SchemaName,tname)
			If primarykeys '= "" {
				Do ..CreateOneLinkTable(DataSource,SchemaName,tname,primarykeys,pParms("NewClassName"),pParms("NewTableName"), .pParms, .tItems, tIsMulti, .HasError)
			} Else {
				Do ..LogMsg(tname_": "_tSkipMsg)
			}
			Set i = $O(tItems("Tables",i))
		}
	} While(0)
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(HasError=0:$$$Text("Done"),1:$$$Text("ERROR"))
Done
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW
	Quit	
Trap
	Set $ZT=""	
	Do ..LogMsg($ZE,"ERROR")
	 Goto Done
}

/// Create One Link Table at a time
ClassMethod CreateOneLinkTable(dsnname As %String, schemaname As %String, tname As %String, primarykeys As %String, newclassname As %String, newtablename As %String, ByRef pParms As %String, ByRef tItems As %String, tIsMulti As %Boolean, ByRef HasError As %Boolean)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set MaxLength = $$$MAXCLASSNAMELENGTH

	Do {	
		Set newschemaname = newtablename
		Set fakeschema = ..ReverseSchema(schemaname)
		If tIsMulti {
			Set newclassname = newschemaname _ "." _ tname
			Set newtablename = tname
		} Else {
			If newclassname = "" {
				if fakeschema = ""!($c(0)) set newclassname = tname
				else  set newclassname = schemaname_"."_tname
			}
			If newtablename = "" set newtablename = tname
		}
		
     	// Get selected column name 	 	
	    Set total = ..GetProperties(dsnname,fakeschema,tname,.colnames,.Fields)

		If tIsMulti {
	 	 	Set tCol = $O(colnames(0))
 	 	} Else {
        	Set tCol = 1
 	 	}
 	 	Set TotalColumns = pParms("TotalColumns")
    	While tCol '= "" {
	     	// original column name
	 		If tIsMulti {
		 		Set column = colnames(tCol)
		 		Set newPropname = column
		 		Set readonly = 0
 		 		Set nullable = $P($g(Fields(column)),"^",4)
 		 		Set sqlcolumnnumber = $P($g(Fields(column)),"^",5)
      			Set selected(tCol) = column_"^"_newPropname_"^"_$P($g(Fields(column)),"^",1,3)_"^"_$g(newColname)_"^"_readonly_"^"_nullable_"^"_sqlcolumnnumber_"^"_$P($g(Fields(column)),"^",6)
	 			Set tCol = $O(colnames(tCol))
	 		} Else {
 		 		Set column = tItems("Columns",tCol)
 		 		Set newPropname = tItems(tCol,"newPropname")
 		 		Set newColName = tItems(tCol,"newColName")
 		 		Set readonly = tItems(tCol,"readonly") 				 		
 		 		Set nullable = $P($g(Fields(column)),"^",4)
 		 		Set sqlcolumnnumber = $P($g(Fields(column)),"^",5)
	      		Set selected(tCol) = column_"^"_newPropname_"^"_$P($g(Fields(column)),"^",1,3)_"^"_$g(newColName)_"^"_readonly_"^"_nullable_"^"_sqlcolumnnumber_"^"_$P($g(Fields(column)),"^",6)
			 	If tCol = pParms("TotalColumns") Set tCol = ""
			 	Else  Set tCol = tCol + 1
			 	
	 		}
     	}
        If ##class(%SQL.Manager.API).SupportDelimitedIdentifiers() = 1,$e(newtablename)'="""" {
     		set tablename = """"_newtablename_""""_"^"_$E(newclassname,1,MaxLength)
     	} Else {
        	Set tablename = newtablename_"^"_$E(newclassname,1,MaxLength)
     	}
	 	Set column = "",cols = ""
	 	For  Set column=$o(selected(column)) q:column=""  set cols=$s(cols="":"",1:cols_"@")_selected(column)
	 	if fakeschema = "" Set extname = tname
	 	else  Set extname = schemaname_"."_tname

     	Set tobj = ##class(%SQL.Manager.API).%New()
     	Set status = tobj.CreateLinkTable(dsnname,tablename,cols,primarykeys,extname)
     	If $$$ISERR(status) {
			Do ..LogMsg(tname_": "_$System.Status.GetErrorText(status))
			Set HasError = 1
     	}
     	Kill tobj 
	} While(0)
Done
	Quit	
Trap
	Set $ZT=""
	Do ..LogMsg($ZE,"ERROR")
	Set HasError = 1
	Goto Done
}

/// Create Link Procedure Process Start
ClassMethod CreateLinkProcedure(DataSource As %String, SchemaName As %String, ByRef pParms As %String, ByRef tItems As %String)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set HasError = 0
	Do {
  		Set EventDesc = "Link Procedure"
		Set EventData = ""
		Set p1 = ""
		For  Set p1 = $O(pParms(p1)) Quit:p1=""  Set EventData = EventData_p1_": "_pParms(p1)_$$$CRLF
		Set EventData = EventData_"Procedures: "_$$$CRLF
		For  Set p1 = $O(tItems("Tables",p1)) Quit:p1=""  Set EventData = EventData_p1_": "_$G(tItems("Tables",p1))_$$$CRLF				
		$$$SMPAuditChange
		Set tIsMulti = (pParms("TotalTables") > 1)
		Set i = $O(tItems("Tables",""))
		While i '= "" {
			Set tname = tItems("Tables",i)
    		set newpackagename = $G(pParms("NewTableName"))
			Do ..CreateOneLinkProc(DataSource,SchemaName,tname,newpackagename,.pParms,tIsMulti,.HasError)
			Set i = $O(tItems("Tables",i))
		}
	} While(0)
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(HasError=0:$$$Text("Done"),1:$$$Text("ERROR"))
Done
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW
	Quit	
Trap
	Set $ZT=""	
	Do ..LogMsg($ZE,"ERROR")
	Goto Done
}

/// Create One Link Process at a time
ClassMethod CreateOneLinkProc(dsnname As %String, schemaname As %String, tname As %String, newschemaname As %String, ByRef pParms As %String, tIsMulti As %Boolean, ByRef HasError As %Boolean)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set MaxLength = $$$MAXCLASSNAMELENGTH
	Do {
		Set tDefault = $TR(tname,"_","")
		Set newschemaname = $TR(newschemaname,"_","")
		If tIsMulti {
			Set newtname = $zstrip(tname,"*PC")  //Strip punctuation characters, including blank spaces, and control characters
			Set newclassname = newtname
			Set procedurename = newtname
			Set methodname = newtname
			Set description = ""
		} Else {
			Set newclassname = $G(pParms("NewClassName"), tDefault)
			Set procedurename = $G(pParms("ProcedureName"), tname)
			Set methodname = $G(pParms("MethodName"), tDefault)
			Set description = $G(pParms("Description"))
		}
		Set tschema = ..ReverseSchema(schemaname)
		Do getFlags^%apiGTW(dsnname,.f,.isJ)
     	Set tobj = ##class(%SQL.Manager.API).%New()
     	If isJ Set status = tobj.CreateLinkProcJ(dsnname,tschema,tname,$E(newclassname,1,MaxLength),$E(newschemaname,1,MaxLength),$E(procedurename,1,MaxLength),$E(methodname,1,MaxLength),description)
		Else  Set status = tobj.CreateLinkProc(dsnname,tschema,tname,$E(newclassname,1,MaxLength),$E(newschemaname,1,MaxLength),$E(procedurename,1,MaxLength),$E(methodname,1,MaxLength),description)
     	If $$$ISERR(status) {
			Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML"))
			Set HasError = 1
     	} 
     	Kill tobj
	} While(0)
Done
	Quit	
Trap
	Set $ZT=""	
	Do ..LogMsg($ZE,"ERROR")
	Set HasError = 1
	Goto Done
}

/// Start Data Migration process
ClassMethod CreateDataMigration(DataSource As %String, SchemaName As %String, ByRef pParms As %String, ByRef tItems As %String)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set msgERROR = $$$Text("ERROR")
	Set HasError = 0
	Do {		
    	Set EventDesc = "Data Migration"
		Set EventData = ""
		Set p1 = ""
		For  Set p1 = $O(pParms(p1)) Quit:p1=""  Set EventData = EventData_p1_": "_pParms(p1)_$$$CRLF
		For  Set p1 = $O(tItems("Tables",p1)) Quit:p1=""  Do
		. Set EventData = EventData_p1_": "_$G(tItems("Tables",p1))_" ("_$G(tItems(p1,"TType"))_") schema name: "_$G(tItems(p1,"newSchema"))_ " copyDef: "_$G(tItems(p1,"copyDef"))_ " copyData: "_$G(tItems(p1,"copyData"))_$$$CRLF				
		$$$SMPAuditChange
 		Set username = $Username
		If username = "" Do ..LogMsg($$$TextHTML("Username unknown. Unable to proceed."),msgERROR) Quit
     	// have to convert the dsnname to ODBC name
     	set gateway = ##class(%SQLConnection).NameIndexOpen(DataSource)
     	if gateway = "" {
	     	Set tmsg = $$$TextHTML("Unexpected error: Please verify that the data source exists.")
	     	Do ..LogMsg(tmsg,msgERROR)
	     	Quit
     	}
		
       //ODBC DSN name
     	set odsnname = gateway.Name
     	set isJDBC = gateway.isJDBC
     	set importobj = ##class(%SQL.Migration.Import).%New()
     	set sta = importobj.Connect(odsnname, username, isJDBC)
		If sta '= 1 {
			Set tmsg = $$$FormatText($$$Text("Unable to connect %1"),DataSource)_"("_odsnname_")"
			Set tmsg = tmsg _ $$$FormatText($$$Text(" username = %1"),username)_$c(13,10)_$System.Status.GetErrorText(sta)
			Do ..LogMsg($ZCVT(tmsg,"O","HTML"),msgERROR)
			Quit
		}
		#; YSD1997 - if not set, then use the defaults 
		Set importobj.NoCheck = $G(pParms("NoCheck"),1)
		Set importobj.DeferIndices = $G(pParms("DeferIndices"),1)
		Set importobj.NoTrigger = $G(pParms("NoTrigger"),0)
		Set importobj.NoJournal = $G(pParms("NoJournal"),0)
		Set importobj.DeleteExistingData = $G(pParms("DeleteExistingData"),1)
		Set importobj.MaxErrors = $G(pParms("MaxErrors"),30)
		
		//Handle journaling here
		If importobj.NoJournal DO DISABLE^%NOJRN
		
		// If new schema name is not the same as the source schema name, build owner map first
		Set i = $O(tItems("Tables",""))
		While i '= "" {
			If SchemaName '= $G(tItems(i,"newSchema")) {
				Do importobj.AddOwnerMap(SchemaName, tItems(i,"newSchema"))
			}
			Set i = $O(tItems("Tables",i))
		}
		// Loop through selected tables now
    	// Copy Table Def first 
		Set i = $O(tItems("Tables",""))
		While i '= "" {
         	If tItems(i,"TType") [ "TABLE", $G(tItems(i,"copyDef")) '= "" {
	         	Set tname = tItems("Tables",i)
         		set status = importobj.CopyTableStruct(SchemaName,tname)
         		If status '= 1 Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML")) Set HasError = 1
         	}
			Set i = $O(tItems("Tables",i))
		}
		// Copy foreign keys second
		Set i = $O(tItems("Tables",""))
		While i '= "" {
	        If tItems(i,"TType") [ "TABLE", $G(tItems(i,"copyDef")) '= "" {
	         	Set tname = tItems("Tables",i)
         		if isJDBC { set status = importobj.CopyTableFKeysJ(SchemaName,tname) }
         		else { set status = importobj.CopyTableFKeys(SchemaName,tname) }
         		If status '= 1 Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML")) Set HasError = 1
         	}
			Set i = $O(tItems("Tables",i))
		}
	
     	// Copy Data finally
		Set i = $O(tItems("Tables",""))
		While i '= "" {
         	If tItems(i,"TType") [ "TABLE", tItems(i,"copyData") '= "" {
	         	Set tname = tItems("Tables",i)
         		if isJDBC { set status = importobj.CopyDataJ(SchemaName,tname) }
         		else { set status = importobj.CopyData(SchemaName,tname) }
         		If status '= 1 Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML")) Set HasError = 1
         	}
			Set i = $O(tItems("Tables",i))
		}

      // Process views now. First drop view
		Set i = $O(tItems("Tables",""))
		While i '= "" {
	        If tItems(i,"TType") = "VIEW" {
	         	Set tname = tItems("Tables",i)
	         	Set newschema = $G(tItems(i,"newSchema"),SchemaName)
         		set status = importobj.DropView(newschema,tname)
         		If status '= 1 Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML")) Set HasError = 1
         	}
			Set i = $O(tItems("Tables",i))
		}

     // Second copy view
		Set i = $O(tItems("Tables",""))
		While i '= "" {
	        If tItems(i,"TType") = "VIEW" {
	         	Set tname = tItems("Tables",i)
	         	Set newschema = tItems(i,"newSchema")
	         	//PYD106+ ;Call CopyView with Original Schema. New Schema name has been passed through AddOwnerMap()
	         	//Set newschema = $li(pParms("newSchema"),i)
	         	//If newschema = "" Set newschema = SchemaName
         		//set status = importobj.CopyView(newschema,tname)
         		//PYD106=
         		if isJDBC { set status = importobj.CopyViewJ(SchemaName,tname) }
         		else { set status = importobj.CopyView(SchemaName,tname) }
         		//PYD106-
         		If status '= 1 Do ..LogMsg(tname_": "_$ZCVT($System.Status.GetErrorText(status),"O","HTML")) Set HasError = 1
         	}
			Set i = $O(tItems("Tables",i))
		}
 	
      	// Tune Table after migration
      	If +$G(pParms("TuneTable"),1) = 1 {
			Set SupportDelimitedIdentifiers = ##class(%SQL.Manager.API).SupportDelimitedIdentifiers()
			Set i = $O(tItems("Tables",""))
			While i '= "" {
	         	If tItems(i,"TType") [ "TABLE" {
	         		Set tname = tItems("Tables",i)
					Set newschema = $G(tItems(i,"newSchema"),SchemaName)
			        If SupportDelimitedIdentifiers = 1,$e(tname)'="""" {
			     		set tablename = """"_newschema_""""_"."_tname
			     	} Else {
			        	Set tablename = newschema_"."_tname
			     	}			
					Do $System.SQL.TuneTable(tablename,0,0,.err,0,0)
	         		If $G(err) '= "" Do ..LogMsg(tablename_": "_$ZCVT(err,"O","HTML")) Set HasError = 1
	         	}
				Set i = $O(tItems("Tables",i))
			}
      	}
 	 	if importobj.ErrorCount() > 0 {
		 	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = msgERROR
		 	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog") = +$G(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog")) + importobj.ErrorCount()
		 	Set i = +$O(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",""),-1)
		 	Set j = ""
		 	//PYD107+
		 	//For  Set j = $O(^IRIS.TempSQL($J,"err",j)) Quit:j=""  Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",i+j)=^IRIS.TempSQL($J,"err",j)
		 	//PYD107=
		 	For  Set j = $O(^IRIS.TempSQL($J,"err",j)) Quit:j=""  Set ta=^IRIS.TempSQL($J,"err",j),^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",i+j)=$lb($lg(ta,1),$lg(ta,2),$lg(ta,4)_"."_$lg(ta,5)_":"_$lg(ta,3),$lg(ta,6))
		 	//PYD107-
	 	}
     do importobj.Disconnect()
	 Kill importobj
	 Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(HasError=0:$$$Text("Done"),1:msgERROR)
	} While(0)
Done
	//In case we turned it off...
	DO ENABLE^%NOJRN
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW	
	Quit	
Trap
	Set $ZT=""
	Do ..LogMsg($ZCVT($ZE,"O","HTML"),$$$Text("ERROR"))
	Goto Done
}

/// Return primary keys as a string delimited by commas
ClassMethod GetPrimaryKeys(dsnname As %String, schema As %String, tname As %String) As %String
{
	set tschema = ..ReverseSchema(schema)
	s pfx=""
	do getFlags^%apiGTW(dsnname,.f,.isJ)
	if isJ set pfx="J"

    set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLPrimaryKeys"_pfx)
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.tschema)
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.tname)
	do rs.Execute(dsnname,tschema_"."_tname)
	set keys = ""
	while rs.Next() {
		set colname = rs.Data("COLUMN_NAME")
		if keys = "" set keys = colname
		else  set keys = keys_","_colname
	}
	Kill rs
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW	
	Quit keys
}

/// Get Link Table Properties
ClassMethod GetProperties(dsnname As %String, schema As %String, table As %String, ByRef colnames As %String, ByRef Fields As %String) As %Integer
{
	set cnt = 1
	s pfx=""
	do getFlags^%apiGTW(dsnname,.f,.isJ)
	if isJ set pfx="J"
	set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLFields"_pfx)
	do rs.Execute(dsnname,table,schema)
	while rs.Next() {
		set column = rs.Data("COLUMN_NAME")
	  	set colnames(cnt) = column
	  	set Fields(column) = rs.Data("DATATYPE")_"^"_+rs.Data("COLUMN_SIZE")_"^"_rs.Data("DECIMAL_DIGITS")_"^"_rs.Data("NULLABLE")_"^"_rs.Data("SQLCOLUMNNUMBER")_"^"_rs.Data("DATATYPE_NAME")
		set cnt = cnt + 1
	}
	Kill rs
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW	
	quit cnt
}

/// Return null or empty for no schema or empty schema names
ClassMethod ReverseSchema(schema As %String) As %String
{
	if schema = "[null schema]" quit ""
	if schema = "[empty schema]" quit $c(0)
	if schema = "[no schema]" quit ""
	quit schema
}

/// Log msg into ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorCount") and ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
ClassMethod LogMsg(Msg As %String, ERROR As %String = "")
{
	Set ErrorCount = $O(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",""),-1) + 1
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog") = ErrorCount
	Set $li(ErrMsg,1) = $S(ERROR="":$$$TextHTML("Msg"),1:ERROR)
	Set $li(ErrMsg,2) = "0"
	Set $li(ErrMsg,3) = Msg
	Set $li(ErrMsg,4) = ErrorCount
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",ErrorCount) = ErrMsg
	If ERROR '= "" Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = ERROR
}

/// Validate column name and return unique and valid name.
ClassMethod ValidateColName(class, fldname) As %String
{
	// following code copied from %apiDDL	
	#DEFINE MAXOBJNAMELENGTH $s($$$MAXNAMELENGTH<96:$$$MAXNAMELENGTH,1:96)
	Set propname=$tr(fldname,$$$GetIdTrxFrom,$$$GetIdTrxTo),propname=$e($e("n",$e(propname)?1n)_propname,1,$$$MAXOBJNAMELENGTH)
	If $$$editMemberDefined(class,$$$cCLASSproperty,propname) Set:$Length(propname)=1 propname = propname _ " " f i=48:1:57,65:1:90,97:1:122 s $e(propname,$l(propname))=$c(i) q:'$$$editMemberDefined(class,$$$cCLASSproperty,propname)
	If propname'=fldname $$$editMemberKeySet(class,$$$cCLASSproperty,propname,$$$cPROPsqlfieldname,fldname)
	$$$editMemberKeySet(class,$$$cCLASSproperty,propname,$$$cPROPcollection,"")
	Quit propname
}

}
