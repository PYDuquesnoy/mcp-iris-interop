/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Operation to write RecordMap batch data out to files on an FTP server.
/// Note that this operation uses a temporary file while writing individual records to the batch,
/// and transmits the temporary file when the batch output is complete.
Class EnsLib.RecordMap.Operation.BatchFTPOperation Extends EnsLib.RecordMap.Operation.BatchFileOperation [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

}
