#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	This is a library containing four namespaces, all with different functions
	related to working with, around, on, or about Dropbox in some way:
	1). The __DROPBOX__ namespace contains functions that are used to interact
		with dropbox and the dropbox itself.

	2). The __DROPBOX__COMM namespace is a sister project that allows scripts
		to communicate with one another through dropbox.
	3). The __DROPBOX__TEST namespace is a namespace filled with functions that
		were used to test functionality of that particular namespace, and so I left
		them there as an example.
	4). The __DROPBOX__COMM__TEST namespace is another namespace whose function is
		the same as the __DROPBOX__TEST namespace.

	Since this project is so big, I had no other option than to separate the
	functions into their own namespaces. I haven't finished writing the general
	help file yet, so any reference needs to be made in accordance with the
	description that is above the function.

	Coding conventions:
		1). I like long identifier names when I have to work on a script over a large
			period of time, so it's easier to read, understand, and pick right off
			where I started after I've stopped coding for awhile. Don't get put off
			by them. Sometimes I'll create a really long identifier, and then create
			a alias of it right below it.

		2). Functions are separated into namespaces, there are actually five
			namespaces: __DROPBOX, __DROPBOX__COMM, __DROPBOX__COMM__TEST,
			__DROPBOX__TEST, and PRIVATE__. They're pretty self explanatory.

		3). When I say "BAD MAGIC" in a comment, error log, and such, that means
			a logical contradiction has occurred and it's probably a bug. Let me
			know what it is.

	Known issues:
		None that I've found after debugging today.

	For best results:
		1). Optimize the size & number of your datagrams accordingly. The
			more sparse files you have, the slower the script will run.

	Tasklist:
		`08/07/12 Alex -> Alex :: Debug more. => Incompl.
		 08/07/12 Alex -> Any  :: Tag all magic numbers => Incompl.
		 08/07/12 Alex -> Any  :: Remote execution => Incomplete
		 08/07/12 Alex -> Any  :: Binary data transmission => Incompl.

#ce
#cs -- Reasoning, justification, and design decisions behind __DROPBOX__COMM__
	Reasoning behind __DROPBOX__COMM & design decisions.:
		1). Reasoning:

			I got very sick and tired of dealing with sockets and networking for
			communication between my scripts. It can be unreliable, uncomfortable
			and unnatural to code in, and took a long time to write, and I didn't
			want to use SOAP or any kind of RESTful oriented architecture, http
			nonsense, or anything of that sort -- I just wanted it to work. I
			thought that I'd have to write my own TCP/IP library that made working
			with networking more comfortable and natural.

			So, while I was writing __DROPBOX, I started to wonder if I could use
			dropbox to communicate with scripts over, but in a very natural way,
			like I would using a pipe, a file, or a "channel" like I would talk
			with people in IRC, then later that day, while I was working on an
			old SCO/UNIX system, I remembered... "everything is a file" and it
			all made a lot of sense:
				"Communicate over networks using files, just like Plan 9, UNIX
				and so on, communicates with."

			... It hit me like a ton of bricks.

			The next step was to think out how it would all work...

		2).  Design Decisions
			The model behind __DROPBOX__COMM() is a subscriber->reciever model
			like you would use a ham radio, but a few more perks that allow
			scripts to communicate with them through. There are several modes of
			communication that follow this model of a ham radio:
				1). Many to Many
					All members can contribute and hear all other members.
				2). Many to One
					All members can contribute, but only one can be listening.
				3). One to One
					One to one connection between one computer and another by
					switching channels.
				4). One to none.

			It started to make more and more sense as I went along. but how was
			I going to enable the natural model of reading, writing, and subscribing
			to a channel and working with this data using just a file system, and no
			packets? I didn't know right away, so I mapped out the functions that I'd
			need to implement conforming to the interface of channel based communication.

			Bingo.

			One of the first things that I do when I go to write a script, is to figure
			out what functions I need and start ordering them. knew that I'd need several
			main functions:
				__CREATE_CHANNEL()
				__REMOVE_CHANNEL()
				__WRITE()
				__READ()

			... And then the problems began:
			a). File based communication
				One of the trade offs with using files to send messages through
				is that I have to sacrifice speed for the sake of ease, I wanted
				to be able to gloat about reliability, so I set out with the purpose
				of making this as reliable as possible.

				There are a couple of problems with that, especially when dealing
				with dropbox. Speed, synchronization, file locking, and such all
				come into the equation, and have greatly influenced my design
				decisions.

				This library has some serious limitations in terms of speed. Only
				one datagram can be sent a second, and the reasoning behind that
				is two fold:
					i). I didn't want to have to store a list of which datagrams
						had been read or missed, nor did I want to have to open
						each and every file and perform checksums or do any of
						that. So I decided to use a time variable as a name.

						And so I decided on using epoch time for the file name. It makes
						it very easy to deal with conflicts when communicating over
						dropbox, because when a conflict occurs, dropbox will
						automatically rename it and append the (*conflicted*).ext
						to the file name. Which is great, because it won't interfere
						with the program, and if the extension is the same, that means
						that both files were submitted at the same time and it doesn't
						really matter if you recieve them in order or not. However, if
						multiple sequential writes are performed in the same second
						, then the files will get clobbered. So we delay a write by
						1 second.

						I also found out that if I use unix epoch time, I can process
						the datagrams in order, sort them, manipulate them, and even
						store the name of the file in a configuration file, so if I
						decide to leave a few datagrams in a channel, when the subscriber
						comes back online, they can recieve the messages.

						...You can't do that with TCP/IP.
					ii). I don't trust that the system timer can readily
						 measure time into the millisecond.

						 I didn't want the computer to have to read over many files
						 it had already read before getting to the ones it had not
						 read, and so, what I've done is to store the filename
						 of the last read file (which is in unix epoch time of course)
						 in a .ini file with the computers name and listener function
						 and read that and only read files that are newer than that
						 date. If I use a millisecond timer, there's a greater chance
						 that datagrams can get lost.

			b). Threading
				1). AutoIt doesn't have threads, and if I wanted to use a true
					channel->subscriber model, then I'd need to use them.

					I settled for using AdLibRegister, but the problem with
					AdLibRegister and AdLibUnregister is that the function,
					its parameters, and such will need to change, dynamically.

					And so so I heavily abused Assign, Eval, and Call.

			c). External libraries
				They're a pain, and so I used my own.

			d). Others
				This project has taken a lot of code and a lot of time to
				write, and so there's some difficulty in maintaining it
				because it's so large. I want to be able to reuse this
				over and over again, and so I've taken time and a great
				deal of deliberation in writing this, so I'm considering
				situations where I want to be notified.

			how am I going to identify which files
			to read, or how I'm going to format the datagrams.
			How am I going to deal with threads, when autoit has none
			how am I going to allow the user direct interaction with the
			files while not wanting them to have to look into this script
			before they start writing it?

		3). Further justification
			a). If I need to justify anything else or I have missed anything
				please let me know.

#ce ----------------------------------------------------------------------------
#include-once
#include <Process.au3>
#include <Misc.au3>
#include <Date.au3>
#include <Array.au3>
#include <File.au3>

;; Configuration Options

	; If the logging is too verbose
	; and you just want it to shutup,
	; set this to true.
	Global $__DROPBOX__bHUSH_CERR = False
	Func __DROPBOX__HUSH_CERR()
		$__DROPBOX__bHUSH_CERR = True
	EndFunc
	Func __DROPBOX__UNHUSH_CERR()
		$__DROPBOX__bHUSH_CERR = False
	EndFunc

	; This is the interval to wait for dropbox to
	; appear before timing out.
	Global $__DROPBOX__iPROCESSWAIT_INTERVAL = 1

;;  __COMM__ namespace configuration options
	; This is the interval to wait to poll the channels
	Global $__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD = 250

	; This is the interval to wait between subscriber notifications
	Global $__DROPBOX__iINTERVAL_BETWEEN_SUBSCRIBER_NOTIFY = 0

	; This variable is pretty self explanatory.
	Global $__DROPBOX__iDEFAULT_MAX_REGISTERED_SUBSCRIBERS = 1024
;; End configutation options.

;; Globals - Don't touch
	Global $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = 0
	Global $PRIVATE__DROPBOX__COMM__NUMBER_DIGITS_IN_EPOCH _
		   = StringLen(__DROPBOX__COMM__EPOCH())

	; Contains a pipe delimited string containing
	; function names to call. (Used in __PARSE_SUBSCRIBERS
	; and __SUBSCRIBE and UNSUBSCRIBE)
	Global $__DROPBOX__szREGISTERED_FUNCTIONS = ""
;; End globals
; __DROPBOX__COMM__TEST_CREATE_REMOVE_CHANNEL()
;Sleep(10000)
;ConsoleWrite(@LF)

;__DROPBOX__COMM__TEST_WRITE_READ()
;Sleep(10000)
;ConsoleWrite(@LF)

;__DROPBOX__COMM__TEST_SUBSCRIBE_UNSUBSCRIBE()
;Sleep(10000)

;ConsoleWrite(@LF & @LF & @LF & @LF)
; __DROPBOX__COMM__TEST_MULTICHANNEL_MULTISUBSCRIBER()
; Sleep(10000)

; This function demonstrates is used to test
; the UDF while in development and serves as
; a reference on how to use it.
Func __DROPBOX__TEST()
	ConsoleWrite("__DROPBOX__CHECK_EXIST:> " & __DROPBOX__CHECK_EXIST() & @LF)
	ConsoleWrite("__DROPBOX__INITIALIZE():> " & __DROPBOX__INITIALIZE() & @LF)
	ConsoleWrite("__DROPBOX__TERMINATE():> " & __DROPBOX__TERMINATE() & @LF)
	ConsoleWrite("__DROPBOX__INITIALIZE():> " & __DROPBOX__INITIALIZE() & @LF)
EndFunc

Func __DROPBOX__COMM__TEST_DUMPVARS()
		ConsoleWrite("--> __DROPBOX__COMM__TEST_SUBSCRIBE_UNSUBSCRIBE(), $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = " & _
					 $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS & @LF)
		COnsoleWrite("--> __DROPBOX__COMM__TEST_DUMPVARS(), $__DROPBOX__szREGISTERED_FUNCTIONS = " & $__DROPBOX__szREGISTERED_FUNCTIONS & @LF)
EndFunc
Func __DROPBOX__COMM__TEST_CREATE_REMOVE_CHANNEL()
	 ConsoleWrite("Testing __CREATE_CHANNEL() and __REMOVE_CHANNEL" & @LF)
	 __DROPBOX__COMM__TEST_DUMPVARS()
	 __DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	 __DROPBOX__COMM__TEST_DUMPVARS()
	 Sleep(10000)
	 __DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	 __DROPBOX__COMM__TEST_DUMPVARS()
EndFunc

Func __DROPBOX__COMM__TEST_WRITE_READ()
	Local $strBuf = ""
	$strBuf = "They Call Me Data"
    __DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir)
	__DROPBOX__COMM__TEST_DUMPVARS()
	;__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER_2")
	__DROPBOX__COMM__WRITE("comm", @ScriptDir, $strBuf)
	Sleep(10000)
	__DROPBOX__COMM__READ("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
EndFunc

Func __DROPBOX__COMM__TEST_SUBSCRIBE_UNSUBSCRIBE()
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__WRITE("comm", @ScriptDir, "They Call Me Data")
	Sleep(10000)
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__UNSUBSCRIBE("__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__WRITE("comm", @ScriptDir, "This is not supposed to show up")
	Sleep(10000)
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
EndFunc

; By no means are the following two functions the best way to perform
; a "relay" using my library. The ideal solution would be to use
; a verified copy function, like the one in my __FILE() library,
; and then to copy the datagram from one channel to another.
; anyway, there's more than one way to do it.
Func __DROPBOX__COMM__TEST__MULTICHANNEL_RELAY1($hFile)
	Local $szDatum = FileRead($hFile, -1) ; Read to end
	FileClose($hFile)
	ConsoleWrite("-----------------__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY1---------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
	__DROPBOX__COMM__WRITE("comm2", @ScriptDir, @LF & $szDatum)
EndFunc

Func __DROPBOX__COMM__TEST__MULTICHANNEL_RELAY2($hFile)
	Local $szDatum = FileRead($hFile, -1) ; Read to end
	FileClose($hFile)
	ConsoleWrite("-----------------__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY2---------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
	__DROPBOX__COMM__WRITE("comm3", @ScriptDir, @LF & $szDatum)
EndFunc

Func __DROPBOX__COMM__TEST_MULTICHANNEL_MULTISUBSCRIBER()
	ConsoleWrite("--> Testing multichannel mode." & @LF)
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__CREATE_CHANNEL("comm2", @ScriptDir, "__DROPBOX__CERR")
    __DROPBOX__COMM__CREATE_CHANNEL("comm3", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY1")
	__DROPBOX__COMM__SUBSCRIBE("comm2", @ScriptDir, "__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY2")
	__DROPBOX__COMM__TEST_DUMPVARS()
	ConsoleWrite("--> Writing channel data " & @LF)
	Local $i = 0
	Local $max = 100
	For $i = 0 To $max Step 1
		__DROPBOX__COMM__WRITE("comm", @ScriptDir, "Datagram: " & $i & " of " & $max)
	Next
	Sleep(60000)
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__UNSUBSCRIBE()
	Sleep(60000)
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__REMOVE_CHANNEL("comm2", @ScriptDir, "__DROPBOX__CERR")
    __DROPBOX__COMM__REMOVE_CHANNEL("comm3", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()

	__DROPBOX__COMM__TEST_MULTICHANNEL_MULTISUBSCRIBER2()
EndFunc

Func __DROPBOX__COMM__TEST_MULTICHANNEL_MULTISUBSCRIBER2()
	ConsoleWrite("--> Testing multichannel mode (2)" & @LF)
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__CREATE_CHANNEL("comm2", @ScriptDir, "__DROPBOX__CERR")
    __DROPBOX__COMM__CREATE_CHANNEL("comm3", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
	ConsoleWrite("--> Writing channel data " & @LF)
	Local $i = 0
	Local $max = 100
	For $i = 0 To $max Step 1
		__DROPBOX__COMM__WRITE("comm", @ScriptDir, "Datagram: " & $i & " of " & $max)
	Next
	Sleep(60000)
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY1")
	Sleep(100000)
	; If you're going to subscribe more than one function to a channel that already has a lot of
	; datagrams in it, then you want to wait a little while for it to process it before subscribing
	; the second channel.
	;
	; I've played with this in the function above and had problems with it, so I suppose the solution,
	; for now, is to wait a little while before subscribing another function to a channel that, could,
	; potentially have quite a few datagrams left in it. There are many ways to fix this problem, I just
	; haven't found out which one I want to do yet.
	;  I could rebuild the model by which the delegates are called (the subscribers)
	;  or... I could have __SUBSCRIBE() call the function passed in with a "READ" call and see how
	;  if that works. Sounds to me like that'd be the best solution anyways.
	; I'll decide later.
	;
	; That's what this test demonstrates.
	; The ideal way to do this would be to do it in subscribe itself, so that after the function
	; has subscribed to a channel, it reads some configuration information from the INI file,
	; checks for datagrams in the existing directory, and then
	__DROPBOX__COMM__SUBSCRIBE("comm2", @ScriptDir, "__DROPBOX__COMM__TEST__MULTICHANNEL_RELAY2")
	__DROPBOX__COMM__TEST_DUMPVARS()
	__DROPBOX__COMM__UNSUBSCRIBE()
	Sleep(60000)
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__REMOVE_CHANNEL("comm2", @ScriptDir, "__DROPBOX__CERR")
    __DROPBOX__COMM__REMOVE_CHANNEL("comm3", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__TEST_DUMPVARS()
EndFunc

Func __DROPBOX__COMM__READ__DEMO_READER_2($hFile)
	Local $szDatum = FileRead($hFile, -1) ; Read to end
	ConsoleWrite("-----------------__DROPBOX__COMM__READ__DEMO_READER_2---------------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
EndFunc

; Checks if Dropbox is an active
; process on the system.
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;    True if active
;    False if not.
Func __DROPBOX__CHECK_EXIST($szLogFuncHandler = "__DROPBOX__CERR")
	Local $iProcessResult = ProcessWait("Dropbox.exe", $__DROPBOX__iPROCESSWAIT_INTERVAL)
	If(  $iProcessResult <> 0 ) Then
		; Dropbox exists
		Call($szLogFuncHandler, "In __DROPBOX_CHECK_EXIST(), dropbox appears to be running.")
		Return True
	Else
		; Dropbox doesn't exist
		Call($szLogFuncHandler, "In __DROPBOX_CHECK_EXIST(), dropbox does not appear to be running.")
		Return False
	EndIf
EndFunc

; Terminates the dropbox
; process on the system
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;   True: successful
;   False: otherwise
; @error:
;  -2: Last ditch effort to terminate dropbox failed
;  -1: Unknown error terminating dropbox
;   0: Successfully terminated dropbox
;   1: OpenProcess failed
;   2: AdjustTokenPrivileges failed
;   3: TerminateProcess failed
;   4: Cannot verify if process exists
;   5: Unknown error. Bad magic
; Remarks:
;  If dropbox isn't running on
;  the system, then this func
;  will return true anyways.
Func __DROPBOX__TERMINATE($szLogFuncHandler = "__DROPBOX__CERR")
	Local $bReturnValue = False
	Call($szLogFuncHandler, "In __DROPBOX__TERMINATE()")
	If(ProcessExists("Dropbox.exe")) Then
	   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), dropbox exists, killing")

	   Local $result = ProcessClose("Dropbox.exe")
	   If( $result = 1 ) Then ; Terminated Dropbox, exiting
		  Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), successfully terminated dropbox")
		  SetError(0)
		  $bReturnValue = True
	   Else
		 Select
		 Case @error = 1
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), OpenProcess failed")
			SetError(1)
		 Case @error = 2
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), AdjustTokenPrivileges failed")
			SetError(2)
		 Case @error = 3
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), TerminateProcess failed")
			SetError(3)
		 Case @error = 4
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), Cannot verify if process exists")
			SetError(4)
		 Case Else
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), there was an error and I don't know what caused it.")
			SetError(-1)
		 EndSelect
		 ; Fall back and do everything to kill DropBox
		 If(ProcessExists("Dropbox.exe")) Then
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), we've done almost everything to terminate dropBox(), making a last ditch effort.")
			$result = _RunDos("taskkill /f /im Dropbox.exe")
			If( @error <> 0 ) Then
			   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), last ditch effort to kill Dropbox failed. We're going to bomb now.")
			   SetError(-2)
			   $bReturnValue = False
			Else
			   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), last ditch effort succeeded!")
			   $bReturnValue = True
			EndIf
		 EndIf
	  EndIf
   Else
	  Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), dropbox isn't running")
	  $bReturnValue = True
   EndIf
	Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), exiting")
	Return $bReturnValue
EndFunc

; Initializes (starts)
; dropbox on the host
; system.
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;  If successful:
;    Returns True
;  Otherwise:
;     Returns False and sets @error
;    @error:
; 	   -1: If dropbox dir not found
;      -2: Other problem.
Func __DROPBOX__INITIALIZE($szLogFuncHandler = "__DROPBOX__CERR")
	Local $szDropBoxDir = @AppDataDir & "\Dropbox\bin"
	If( FileExists($szDropBoxDir) = 0 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), cannot find dropbox directory")
		; Dropbox directory doesn't exist
		SetError(-1)
		Return False
	Else
		; Dropbox directory exists
		Local $iResult = Run($szDropBoxDir & "\Dropbox.exe", "", @SW_HIDE)
		Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), " & _
			_Iif($iResult <> 0, "successfully started dropbox.", _
			"unsuccessfully started dropbox.") & _
			" PID: " & $iResult)
		If($iResult <> 0 ) Then
			Return True
		Else
			Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), failed to start dropbox.")
			SetError(-2)
			Return False
		EndIf
	EndIf
EndFunc

; This function creates a channel in the specified directory
; for communications to go through.
;
; Parameters:
;    $szChannelName: A string describing the channel
;    $szChannelPath: The path to create the channel in.
;    $szLogFuncHandler: A string containing a function name
;                       to call with log information.
; Returns:
;   True: If the channel was created successfully.
;   False: If the channel was not created successfully
;          (see @error)
; @error:
;    -1: General error creating channel directory.
;    -2: Error creating configuration file in channel.
;    -3: Channel already exists.
; Remarks:
;   TODO.
Func __DROPBOX__COMM__CREATE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
		; The channel doesn't exist, create it.
		Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), Creating channel: " & $szChannelPath & "\" & $szChannelName)
		Local $oChannelCreationResult = DirCreate($szChannelPath & "\" & $szChannelName)
		If( $oChannelCreationResult = 0 ) Then ; There was a problem
			Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), there was an error creating the channel.")
			SetError(-1)
			Return False
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), Channel created, result: " & $oChannelCreationResult)
			Local $oChannelIniCreationResult = IniWrite($szChannelPath & "\" & $szChannelName & "\" & $szChannelName & _
												".ini" , $szChannelName & "-Creator", @ComputerName, __DROPBOX__COMM__EPOCH())
			Local $oChannelIniCreationResult2 = IniWrite($szChannelPath & "\" & $szChannelName & "\" & @ComputerName & _
												".ini" , $szChannelName & "-Creator", @ComputerName, __DROPBOX__COMM__EPOCH())
			If( $oChannelCreationResult = 0) Then ; There was a problem
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), there was an error creating INI file for the channel")
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), cleaning up...")
				Local $bCleanupResult = __DROPBOX__COMM__REMOVE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler)
				; TODO: Add error handling code here (for __DROPBOX__COMM__REMOVE_CHANNEL())
				SetError(-2)
				Return False
			Else
				SetError(0)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), creating channel configuration file. Result: " & $oChannelIniCreationResult)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), channel " & $szChannelName & " created successfully.")
				Return True
			EndIf
		EndIf
	Else
		; Channel exists
		Call($szLogFuncHandler, "In __DROPBOX__COMM_CREATE_CHANNEL(), channel already exists.")
		SetError(-3)
		Return False
	EndIf
EndFunc

; This function removes a channel in the specified directory
; for communications to go through.
;
; Parameters:
;    $szChannelName: A string describing the channel
;    $szChannelPath: The path to create the channel in.
;    $szLogFuncHandler: A string containing a function name
;                       to call with log information.
; Returns:
;   True: If the channel was removed successfully
;         (see @error)
;   False: If the channel was not removed successfully
;          (see @error)
; @error:
;    -1: General error unsubscribing from channel. (See @extended)
;    -2: Error unsubscribing from channel,
;         --> See @extended
;    -3: Channel doesn't exist.
; @extended:
;    Set to the return value of unsubscribe on error..
;
; Remarks:
;   TODO: Finish fixing this (so that it can remove a channel without removing all
;         subscribers from all channels.
;   When you remove a channel, this function goes through the global list of subscribed functions,
;    and iteratively removes them. This process runs at or above linear time, so, this operation is
;    expensive. However, If your subscriber list is so large that you're running into some kind of a
;    performance issue with the script itself and not whatever platform is facilitating the file-syncing
;    then you have other problems...
Func __DROPBOX__COMM__REMOVE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	If( FileExists($szChannelComb) <> 1 ) Then
		; Channel doesn't exist, so there's nothing to remove.
		SetError(-3)
		Return True ; Should I return here?
	EndIf
If( $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS > 0 ) Then
	Local $aszFuncListing = __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST($szLogFuncHandler)
	Local $i = 0
	For $i = 1 To $aszFuncListing[0] - 1 Step 1
		Local $chan = ""
		Local $path = ""
		Local $buf1 = "" ; This is the data handler
		Local $buf2 = "" ; This is the log func handler
		Local $aszFuncData = __DROPBOX__COMM__GET_FUNCTION_DATA($aszFuncListing[$i], _
																$chan, $path, $buf1, _
																$buf2, $szLogFuncHandler)
		Local $_szChannelComb = $path & "\" & $path
		If( StringCompare($_szChannelComb, $szChannelComb, 2) = 0 ) Then
			; The channel name and paths match, so, remove that function.
			Local $retVal = __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($aszFuncListing[$i], $szLogFuncHandler)
			If( $retVal = False ) Then
				; There was an error
				Local $tmpExtended = @error
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), there was an error," & _
										"unsubscribing a function, " & $aszFuncListing[$i] & ". " & _
										"@error is " & @error & ".")
				; At this point, there's nothing that I know to do.
				SetError(-2, $tmpExtended)
				; Don't return here, because we want to finish removing the channel.
			EndIf
		EndIf
	Next
EndIf
	Local $oChannelDeletionResult = DirRemove($szChannelPath & "\" & $szChannelName, 1)
	If( $oChannelDeletionResult = 0 ) Then ; There was a problem.
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), error removing channel dir.")
		If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
			; Dir doesn't exist, but, prior to entering this section of the massive IF statment
			; (the one in the beginning), the directory must have existed for us to get to this
			; point, and for the control flow to get here at this point means that we're at a
			; logical contradiction... and therefore there's a bug in the logic.
			;
			; Code can't just magically change it's mind, that's why I call it bad magic.
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel dir doesn't exist. BAD MAGIC")
			SetError(-3)
			Return True
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel exists, but cannot be deleted.")
			SetError(-4)
			Return False
		EndIf
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), successfully removed channel.")
		Return True
	EndIf
	#cs -- TODO: Remove this code.
	If( FileExists($szChannelPath & "\" & $szChannelName) = 1 ) Then ; Channel exists
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), file exists")
		; Remove all the datagrams & channel directory.
		$bReturnValue = __DROPBOX__COMM__UNSUBSCRIBE("-1", $szLogFuncHandler)
		#cs
		;	-- This is a bugfix that fixes an issue where calling this function
		;   -- While there is more than one channel subscribed will unsubscribe all
		;	-- functions from all channels.
		Local $bReturnValue = False
		Local $i = 0
		Local $aszFuncListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		For $i = 1 To $aszFuncListing[0]-1 Step 1
			Local $chan = ""
			Local $path = ""
			Local $name = ""
			Local $logf = ""
			Local $bGetDataResult = __DROPBOX__COMM__GET_FUNCTION_DATA($aszFuncListing[$i], $chan, $path, $name, $logf, $szLogFuncHandler)
			If( $bGetDataResult = False ) Then
				; There was a problem
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), there was an error retrieving data for function " & $aszFuncListing[$i] & ".")
				$bReturnValue = False
			Else
				Local $szChannelCombParam = $szChannelPath & "\" & $szChannelName
				Local $szChannelCombDatum = $chan & "\" & $path
				If( StringCompare($szChannelCombParam, $szChannelCombDatum, 2) = 0 ) Then
					; Both are equal, so remove it.
					ConsoleWrite("In __DROPBOX__COMM__REMOVE_CHANNEL(), removing " & $aszFuncListing[$i] & " from " & $szChannelName & "." & @lF)
					__DROPBOX__COMM__UNSUBSCRIBE($aszFuncListing[$i], $szLogFuncHandler)
				Else
					; Not a match, for now
					ConsoleWrite("In __DROPBOX__COMM__REMOVE_CHANNEL(), did not remove " & $aszFuncListing[$i] & " from " & $szChannelName & "." & @lF)
					ConsoleWrite("---> Mismatch: " & $chan & " " & $path & " " & $name & " " & $logf & @LF)
				EndIf
		#ce
		If($bReturnValue = False) Then
			; __DROPBOX__COMM__UNSUBSCRIBE() throws errors if there was an error deallocating memory, or if
			; there was no subscriber attached to the thread. Both of these threads are non-fatal -- so
			; what we can do here is just continue... but first, let's retrieve the value stored in @error and
			; in @extended before we call the log-handler (because call can reset both of those to be 0xDEADBEEF
			; and I don't want that.
			Local $tmpaterror = @error
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), error unsubscribing from channel. @error: " & @error)
			SetError(-2)
			SetExtended($tmpaterror)
		EndIf

		Local $oChannelDeletionResult = DirRemove($szChannelPath & "\" & $szChannelName, 1)
		If( $oChannelDeletionResult = 0 ) Then ; There was a problem.
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), error removing channel dir.")
			If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
				; Dir doesn't exist, but, prior to entering this section of the massive IF statment
				; (the one in the beginning), the directory must have existed for us to get to this
				; point, and for the control flow to get here at this point means that we're at a
				; logical contradiction... and therefore there's a bug in the logic.
				;
				; Code can't just magically change it's mind, that's why I call it bad magic.
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel dir doesn't exist. BAD MAGIC")
				SetError(-3)
				Return True
			Else
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel exists, but cannot be deleted.")
				SetError(-4)
				Return False
			EndIf
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), successfully removed channel.")
			Return True
		EndIf
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel dir doesn't exist.")
		SetError(-3)
		Return True
	EndIf
	Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), BAD MAGIC ON: " & @ScriptLineNumber)
	; I just had a feeling.
	#ce
EndFunc

; This function takes a single parameter, $szFunctionName,
; that denotes the name of the subscribed function, as would
; be used as a parameter to Call() and gets the data associated
; , internally, with that function, such as the channel name,
; channel path, and log functions and such associated with
; that function.
;
; Parameters:
;    $szFunctionName: The name of the function, as would be used
;                     as a parameter to Call()
;    $_szChannelName: A variable to store the channel name in
;    $_szChannelPath: A variable to store the channel path in
;    $_szFuncDataHandler: A variable to store the name of the
;                        function used to parse input data.
;                        In this case, this parameter is
;                        redundant and will be assigned
;                        the same data as what was supplied
;                        in $szFunctionName.
;	$_szLogFuncHandler:  A variable to store the name of the
;                       function called for logging purposes.
;    $szLogFuncHandler: The name of the function to call with
;						logging information.
; Returns:
;	If successful:
;		1. Returns True
;		2. Sets @error to 0
;       3. Assigns the appropriate
;		   data to the supplied ByRef
;          variables
;   If not successful:
;		1. Returns False
;		2. Sets @error as appropriate
;		3. Assigns "" to all the provided
;		   variables.
; @error:
;    0: No problems.
;   -1: Problem reading data from global variables.
;
; Remarks:
;   None.

Func __DROPBOX__COMM__GET_FUNCTION_DATA($szFunctionName, _
									    ByRef $_szChannelName, ByRef $_szChannelPath, _
										ByRef $_szFuncDataHandler, ByRef $_szLogFuncHandler, _
										$szLogFuncHandler = "__DROPBOX__CERR")

		Local $j1 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szChannelName")
		;ConsoleWrite("DEBUG: " & $chan & @LF)
		Local $j2 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szChannelPath")
		;ConsoleWrite("DEBUG: " & $path & @LF)
		Local $j3 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szFuncDataHandler")
		; ConsoleWrite("DEBUG: " & Eval($hand) & @LF)
		Local $j4 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szLogFuncHandler")

		If( ($j1 & $j2 & $j3 & $j4) <> "") Then
			; No problems.
			SetError(0)
			Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_FUNCTION_DATA(), successfully retrieved function data")
			Return True
		Else
			Local $szLogErrMessageForAssign = "Failed to retrieve the following data for the function " & $szFunctionName & ": "
			If( $j1 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Name] "
			EndIf

			If( $j2 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Path] "
			EndIf

			If( $j3 = 0 ) Then
				$szLogErrMessageForAssign &= "[Data Handler] "
			EndIf

			If( $j4 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Error Log Handler]."
			EndIf

			Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_FUNCTION_DATA(), " & $szLogErrMessageForAssign)
			SetError(-1)
			Return False
		EndIf
EndFunc

; This function subscribes a function specified by
; a parameter to changes made in the specified channel
; name. The function specified is called using AdLibRegister.
;
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    $szFuncDataHandler: A string describing a function
;                        to be called when changes are
;                        made in the channel
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful
;   False: If not successful, and sets @error
; @error:
;    0: Channel doesn't exist.
;   -1: Max number of subscribers reached
;   -2: Problem assigning data to vars.
;
; Remarks:
;   At this point, I've only coded this library to handle
;   only one subscriber at a time. It wouldn't be too hard
;   to add it, but I'm working on it...
Func __DROPBOX__COMM__SUBSCRIBE($szChannelName, $szChannelPath, $szFuncDataHandler, $szLogFuncHandler = "__DROPBOX__CERR", $szListenMode = False)
	If( $szListenMode = False ) Then
		If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
			SetError(0)
			Return False
		EndIf
	EndIf

	If( _
		$PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = 0 _
		OR _
		$PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS < $__DROPBOX__iDEFAULT_MAX_REGISTERED_SUBSCRIBERS _
	   ) Then

		Local $oChannelIniCreationResult = IniWrite($szChannelPath & "\" & $szChannelName & "\" & _
				@ComputerName & ".ini" , $szChannelName & "-Listening", $szFuncDataHandler, _
				__DROPBOX__COMM__EPOCH())

		$PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS + 1
		$__DROPBOX__szREGISTERED_FUNCTIONS &= $szFuncDataHandler & "|"
		Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), adding subscriber " & "#" & _
		     $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS &" : " & $szFuncDataHandler & "().")
		Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szChannelName", $szChannelName, 2)
		Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szChannelPath", $szChannelPath, 2)
		Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szFuncDataHandler", $szFuncDataHandler, 2)
		Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szLogFuncHandler & "_szLogFuncHandler", $szLogFuncHandler, 2)
		;ConsoleWrite($j1 & " :: " & $j2 & " :: " & $j3 & " :: " & $j4 & @LF)

		If( ($j1 + $j2 + $j3 + $j4) = 4) Then
			If( $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS <= 1 ) Then
				AdlibRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS", _
							$__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD)
			EndIf
			Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), successfully added subscriber.")
			Return True
		Else
			Local $szLogErrMessageForAssign = "The following assignments have failed: "
			If( $j1 = 0 ) Then
				$szLogErrMessageForAssign &= "$j1, "
			EndIf

			If( $j2 = 0 ) Then
				$szLogErrMessageForAssign &= "$j2, "
			EndIf

			If( $j3 = 0 ) Then
				$szLogErrMessageForAssign &= "$j3, "
			EndIf

			If( $j4 = 0 ) Then
				$szLogErrMessageForAssign &= "$j4."
			EndIf

			Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), there was a problem calling Assign()." & _
									$szLogErrMessageForAssign)
			SetError(-2)
			Return False
		EndIf
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), attempted to subscribe handler when limit reached")
		SetError(-1)
		Return False
	EndIf
EndFunc

; Not intended to be called from the outside,
; but this function execs the stuff that was
; assigned in __SUBSCRIBE().
Func PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS()
	AdlibUnRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS")
	Local $i = 0
	 Local $aszListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
	 ; _ArrayDisplay($aszListing, "Stuff")
	For $i = 1 To $aszListing[0]-1 Step 1
		; ConsoleWrite("DEBUG: " & $aszListing[$i] & @LF)
		;__PRIVATE__DROPBOX__COMM__SUBSCRIBE_
		Local $chan = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szChannelName")
		;ConsoleWrite("DEBUG: " & $chan & @LF)
		Local $path = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szChannelPath")
		;ConsoleWrite("DEBUG: " & $path & @LF)
		Local $hand = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szFuncDataHandler")
		; ConsoleWrite("DEBUG: " & Eval($hand) & @LF)
		Local $logf = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szLogFuncHandler")
		;ConsoleWrite("DEBUG: " & $logf & @LF)
		__DROPBOX__COMM__READ($chan, $path, $hand, $logf)
		Sleep($__DROPBOX__iINTERVAL_BETWEEN_SUBSCRIBER_NOTIFY)
	Next
	AdlibRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS", $__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD)
EndFunc

; The following function is used by __UNSUBSCRIBE()
; to alert the user if a deadlock error happens where,
; __UNSUBSCRIBE() doesn't correctly unsubscribe a function
; from being called.
Func PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER($msg)
	Call("__DROPBOX__CERR", "In PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER(), " & _
					"A FUNCTION THAT HAS BEEN REMOVED FROM THE NOTIFY LIST " & _
					"HAS CALLED THIS FUNCTION, HERE IS THE DATA IT GAVE ME: " & _
					$msg)
EndFunc

; This function unsubscribes a previously assigned
; function from the specified channel residing in
; the specified path. The function specified is
; removed from being called using AdLibUnRegister.
;
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    [$szFuncName = "-1"]: The function to unregister from
;                          the call. The default for this is
;                          "-1", which basically means unsub
;                          -scribe everything.
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful, @error is possibly set.
;   False: If not successful, and sets @error
;   -->    See Remarks
; @error:
;    0: No problems.
;   -1: No subscribers are registered.
;   -2: General failure
;
; Remarks:
;    1). This function will always return true. Check @error for results.
;    2). This function has some bad bugs in it that are a result of poor
;        design and forethought on my part. This function should really
;        be named UNSUBSCRIBE_ALL() and remove all of the functions from
;        the list and reset everything, but instead... I attempted to
;        combine the behavior of an UNSUBSCRIBE_ALL() function into a
;        function that could unsubscribe individual functions as well
;        as all functions.
;
;        "Oh, well, that's easy, you can just. Iterate through the ...
;         and do ..."
;         No.
;
; Issues:
;    1). It's not recommended that you use this function.
;
; Known Bugs:
;    1). There's a problem in this function where, when you call it, it will unsubscribe
;        all the functions that are active. This is not desireable behavior.
Func __DROPBOX__COMM__UNSUBSCRIBE($szLogFuncHandler = "__DROPBOX__CERR")
	If( $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = 0 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), attempted to unsubscribe when there are no subscribers.")
		SetError(-1)
		Return True
	EndIf
	Local $aszFuncListing = __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST($szLogFuncHandler)
	;_ArrayDisplay($aszFuncListing)
	Local $i = 0
	For $i = 1 To $aszFuncListing[0] Step 1
		Local $chan = ""
		Local $path = ""
		Local $buf1 = "" ; This is the data handler
		Local $buf2 = "" ; This is the log func handler
		Local $aszFuncData = __DROPBOX__COMM__GET_FUNCTION_DATA($aszFuncListing[$i], _
																$chan, $path, $buf1, _
																$buf2, $szLogFuncHandler)
		Local $_szChannelComb = $path & "\" & $path
		Local $retVal = __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($aszFuncListing[$i], $szLogFuncHandler)
		If( $retVal = False ) Then
			; There was an error
			Local $tmpExtended = @error
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE(), there was an error," & _
									"unsubscribing a function, " & $aszFuncListing[$i] & ". " & _
									"@error is " & @error & ".")
			; At this point, there's nothing that I know to do.
			SetError(-2, $tmpExtended)
		EndIf
	Next
EndFunc

; This function unsubscribes a specified function
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    [$szFuncName = "-1"]: The function to unregister from
;                          the call. The default for this is
;                          "-1", which basically means unsub
;                          -scribe everything.
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful, @error is possibly set.
;   False: If not successful, and sets @error
; @error:
;    0: No problems.
;   -1: Function not registered.
;   -2: Problem assigning data to vars.
; Remarks:
;   If you look in the source code and see the variables $f and
;   $f2, it's hard to understand why they're there.
;
;   $f is an alias of the function provided in $szFuncName
;   $f2 is a function used for debugging purposes to locate
;   functions that, are transparent to the program, but may
;   still be called by the program while it is reading info
;   from a channel.
;
;   If the function specified in $f2 gets called, that means
;   something was not removed from the list correctly. Get it?
;
;   It's a bit to wrap your head around, but if you've gotten
;   this far, you know what I mean.
Func __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($szFuncName, $szLogFuncHandler = "__DROPBOX__CERR")
	If( $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = 0 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), attempted to unsubscribe when there are no subscribers.")
		SetError(-1)
		Return True
	EndIf

	; $f is an alias for that damn long function name.
	Local $f2 = "PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER"
	Local $f = $szFuncName

	Local $chan = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & $f & "_szChannelName")
	Local $path = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & $f & "_szChannelPath")

	Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szChannelName", "", 2)
	Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szChannelPath", "", 2)
	Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szFuncDataHandler", $f, 2)
	Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szLogFuncHandler", $f2, 2)
	Local $oChannelIniListDResult = IniWrite($path & "\" & $chan & "\" & _
				@ComputerName & ".ini" , $chan & "-Listening", $szFuncName, -1)


	If( ($j1 + $j2 + $j3 + $j4) = 4) Then
		Local $aszFuncListing = __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST($szLogFuncHandler)
		Local $szNewRegisteredFunctionsList = ""
		; Perform a linear search on the function
		; list and locate the index of the unsubscribed
		; function and remove it
		Local $i = 0
		Local $iFoundIndex = -1
		For $i = 1 To $aszFuncListing[0] Step 1
			Local $cmpr = StringCompare($szFuncName, $aszFuncListing[$i], 2) ; Case insensitive
			If( $cmpr = 0 ) Then
				; Found it
				$iFoundIndex = $i
			Else
				; Add the function to the new list.
				$szNewRegisteredFunctionsList &= $aszFuncListing[$i] & "|"
			EndIf
		Next
		$__DROPBOX__szREGISTERED_FUNCTIONS = $szNewRegisteredFunctionsList
		If( $iFoundIndex = -1 ) Then
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), removal was successful. Function not found. BAD MAGIC." & $szFuncName)
			SetError(-1)
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), successfully removed subscriber info.")
			SetError(0)
		EndIf
		$PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS - 1
		Return True
		; Rationale: We'll return true in this cause because at this point the end case is the same regardless of whether or not
		;             this function exists. We should return true so long as the function (to the script's knowledge) is not there
		;             after returning from the script.
		;
		;            If the error where @error is -1 (where there is obviously some BAD MAGIC going on since in order for the control
		;             flow to reach that point, that means that the function must have existed, but if the iterative search through.
		;             the function listing was not able to locate the desired function, it points to a logical fallacy showing a bug
		;             in disguise. (And these days, the bugs have gotten awfully stealthy).
	Else
		Local $szLogErrMessageForAssign = "The following assignments have failed: "
		If( $j1 = 0 ) Then
			$szLogErrMessageForAssign &= "$j1, "
		EndIf

		If( $j2 = 0 ) Then
			$szLogErrMessageForAssign &= "$j2, "
		EndIf

		If( $j3 = 0 ) Then
			$szLogErrMessageForAssign &= "$j3, "
		EndIf

		If( $j4 = 0 ) Then
			$szLogErrMessageForAssign &= "$j4."
		EndIf

		Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), there was a problem calling Assign()." & _
								$szLogErrMessageForAssign)
		SetError(-2)
		Return False
	EndIf
EndFunc


; This function writes the specified data
; to the specified channel residing in the
; specified path.
;
; Parameters:
;    $szChannelName: The channel name
;    $szChannelPath; The path the channel resides in
;    $szData: The data to transmit
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True: If successful
;    False: If not successful, and sets @error
; @error:
;    -1: Error opening up tmp datagram file for
;        writing.
;    -2: Error writing datagram information to
;        the file
;    -3: Error moving (renaming) file to .dg
;        extension. (See remarks)
;
; Remarks:
;  This function creates a file in the channel
;  with a name containing the current unix_epoch
;  time. Then it writes the following data to the
;  file:
;    Line 1) Unix epoch time of transmission
;    Line 2) Source
;    Line 3) Number of characters in transmission
;    Line 4) Actual transmission data (specified
;            in $szData)
;  After the data is written to the file, it is
;  saved in the dropbox and then renamed to have
;  a ".dg" extension, which stands for datagram.
;
;  The reasoning behind this is that it solves the
;  file locking problem that can sometimes happen
;  when a client is listening while another is
;  writing the information. (See __READ())

Func __DROPBOX__COMM__WRITE($szChannelName, $szChannelPath, $szData, $szLogFuncHandler = "__DROPBOX__CERR")
	Sleep(1000) ; I hate to have to use sleeps in my functions, but until the time gets changed from unix
	; epoch time to something that supports a higher resolution, then the transmission speed limit in
	; datagrams per second is limited to 1dg/s. However... within reason, you can put as much information
	; into one datagram as you'd like.
	Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), transmitting information...")
	Local $DatumBuff = ""
	Local $TxTime = __DROPBOX__COMM__EPOCH()
	$DatumBuff &= $TxTime & @LF
	$DatumBuff &= @ComputerName & @LF
	$DatumBuff &= StringLen($szData) & @LF
	$DatumBuff &= $szData
	Local $szFileName = $szChannelPath & "\" & $szChannelName & "\" & $TxTime
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $hFileOpenHandle = FileOpen($szFileName, 10)
	If( $hFileOpenHandle = -1 ) Then ; There was an error
		Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error opening file for writing.")
		SetError(-1)
		Return False
	Else
		Local $iFileWriteResults = FileWrite($hFileOpenHandle, $DatumBuff)
		If( $iFileWriteResults = 0 ) Then ; There was an error
			Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error writing to the file.")
			SetError(-2)
			Return False
		Else
			FileFlush($hFileOpenHandle)
			FileClose($hFileOpenHandle)
			Local $iFileMoveResults = FileMove($szFileName, $szFileName & ".dg", 1)
			If( $iFileMoveResults = 0 ) Then ; There was an error
				Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error moving file to .dg ext.")
				SetError(-3)
				Return False
			Else
				IniWrite($szChannelComb & "\" & @ComputerName & ".ini", _
				$szChannelName & "-LastTx", @ComputerName, $TxTime)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), successfully transmitted datagram.")
				SetError(0)
				Return True
			EndIf
		EndIf
	EndIf
EndFunc

Func __DROPBOX__COMM__READ__DEMO_READER($hFile)
	Local $szDatum = FileRead($hFile, -1) ; Read to end
	FileClose($hFile)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
EndFunc

; This function is used to read new datagrams
; from the specified channel residing in the
; specified path using the specified function.
;
; Parameters:
;    $szChannelName: The channel name
;    $szChannelPath; The path the channel resides in
;    $szFuncReader: A string containing the name of
;                   a function that takes a filehandle
;                   as a parameter and is used to parse
;                   information recieved from new data
;                   -grams.
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True: If successful
;    False: If not successful, and sets @error
; @error:
;	Returns nothing.
;
; Remarks:
;   The way this function works is a bit quirky,
;   and the best way to do it is to use the
;   __SUBSCRIBE() function, which calls this and
;  will automatically notify your calling program of
;  any new datagrams recieved on this end.
;
;  If you're calling this directly, the function
;  you supply in $szFuncReader will be called for
;  each new file found in $szChannelName.
;
;  It automatically writes (and reads) to an Ini
;  file to determine if you've read information from
;  this channel before, and will automatically update
;  it right before this function returns.
;
;  So, what this means is that when you call this for
;  the first time. If you're in a channel containing a
;  lot of files you have not read... it may not be nice
;  to you.
;
; TODO: Contemplate adding @error signals and such to this function
;		--> Issues:
;			1). This function is usually called by the __PARSE_SUBSCRIBERS()
; 				function, indirectly. So, we shouldn't have to think about
;				handling errors in this function. It either works or it
;				doesn't. If it doesn't, there's not much that can be done
;				about it.
;			2). Should this function, when it recieves a datagram, send
;				a file handle back to $szFuncReader or should it send an
;				array or a string?
Func __DROPBOX__COMM__READ($szChannelName, $szChannelPath, $szFuncReader, $szLogFuncHandler = "__DROPBOX__CERR")
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $iDateTimeFilter = IniRead($szChannelComb & "\" & @ComputerName & ".ini", _
							$szChannelName & "-LastRx", $szFuncReader, -1)
	Local $aszListing = _FileListToArray($szChannelComb, "*.dg", 1)
	Local $iELOS = $PRIVATE__DROPBOX__COMM__NUMBER_DIGITS_IN_EPOCH
	; _ArrayDisplay($aszListing)
	Local $i = 0
	Local $hFileToRead
	Local $iMostRecentDateTime = 0
	For $i = 1 To UBound($aszListing)-1 Step 1
		If( StringLeft($aszListing[$i], $iELOS) > $iMostRecentDateTime ) Then
					$iMostRecentDateTime = StringLeft($aszListing[$i], $iELOS)
				If(StringLeft($aszListing[$i], $iELOS) > $iDateTimeFilter) Then
					$hFileToRead = FileOpen($szChannelComb & "\" & $aszListing[$i]) ; Read only
					Call($szFuncReader, $hFileToRead)
					; I'm expecting the user to close the file after
					; they're done using it after it returns from the
					; Call() done in the line prior, however, if they
					; don't close it, then I'll close it myself.
					FileClose($hFileToRead)
				EndIf
		Else
			; Do nothing.
		EndIf
	Next

	; To prevent too much traffic on the dropbox.
	If( $iMostRecentDateTime > $iDateTimeFilter ) Then
		IniWrite($szChannelComb & "\" & @ComputerName & ".ini", _
			$szChannelName & "-LastRx", $szFuncReader, $iMostRecentDateTime)
	EndIf
EndFunc

; This function returns the current
; epoch time.
Func __DROPBOX__COMM__EPOCH()
	Return _DateDiff('s', "1970/01/01 00:00:00", _NowCalc())
EndFunc

; This function is used to purge old datagrams
; from the specified channel residing in the
; specified path.
;
; Parameters:
;    $szChannelName: The channel name (no trailing \)
;    $szChannelPath: The path the channel resides in (no trailing \)
;    [$iMaxFileAge = 0]:   If the age of the file is greater than the value
;                    specified in this parameter, then the file will
;                    be deleted. If 0, then all files will be purged.
;                    (See remarks)
;
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True:  If successful
;    False: If not successful, and sets @error
; @error:
;    -1: Error deleting datagram.
; Remarks:
;   Age is calculated as the difference now and the file name:
;     $iDifference =  (__DROPBOX__COMM__EPOCH() - $szCurrFile)
;   So, when you specify $iMaxFileAge, you're specifying the
;   maximum difference between the current time and the file
;   time.
;
;
Func __DROPBOX__COMM__PURGE($szChannelName, $szChannelPath, $iMaxFileAge = 0, $szLogFuncHandler = "__DROPBOX__CERR")
	Call($szLogFuncHandler, "In __DROPBOX__COMM__PURGE(), purging datagrams from channel")
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $iCurrentEpoch = __DROPBOX__COMM__EPOCH()
	Local $aszFileListing = _FileListToArray($szChannelComb, "*.dg")
	Local $i = 0
	For $i = 1 To UBound($aszFileListing)-1 Step 1
		Local $iLoopFileName = StringTrimLeft($aszFileListing[$i], 10)
		Local $iDifference   = $iCurrentEpoch - $iLoopFileName
		If( $iDifference >= $iMaxFileAge ) Then
			Local $iDelResult = FileDelete( $szChannelComb & "\" & $aszFileListing[$i] )
			If( $iDelResult <> 1 ) Then ; There was an error
				Call($szLogFuncHandler, "In __DROPBOX__COMM__PURGE(), error deleting file " & $aszFileListing[$i])
				SetError(-1)
				Return False
			EndIf
		EndIf
	Next
	Return True
EndFunc

; This function is used to retrieve the list of functions
; using this library to subscribe to a channel.
;
; Parameters:
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;   If successful:
;    An array of strings containing function names.
;   If unsuccessful:
;    An array of three "-1"'s and sets @error
; @error:
;	-1: No subscribed functions
;
; Remarks:
;    This function is used to get a list of functions. Use this instead of manually
;    iterating through $__DROPBOX__szREGISTERED_FUNCTIONS.
Func __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST($szLogFuncHandler = "__DROPBOX__CERR")
	Local $aszSubscribedFunctionList = $__DROPBOX__szREGISTERED_FUNCTIONS
	Local $aszRetVal = StringSplit("-1|-1|-1", "|")
	If( $PRIVATE__DROPBOX__REGISTERED_SUBSCRIBERS = 0 ) Then
		; There are no functions subscribed.
		Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST(), was " & _
			 "called when there are no registered subscribers.")
		SetError(-1)
	Else
		; One thing to note: potential bug here. If the list of registered
		; functions has not been truncated properly, and has a pipe charact
		; -er on the end, for example:
		;   Bad:
		;     _functions = "func1|func2|func3|"
		; ... Then a condition may occur where the last element in the array
		; $aszRetVal is blank.
		;
		; So, as a simple fix, we have an if clause to check for it.
		; Will this blow up? Probably.
		If( StringRight($__DROPBOX__szREGISTERED_FUNCTIONS, 1) <> "|" ) Then
			; The $__DROPBOX__szREGISTERED_FUNCTIONS variable doesn't contain
			; a | on the last line (which would yield a off-by-one bug), so
			; we can just call StringSplit() and return back an array.
			$aszRetVal = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		Else
			; Otherwise, the contrary has happened...
			$aszRetVal = StringSplit _
						 ( _
							StringTrimRight _
							( _
							  $__DROPBOX__szREGISTERED_FUNCTIONS, 1 _
							) _
						  , "|" _
						  )
		EndIf
	EndIf
	Return $aszRetVal
EndFunc

; This function places a lock for the pipe (for use as a semaphore)
; given a particular file. I don't know if I'm going to use this or not.
Func __DROPBOX__COMM__LOCK($szFileFullPath, $szLogFuncHandler = "__DROPBOX__CERR")
EndFunc

; I don't know if I'm going to use this or not.
Func __DROPBOX__COMM__RELEASE($szFileFullPath, $szLogFuncHandler = "__DROPBOX__CERR")
EndFunc


;;; END Communications through dropbox section.

Func __DROPBOX__CERR($szMsg)
	If($__DROPBOX__bHUSH_CERR = False ) Then
		ConsoleWrite($szMsg & @LF)
	EndIf
EndFunc
