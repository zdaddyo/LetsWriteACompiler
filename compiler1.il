.assembly extern mscorlib {}
.assembly compiler1 {}

.method static void compiler1()
{
  .entrypoint
	.maxstack 3
   
	.locals init (
		[0] class [mscorlib]System.IO.StreamReader sr,
		[1] class [mscorlib]System.IO.StreamWriter sw,
		[2] string line
	)
   
	ldstr "C:/Temp/test.bas"		//we are being lazy here by just reading test.bas
	newobj instance void [mscorlib]System.IO.StreamReader::.ctor(string)	//creating a new StreamReader
	stloc sr
	
	ldstr "C:/Temp/testoutput.il"	//once again lazy
	newobj instance void [mscorlib]System.IO.StreamWriter::.ctor(string)	//creating a new StreamWriter
	stloc sw
	
	_READLOOP:
	
	ldloc sr		//push the StreamReader onto the stack and read a line
	callvirt instance string [mscorlib]System.IO.TextReader::ReadLine()
	dup				//copy the line read onto the stack
	stloc line		//copy the duplicate line into "line"
	
	ldnull
	ceq
	ldc.i4.1		//compare the line to null and branch to _LOOPFINISHED if "line" is null
	beq _LOOPFINISHED
	
	ldloc line		//push "line" onto the stack and write it to the console
	call void [mscorlib]System.Console::WriteLine(string)
	
	ldloc sw		//oh, by the way we are emitting the initialization of the program
	call void InitializeProgram(class [mscorlib]System.IO.StreamWriter)
	
	br.s _READLOOP	//loop back to read the next line
	
	_LOOPFINISHED:
	
	ldloc sr		//close the reader and writer
	callvirt instance void [mscorlib]System.IO.TextReader::Close()
	
	ldloc sw
	callvirt instance void [mscorlib]System.IO.TextWriter::Close()
	ret
}

//we initialize our assembly program...
.method private static void InitializeProgram(class [mscorlib]System.IO.StreamWriter)
{
	ldarg.0			//push the writer onto the stack and write the string
	ldstr ".assembly extern mscorlib {}";
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
	
	ldarg.0
	ldstr ".assembly testoutput {}";
	callvirt instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
}
