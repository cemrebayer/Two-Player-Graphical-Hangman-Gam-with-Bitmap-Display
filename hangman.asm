.data
word_buffer: .space 32
mask_buffer: .space 32
hint_used: .word 0         # Her tur sıfırlanacak

prompt:     .asciiz 
correct:    .asciiz 
wrong:      .asciiz 
win_round:  .asciiz "\nYou guessed the word!\n"
lose_round: .asciiz "\nYou ran out of lives!\n"
reveal_msg: .asciiz "The correct word was: "
already_guessed_msg: .asciiz 
newline:    .asciiz 

guessed_letters: .space 26 
guessed_count: .word 0     
lives: .word 6             

player1_score: .word 0
player2_score: .word 0
current_player_setting: .word 1 # 1: P1 sets, P2 guesses; 2: P2 sets, P1 guesses


p1_enter_word_msg: .asciiz "Player 1, enter a word (max 31 chars): "
p2_enter_word_msg: .asciiz "Player 2, enter a word (max 31 chars): "
p1_turn_guess_msg: .asciiz 
p2_turn_guess_msg: .asciiz 
p1_score_msg:      .asciiz 
p2_score_msg:      .asciiz 
p1_wins_game_msg:  .asciiz 
p2_wins_game_msg:  .asciiz 
final_scores_msg:  .asciiz 
max_score_val:     .word 3

# Bitmap Ayarları
.eqv BITMAP_BASE 0x10010000 
.eqv WIDTH 128
.eqv HEIGHT 128
.eqv BLACK 0x00000000        
.eqv YELLOW 0x00FFFF00       
.eqv ROPE_COLOR 0x00A0522D   
.eqv HANGMAN_COLOR 0x00FF0000 

.text
.globl main

main:
    j main_game_loop

main_game_loop:
    lw $s0, player1_score
    lw $s1, player2_score
    lw $s2, max_score_val

    bge $s0, $s2, player1_wins_overall
    bge $s1, $s2, player2_wins_overall

    lw $s3, current_player_setting
    li $t0, 1
    beq $s3, $t0, p1_sets_word_branch
    li $v0, 4
    la $a0, p2_enter_word_msg
    syscall
    j get_word_input_branch

p1_sets_word_branch:
    li $v0, 4
    la $a0, p1_enter_word_msg
    syscall

get_word_input_branch:
    li $v0, 8
    la $a0, word_buffer
    li $a1, 32
    syscall

    la $t0, word_buffer
find_newline_loop_main:
    lb $t1, 0($t0)
    beqz $t1, end_newline_removal_main
    li $t2, '\n'
    beq $t1, $t2, replace_newline_char_main
    addi $t0, $t0, 1
    j find_newline_loop_main
replace_newline_char_main:
    sb $zero, 0($t0)
end_newline_removal_main:

    la $a0, mask_buffer
    la $a1, word_buffer
    jal initialize_mask

    li $t0, 6
    sw $t0, lives
    sw $zero, guessed_count
    la $t0, guessed_letters
    li $t1, 26
    li $t2, 0
clear_guessed_loop:
    bge $t2, $t1, guessed_cleared
    sb $zero, 0($t0)
    addi $t0, $t0, 1
    addi $t2, $t2, 1
    j clear_guessed_loop
guessed_cleared:
    sw $zero, hint_used

    # <<< DEĞİŞİKLİK BAŞLANGICI: Belirli bir alanı temizle >>>
    li $a0, 20  
    li $a1, 10  
    li $a2, 63  
    li $a3, 80  
    jal clear_game_area
    # <<< DEĞİŞİKLİK SONU >>>

    jal draw_gallows # Darağacını (temizlenmiş alana) yeniden çiz

    lw $s3, current_player_setting
    li $t0, 1
    beq $s3, $t0, p2_guesses_now_branch
    li $v0, 4
    la $a0, p1_turn_guess_msg
    syscall
    j round_loop_start

p2_guesses_now_branch:
    li $v0, 4
    la $a0, p2_turn_guess_msg
    syscall

round_loop_start:
    lw $t0, lives
    beqz $t0, round_lost

    li $v0, 4
    la $a0, mask_buffer
    syscall

    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 12
    syscall
    move $t1, $v0

    li $t2, '?'
    beq $t1, $t2, provide_hint

    la $t2, guessed_letters
    lw $t3, guessed_count
    li $t4, 0
check_repeat_round:
    bge $t4, $t3, not_repeated_round
    lb $t5, 0($t2)
    beq $t5, $t1, repeat_found_round
    addi $t2, $t2, 1
    addi $t4, $t4, 1
    j check_repeat_round

repeat_found_round:
    li $v0, 4
    la $a0, already_guessed_msg
    syscall
    j round_loop_start

not_repeated_round:
    la $t2, guessed_letters
    lw $t3, guessed_count
    add $t2, $t2, $t3
    sb $t1, 0($t2)
    addi $t3, $t3, 1
    sw $t3, guessed_count

    la $t4, word_buffer
    la $t5, mask_buffer
    li $t6, 0

check_letter_loop_round:
    lb $t7, 0($t4)
    beqz $t7, check_done_round
    beq $t7, $t1, letter_match_round
continue_check_round:
    addi $t4, $t4, 1
    addi $t5, $t5, 1
    j check_letter_loop_round

letter_match_round:
    sb $t1, 0($t5)
    li $t6, 1
    j continue_check_round

check_done_round:
    bnez $t6, print_correct_round

    li $v0, 4
    la $a0, wrong
    syscall
    lw $t0, lives
    addi $t0, $t0, -1
    sw $t0, lives
    li $t1, 6
    sub $a0, $t1, $t0
    jal draw_hangman_part
    beqz $t0, round_lost
    j check_mask_loop_round

print_correct_round:
    li $v0, 4
    la $a0, correct
    syscall

check_mask_loop_round:
    la $t1, mask_buffer
check_mask_inner_loop:
    lb $t2, 0($t1)
    beqz $t2, round_won
    li $t3, '_'
    beq $t2, $t3, round_loop_start
    addi $t1, $t1, 1
    j check_mask_inner_loop

round_won:
    li $v0, 4
    la $a0, mask_buffer
    syscall
    li $v0, 4
    la $a0, win_round
    syscall
    li $v0, 4
    la $a0, reveal_msg
    syscall
    li $v0, 4
    la $a0, word_buffer
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    lw $s3, current_player_setting
    li $t0, 1
    beq $s3, $t0, p2_scores_point_on_win
    lw $t1, player1_score
    addi $t1, $t1, 1
    sw $t1, player1_score
    j display_scores_after_round

p2_scores_point_on_win:
    lw $t1, player2_score
    addi $t1, $t1, 1
    sw $t1, player2_score
    j display_scores_after_round

round_lost:
    li $v0, 4
    la $a0, mask_buffer
    syscall
    li $v0, 4
    la $a0, lose_round
    syscall
    li $v0, 4
    la $a0, reveal_msg
    syscall
    li $v0, 4
    la $a0, word_buffer
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    lw $s3, current_player_setting
    li $t0, 1
    beq $s3, $t0, p1_scores_point_on_p2_loss
    lw $t1, player2_score
    addi $t1, $t1, 1
    sw $t1, player2_score
    j display_scores_after_round

p1_scores_point_on_p2_loss:
    lw $t1, player1_score
    addi $t1, $t1, 1
    sw $t1, player1_score
    j display_scores_after_round

display_scores_after_round:
    li $v0, 4
    la $a0, p1_score_msg
    syscall
    li $v0, 1
    lw $a0, player1_score
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, p2_score_msg
    syscall
    li $v0, 1
    lw $a0, player2_score
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    j next_round_setup

next_round_setup:
    lw $s3, current_player_setting
    li $t0, 1
    beq $s3, $t0, set_p2_to_set_branch
    li $t0, 1
    sw $t0, current_player_setting
    j main_game_loop

set_p2_to_set_branch:
    li $t0, 2
    sw $t0, current_player_setting
    j main_game_loop

player1_wins_overall:
    li $v0, 4
    la $a0, p1_wins_game_msg
    syscall
    j display_final_scores_and_exit

player2_wins_overall:
    li $v0, 4
    la $a0, p2_wins_game_msg
    syscall

display_final_scores_and_exit:
    li $v0, 4
    la $a0, final_scores_msg
    syscall
    li $v0, 4
    la $a0, p1_score_msg
    syscall
    li $v0, 1
    lw $a0, player1_score
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, p2_score_msg
    syscall
    li $v0, 1
    lw $a0, player2_score
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 10
    syscall

provide_hint:
    lw $t0, hint_used
    bnez $t0, hint_return_no_action_actual

    la $s5, word_buffer
    la $s6, mask_buffer

hint_loop_actual:
    lb $t3, 0($s6)
    beqz $t3, hint_return_no_action_actual
    li $t4, '_'
    bne $t3, $t4, hint_skip_actual

    lb $t5, 0($s5)
    sb $t5, 0($s6)
    li $t0, 1
    sw $t0, hint_used
    j check_mask_loop_round

hint_skip_actual:
    addi $s5, $s5, 1
    addi $s6, $s6, 1
    j hint_loop_actual

hint_return_no_action_actual:
    j round_loop_start

initialize_mask:
    move $t0, $a0
    move $t1, $a1
init_mask_loop_actual:
    lb $t2, 0($t1)
    beqz $t2, init_mask_done_actual
    li $t3, '_'
    sb $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j init_mask_loop_actual
init_mask_done_actual:
    sb $zero, 0($t0)
    jr $ra

clear_game_area:
    move $s4, $ra # $ra'yı koru (geçici olarak $s4'te, normalde stack kullanılır)

    move $t0, $a1           # current_y = y_min ($t0 döngü için y sayacı)
    li $t7, BLACK           

clear_area_y_loop:
    bgt $t0, $a3, clear_area_done # if current_y > y_max, y döngüsünden çık

    move $t1, $a0           # current_x = x_min ($t1 döngü için x sayacı)
clear_area_x_loop:
    bgt $t1, $a2, clear_area_next_y # if current_x > x_max, x döngüsünden çık (bir sonraki satıra geç)

    # Adres hesapla: BITMAP_BASE + (current_y * WIDTH + current_x) * 4
    mul $t2, $t0, WIDTH     # current_y * WIDTH
    add $t2, $t2, $t1       # (current_y * WIDTH) + current_x
    sll $t2, $t2, 2         # offset_bytes = offset_pixels * 4
    add $t2, $t2, BITMAP_BASE # mutlak adres

    sw $t7, 0($t2)          # Adrese rengi yaz

    addi $t1, $t1, 1        # current_x++
    j clear_area_x_loop

clear_area_next_y:
    addi $t0, $t0, 1        # current_y++
    j clear_area_y_loop

clear_area_done:
    move $ra, $s4 # $ra'yı geri yükle
    jr $ra

# --- ESKİ clear_bitmap_screen FONKSİYONU SİLİNDİ VEYA YORUM SATIRI YAPILDI ---
# clear_bitmap_screen:
#     ... (tüm ekranı temizleyen kod) ...

draw_gallows:
    li $t0, 10
draw_post_loop:
    li $t1, 20
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, YELLOW
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    li $t5, 80
    ble $t0, $t5, draw_post_loop

    li $t0, 10
    li $t1, 20
draw_topbar_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, YELLOW
    sw $t3, 0($t2)
    addi $t1, $t1, 1
    li $t5, 60
    ble $t1, $t5, draw_topbar_loop

    li $t1, 60
    li $t0, 11
draw_rope_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, ROPE_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    li $t5, 25
    ble $t0, $t5, draw_rope_loop
    jr $ra

draw_hangman_part:
    move $s7, $a0
    li $t3, 1
    beq $s7, $t3, draw_head
    li $t3, 2
    beq $s7, $t3, draw_body
    li $t3, 3
    beq $s7, $t3, draw_left_arm
    li $t3, 4
    beq $s7, $t3, draw_right_arm
    li $t3, 5
    beq $s7, $t3, draw_left_leg
    li $t3, 6
    beq $s7, $t3, draw_right_leg
    jr $ra

draw_head:
    li $t0, 25
.head_outer_loop:
    li $t1, 58
.head_inner_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t1, $t1, 1
    li $t5, 62
    blt $t1, $t5, .head_inner_loop
    addi $t0, $t0, 1
    li $t5, 29
    blt $t0, $t5, .head_outer_loop
    jr $ra

draw_body:
    li $t1, 60
    li $t0, 29
.body_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    li $t5, 35
    blt $t0, $t5, .body_loop
    jr $ra

draw_left_arm:
    li $t0, 30
    li $t1, 59
    li $t6, 0
.larm_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    addi $t6, $t6, 1
    li $t5, 3
    blt $t6, $t5, .larm_loop
    jr $ra

draw_right_arm:
    li $t0, 30
    li $t1, 61
    li $t6, 0
.rarm_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t6, $t6, 1
    li $t5, 3
    blt $t6, $t5, .rarm_loop
    jr $ra

draw_left_leg:
    li $t0, 35
    li $t1, 59
    li $t6, 0
.lleg_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    addi $t6, $t6, 1
    li $t5, 3
    blt $t6, $t5, .lleg_loop
    jr $ra

draw_right_leg:
    li $t0, 35
    li $t1, 61
    li $t6, 0
.rleg_loop:
    mul $t4, $t0, WIDTH
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t2, $t4, BITMAP_BASE
    li $t3, HANGMAN_COLOR
    sw $t3, 0($t2)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t6, $t6, 1
    li $t5, 3
    blt $t6, $t5, .rleg_loop
    jr $ra
