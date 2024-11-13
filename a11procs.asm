; *****************************************************************
;  Name: Aaron De La Rosa
;  NSHE_ID: 5006117956
;  Section: 1002
;  Assignment: 11
;  Description:  File reading using system call and reading data into a buffer and checking

; -----
;  The provided main calls four functions.

;  1) checkParameters()
;	Get command line arguments (word, match case flag, and
;	file descriptor), performs appropriate error checking,
;	opens file, and returns the word, match case flag, and
;	the file descriptor and word.  If there any errors in
;	command line arguments, display appropriate error
;	message, and return FALSE status code.

;  2) getWord()
;	Get a single word of text (which must be verified
;	as no more than MAXWORDLENGTH characters).
;	Returned word is terminated with an NULL.
;	Note, this routine performs all buffer management.

;  NOTE: The buffer management is a significant portion of
;	the assignment.  Omitting or skipping the I/O
;	buffering will significantly impact the score.

;  3) checkWord()
;       Given the new word from the file and the user specified
;       word and the current count, update the count if the 
;	words match.

;----------------------------------------------------------------------------

section	.data

; -----
;  Define standard constants.

LF		equ	10			; line feed
NULL		equ	0			; end of string
SPACE		equ	0x20			; space
TAB		equ	0x09

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; Successful operation
NOSUCCESS	equ	1			; Unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

S_IRUSR		equ	00400q
S_IWUSR		equ	00200q
S_IXUSR		equ	00100q

; -----
;  Variables for getFileDescriptors()

usageMsg	db	"Usage: ./grep -w <searchWord> <-mc|-ic> -f <inputFile>"
		db	LF, NULL

errBadCLQ	db	"Error, invalid command line arguments."
		db	LF, NULL

errWordSpec	db	"Error, invalid search word specifier."
		db	LF, NULL

errWordLength	db	"Error, search word length must be < 80 "
		db	"characters."
		db	LF, NULL

errFileSpec	db	"Error, invalid input file specifier."
		db	LF, NULL

errCaseSpec	db	"Error, invalid match case specifier."
		db	LF, NULL

errOpenIn	db	"Error, can not open input file."
		db	LF, NULL
		
errBadRead	db	"Error, can read input file, program terminated."
		db	LF, NULL

; -----
;  Define constants and variables for getWord()

MAXWORDLENGTH	equ	80
BUFFSIZE	equ	800000

bfMax		dq	BUFFSIZE
currentIndex		dq	BUFFSIZE

EOF		db	FALSE

i           dq  0

letterFound  db  FALSE

errFileRead	db	"Error reading input file."
		db	LF, NULL

; -------------------------------------------------------

section	.bss 

Buffer		resb	BUFFSIZE+1
currentWord	resb	MAXWORDLENGTH+1


; -------------------------------------------------------

section	.text

;pass string in rdi?
global checkSpace
checkSpace:
   ; push rdi  ; Preserve the value of rdi

lloop:
    mov al, r14b
    cmp al, 'A'
    jl invalidletter
    cmp al, 'Z'
    jle validletter

    cmp al, 'a'
    jl invalidletter
    cmp al, 'z'
    jle validletter

invalidletter:
    mov rax, FALSE
    jmp doneCheck

validletter:
    mov rax, TRUE

doneCheck:
    ;pop rdi  ; Restore the value of rdi

    ret







; -------------------------------------------------------
;  Check and return command line parameters.
;	Assignment #11 requires a word to search for, flag for
;	case handling and a file name.
;	Example:    % ./grep -w <searchWord> <-mc|-ic> -f <infile>

; NOTE: Match case (-mc) is TRUE to match case.
;	Match case (-ic) is FALSE when ignoring case.
;	To ignore case, it is easiest to either uppoer or lower case
;	all letters in both strings to be compared.
;	Note, best to NOT change the original and perform the match on
;	a copy of the original.

; -----
; HLL Call:
;	bool = checkParameters(ARGC, ARGV, searchWord, matchCase, rdFileDesc)

;  Arguments passed:
;	1) argc, value = rdi
;	2) argv, address = rsi
;	3) search word string, address = rdx
;	4) match case boolean, address = rcx
;	5) input file descriptor, address = r8?

global checkParameters
checkParameters:
push rbp
mov rbp, rsp

mov rbx, rsi ;put argv in rbx
mov r12, rdi ; puts argc in r12
mov r14, rdx
mov r15, rcx

;check if argc = 1
cmp r12, 1
jne checkArgC
mov rdi, usageMsg
call printString
mov rax, FALSE
jmp end

; check if argc != 6
checkArgC:
cmp r12, 6
je argcGood
mov rdi, errBadCLQ
call printString
mov rax, FALSE
jmp end

argcGood:
mov r12, 0
mov r12, qword[rbx+8] ; sets r12 to argv[1] Word Spec

mov al, byte[r12]
cmp al, "-"
jne errorW
mov al, byte[r12+1]
cmp al, "w"
jne errorW
mov al, byte[r12+2]
cmp al, NULL
jne errorW

jmp wordCheck

errorW:
mov rdi, errWordSpec
call printString
mov rax, FALSE
jmp end

wordCheck:
mov r12, qword[rbx+16]  ; Set r12 to argv[2] Word search
    
    ; Initialize index and loop
    mov r10, 0  ; Index
	mov rax, 0
	mov r13, 0 ; second index
    
sizeLoop: ; Size check loop
    cmp r10, MAXWORDLENGTH  ; Check if the word length exceeds the maximum
    jge sizeExceeded  ; If so, exit the loop
    
    mov al, byte[r12 + r10]  ; Load the byte from the string into al
    cmp al, NULL  ; Check if it's the end of the string
    je mCase
    
    mov byte[r14+ r13], al  ; Store the character in the memory location pointed to by rdx
    inc r13  ; Move to the next byte in the destination buffer
    inc r10  ; Increment the index
    jmp sizeLoop  ; Repeat the loop

sizeExceeded:
    mov rdi, errWordLength  ; Print error message for word length exceeding limit
    call printString
    mov rax, FALSE  ; Set return value to FALSE
    jmp end  ; Exit
    
mCase:
;<-mc|-ic>
;return case as a true or false byte 
mov byte[r14+ r13], NULL
mov rdx, r14
mov r12, qword[rbx+24] ;sets r12 to argv[3] case spec

mov al, byte[r12]
cmp al, "-"
jne errorMC

mov al, byte[r12+1]
cmp al, "m"
je matchCase
cmp al, "i"
je ignoreCase
jmp errorMC

matchCase:
mov cl, TRUE  ;returns byte to argument register
mov byte[r15], cl
jmp caseCheck
ignoreCase:
mov cl, FALSE
mov byte[r15], cl
jmp caseCheck

caseCheck:
mov al, byte[r12+2]
cmp al, "c"
jne errorMC
mov al, byte[r12+3]
cmp al, NULL 
jne errorMC
jmp filespecCheck


errorMC:
mov rdi, errCaseSpec
call printString
mov rax, FALSE
jmp end


filespecCheck:

mov r12, qword[rbx+32] ; argv[4] filespec

mov al, byte[r12]
cmp al, "-"
jne errorF
mov al, byte[r12+1]
cmp al, "f"
jne errorF
mov al, byte[r12+2]
cmp al, NULL
jne errorF

jmp fileCheck

errorF:
mov rdi, errFileSpec
call printString
mov rax, FALSE
jmp end


fileCheck:

mov r12, qword[rbx+40] ; argv[5] file name

push rdi
push rsi
push rdx
push rcx
push r8

mov rax, SYS_open
mov rdi, r12
mov rsi, O_RDONLY
syscall
pop r8
pop rcx
pop rdx
pop rsi
pop rdi

cmp rax, 0
jl fileOpenError
mov qword[r8], rax
mov rax, TRUE
jmp end


fileOpenError:
mov rdi, errOpenIn
call printString
mov rax, FALSE
jmp end


end:

pop rbp
ret

; -------------------------------------------------------
;  Get a single word of text and return.
;  Implements basic C++ (searchWord << inFile) functionality.

;  A "word" is considered a set of contiguous non-white space
;  characters.  White space includes spaces, tabs, and LF.
;  Any character <= a space character is considered white space.
;  Function terminates word string with a NULL.

;  If a word exceeds the passed max length, must not over-write
;  the buffer.  Instead, just skip remaining characters.
;  This returns a partial word (which is ok in this context).

;  This routine handles the I/O buffer management.
;	- if buffer is empty, get more chars from file
;	- return word and update buffer pointers

;  If a word is returned, return TRUE.
;  Otherwise, return FALSE.

; -----
; HLL Call:
;	bool = getWord(currentWord, maxLength, rdFileDesc)

;  Arguments passed:
;	1) word buffer, address ;rdi
;	2) max word length (excluding NULL), value ;rsi
;	3) file descriptor, value ;rdx

;Cutting off word midway
; I fixed it by checking if I hit the end of the buffer before grabbing a character.
; If I hit the end of the buffer but I haven’t hit a non-letter character in my current word yet, 
;I go back and refill the buffer before continuing


global getWord ;everytime you get 1 word your return true and exit
getWord:
push r10
push r11
push r12
push r13
push r14
push r15

mov r15, rdi ;current word

mov qword[i], 0 ;i = 0 

;**********
getNextByte: 
mov rax, qword[bfMax]
cmp qword[currentIndex], rax ;if currentIndex >= buffmax refill buffer
jge fillBuffer
jmp skipFill

cmp byte[EOF], TRUE
je reachedEnd

fillBuffer:
push rdi
push rsi
push rdx
mov rax, SYS_read
mov rdi, rdx ;sets to file descriptor
mov rsi, Buffer ;sets rsi to address of buffer
mov rdx, BUFFSIZE ;cnt of char to read
syscall
pop  rdx
pop  rsi
pop  rdx

cmp rax, 0 ;check for read error, if so return false
jl readError

cmp rax, BUFFSIZE ;check if actualRead(rax) < requestedRead) ; eof = true ; buffMax = actualRead
jne valueChange 
jmp indexReset

valueChange:
mov byte[EOF], TRUE
mov qword[bfMax], rax
cmp rax, 0
je reachedEnd


indexReset:
mov qword[currentIndex], 0




skipFill: ;put chr in buffer in register and send check if letter
mov r12, qword[currentIndex] ;set to index increment

mov r14b, byte[Buffer + r12] ;sets r11b to first byte if buffer
inc qword[currentIndex] ;increment buffer index

cmp qword[i], MAXWORDLENGTH ;compares currentWor[i] index > 80
jg getWord ;Word too big and fetches next chr


push rdi
mov dil, r14b 
call checkSpace ;letter check function
pop rdi
cmp rax, 0 ;check if False or non-letter
je skip1

mov byte[letterFound], TRUE ;otherwise first letter was found so now true

mov r13, qword[i]
mov byte[r15 + r13], r14b ;saves chr from register to currentword ;Segfaulting?
inc qword[i] ;increments currentWord index to not overwrite
jmp getNextByte

skip1:
cmp byte[letterFound], TRUE ;checks bool if letter has been found
je capNull ;if yes cap with null
jmp getNextByte ;if not check next byte, most likely blanks before letter

capNull:
mov r13, qword[i]
mov byte[r15+r13], NULL ;seg faulting?
mov rax, TRUE ;returns getword true
jmp fin

readError:
mov rdi, errFileRead
call printString
mov rax, FALSE
jmp fin


reachedEnd:
mov rax, FALSE


fin:
pop r15
pop r14
pop r13
pop r12
pop r11
pop r10
ret
; -------------------------------------------------------
;  Compare strings, searchWord to currWord.
;  If same, increment word count.
;  Must handle match based on case flag.

; NOTE: Match case (-mc) is TRUE to match case.
;	Match case (-ic) is FALSE when ignoring case.
;	To ignore case, it is easiest to either uppoer or lower case
;	all letters in both strings to be compared.
;	Note, best to NOT change the original and perform the match on
;	a copy of the original.

; -----
;  HLL Call:
;	call checkWord(searchWord, currentWord, matchCase, wordCount)

;  Argument passed:
;	1) searchWord, address = rdi
;	2) currentWord, address = rsi 
;	3) match case flag, value = rdx
;	4) word count, address = rcx
global checkWord
checkWord:
push r14
push r13
push r10



mov r14, rdi ;searchword
mov r13, rsi ;curret word
mov r10, 0 ;index

mov r9b, dl
cmp r9b, FALSE
je ignore
jmp checkCase

ignore:
;convert to searchword to lower case
searchWC:
mov al, byte[r14 + r10]
cmp al, NULL
je nextC
cmp al, "Z"
jle lowerConvert
inc r10
jmp searchWC

lowerConvert: ;to convert to lower add 32 = " "
add al, " " ;converts to uppercase
mov byte[r14 + r10], al
inc r10
jmp searchWC

nextC:
mov r10, 0
;convertCurrentword to lowercase
currentWC:
mov al, byte[r13 + r10]
cmp al, NULL
je checkabc
cmp al, "Z"
jle secondlowerConvert
inc r10
jmp currentWC

secondlowerConvert:
add al, " " ;converts to uppercase
mov byte[r13 + r10], al
inc r10
jmp currentWC

checkabc:
mov r10, 0; reset index

jmp checkCase ;reuse code

checkCase:
mov al, byte[r14 + r10]
cmp al, byte[r13 + r10]
jne noMatch
cmp al, NULL
je matchFound
inc r10
jmp checkCase


matchFound:
;dereference rcx and add 1
mov eax, dword[rcx]
add eax, 1
mov dword[rcx], eax

noMatch:

pop r10
pop r13
pop r14

ret
; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.

;  Algorithm:
;	Count characters in string (excluding NULL)
;	Uses syscall to output characters

; -----
;  HLL Call:
;	printString(stringAddr);

;  Arguments:
;	1) address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
;  Count characters to write.

	mov	rdx, 0
strCountLoop:
	cmp	byte [rdi+rdx], NULL
	je	strCountLoopDone
	inc	rdx
	jmp	strCountLoop
strCountLoopDone:
	cmp	rdx, 0
	je	printStringDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; rdx=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

printStringDone:
	ret

; ******************************************************************
