/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %WebStress.Portal.Application 
Class %WebStress.Portal.Application Extends %ZEN.Portal.Application [ System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "WebStress";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "%25WebStress.Portal.Home.cls";

Parameter DOMAIN = "%WebStress";

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

}
