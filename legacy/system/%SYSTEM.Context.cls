/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Internal class not for customer use.
/// Shell for $system.Context system implemented class.
/// <p>This provides a singleton oref per job used internally to store partition wide data.
/// For example '$system.Context.ABC()' will instanciate an instance of the class %SYSTEM.Context.ABC
/// and return this oref, it will keep this oref open in this process so the next time $system.Context.ABC()
/// is referenced it will return the previously opened singleton oref.<p>
/// These can be cleared using the call 'Do $System.CLS.ClearContext("*")' to remove all context objects or
/// 'Do $System.CLS.ClearContext("ABC")' to clear just the $system.Context.ABC() one.
Class %SYSTEM.Context
{

}
