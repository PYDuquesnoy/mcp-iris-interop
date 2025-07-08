/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Super class for common Error related methods.
Class %CSP.UI.SQL.Error [ Abstract, System = 4 ]
{

/// Draws error box for object error message. 
ClassMethod DrawErrorBox(tObj)
{
	&html<<div class="ErrorBox">#($ZCONVERT($System.Status.GetErrorText(tObj),"O","HTML"))#</div>>
}

}
