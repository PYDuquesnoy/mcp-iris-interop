/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Task to backup all databases
Class %SYS.Task.BackupCumulativeDatabaseList Extends (%SYS.Task.Definition, %SYS.Task.BackupSuper) [ Inheritance = right, System = 4 ]
{

Parameter TaskName = "CumuIncrDBList";

}
