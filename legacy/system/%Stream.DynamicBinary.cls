/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syGluedef, %occStream, %PVA)

/// <class>%Stream.DynamicBinary</class> character stream containing
/// the 8-bit binary bytes of
/// an element of a <class>%DynamicAbstractObject</class>. It is
/// particularly useful for
/// holding the value of a <class>%DynamicAbstractObject</class> element
/// with a byte stream
/// value that would exceed the capacity of an ObjectScript string variable.
/// A <class>%Stream.DynamicBinary</class> object is readonly and it
/// cannot be modified or saved.
/// But it can be copied to any other %Stream class object that does support
/// modification and saving.
/// <p>
/// One way to create a <class>%Stream.DynamicBinary</class>
/// is by making a method call that
/// looks like dao.%Get(key,default,"stream"),
/// dao.%Get(key,default,"stream&lt;base64")
/// or dao.%Get(key,default,"stream&gt;base64")
/// where <var>dao</var> is an object reference
/// to a subclass of <class>%DynamicAbstractObject</class>; and
/// where <var>key</var> is the key name
/// value of an element of a <class>%DynamicObject</class> or the index value of an
/// element of a <class>%DynamicArray</class>.  You can also get a
/// <class>%Stream.DynamicBinary</class> object by calling the
/// %GetNext(.key,.value,.type) 
/// method in one of subclasses of the
/// <class>%Iterator.AbstractIterator</class> class.
/// 
Class %Stream.DynamicBinary Extends %Stream.DynamicCharacter [ ClientDataType = BINARYSTREAM, OdbcType = LONGVARBINARY, System = 2 ]
{

/// This reads from the stream until it finds the
/// <property>LineTerminator</property> and returns a new 
/// <class>%Stream.TmpCharacter</class>
/// stream containing the bytes in the line. If the stream does not contain
/// the line terminator then this can potentially be the
/// entire stream.
Method ReadLineIntoStream(ByRef sc As %Status) As %Stream.Object
{
	Return ##super(.sc)
}

/// Write out <var>len</var> bytes of the stream to the current device
/// starting from the current position. If <var>len</var> is omitted
/// or set to -1 then the <method>OutputToDevice</method> method
/// will write out the entire stream starting at the beginning and then
/// rewind back to the beginning.  If <var>len</var> &gt 0 and we are unable to
/// write <var>len</var>
/// bytes because we reach the end of the stream then we will stop writing
/// and set the <property>AtEnd</property> property to 1.  Otherwise, we will leave
/// the stream positioned after the last byte written to the device.
/// If parameter <var>len</var>
/// is passed by reference and if no error occurs then the number of
/// bytes actually written to the output device will be assigned
/// to <var>len</var>.
/// If zero bytes are written because we are already positioned at the end
/// of the stream then <var>len</var> will be assigned to -1.
/// If an error occurs while writing the device then <var>len</var> will be assigned
/// to -2, an error <type>%Status</type> value will be returned and the stream
/// will rollback to its original position.
Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Return ##super(.len)
}

}
