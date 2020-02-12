; Author: Sajid C.
; Date: June 2016
; Program Description: 
COMMENT @
	This program simulates an automated teller machine (ATM) system. The user is asked to enter an account number and PIN. These values are then checked with values within a predefined array.
	Next, the user is presented with a menu of options including the ability to: view the account balance, make a withdrawal up to $1000, deposit a cheque or cash, print a receipt of the
	current sessions transactions, and exit the program. The program also limits the user to 3 transactions per session.
@

INCLUDE Irvine32.inc

	;The maximum withdrawal amount. The user cannot withdraw more than this amount during a transaction
	maxWidr= 1000
	
	;A list of symbolic constants that will be displayed to the console at appropriate points in the program
	enterAcct			EQU		<"Please Enter your Account Number and press Return",0dh,0ah,0>
	enterPIN			EQU		<"Please Enter your PIN and press Return",0dh,0ah,0>
	errorAcct			EQU		<"Error: Invalid Account or PIN. Try again.",0dh,0ah,0>
	errorAttempts		EQU		<"Program has terminated.",0dh,0ah,0>
	errorWidrSize		EQU		<"Error: Withdrawal size too large. Please withdraw less than or equal to $1000",0dh,0ah,0>
	errorWidBalance		EQU		<"Error: Insufficient Funds",0dh,0ah,0>
	successTrans		EQU		<"Transaction was successful",0dh,0ah,0>
	promptRange			EQU		<"Error: Your selection is out of range. Try again.",0dh,0ah,0>
	promptBal			EQU		<"Your current balance is ($):",0dh,0ah,0>
	promptDep			EQU		<"Enter the multiples of $10 you would like to deposit",0dh,0ah,0>
	promptChq			EQU		<"Enter an amount to Deposit",0dh,0ah,0>
	promptWidr			EQU		<"Enter an amount to Withdraw",0dh,0ah,0>
	promptTotWidr		EQU		<"TOTAL WITHDRAWALS:",0dh,0ah,0>
	promptTotDep		EQU		<"TOTAL DEPOSITS:",0dh,0ah,0>
	promptAccNum		EQU		<"ACCOUNT NUMBER:",0dh,0ah,0>
	promptTransLim		EQU		<"Maximum Transactions for the session reached.",0dh,0ah,0>
	
	menu				EQU		<"[1] Account Balance",0dh,0ah,"[2] Withdraw",0dh,0ah,"[3] Deposit",0dh,0ah,\
	"[4] Print Receipt",0dh,0ah,"[5] Exit",0dh,0ah," -Please make your selection and press Return-",0dh,0ah,0>

	depMenu				EQU		<"[1] Deposit Cash",0dh,0ah,"[2] Deposit Cheque",0dh,0ah," -Please make your selection and press Return-",0dh,0ah,0>
	
	
.data																;variable declarations
	
	maxTransactions		DWORD	3									;The maximum number of transactions that can occur in a single session.
	
	accountNumbers		DWORD	10021331,12322244,44499922,10222334	;Arrays that store the account numbers, pins, and balances.
	PINS				WORD	2341,3345,1923,3456					;The index of the accountNumbers array has a pin number with a consistent index in the PIN array,
	balances			DWORD	1000,0,80000,4521					;and a balance wtha a consistent index in the balance array	
	
	
	acctEntry			DWORD	?									;Stores the Account Number entered by the user to compare with the Account Numbers array. Stores the correct account number once the user has logged in.
	PINEntry			DWORD	?									;Stores the PIN number entered by the user to compare with the PINS in the PIN array	
	indexAcc			DWORD	0									;stores the current index of each array being accessed during comparisons
	loopCount			DWORD	?									;stores the value for the outer loop, L1

	totalWidr			DWORD	0									;stores the sum of the validated withdrawals made by the user
	totalDep			DWORD	0									;stores the sum of the validated deposits made by the user
	currentBal			DWORD	?									;stores the value of the current balance
	selection			DWORD	?									;variable stores the user entered selection, to be used with the programs menus
	
	menuPrompt			BYTE	menu								;to display the main menu
	dispDepMen			BYTE	depMenu								;to display deposits menu
	dispTotWidr			BYTE	promptTotWidr						;to display total Withdrawal title
	dispTotDep			BYTE	promptTotDep						;to display total deposits title
	
	erActPrompt			BYTE	errorAcct							;These variables are Prompts that display appropriate error messages for invalid selections/inputs
	erAttempts			BYTE	errorAttempts						
	erRange				BYTE	promptRange							
	erWidr				BYTE	errorWidrSize						
	erWidrBal			BYTE	errorWidBalance
	erTransLim			BYTE	promptTransLim

	sucTrans			BYTE	successTrans						;Prompt to display a successful transaction has occured

	acctPrompt			BYTE	enterAcct							;These variables Prompt the user to enter various data
	PINPrompt			BYTE	enterPIN
	disAccNum			BYTE	promptAccNum						
	dispBal				BYTE	promptBal							
	dispWidr			BYTE	promptWidr							
	dispDep				BYTE	promptDep							
	dispChq				BYTE	promptChq							

					
	

	

.code																;code declarations
													
main proc
	
	call ClearRegisters												;clear registers for use
	call UserAuthentication											;authenticate user entered account number and PIN, and store associated balance in variable
	call MainMenu													;display main menu and handle all selections

	
				
main endp															;ends main procedure







;-----------------------------------------------------
UserAuthentication proc
;Takes user string input and matches it with the arrays for 
;balances and PINS for authentication. Once verified, it stores the balance in a variable.
;Receives: Nothing
;Returns: userBalance- the balance associated with the verified account
;-----------------------------------------------------
	mov ecx, 3														;sets outer loop count
	L1:																;loops input prompts for 3 attempts

		call StoreAuthInput											;Store users input for balance and PIN into variables


		mov ecx,		LENGTHOF accountNumbers						;set inner loop count
		L2:															;iterates through all elements of array

			call AuthenticateInput

			loop		L2											;loop until entire array has been authenticated


		mov ecx,	loopCount										;restore outer loop count
		


		call PINCompare												;compare the entered PIN to the PINArray and balance and store balance if authenticated, or move to error if not.


		dec		cx													;decrement outer loop count
		jne		L1													;jump back to beginning of outer loop until 3 attempts are up
		ret															;return procedure


UserAuthentication endp												;end procedure





;-----------------------------------------------------
StoreAuthInput proc
;Takes the user input for account number and PIN and stores them in variables
;receives: nothing
;returns: nothing
;
;-----------------------------------------------------	
	mov esi,		0												;clears esi
	or	edi,		1												;clears ZF
	mov loopCount,	ecx												;saves outer loop count

	mov edx,		OFFSET acctPrompt								;mov account number into edx
	call			UserInput										;display label and ask for user input and store it into eax
	mov acctEntry,	eax												;store user input in acctEntry

	mov edx,		OFFSET PINPrompt								;display label and ask for user input and store it into eax
	call			UserInput									
	mov PINEntry,	eax												;store user input for PIN in PINEntry
	ret																;return procedure


StoreAuthInput endp





;-----------------------------------------------------
AuthenticateInput proc
;Iterates through the balance array and compares the user input to it for a match.
;Saves the current index of the array under consideration into indexAcc
;receives: nothing
;returns: ecx- loop terminator once procedure is returned. IndexAcc- the index at which a match was found, if found
;-----------------------------------------------------	
	mov ebx,	accountNumbers[esi]									;move accountNumbers array element into ebx for comparison
	cmp ebx,	[acctEntry]											;compare user entered account to array element
	jz			exitLoop											;jump to PINCompare if account number is in array
		
	add esi,	TYPE accountNumbers									;increment to access next array element
	inc	[indexAcc]													;keep track of index of array element under use
	ret																;return procedure

	exitLoop:														;If a match is found, no more iterations occur
		mov ecx, 1													;will exit any loop this procedure is in
		ret															;return procedure


AuthenticateInput endp





;-----------------------------------------------------
PINCompare proc														
;Compares the user PIN to the appropriate index in the PIN array. calls appropriate procedure depending on if there is a match or not.
;Receives: IndexAcc- the index at which the balance was found in the balance array
;Returns: nothing
;
;-----------------------------------------------------	
	mov [acctEntry],	ebx											;store user entered account number in acctEntry
	mov ebx,			0											;clear ebx
	or	edi,			1											;clear ZF

	mov esi,			[indexAcc]									;move index at which account balance was found into esi
	mov ax,				PINS[esi*TYPE PINS]							;move same index of PIN from array into ax
	mov ebx,			[PINEntry]									;store user entered pin into ebx
	cmp	ax,				bx											;compare pins with each other
	jz					jumpStore									;store balance if pins match
	jnz					jumpError
	ret																;return procedure

	jumpStore:														;if the PIN matches the account number, jump here
		call StoreBalance											;stores tha balance of account
		ret															;return procedure

	jumpError:														;if the PIN and account number do not match, jump here
		call EntryError												;display error message
		ret															;return procedure


PINCompare endp





;-----------------------------------------------------
StoreBalance proc													
;Retrieves the balance and stores it in a variable, if the user account information is authenticated
;Receives: nothing
;Returns, ebx-value of current balance of account under consideration, ecx- loop terminator once procedure is returned
;
;-----------------------------------------------------	
	mov esi,0
	mov ebx,0

	mov esi,			[indexAcc]									;move index of array that balance was matched to, to esi
	mov ebx,			balances[esi*TYPE balances]					;access that array element of balances array, and store it in ebx
	mov [currentBal],	ebx											;store value of current balance, into currentBal

	mov ecx, 1														;will exit any loop this procedure is in
	ret																;return procedure


StoreBalance endp





;-----------------------------------------------------
EntryError proc														;handle invalid Account/PIN entry
;Display error message for invalid authentication. Exit program after 3 attempts.
;Receives: nothing
;Returns: nothing
;
;-----------------------------------------------------	
	mov [indexAcc],	 0												;reset index count to zero for reuse in loop

	mov edx,		OFFSET erActPrompt								;show error for invalid entry
	call			WriteString								
	call			Crlf									
	call			WaitMsg											;show wait message
	call			Clrscr									

	cmp ecx, 1														;compares the current attempt to maximum allowed attempts
	jz TerminatePrgm												;terminates the program if current attempt=maximum allowed attempts
	ret																;return procedure

	TerminatePrgm:
		call	ErrorTerminate										;Go to terminate program if 3 attempts used up


EntryError endp





;-----------------------------------------------------
UserInput Proc
;Prompts the user for input
;Receives: edx-label to be prompted
;Returns: eax- the integer entered by the user
;
;-----------------------------------------------------
	call WriteString												;Write string to console
	call ReadInt													;Read integer input from user and store in eax
	call Crlf														;new linw
	ret																;return procedure


UserInput endp														;end procedure





;-----------------------------------------------------
ErrorTerminate proc
;Displays a terminate message and jumps to the main functions exit sequence.
;Receives: nothing
;Returns: nothing
;
;-----------------------------------------------------
	call	Clrscr													;clear screen, and display error message for too many attempts to login		
	mov		edx, OFFSET erAttempts									
	call	WriteString												
	call	Crlf													

	invoke ExitProcess,0											;program terminates
	ret																;return procedure


ErrorTerminate endp													;end procedure





;-----------------------------------------------------
MainMenu proc
;Displays and loops through the main menu. Matches the users integer input to the appropriate
;methods/labels for dealing with the input. Compares user selection to zero flag, jumps to appropriate label to handle option or error.
;Receives: nothing
;Requires: nothing
;-----------------------------------------------------
	or	edi, 1													;clear ZF

	call Clrscr													;clear screen
	mov edx, OFFSET menuPrompt									;move menu label to edx
	call UserInput												;display label and ask for user input and store it into eax
	mov selection, eax											;move users integer input into selection


	cmp [selection], 1											;compare users input to a number representing the menu option
	jl jumpRange												;if less than 1, give error
	jz jumpView													;if ZF set, jump to view current balance, option 1
	
	cmp [selection], 5											
	jg jumpRange												;if user input greater than 5, display error
	jz jumpTerminate											;if user enters 5, exit program

	cmp [selection], 2											
	je jumpWithdrawals											;if user enters 2, ask for withdrawal amount
													
	cmp [selection], 3											
	je jumpDeposits												;if user enters 3, display deposits menu
		
	cmp [selection], 4											
	je jumpPrint												;if user enters 4, print the receipt of current session

	jumpRange:													;various jumps for handling the input by jumping to appropriate procedure
		call RangePrompt
	jumpView:
		call ViewBalance
	jumpTerminate:
		call ErrorTerminate	
	jumpWithdrawals:
		call Withdrawals
	jumpDeposits:
		call Deposits	
	jumpPrint:
		call PrintReceipt	
		ret


MainMenu endp												;end procedure
												
		



;-----------------------------------------------------	
RangePrompt proc												
;Displays an error if an option outside of the range 1-5 is entered.
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	mov edx,	OFFSET erRange								;display error message for out of range
	call		WriteString									
	call		Crlf										
	call		WaitMsg										
	call		Clrscr										

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure


RangePrompt endp											;end procedure





;-----------------------------------------------------	
ViewBalance proc
;Displays the balance to the screen and then proceeds to the Main Menu.
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------													
	mov edx,	OFFSET dispBal								;display label to screen
	call		WriteString									
													
	mov eax,	[currentBal]								;display current balance to screen
	call		WriteDec									
	call		Crlf										
	call		Crlf										
	call		WaitMsg										;Show message and wait for user input

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure


ViewBalance endp											;end procedure





;-----------------------------------------------------	
Withdrawals proc											
;Checks that user entered withdrawal amount doesn't exceed 1000, isnt more than the balance, 
;and that max transactions haven't been reached. Jumps to appropriate procedure for each condition
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------													
	cmp [maxTransactions],	0								;make sure transaction limit has not been reached, otherwise show error
	jz			jumpPrevent							

	mov edx,	OFFSET dispWidr								;prompt for withdrawal
	call		UserInput									;display label and ask for user input and store it into eax
	cmp eax,	maxWidr										;compare user input to maximum allowed withdrawal of $1000
	ja			jumpOverFlow								;error for withdrawing too much
	jbe			jumpWidSuccess									;deal with a valid withdrawal amount

	jumpPrevent:
		call PreventTransaction
	jumpOverFlow:
		call WithdrawOverflow
	jumpWidSuccess:
		call WithdrawSuccess
	ret														;return procedure


Withdrawals endp											;end procedure





;-----------------------------------------------------	
WithdrawOverflow proc											
;Displays an error message for withdrawal amounts out of range
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	

	mov edx,	OFFSET erWidr								;display error for overlimit withdrawal
	call		WriteString										
	call		Crlf										
	call		WaitMsg										

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure


WithdrawOverflow endp										;end procedure





;-----------------------------------------------------	
WithdrawSuccess proc
;Checks to make sure user entry is less than current balance. Displays a message for a successful transaction.
;Displays the balance, and decrementss the number of remaining transactions.
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	cmp eax,	[CurrentBal]								;check to see if user requested withdrawal exceeds current balance and display error if so
	ja			jumpWidError 								

	sub [currentBal],	eax									;subtract entered withdrawal from current balance 
	add [totalWidr],	eax									;add entered withdrawal to total withdrawals

	mov edx,	OFFSET sucTrans								;display that the transaction was successful
	call		WriteString									
	call		Crlf										

	call		TransactionLimit							;decrease number of transactions that can be performed

	call		ViewBalance									;view the new balance

	jumpWidError:
		call WithdrawError
	ret														;return procedure


WithdrawSuccess endp										;end procedure





;-----------------------------------------------------	
WithDrawError proc												
;Displays error message for insufficient funds and proceeds to the main menu
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	mov edx,	OFFSET erWidrBal							;display error message to screen
	call		WriteString									
	call		Crlf										
	call		WaitMsg										

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure
	
				
WithDrawError endp											;end procedure





;-----------------------------------------------------	
Deposits proc													
;Displays the deposits menu, and takes the users selection
;and deposits the money accordingly.Makes sure transaction limit has not been reached.
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	cmp [maxTransactions],	0								;make sure transaction limit has not been reached, otherwise show error
	jz			jumpPrevent							

	call		Clrscr										;clear the screen
	mov edx,	OFFSET dispDepMen							;show the deposits menu
	call		UserInput									;display label and ask for user input and store it into eax

	mov [selection],	eax									;move user selection to selection variable
	cmp [selection],	1									;compare entry to integer 1
	je			jumpCash									;show prompt for cash desposit if `
	jne			jumpChq								;show prompt for cheques otherwise

	jumpPrevent:
		call PreventTransaction	

	jumpCash:
		call DepositCash	

	jumpChq:
		call DepositCheque
	ret														;return procedure


Deposits endp												;end procedure





;-----------------------------------------------------	
DepositCash proc												
;Prompts user to enter cash amount to deposit and stores the result.
;Receives: nothing
;Returns: dx-scale factor, eax-user's deposit amount
;-----------------------------------------------------	
	mov edx,	OFFSET dispDep								;display prompt to deposit cash as multiples of 10
	call		UserInput									;display label and ask for user input and store it into eax

	mov dx,		10											;multiple input by 10
	call		DepositMoney								;change the balance and show prompts accordingly
	ret														;return procedure


DepositCash endp											;end procedure
	




;-----------------------------------------------------	
DepositCheque proc												
;Prompts user to enter cheque amount to deposit and stores the result.
;Receives: nothing
;Returns: dx-scale factor, eax-user's deposit amount
;-----------------------------------------------------												
	mov edx,	OFFSET dispChq								;display prompt to deposit cheque amount
	call		UserInput									;display label and ask for user input and store it into eax

	mov dx,		1											;keep value of user entry the same
	call		DepositMoney								;change the balance and show prompts accordingly
	ret														;return procedure
	
				
DepositCheque endp											;end procedure





;-----------------------------------------------------
DepositMoney proc
;Scales the user entered deposit, adds the value to the current balance and total deposits balance
;and displays the new account balance to the screen
;Receives:dx, scale factor, eax- amount requested to be deposited
;Returns: nothing
;-----------------------------------------------------
	mul dx															;multiply dx by eax
	add [currentBal],	eax											;add eax to currentBal and total Dep
	add [totalDep],		eax											

	mov edx,	OFFSET sucTrans										;display that the transaction was successful
	call		WriteString											
	call		Crlf												
	call		TransactionLimit									;decrement the allowed number of transactions

	jmp			ViewBalance											;show current balance to screen
	ret																;return procedure


DepositMoney endp													;end procedure





;-----------------------------------------------------											
PrintReceipt proc								
;Displays the users account number, balance, and total withdrawals and deposits. Proceeds to the main menu
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	mov edx,	OFFSET disAccNum							;account number label display
	mov eax,	[acctEntry]									;current account number stored in eax to be displayed
	call		ReceiptView									;show label and  account number
		
	mov edx,	OFFSET dispTotWidr							;total withdrawals display
	mov eax,	[totalWidr]									;current value of total withdrawals
	call		ReceiptView	 								;show label and account number
		
	mov edx,	OFFSET dispTotDep							;total deposits display
	mov eax,	[totalDep]									;current calue of total deposits
	call		ReceiptView									;show label and total deposits

	mov edx,	OFFSET dispBal
	mov eax,	[currentBal]
	call		ReceiptView
	call		WaitMsg										;wait for user input to show menu again

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure


PrintReceipt endp											;end procedure





;-----------------------------------------------------
ReceiptView proc
;Prints to the console, the sessional information of balance and transactions
;Receives: edx- string labels, eax-integer values
;Returns: nothing
;
;-----------------------------------------------------
	call WriteString												;Write string to console
	call WriteDec													;write integer to console
	call Crlf														;new line
	call Crlf														;new line
	ret																;return procedure


ReceiptView endp													;end procedure





;-----------------------------------------------------	
PreventTransaction proc											
;Displays error message if transaction limit has been reached, stops further transactions.
;Proceeds to the main menu.
;Receives: nothing
;Returns: nothing
;-----------------------------------------------------	
	mov edx,	OFFSET erTransLim							;display error message for max transactions reached
	call		WriteString									
	call		WaitMsg										

	call		MainMenu									;loop back to MainMenu to display menu again
	ret														;return procedure


PreventTransaction endp										;end procedure





;-----------------------------------------------------
TransactionLimit proc
;Decrements the variable tracking the number of transactions. Sets the Zero flag
;Receives: maxTransactions- transaction number tracker
;Returns: nothing
;
;-----------------------------------------------------
	dec [maxTransactions]											;decrease number of transactions allowed, start is 3
	cmp [maxTransactions],	0										;If no more transactions allowed, set ZF
	ret																;return procedure


TransactionLimit endp												;end procedure





;-----------------------------------------------------
ClearRegisters Proc
;Clears all the registers for future use
;Receives: nothing
;Returns: nothing
;
;-----------------------------------------------------
	mov	eax, 0														;clear registers
	mov	ebx, 0											
	mov ecx, 0											
	mov edx, 0											
	mov	esi, 0
	mov	edi, 0
	ret																;return procedure


ClearRegisters endp													;end procedure







						
end main															;end of file
