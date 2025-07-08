/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Internal class not for customer use.
/// Shell for $system.Rtn system implemented class.
Class %SYSTEM.Rtn
{

/// Return internal pointer into routine buffer for the routine/class back a specific number
/// of <var>frame</var> levels
ClassMethod GetCurrent(frame As %Integer) As %String
{
}

/// Call the <var>label</var> in the routine/class referenced by the <var>pointer</var> into the
/// routine buffer from <method>GetCurrent</method> passing in any additional arguments in 'args...'.
ClassMethod Invoke(pointer As %Binary, label As %String, args...)
{
}

}
