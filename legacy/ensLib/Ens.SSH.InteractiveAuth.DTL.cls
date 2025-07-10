/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.SSH.InteractiveAuth.DTL Extends Ens.DataTransformDTL [ DependsOn = (Ens.SSH.InteractiveAuth.Challenge, Ens.SSH.InteractiveAuth.Response), System = 4 ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='Ens.SSH.InteractiveAuth.Challenge' targetClass='Ens.SSH.InteractiveAuth.Response' create='new' language='objectscript' >
<assign value='1' property='target.UseCredentialsPasswordAt' action='set' />
</transform>
}

}
