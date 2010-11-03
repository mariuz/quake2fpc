.386P
.model FLAT

include ..\ref_soft\qasm.inc

if id386

_DATA SEGMENT
 bias 		dd 0	;static unsigned long bias
 histogramPtr 	dd 0	;static unsigned long *histogram;
 start 		dd 0	;static unsigned long start, range;
 range 		dd 0

 x86_loopindex_i dd 0		;i indice intero
 biastable dd 100 dup (?)	;unsigned long biastable[100];
 Lstack dd 0			
_DATA ENDS


_TEXT SEGMENT


EXTRN _Z_Malloc


public _x86_TimerStart

_x86_TimerStart:

    db 0fh 
    db 31h
    mov  start, eax
    ret


public _x86_TimerStop

_x86_TimerStop:

    push edi
    mov edi, histogramPtr
    db 0fh
    db 31h
    sub eax, start
    sub eax, bias
    js discard
    cmp eax, range
    jge  discard
    lea edi, [edi + eax*4]
    inc dword ptr [edi]
discard:
    pop edi
    ret



public _x86_TimerStopBias

_x86_TimerStopBias:
    
    push edi
    mov edi, histogramPtr
    db 0fh
    db 31h
    sub eax, start
    pop edi
    ret



;void x86_TimerInit( unsigned long smallest, unsigned length )

public _x86_TimerInit

_x86_TimerInit PROC

 ARG smallest:DWORD, lunghezza:DWORD
 push ebp	; preserve caller's stack frame
 push edi	
 push esi	; preserve register variables
 push edx
;mov ds:dword ptr[Lstack],esp	; for clearing the stack later
 mov ebp, esp


;	range = length;
;	bias = 10000;

 mov eax, lunghezza
 mov bias, 02710h
 
 mov range, eax
 xor edx, edx	; azzeriamo EDX 
 
x86_Loop1:

;	for ( i = 0; i < 100; i++ )
;	{
;		x86_TimerStart();
;		biastable[i] = x86_TimerStopBias();


 db 0fh 
 db 31h
 mov  start, eax
 mov edi, histogramPtr
 db 0fh
 db 31h
 sub eax, start
 mov [biastable + edx*4], eax
 
 


;		if ( bias > biastable[i] )
;			bias = biastable[i];

 cmp bias, eax
 jle x86_minore
 mov bias, eax

x86_minore:
 cmp edx, 063h
 jl x86_Loop1

;	}

;	bias += smallest;

 mov edx, smallest
 add bias, edx

;	histogramPtr = Z_Malloc( range * sizeof( unsigned long ) );

 mov eax, 4
 push eax
 call _Z_Malloc
 mov histogramPtr, eax

 pop ebx	; restore register variables
 pop esi	
 pop edi	
 pop ebp	; restore the caller's stack frame
 ret	

_x86_TimerInit ENDP





public _x86_TimerGetHistogram

_x86_TimerGetHistogram PROC

 mov eax, histogramPtr
 ret
 
_x86_TimerGetHistogram ENDP


_TEXT ENDS
endif	;id386
END