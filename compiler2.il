.assembly extern mscorlib {}
.assembly compiler2 {}

.method static void compiler2()
{
	.entrypoint
	.maxstack 4
	
	//We need to be able to read the source file and write out the compiled code so we
	//will create a StreamReader and StreamWriter. Initially we are going to be lazy and
	//just hardcode those files as "test.bas" and "testoutput.il". "testoutput.il" will
	//be able to be assembled by ilasm.exe into the .NET executable. We also need to store
	//each line of the source code which we do in the string variable "line". "codeoutput"
	//holds the output we will emit into "testoutput.il".
	.locals init (
		[0] class [mscorlib]System.IO.StreamReader sr,
		[1] class [mscorlib]System.IO.StreamWriter sw,
		[2] string line,
		[3] string codeoutput
	)
   
	ldstr "C:/Temp/test.bas"
	newobj instance void [mscorlib]System.IO.StreamReader::.ctor(string)		//create new StreamReader
	stloc sr

	ldstr "C:/Temp/testoutput.il"
	ldc.i4.0																	//overwrite file
	newobj instance void [mscorlib]System.IO.StreamWriter::.ctor(string,bool)	//create new StreamWriter
	stloc sw
	
	//We are done creating the StreamReader and StreamWriter so now we call
	//InitializeProgram with the StreamWriter parameter so we can emit the
	//initialization of the output file. This includes stuff like .assembly
	//and .entrypoint.
	ldloc sw
	call void InitializeProgram(class [mscorlib]System.IO.StreamWriter)

	//Now we have our main loop where we read the BASIC file line by line and
	//process each line. We read the file until we get a null value which signals
	//that we are at the end of the file.
_READLOOP:

	ldloc sr			//push StreamReader onto stack and read line
	callvirt instance string [mscorlib]System.IO.TextReader::ReadLine()
	dup					//dup line so we can save it and check for null
	stloc line

	ldnull
	ceq
	ldc.i4.1			//compare line to null and branch to _LOOPFINISHED if it is null
	beq _LOOPFINISHED

	ldloc line			//push "line" onto stack and write it to console
	call void [mscorlib]System.Console::WriteLine(string)
	
	ldloc line			//process line, ProcessLine leaves code to emit on stack
	call string ProcessLine(string)
	
	stloc codeoutput	//pop processed string
	ldloc sw
	ldloc codeoutput
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)

	br.s _READLOOP		//read next line

_LOOPFINISHED:
	
	//We've hit the end of the file, so now we need to clean things up by
	//emitting the final bit of code to make sure the program assembles.
	ldloc sw
	call void FinishProgram(class [mscorlib]System.IO.StreamWriter)

	ldloc sr			//close the reader and writer
	callvirt instance void [mscorlib]System.IO.TextReader::Close()

	ldloc sw
	callvirt instance void [mscorlib]System.IO.TextWriter::Close()
	ret
}

//process the input line
.method private static string ProcessLine(string)
{
	.maxstack 3
	
	.locals init (
		[0] string[] linesections,
		[1] string linenumber,
		[2] string command,
		[3] char[] delim,
		[4] string tempstring,
		[5] string returnval
	)
	
	//create the array to split up input line using spaces
	ldc.i4.1
	newarr [mscorlib]System.Char
	stloc.s delim
	
	ldloc.s delim
	ldc.i4.0
	ldc.i4.s 32	//ascii space
	stelem.i2
	ldloc.s delim
	stloc.s delim
	
	ldarg.0
	ldloc delim
	callvirt instance string[] [mscorlib]System.String::Split(char[])
	stloc linesections

	ldloc linesections
	ldc.i4.0
	ldelem.ref
	stloc linenumber
	
	ldloc linesections
	ldc.i4.1
	ldelem.ref
	stloc command
	
	//get the line number and use it as a label with a nop
	ldstr "BAS_"
	ldloc linenumber
	ldstr ": nop\n"
	call string [mscorlib]System.String::Concat(string,string,string)
	stloc returnval
	
	//lets look at the command and work off of that right now
	ldloc command
	ldstr "END"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _ENDCOMMAND
	
	ldloc command
	ldstr "REM"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _REMCOMMAND
	
	ldloc command
	ldstr "GOTO"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _GOTOCOMMAND
	
	ldloc command
	ldstr "PRINT"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _PRINTCOMMAND
	
	ldloc command
	ldstr "LET"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _LETCOMMAND
	
	ldloc command
	ldstr "IF"
	call bool [mscorlib]System.String::op_Equality(string,string)
	brtrue _IFCOMMAND
	
	br _UNKNOWNCOMMAND
	
_ENDCOMMAND:
	ldloc returnval
	ldstr "ret"		//end just returns from the program
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_REMCOMMAND:
	ldloc returnval
	ldstr "//"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	
	//load line onto stack so we can get the rem text 
	//after getting length of linenumber
	ldarg.0
	
	//need length of linenumber plus 5
	ldloc linenumber
	callvirt instance int32[mscorlib]System.String::get_Length()
	ldc.i4.5
	add

	callvirt instance string [mscorlib]System.String::Substring(int32)
	stloc tempstring
	
	ldloc returnval
	ldloc tempstring
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_GOTOCOMMAND:
	ldloc returnval
	ldstr "br BAS_"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	
	ldloc returnval
	ldloc linesections
	ldc.i4.2
	ldelem.ref
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	
	br _ENDPROCESS
	
_PRINTCOMMAND:
	//check to see if the first character is a quote
	ldloc linesections
	ldc.i4.2
	ldelem.ref
	ldc.i4.0
	callvirt instance char [mscorlib]System.String::get_Chars(int32)
	ldc.i4.s 34
	ceq
	brfalse.s _PRINTEXPRESSION
	ldloc returnval
	ldstr "//PRINT COMMAND STRING"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_PRINTEXPRESSION:	
	ldloc returnval
	ldstr "//PRINT COMMAND EXPRESSION"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_LETCOMMAND:
	ldloc returnval
	ldstr "//LET COMMAND"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_IFCOMMAND:
	ldloc returnval
	ldstr "//IF COMMAND"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br _ENDPROCESS
	
_UNKNOWNCOMMAND:
	ldloc returnval
	ldstr "//UNKNOWN COMMAND"
	call string[mscorlib]System.String::Concat(string,string)
	stloc returnval
	br.s _ENDPROCESS
	
_ENDPROCESS:
	ldloc returnval
	ret
}

//we initialize our assembly program by setting up the system library and naming our program assembly
//as of now it does nothing but return
.method private static void InitializeProgram(class [mscorlib]System.IO.StreamWriter)
{
	.maxstack 2
	
	ldarg.0			//push the writer onto the stack and write the string
	ldstr ".assembly extern mscorlib {}"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)

	ldarg.0
	ldstr ".assembly testoutput {}"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)

	ldarg.0
	ldstr ".method static void testoutput() {"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
	
	ldarg.0
	ldstr ".entrypoint"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
	
	ret
}

//now finish the main method
.method private static void FinishProgram(class [mscorlib]System.IO.StreamWriter)
{
	.maxstack 2
	
	ldarg.0
	ldstr "}"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
	
	ret
}
