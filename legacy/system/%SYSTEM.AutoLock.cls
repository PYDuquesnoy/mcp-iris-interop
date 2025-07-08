/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Add a new class which can hold lock references and automatically release them when the oref goes out of scope.
/// This can greatly simplify the locking code and prevent errors if the user forgets to add an error trap to
/// make sure the lock is released in the event of an error.<p>
/// There are two ways to use this, the first uses a macro to get the lock and this lock is released when you leave the current stack frame:
/// <example>#include %systemInclude
/// Function() public {
/// 	$$$AutoLock(^Global,"S",10)  ; Lock ^Global with shared lock and a timeout of 10 seconds
/// 	If '$test Write "Lock failed" Quit
/// 	; Do work here
/// }</example>
/// This will obtain a shared 'S' lock on ^Global with a timeout of 10 seconds and if it fails to get the lock
/// it will write that it failed and exit, otherwise it will hold the lock until after the end of the function
/// where the stack frame is removed. If the work throws an error then even though this routine has no error
/// trapping the lock will still be removed correctly.<p>
/// The alternative form explicitly returns an oref from the lock call so you can manage this oref yourself, for example:
/// <example>#include %systemInclude
/// Function() public {
/// 	Set lock=$system.AutoLock.Lock("^Global","S",10)
/// 	If lock=$$$NULLOREF Write "Lock failed",! Quit
/// 	; Do work
/// }</example>
/// This obtains the same lock but puts the oref into 'lock' local variable, sometimes this can be useful
/// as it can be returned to the caller for it to manage rather than always having the lock removed when you
/// go back from this stack frame as the other method of using this does.
Class %SYSTEM.AutoLock Extends %SystemBase
{

Property Args As %String [ Private ];

Property Lock As %String [ Private ];

Method %OnNew(lock As %String, args As %String = "") As %Status [ Private ]
{
	Set i%Lock=lock,i%Args=args
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	#; In case we have swapped namespace since getting the lock
	If $namespace'=..%OriginalNamespace() New $namespace Set $namespace=..%OriginalNamespace()
	Lock -@i%Lock#i%Args
	Quit $$$OK
}

/// Passed a <var>lock</var> reference and optional <var>args</var> for the lock and optional <var>timeout</var>
/// and it will try to obtain this lock. If it fails then it will return "", but if it worked then it will return
/// an oref which will automatically release the lock when it goes out of scope.
ClassMethod Lock(lock As %String, args As %String = "", timeout As %Integer = 0) As %SYSTEM.AutoLock
{
	Lock +@lock#$translate(args,"IiDd"):timeout
	If $test {
		Quit ..%New(lock,args)
	} Else {
		Quit $$$NULLOREF
	}
}

}
