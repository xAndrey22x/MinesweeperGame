.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "MineSweeper",0
area_width EQU 640
area_height EQU 480
area DD 0


counter DD 0 ; numara evenimentele de tip timer
counterok DD 0
ifStart DD 0
ifInGame DD 0
ifClickedRightInGame DD 0


arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc


button_x EQU 217
button_y EQU 160
button_width EQU 160
button_height EQU 80

exit_x EQU 240
exit_y EQU 390
exit_width EQU 130
exit_height EQU 60

game_x EQU 120
game_y EQU 50
game_width EQU 400
game_height EQU 320

blockpos1 DD 0
blockpos2 DD 0

nearbyx DD 0
nearbyy DD 0

matrix DB 100 DUP(0)
loopprint_matrix DB 80
loopbombs_matrix DB 12
counter_matrix DB 0

format_printf_matrix DB "%d ",0
format_printf2_matrix DB " ",13,10,0

include bomba.inc
bomba_width EQU 20
bomba_height EQU 20
counter_draw_picture DB 0

matrix_pixel_poz DD 0
matrix_x DD 0
matrix_y DD 0
nearbyx_draw DD 0
nearbyy_draw DD 0

textcolor DB 0
ifLose DD 0
ifWin DD 0
counterToWin DB 0

first0x DD 0
first0y DD 0
first0matrix DD 0
rr DD 0
rl DD 0
ru DD 0
rd DD 0
rlu DD 0
rru DD 0
rld DD 0

backup0x DD 0
backup0y DD 0
backup0matrix DD 0
second_diagonal DD 0
third_diagonal DD 0
fourth_diagonal DD 0

.code


; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	cmp textcolor, 0
	jne pixel_gri
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
	pixel_gri:
	mov dword ptr [edi], 0D3D3D3h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


line_horizontal macro x, y, len, color
local bucla_line
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl eax, 2 ; EAX = (y*area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

line_vertical macro x, y, len, color
local bucla_line
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl eax, 2 ; EAX = (y*area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add EAX, area_width * 4
	loop bucla_line
endm

bomb_draw macro x, y
local bucla_line, same_row
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl eax, 2 ; EAX = (y*area_width + x) * 4
	add eax, area
	mov ecx, 400
	lea esi, bomba
	mov counter_draw_picture, 0
bucla_line:
	mov EBX, dword ptr[esi]
	mov dword ptr[eax], EBX
	inc counter_draw_picture
	cmp counter_draw_picture, 20
	jne same_row
	sub EAX, 20 * 4
	add EAX, 4 * area_width
	mov counter_draw_picture, 0
same_row:
	add ESI, 4
	add EAX, 4
	loop bucla_line
endm

create_random_matrix macro
local bomb_loop, already_bomb, number_of_bombs_loop, search_another1, search_another2, search_another3, search_another4, search_another5, search_another6, search_another7, search_another8
	
	; plasare bombe
	
	bomb_loop:
	rdtsc
	mov EBX, 80
	mov EDX, 0
	div EBX
	cmp matrix[EDX], 9
	je already_bomb
	mov matrix[EDX], 9
	dec loopbombs_matrix
	already_bomb:
	cmp loopbombs_matrix, 0
	jne bomb_loop
	
	;plasare numar bombe adiacente
	
	mov ESI, 0
	mov EDI, 0
	mov loopprint_matrix, 80
	
	number_of_bombs_loop:
	
	mov ebx,0
	mov BL, byte ptr matrix[EDI][ESI] 
	
	cmp EBX, 9
	je incrementare
	
	mov counter_matrix, 0
	mov ebx,0
	
	;dreapta
	
	cmp ESI, 9
	je search_another1
	mov BL, byte ptr matrix[EDI][ESI + 1] 
	cmp EBX, 9
	jne search_another1
	inc counter_matrix
	
	search_another1:
	
	;stanga
	
	cmp ESI, 0
	je search_another2
	mov BL, byte ptr matrix[EDI][ESI - 1] 
	cmp EBX, 9
	jne search_another2
	inc counter_matrix
	
	search_another2:
	
	;jos
	
	; cmp ESI, 9
	; je search_another3
	mov BL, byte ptr matrix[EDI][ESI + 10] 
	cmp EBX, 9
	jne search_another3
	inc counter_matrix
	
	search_another3:
	
	;sus
	
	; cmp ESI, 0
	; je search_another4
	mov BL, byte ptr matrix[EDI][ESI - 10] 
	cmp EBX, 9
	jne search_another4
	inc counter_matrix
	
	search_another4:
	
	;dreapta sus
	
	cmp ESI, 0
	je search_another5
	mov BL, byte ptr matrix[EDI][ESI + 9] 
	cmp EBX, 9
	jne search_another5
	inc counter_matrix
	
	search_another5:
	
	;stanga sus
	
	cmp ESI, 9
	je search_another6
	mov BL, byte ptr matrix[EDI][ESI + 11] 
	cmp EBX, 9
	jne search_another6
	inc counter_matrix
	
	search_another6:
	
	;dreapta jos
	
	cmp ESI, 0
	je search_another7
	mov BL, byte ptr matrix[EDI][ESI - 11] 
	cmp EBX, 9
	jne search_another7
	inc counter_matrix
	
	search_another7:
	
	;stanga jos
	
	cmp ESI, 9
	je search_another8
	mov BL, byte ptr matrix[EDI][ESI - 9] 
	cmp EBX, 9
	jne search_another8
	inc counter_matrix
	
	search_another8:
	
	mov ebx, 0
	mov bl, counter_matrix
	mov byte ptr matrix[EDI][ESI], BL
	
	incrementare:
	inc ESI
	cmp ESI, 10
	jne continue_with_curent_row
	mov ESI,0
	add EDI, 10
	continue_with_curent_row:
	dec loopprint_matrix
	cmp loopprint_matrix, 0
	jne number_of_bombs_loop
endm



; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	; mov eax, [ebp+arg3] ; EAX = y
	; mov ebx, area_width
	; mul ebx ; EAX = y * area_width
	; add eax, [ebp+arg2] ; EAX = y*area_width + x
	; shl eax, 2 ; EAX = (y*area_width + x) * 4
	; add eax, area
	; mov dword ptr[eax], 0FF0000h
	; mov dword ptr[eax+4], 0FF0000h
	; mov dword ptr[eax-4], 0FF0000h
	; mov dword ptr[eax + 4 * area_width], 0FF0000h
	; mov dword ptr[eax - 4 * area_width], 0FF0000h
	; line_horizontal [ebp+arg2], [ebp+arg3], 30, 0FFh
	; line_vertical [ebp+arg2], [ebp+arg3], 30, 0FFh
	
	;Verificam daca a fost apasat startul
	
	cmp ifStart, 1
	je already_ingame
	
	mov EAX, [ebp+arg2]
	cmp eax, button_x
	jl button_fail
	cmp eax, button_x + button_width
	jg button_fail
	mov EAX, [ebp+arg3]
	cmp eax, button_y
	jl button_fail
	cmp eax, button_y+button_height
	jg button_fail
	; s-a dat click in buton
	mov ifStart, 1
	
	
	
	; make_text_macro 'O', area, button_x + button_width / 2 - 5, button_y + button_height + 10
	; make_text_macro 'K', area, button_x + button_width / 2 + 5, button_y + button_height + 10
	; mov counterok, 0
	
button_fail:
	; make_text_macro ' ', area, button_x + button_width / 2 - 5, button_y + button_height + 10
	; make_text_macro ' ', area, button_x + button_width / 2 + 5, button_y + button_height + 10
	
	
	jmp afisare_litere

already_ingame:

	
;colorare blocuri pe care dam click
	
    mov ifInGame, 1 ; retinem ca a fost apasat startul
	
	;nu coloram exteriorul jocului
	mov ifClickedRightInGame, 0
	
	mov EAX, [ebp+arg2]
	cmp eax, game_x
	jl wrong_click
	cmp eax, (game_x + game_width)
	jg wrong_click
	mov EAX, [ebp+arg3]
	cmp eax, game_y
	jl wrong_click
	cmp eax, (game_y + game_height)
	jg wrong_click
	
	mov ifClickedRightInGame, 1 ; retinem ca am apasat in interiorul jocului
	
	
	mov EAX, [ebp+arg2]
	mov EBX, [ebp+arg3]
	
	mov nearbyx, EAX
	mov nearbyy, EBX
	
	
	
	; find the most nearbyx x and y to fill a block
	
reveal_nearby_blocks:
	
	
bucla_nearbyx:
	mov EAX, nearbyx
	sub EAX, game_x
	mov EBX, 40
	mov EDX, 0
	div EBX
	dec nearbyx
	cmp EDX, 0
	jne bucla_nearbyx
	
bucla_nearbyy:
	mov EAX, nearbyy
	sub EAX, game_y
	mov EBX, 40
	mov EDX, 0
	div EBX
	dec nearbyy
	cmp EDX, 0
	jne bucla_nearbyy
	
	;verificare daca s-a pierdut
	
	mov EAX, ifLose
	cmp EAX, 0
	jne wrong_click
	
	;verificare daca s-a castigat
	
	mov EAX, ifWin
	cmp EAX, 0
	jne wrong_click
	
	; colorare block pe care am apasat
	
	mov EDI, 1
	mov EAX, nearbyy
	mov blockpos1, EAX
	add blockpos1, 2
	add nearbyx, 2
bucla_fundal_block:
	line_horizontal nearbyx, blockpos1, 39, 0D3D3D3h
	add blockpos1, 1
	inc EDI
	cmp EDI, 40
	jne bucla_fundal_block
	
	; plasare bombe la locatiile din matrice
	
	mov EAX, nearbyx
	mov nearbyx_draw,EAX
	mov EAX, nearbyy
	add EAX, 2
	mov nearbyy_draw,EAX
	
	add nearbyx_draw, 9
	add nearbyy_draw, 9
	
	
	
	sub nearbyx, 2
	sub nearbyx, 119
	sub nearbyy, 49
	
	mov EBX, 0
	mov EBX, 40
	mov EAX, 0
	mov EAX, nearbyx
	div EBX
	
	mov matrix_x, EAX
	
	mov EAX, 0
	mov EAX, nearbyy
	div EBX
	
	mov matrix_y, EAX
	
	mov matrix_pixel_poz, 0
	mov EBX, matrix_x
	mov matrix_pixel_poz, EBX
	
	mov EAX, matrix_y
	mov EBX, 10
	mul EBX
	add matrix_pixel_poz, EAX
	
	
	mov ESI, matrix_pixel_poz
	
	cmp matrix[ESI], 10
	jge not_increment
	inc counterToWin
	not_increment:
	
	cmp matrix[ESI], 9
	jne not_bomb
	mov ifLose, 1
	
	bomb_draw nearbyx_draw, nearbyy_draw
	mov textcolor, 0
	make_text_macro 'G', area, 270, 20
	make_text_macro 'A', area, 280, 20
	make_text_macro 'M', area, 290, 20
	make_text_macro 'E', area, 300, 20
	make_text_macro ' ', area, 310, 20
	make_text_macro 'O', area, 320, 20
	make_text_macro 'V', area, 330, 20
	make_text_macro 'E', area, 340, 20
	make_text_macro 'R', area, 350, 20
	
	jmp continue_game
	
	not_bomb:
	
	cmp matrix[ESI], 10
	jng first_call
	sub matrix[ESI], 10
	first_call:
	
	mov textcolor, 1
	mov EAX, nearbyx_draw
	add EAX, 5
	
	cmp matrix[ESI], 1
	jne next_number1
	make_text_macro '1', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	next_number1:
	
	cmp matrix[ESI], 2
	jne next_number2
	make_text_macro '2', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number2:
	cmp matrix[ESI], 3
	jne next_number3
	make_text_macro '3', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number3:
	cmp matrix[ESI], 4
	jne next_number4
	make_text_macro '4', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number4:
	cmp matrix[ESI], 5
	jne next_number5
	make_text_macro '5', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number5:
	cmp matrix[ESI], 6
	jne next_number6
	make_text_macro '6', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number6:
	cmp matrix[ESI], 7
	jne next_number7
	make_text_macro '7', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	next_number7:
	cmp matrix[ESI], 8
	jne not_number
	make_text_macro '8', area, EAX, nearbyy_draw
	add matrix[ESI], 10
	
	not_number:
	
	;reveal right
	
	mov ECX, rld
	cmp ECX, 1
	je reveal_right_down
	
	mov ECX, rru
	cmp ECX, 1
	je reveal_left_down
	
	mov ECX, rlu
	cmp ECX, 1
	je reveal_right_up
	
	mov ECX, rd
	cmp ECX, 1
	je reveal_left_up
	
	mov ECX, ru
	cmp ECX, 1
	je reveal_down
	
	mov ECX, rl
	cmp ECX, 1
	je reveal_up
	
	mov ECX, rr
	cmp ECX, 1
	je reveal_left
	
	
	
	cmp matrix[ESI], 0
	jne reveal_left
	cmp first0x, 0
	jne nu_retinem
	mov first0x, EAX
	mov EBX, nearbyy_draw
	mov first0y, EBX
	mov first0matrix, ESI
	
	cmp backup0x, 0
	jne backup_already
	
	mov ECX, first0x
	mov backup0x, ECX
	mov ECX, first0y
	mov backup0y, ECX
	mov ECX, first0matrix
	mov backup0matrix, ECX
	
	backup_already:
	
	nu_retinem:
	add matrix[ESI], 10
	add EAX, 40
	cmp EAX, (game_x+game_width)
	jg reveal_left
	mov nearbyx, eax
	mov EBX, nearbyy_draw
	mov nearbyy, EBX
	jmp reveal_nearby_blocks
	
	;reveal left
	
	
	reveal_left:
	
	cmp first0x, 0
	jne not_problem
	
	cmp fourth_diagonal, 1
	je continuare_joc
	
	cmp third_diagonal, 1
	je continue_diagonal2
	
	cmp second_diagonal, 1
	je continue_diagonal1
	
	cmp backup0x, 0
	jne continue_diagonal
	not_problem:
	
	
	mov ECX, rr
	cmp ECX, 0
	jne already_reveal_left
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_left:
	mov rr, 1
	cmp matrix[ESI], 0
	jne reveal_up
	add matrix[ESI], 10
	sub EAX, 40
	cmp EAX, game_x
	jl reveal_up
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	mov nearbyy, EBX
	jmp reveal_nearby_blocks
	
	;reveal up
	
	
	reveal_up:
	mov ECX, rl
	cmp ECX, 0
	jne already_reveal_up
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_up:
	mov rl, 1
	cmp matrix[ESI], 0
	jne reveal_down
	add matrix[ESI], 10
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	sub EBX, 40
	cmp EBX, game_y
	jl reveal_down
	mov nearbyy, EBX
	jmp reveal_nearby_blocks
	
	
	;reveal down
	
	
	reveal_down:
	mov ECX, ru
	cmp ECX, 0
	jne already_reveal_down
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_down:
	mov ru, 1
	cmp matrix[ESI], 0
	jne reveal_left_up
	add matrix[ESI], 10
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	add EBX, 40
	cmp EBX, (game_y + game_height)
	jg reveal_left_up
	mov nearbyy, EBX
	jmp reveal_nearby_blocks
	
	;reveal left up
	
	
	reveal_left_up:
	
	cmp second_diagonal, 1
	je reveal_right_up
	
	mov ECX, rd
	cmp ECX, 0
	jne already_reveal_left_up
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_left_up:
	mov rd, 1
	cmp matrix[ESI], 0
	jne reveal_right_up
	add matrix[ESI], 10
	sub EAX, 40 
	cmp EAX, game_x
	jl reveal_right_up
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	sub EBX, 40
	cmp EBX, game_y
	jl reveal_right_up
	mov nearbyy, EBX
	mov rd, 0
	mov ru, 0
	mov rl, 0
	mov rr, 0
	mov rlu, 0
	mov rru, 0
	mov rld, 0
	mov first0x, 0
	mov first0y, 0
	mov first0matrix, 0
	jmp reveal_nearby_blocks
	
	
	;reveal right up
	
	
	continue_diagonal:
	
	reveal_right_up:
	
	cmp backup0x, 0
	je never_backup
	
	mov ECX, backup0x
	mov first0x, ECX
	mov ECX, backup0y
	mov first0y, ECX
	mov ECX, backup0matrix
	mov first0matrix, ECX
	
	never_backup:
	
	mov ECX, rlu
	cmp ECX, 0
	jne already_reveal_right_up
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_right_up:
	mov rlu, 1
	cmp matrix[ESI], 0
	jne reveal_left_down
	add matrix[ESI], 10
	add EAX, 40 
	cmp EAX, (game_x + game_width)
	jg reveal_left_down
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	sub EBX, 40
	cmp EBX, game_y
	jl reveal_left_down
	mov nearbyy, EBX
	
	mov rd, 0
	mov ru, 0
	mov rl, 0
	mov rr, 0
	mov rlu, 0
	mov rru, 0
	mov rld, 0
	mov first0x, 0
	mov first0y, 0
	mov first0matrix, 0
	
	mov second_diagonal, 1
	
	jmp reveal_nearby_blocks
	
	;reveal left down
	
	continue_diagonal1:
	
	reveal_left_down:
	
	cmp backup0x, 0
	je never_backup1
	
	mov ECX, backup0x
	mov first0x, ECX
	mov ECX, backup0y
	mov first0y, ECX
	mov ECX, backup0matrix
	mov first0matrix, ECX
	
	never_backup1:
	
	mov ECX, rru
	cmp ECX, 0
	jne already_reveal_left_down
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_left_down:
	mov rru, 1
	cmp matrix[ESI], 0
	jne reveal_right_down
	add matrix[ESI], 10
	sub EAX, 40 
	cmp EAX, game_x
	jl reveal_right_down
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	add EBX, 40
	cmp EBX, (game_y + game_height)
	jg reveal_right_down
	mov nearbyy, EBX
	
	mov rd, 0
	mov ru, 0
	mov rl, 0
	mov rr, 0
	mov rlu, 0
	mov rru, 0
	mov rld, 0
	mov first0x, 0
	mov first0y, 0
	mov first0matrix, 0
	
	mov third_diagonal, 1
	
	jmp reveal_nearby_blocks
	
	;reveal right down
	
	continue_diagonal2:
	
	reveal_right_down:
	
	cmp backup0x, 0
	je never_backup2
	
	mov ECX, backup0x
	mov first0x, ECX
	mov ECX, backup0y
	mov first0y, ECX
	mov ECX, backup0matrix
	mov first0matrix, ECX
	
	never_backup2:
	
	mov ECX, rld
	cmp ECX, 0
	jne already_reveal_right_down
	cmp first0x, 0
	je continuare_joc
	mov EAX, first0x
	mov EBX, first0y
	mov nearbyy_draw, EBX
	mov ESI, first0matrix
	sub matrix[ESI], 10
	already_reveal_right_down:
	mov rld, 1
	cmp matrix[ESI], 0
	jne continuare_joc
	add matrix[ESI], 10
	add EAX, 40 
	cmp EAX, (game_x + game_width)
	jg continuare_joc
	mov nearbyx, EAX
	mov EBX, nearbyy_draw
	add EBX, 40
	cmp EBX, (game_y + game_height)
	jg continuare_joc
	mov nearbyy, EBX
	
	mov rd, 0
	mov ru, 0
	mov rl, 0
	mov rr, 0
	mov rlu, 0
	mov rru, 0
	mov rld, 0
	mov first0x, 0
	mov first0y, 0
	mov first0matrix, 0
	
	mov fourth_diagonal, 1
	
	jmp reveal_nearby_blocks
	
	continuare_joc:
	mov rd, 0
	mov ru, 0
	mov rl, 0
	mov rr, 0
	mov rlu, 0
	mov rru, 0
	mov rld, 0
	mov first0x, 0
	mov first0y, 0
	mov first0matrix, 0
	mov backup0x, 0
	mov second_diagonal, 0
	mov third_diagonal, 0
	mov fourth_diagonal, 0
	
	; add matrix[ESI], 10
	
	
	
	
	
	cmp counterToWin, 68
	jne continue_game
	mov ifWin, 1
	mov textcolor, 0
	make_text_macro 'G', area, 270, 20
	make_text_macro 'A', area, 280, 20
	make_text_macro 'M', area, 290, 20
	make_text_macro 'E', area, 300, 20
	make_text_macro ' ', area, 310, 20
	make_text_macro 'W', area, 320, 20
	make_text_macro 'O', area, 330, 20
	make_text_macro 'N', area, 340, 20
	
	continue_game:
	
	; add nearbyy, 2
	; bomb_draw nearbyx, nearbyy
	
wrong_click:
	
	cmp ifClickedRightInGame, 1
	je final_draw

	
	mov EAX, [ebp+arg2]
	cmp eax, exit_x
	jl final_draw
	cmp eax, exit_x + exit_width
	jg final_draw
	mov EAX, [ebp+arg3]
	cmp eax, exit_y
	jl final_draw
	cmp eax, exit_y + exit_height
	jg final_draw
	
button_exit:
	push 0
	call exit
	
evt_timer:
	inc counter
	inc counterok
	cmp counterok, 15
	je button_fail

	
afisare_litere:
	cmp ifStart, 1
	je scoatere_litere
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	
	; mov ebx, 10
	; mov eax, counter
	
	;cifra unitatilor
	
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 30, 10
	
	;cifra zecilor
	
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 20, 10
	
	;cifra sutelor
	
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 10, 10

	;titlu
	
	make_text_macro 'M', area, 245, 100
	make_text_macro 'I', area, 255, 100
	make_text_macro 'N', area, 265, 100
	make_text_macro 'E', area, 275, 100
	make_text_macro 'S', area, 285, 100
	make_text_macro 'W', area, 295, 100
	make_text_macro 'E', area, 305, 100
	make_text_macro 'E', area, 315, 100
	make_text_macro 'P', area, 325, 100
	make_text_macro 'E', area, 335, 100
	make_text_macro 'R', area, 345, 100
	
	;buton start
	
	make_text_macro 'S', area, button_x + button_width / 3 + 5, button_y + button_height / 3
	make_text_macro 'T', area, button_x + button_width / 3 + 15, button_y + button_height / 3
	make_text_macro 'A', area, button_x + button_width / 3 + 25, button_y + button_height / 3
	make_text_macro 'R', area, button_x + button_width / 3 + 35, button_y + button_height / 3
	make_text_macro 'T', area, button_x + button_width / 3 + 45, button_y + button_height / 3
	
	line_horizontal button_x , button_y, button_width, 0
	line_horizontal button_x, button_y + button_height, button_width, 0
	line_vertical button_x, button_y, button_height, 0
	line_vertical button_x + button_width, button_y, button_height, 0
	
	
	jmp final_draw
	

scoatere_litere:
	
	;eliberare ecran
	cmp ifInGame, 0
	jne final_draw
	
	make_text_macro ' ', area, 245, 100
	make_text_macro ' ', area, 255, 100
	make_text_macro ' ', area, 265, 100
	make_text_macro ' ', area, 275, 100
	make_text_macro ' ', area, 285, 100
	make_text_macro ' ', area, 295, 100
	make_text_macro ' ', area, 305, 100
	make_text_macro ' ', area, 315, 100
	make_text_macro ' ', area, 325, 100
	make_text_macro ' ', area, 335, 100
	make_text_macro ' ', area, 345, 100
	
	make_text_macro ' ', area, button_x + button_width / 3 + 5, button_y + button_height / 3
	make_text_macro ' ', area, button_x + button_width / 3 + 15, button_y + button_height / 3
	make_text_macro ' ', area, button_x + button_width / 3 + 25, button_y + button_height / 3
	make_text_macro ' ', area, button_x + button_width / 3 + 35, button_y + button_height / 3
	make_text_macro ' ', area, button_x + button_width / 3 + 45, button_y + button_height / 3
	
	
	line_horizontal button_x , button_y, button_width, 0FFFFFFh
	line_horizontal button_x, button_y + button_height, button_width, 0FFFFFFh
	line_vertical button_x, button_y, button_height, 0FFFFFFh
	line_vertical button_x + button_width, button_y, button_height, 0FFFFFFh
	
	; buton exit
	
	make_text_macro 'E', area, exit_x + exit_width / 3 + 4, exit_y + exit_height / 3
	make_text_macro 'X', area, exit_x + exit_width / 3 + 14, exit_y + exit_height / 3
	make_text_macro 'I', area, exit_x + exit_width / 3 + 24, exit_y + exit_height / 3
	make_text_macro 'T', area, exit_x + exit_width / 3 + 34, exit_y + exit_height / 3
	
	line_horizontal exit_x , exit_y, exit_width, 0
	line_horizontal exit_x, exit_y + exit_height, exit_width, 0
	line_vertical exit_x, exit_y, exit_height, 0
	line_vertical exit_x + exit_width, exit_y, exit_height, 0
	
	

	;fundal joc

	mov EDI, 1
	mov blockpos1, game_y
	add blockpos1, 1
	
bucla_fundal:
	line_horizontal game_x, blockpos1, game_width, 0B9B9B9h
	add blockpos1, 1
	inc EDI
	cmp EDI, game_height
	jne bucla_fundal
	
	;chenar joc
	
	line_vertical game_x, game_y , game_height, 0
	line_vertical game_x + game_width, game_y , game_height, 0
	line_horizontal game_x, game_y , game_width, 0
	line_horizontal game_x, game_y + game_height , game_width, 0
	
	;blocuri joc
	
	mov blockpos1, game_y
	add blockpos1, 40
	
	mov blockpos2, game_x
	add blockpos2, 40
	
	mov EDI, 0
	
bucla_blocuri:
	line_horizontal game_x , blockpos1,game_width, 0
	line_vertical blockpos2, game_y  ,game_height, 0
	add blockpos1, 40
	add blockpos2, 40
	inc EDI
	cmp EDI, 9
	jne bucla_blocuri
	sub blockpos1, 40
	line_horizontal game_x , blockpos1,game_width, 0FFFFFFh
	
	;creare matrice aleatoare corespunzatoare bombelor
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;cream matricea cu bombe
	
	create_random_matrix
	
	;afisare matrice
	
	; mov loopprint_matrix, 80
	; mov ESI, 0
	; mov EDI, 0
	; loop_printf2:
		; mov ebx,0
		; mov BL, byte ptr matrix[EDI][ESI]
		
		; push ebx
		; push offset format_printf_matrix
		; call printf
		; add ESP, 8
		
		; inc ESI
		; cmp ESI, 10
		; jne continue_print
		
		; mov ESI,0
		; add EDI, 10
		
		; push offset format_printf2_matrix
		; call printf
		; add ESP, 4
		
		; continue_print:
		
		; dec loopprint_matrix
		; cmp loopprint_matrix, 0
		; jne loop_printf2
		
	;alocam memorie pentru zona de desenat	
	
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
