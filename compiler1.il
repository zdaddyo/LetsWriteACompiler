.assembly extern mscorlib {}
.assembly compiler1 {}

.method static void compiler1()
{
	.entrypoint
	.maxstack 3
   
	.locals init (		//we need a stream reader, writer and a string to hold each line read by sr
		[0] class [mscorlib]System.IO.StreamReader sr,
		[1] class [mscorlib]System.IO.StreamWriter sw,
		[2] string line
	)
   
	ldstr "C:/Temp/test.bas"	//we are being lazy here by hard coding test.bas
	newobj instance void [mscorlib]System.IO.StreamReader::.ctor(string)		//create new StreamReader
	stloc sr
	
	ldstr "C:/Temp/testoutput.il"	//once again lazy
	ldc.i4.0			//we want to overwrite the file
	newobj instance void [mscorlib]System.IO.StreamWriter::.ctor(string,bool)	//create new StreamWriter
	stloc sw
	
	ldloc sw		//oh, by the way we are emitting the initialization of the program
	call void InitializeProgram(class [mscorlib]System.IO.StreamWriter)
	
	_READLOOP:
	
	ldloc sr		//push StreamReader onto stack and read a line
	callvirt instance string [mscorlib]System.IO.TextReader::ReadLine()
	dup			//copy line read onto stack
	stloc line		//copy duplicate line into variable "line"
	
	ldnull
	ceq
	ldc.i4.1		//compare line to null and branch to _LOOPFINISHED if "line" is null
	beq _LOOPFINISHED
	
	ldloc line		//push "line" onto stack and write to console
	call void [mscorlib]System.Console::WriteLine(string)

	ldloc sw
	ldstr "nop"		//emit a "no operation" for each line
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)

	br.s _READLOOP		//loop back to read the next line
	
	_LOOPFINISHED:

	ldloc sw
	call void FinishProgram(class [mscorlib]System.IO.StreamWriter)
	
	ldloc sr		//close reader and writer
	callvirt instance void [mscorlib]System.IO.TextReader::Close()
	
	ldloc sw
	callvirt instance void [mscorlib]System.IO.TextWriter::Close()
	ret
}

//we initialize our assembly program by setting up the system library and naming our program assembly
//as of now it does nothing but return
.method private static void InitializeProgram(class [mscorlib]System.IO.StreamWriter)
{
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
}

//now finish the main method
.method private static void FinishProgram(class [mscorlib]System.IO.StreamWriter)
{
	ldarg.0
	ldstr "ret"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
	
	ldarg.0
	ldstr "}"
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
}
