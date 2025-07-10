/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Operation to write ComplexBatch data out to files on an FTP server.
/// Note that this operation uses a temporary file while writing out the ComplexBatch,
/// and transmits the temporary file when output is complete.
Class EnsLib.RecordMap.Operation.ComplexBatchFTPOperation Extends EnsLib.RecordMap.Operation.ComplexBatchFileOperation [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

}
