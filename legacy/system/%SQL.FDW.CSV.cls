/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occJava

Class %SQL.FDW.CSV Extends %SQL.FDW.Java
{

Parameter JAVACLASS = "com.intersystems.xdbc.gateway.CsvReader";

Method SetUpClassPath()
{
	do ..Gateway.addToPath(##class(%File).NormalizeFilename($SYSTEM.Util.InstallDirectory()_"dev/java/lib/1.8/"_$$$javaUtilsJAR)) // Loader jar has Jackson library already bundled up
}

}
