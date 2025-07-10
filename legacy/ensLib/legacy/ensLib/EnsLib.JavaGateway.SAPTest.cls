/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JavaGateway.SAPTest Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Note: in order to run this sample, you need to have Demo.SAP.* classes
ClassMethod GetCustomers(KUNNR As %String, NAME1 As %String, port As %Integer = 22222, host As %String = "127.0.0.1", jcoJar As %String = "") As %ObjectHandle
{
	Set %objlasterror="",$ZT="Error"
	Do ..Connect(jcoJar,port,host,.gateway,.connection,.repository)
	Set function=..CreateFunction(repository,"RFC_CUSTOMER_GET") If function="" Quit
	
   	Set input=function.getImportParameterList()
	Do input.setValue(NAME1,"NAME1")
	Do input.setValue(KUNNR,"KUNNR")
	Do connection.execute(function)
	
	Set customers=##class(Demo.SAP.RFC.RFCCUSTOMERGET.Response).%New()

	Set table=function.getTableParameterList().getTable("CUSTOMER_T")
	for i=0:1:table.getNumRows() {
		Do table.setRow(i)
		Set customer=##class(Demo.SAP.RFC.BRFCKNA1).%New()
		Set customer.KUNNR=table.getString("KUNNR")
		Set customer.ANRED=table.getString("ANRED")
		Set customer.NAME1=table.getString("NAME1")
		Set customer.PFACH=table.getString("PFACH")
		Set customer.STRAS=table.getString("STRAS")
		Set customer.PSTLZ=table.getString("PSTLZ")
		Set customer.ORT01=table.getString("ORT01")
		Set customer.TELF1=table.getString("TELF1")
		Set customer.TELFX=table.getString("TELFX")
		Do customers.CUSTOMERT.Insert(customer)
	}
	Do connection.disconnect()
    Do gateway.%Disconnect()
	Quit customers
Error 	
	Do ..PrintError()
}

ClassMethod PrintCustomers(KUNNR As %String, NAME1 As %String, port As %Integer = 22222, host As %String = "127.0.0.1", jcoJar As %String = "")
{
	Set cust=..GetCustomers(KUNNR,NAME1,port,host,jcoJar)
	Set customers=cust.CUSTOMERT
	For i=1:1:customers.Count() {
		Set customer=customers.GetAt(i)
		Write customer.NAME1_"    "_customer.STRAS_"    "_customer.TELF1,!
	}
}

ClassMethod CompanyCodeBAPI(port As %Integer, host As %String = "127.0.0.1", jcoJar As %String = "")
{
	Set %objlasterror="",$ZT="Error"
	Do ..Connect(jcoJar,port,host,.gateway,.connection,.repository)
	Set function=..CreateFunction(repository,"BAPI_COMPANYCODE_GETLIST")
	If function="" Quit
	Do connection.execute(function)

	Set returnStructure=function.getExportParameterList().getStructure("RETURN")
	if (('returnStructure.getString("TYPE")="") ||
		(returnStructure.getString("TYPE")="S")) {
		Write returnStructure.getString("MESSAGE"),!
		Quit
	}
	Set codes=function.getTableParameterList().getTable("COMPANYCODE_LIST")
	for i=0:1:codes.getNumRows() {
		Do codes.setRow(i)
		Write codes.getString("COMP_CODE")_" "_codes.getString("COMP_NAME"),!
	}
	Do codes.firstRow()
	for i=0:1:codes.getNumRows() {
		Do codes.nextRow()
		Set function=..CreateFunction(repository,"BAPI_COMPANYCODE_GETDETAIL")
		If function="" Quit
	   	Do function.getImportParameterList().setValue(codes.getString("COMP_CODE"),"COMPANYCODEID")
	   	Do function.getExportParameterList().setActive(0,"COMPANYCODE_ADDRESS")
	   	Do connection.execute(function)
	   	Set returnStructure=function.getExportParameterList().getStructure("RETURN")
	   	if (('returnStructure.getString("TYPE")="") ||
			(returnStructure.getString("TYPE")="S") ||
			(returnStructure.getString("TYPE")="W")) {
		    Write returnStructure.getString("MESSAGE"),!
		}
	}
	Set detail = function.getExportParameterList().getStructure("COMPANYCODE_DETAIL")
	Write detail.getString("COMP_CODE")_detail.getString("COUNTRY")_" "_detail.getString("CITY")
	Do connection.disconnect()
    Do gateway.%Disconnect()
	Quit
Error Do ..PrintError()
	Quit
}

ClassMethod HelloWorldBAPI(port As %Integer, host As %String = "127.0.0.1", jcoJar As %String = "")
{
	Set %objlasterror="",$ZT="Error"
	Do ..Connect(jcoJar,port,host,.gateway,.connection,.repository)

	// Print the version of the underlying JCO library
    Write !,"JCO-library Version: "
    Write ##class(com.sap.mw.jco.JCO).getMiddlewareVersion(gateway),!
      
    // Get the attributes of the connection and print them 
    Set attributes=connection.getAttributes()
    //Write "Connection attributes:",!,attributes,!
      
    // Create the input parameter list
    Set input=##class(com.sap.mw.jco.JCO).createParameterList(gateway)

    // Set the first (and only) import parameter
    Do input.appendValue("REQUTEXT",##class(com.sap.mw.jco.JCO).%GetParameter("TYPEuCHAR"),255,"My Hello World BAPI")

    // Create the out parameter list
    Set output=##class(com.sap.mw.jco.JCO).createParameterList(gateway)

    // Specify the parameters types the function will be returning
    Do output.addInfo("ECHOTEXT",##class(com.sap.mw.jco.JCO).%GetParameter("TYPEuCHAR"),255)
    Do output.addInfo("RESPTEXT",##class(com.sap.mw.jco.JCO).%GetParameter("TYPEuCHAR"),255)

    // Call the function
    Do connection.execute("STFC_CONNECTION",input,output)

    // Print the result
    Write !,"Function 'STFC_CONNECTION' returned the following parameters:",!
    For i=0:1:output.getFieldCount()-1 {
        Write "  Name: "_output.getName(i)_" Value: "_output.getString(i),!
    }

    // Close the connection
    Do connection.disconnect()
    Do gateway.%Disconnect()
    Quit
Error Do ..PrintError()
	Quit
}

ClassMethod GetBAPIs(port As %Integer, host As %String = "127.0.0.1", jcoJar As %String = "")
{
	Do ..Connect(jcoJar,port,host,.gateway,.connection,.repository)
	Set bapiList=##class(%Library.ListOfDataTypes).%New()	
	Set function=..CreateFunction(repository,"SWO_QUERY_API_METHODS") If function="" Quit
	Set paramList=function.getTableParameterList()
	if (paramList'="") {
		Do connection.execute(function)
	}
	Set returnTable=paramList.getTable("API_METHODS")
	Set bapis = returnTable.getNumRows()
	Write !,"Total number of BAPIS: "_bapis
	for i=0:1:bapis-1 {
		Do returnTable.setRow(i)
		Do bapiList.Insert(returnTable.getString("FUNCTION"))
		//Write returnTable.getString("DESCRIPT")
		//Write returnTable.getString("METHODNAME")
	}
    Do connection.disconnect()
	for i=0:1:bapis-1 {
		Write "  "_bapiList.GetAt(i),!
	}
    Do gateway.%Disconnect()
	Quit
Error Do ..PrintError()
	Quit
}

ClassMethod Connect(jcoJar As %String, port As %Integer, host As %String = "127.0.0.1", ByRef gateway As EnsLib.JavaGateway.JavaGateway, ByRef connection As %ObjectHandle, ByRef repository As %ObjectHandle)
{
	Set %objlasterror="",$ZT="Error",namespace=$namespace,timeout=2
	Set classPath=##class(%ListOfDataTypes).%New()
	If (jcoJar'="") {
		Do classPath.Insert(jcoJar)
	}
	Set gateway=##class(EnsLib.JavaGateway.JavaGateway).%New()
	Set status=gateway.%Connect(host,port,namespace,timeout,classPath,,,0) If 'status Goto Error

    // Create a client connection to a dedicated R/3 system
    Set connection=##class(com.sap.mw.jco.JCO).createClient(gateway,
    			"800", 				// SAP client
				"IWAY016",  		// userid
				"DONUT36",  		// password
				"EN",				// language
				"172.30.143.13", 	// host name
				"00")				// system number
	Do connection.connect()
	Set repository=##class(com.sap.mw.jco.JCO.Repository).%New(gateway,"Aleks",connection)
Error Do ..PrintError()
	Quit
}

ClassMethod PrintError()
{
	If %objlasterror'="" { Write $system.OBJ.DisplayError(%objlasterror) } Else { Write $ze }
}

/// ClassMethod CreateFunction(repository As com.sap.mw.jco.JCO.Repository, bapiName As %String) As %ObjectHandle
ClassMethod CreateFunction(repository As %ObjectHandle, bapiName As %String) As %ObjectHandle
{
	Set ft=repository.getFunctionTemplate(bapiName)
   	Set function=ft.getFunction()
	if (function="") {
		Write bapiName_" not found in SAP.",!
		Quit ""
	}
	Quit function
}

}
