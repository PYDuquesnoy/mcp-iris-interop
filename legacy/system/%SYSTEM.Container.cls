/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// The <class>%SYSTEM.Container</class> class provides an interface for managing
/// container functions.<br>
/// 
/// <p>You can use it via the special <b>$SYSTEM</b> object:<br>
/// <p>
/// <p>You can call help to get a list of all entrypoints:<br>
/// <p>
/// Do $SYSTEM.Container.Help()
Class %SYSTEM.Container Extends Help [ Abstract, System = 4 ]
{

/// Returns whether or not this instance has been deployed with Durable %SYS.
ClassMethod IsDeployed() As %Integer
{
}

}
