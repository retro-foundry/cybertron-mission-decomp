; Cybertron Acorn Electron runtime reconstruction

cpu 1

INCLUDE "source_acorn_electron/memory_map.inc"

org runtime_start

; This is reconstructed source, not original author source.
; Reconstructed routines are validated against the known CYBRUN length and SHA-256 digest.


.copy_current_score_to_best_if_not_lower
    LDX      #&4    ; &0D80

.compare_score_digit_loop_0d80
    DEX    ; &0D82
    BMI      copy_current_score_to_best_digits_0d80    ; &0D83
    LDA      score_counter_chars,X    ; &0D85
    CMP      best_score_counter_chars,X    ; &0D88
    BEQ      compare_score_digit_loop_0d80    ; &0D8B
    BPL      copy_current_score_to_best_digits_0d80    ; &0D8D
    RTS    ; &0D8F

.copy_current_score_to_best_digits_0d80
    LDX      #&3    ; &0D90

.copy_current_score_to_best_loop_0d80
    LDA      score_counter_chars,X    ; &0D92
    STA      best_score_counter_chars,X    ; &0D95
    DEX    ; &0D98
    BPL      copy_current_score_to_best_loop_0d80    ; &0D99
    RTS    ; &0D9B

.update_title_score_glyph_tables
    LDX      #&3    ; &0D9C
    LDY      #&0    ; &0D9E

.update_title_score_glyph_loop_0d9c
    LDA      best_score_counter_chars,X    ; &0DA0
    SEC    ; &0DA3
    SBC      #&10    ; &0DA4
    STA      best_score_title_digits,Y    ; &0DA6
    LDA      score_counter_chars,X    ; &0DA9
    SEC    ; &0DAC
    SBC      #&10    ; &0DAD
    STA      current_score_title_digits,Y    ; &0DAF
    INY    ; &0DB2
    DEX    ; &0DB3
    BPL      update_title_score_glyph_loop_0d9c    ; &0DB4
    RTS    ; &0DB6

.oswrch_wrapper_from_a
    JSR      clear_all_palette_entries    ; &0DB7
    LDA      #&c    ; &0DBA
    JMP      MOS_OSWRCH    ; &0DBC

.copy_level_modulo_24byte_fill_pattern
    LDA      level_units_digit    ; &0DBF
    AND      #&3    ; &0DC2
    STA      zp_scratch_76    ; &0DC4
    CLC    ; &0DC6
    ADC      zp_scratch_76    ; &0DC7
    ADC      zp_scratch_76    ; &0DC9
    ASL      A    ; &0DCB
    ASL      A    ; &0DCC
    ASL      A    ; &0DCD
    TAX    ; &0DCE
    LDY      #&0    ; &0DCF

.copy_level_fill_pattern_loop_0dbf
    LDA      initial_screen_level_modulo_fill_patterns_0dbf,X    ; &0DD1
    STA      (zp_screen_ptr_70_low),Y    ; &0DD4
    INY    ; &0DD6
    INX    ; &0DD7
    CPY      #&18    ; &0DD8
    BNE      copy_level_fill_pattern_loop_0dbf    ; &0DDA
    RTS    ; &0DDC

.wait_one_frame_tick
    LDA      bootstrap_osbyte81_x_result_flag    ; &0DDD

.wait_frame_tick_mode_branch
    BEQ      wait_for_0224_tick_change    ; &0DE0

.wait_vsync_with_osbyte19
    LDA      #&13    ; &0DE2
    JMP      MOS_OSBYTE    ; &0DE4

.wait_for_0224_tick_change
    LDA      polled_frame_tick_byte_0224    ; &0DE7

.wait_for_0224_tick_change_loop_0ddd
    CMP      polled_frame_tick_byte_0224    ; &0DEA
    BEQ      wait_for_0224_tick_change_loop_0ddd    ; &0DED
    RTS    ; &0DEF

.runtime_pre_entry_unexecuted_bytes_0df0
    ; unused/pre-entry bytes before runtime_entry at $0E02; preserved byte-exact
    EQUB &68,&00,&8D,&78,&30,&00,&00,&B2    ; &0DF0
    EQUB &0C,&00,&8C,&5E,&70,&00,&00,&78    ; &0DF8

.runtime_entry_nop_padding
    NOP    ; &0E00
    NOP    ; &0E01

.runtime_entry_after_bootstrap
    JSR      early_init_sub_13b4    ; &0E02

.menu_attract_entry_loop_0e05
    LDA      #&c    ; &0E05
    JSR      play_sound_id_if_enabled    ; &0E07
    LDA      #&10    ; &0E0A
    JSR      play_sound_id_if_enabled    ; &0E0C
    JSR      oswrch_wrapper_from_a    ; &0E0F
    JSR      show_controls_and_start_prompt_screen    ; &0E12
    JSR      apply_level_palette    ; &0E15
    JSR      wait_for_start_escape_fire_or_timeout    ; &0E18
    BCS      start_level_or_round    ; &0E1B
    JSR      oswrch_wrapper_from_a    ; &0E1D
    JSR      show_object_legend_screen    ; &0E20
    JSR      apply_level_palette    ; &0E23
    JSR      wait_for_start_escape_fire_or_timeout    ; &0E26
    BCS      start_level_or_round    ; &0E29

.early_game_setup_path
    JMP      menu_attract_entry_loop_0e05    ; &0E2B

.wait_for_start_escape_fire_or_timeout
    LDA      #&4    ; &0E2E
    STA      text_render_colour_value    ; &0E30
    LDA      #&0    ; &0E33
    STA      zp_scratch_76    ; &0E35
    STA      zp_scratch_79    ; &0E37
    STA      zp_scratch_78    ; &0E39
    STA      zp_scratch_77    ; &0E3B
    LDA      #&2    ; &0E3D
    STA      zp_indirect_74_high    ; &0E3F
    LDA      bootstrap_osbyte81_x_result_flag    ; &0E41
    BEQ      attract_wait_poll_loop_0e2e    ; &0E44
    SEI    ; &0E46

.attract_wait_poll_loop_0e2e
    LDA      #&2    ; &0E47
    JSR      wait_frames_count_a    ; &0E49
    JSR      draw_rotating_wait_text_strip    ; &0E4C
    LDX      #&9d    ; &0E4F
    JSR      scan_inkey_x    ; &0E51
    BEQ      attract_wait_check_escape_0e2e    ; &0E54
    LDA      #&0    ; &0E56
    STA      input_mode_keyboard_or_joystick    ; &0E58
    CLI    ; &0E5B
    SEC    ; &0E5C
    RTS    ; &0E5D

.attract_wait_check_escape_0e2e
    LDX      #&8f    ; &0E5E
    JSR      scan_inkey_x    ; &0E60
    BEQ      attract_wait_check_joystick_fire_0e2e    ; &0E63
    CLC    ; &0E65
    RTS    ; &0E66

.attract_wait_check_joystick_fire_0e2e
    LDA      #&80    ; &0E67
    LDX      #&0    ; &0E69
    JSR      MOS_OSBYTE    ; &0E6B
    TXA    ; &0E6E
    AND      #&1    ; &0E6F
    BEQ      attract_wait_countdown_0e2e    ; &0E71

.mark_status_and_return_carry_set
    LDA      #&1    ; &0E73
    STA      input_mode_keyboard_or_joystick    ; &0E75
    CLI    ; &0E78
    SEC    ; &0E79
    RTS    ; &0E7A

.attract_wait_countdown_0e2e
    DEC      zp_scratch_76    ; &0E7B
    BNE      attract_wait_poll_loop_0e2e    ; &0E7D
    DEC      zp_indirect_74_high    ; &0E7F
    BNE      attract_wait_poll_loop_0e2e    ; &0E81
    CLC    ; &0E83
    RTS    ; &0E84

.start_level_or_round
    LDA      #&4    ; &0E85
    STA      lives_status_count    ; &0E87
    LDA      #&0    ; &0E8A
    STA      room_area    ; &0E8C
    LDA      #&0    ; &0E8E
    STA      level_index_and_hazard_gate    ; &0E90
    STA      level_tens_digit    ; &0E92
    LDA      #&1    ; &0E95
    STA      level_units_digit    ; &0E97
    LDA      #&20    ; &0E9A
    LDX      #&3    ; &0E9C

.clear_score_counter_loop_0e85
    STA      score_counter_chars,X    ; &0E9E
    DEX    ; &0EA1
    BPL      clear_score_counter_loop_0e85    ; &0EA2

.begin_level_intro_setup_path_0e85
    JSR      oswrch_wrapper_from_a    ; &0EA4
    LDA      #&0    ; &0EA7
    STA      level_loop_seed_or_status    ; &0EA9
    STA      current_level_intro_or_loop_flag    ; &0EAC
    JSR      show_level_intro_and_required_targets    ; &0EAE
    LDA      level_tens_digit    ; &0EB1
    BNE      level_active_loop    ; &0EB4
    LDA      level_units_digit    ; &0EB6
    CMP      #&6    ; &0EB9
    BPL      level_active_loop    ; &0EBB
    STA      level_index_and_hazard_gate    ; &0EBD
    DEC      level_index_and_hazard_gate    ; &0EBF

.level_active_loop
    LDA      level_loop_seed_or_status    ; &0EC1
    STA      saved_level_loop_seed_or_status    ; &0EC4
    LDA      #&1    ; &0EC6
    STA      remaining_active_object_count    ; &0EC8
    JSR      start_or_reset_player_and_level_objects    ; &0ECA
    LDA      #&0    ; &0ECD
    STA      transition_delay    ; &0ECF
    STA      fire_edge_request    ; &0ED1
    STA      input_delta_x    ; &0ED3
    STA      input_delta_y    ; &0ED5
    STA      projectile_spook_pause_collision_flag    ; &0ED7
    JSR      frame_update    ; &0ED9
    JSR      oswrch_wrapper_from_a    ; &0EDC
    LDA      lives_status_count    ; &0EDF
    BPL      level_active_loop    ; &0EE2
    JSR      apply_level_palette    ; &0EE4
    LDX      #&e5    ; &0EE7
    LDA      #&0    ; &0EE9
    LDY      #&53    ; &0EEB
    JSR      draw_encoded_text_stream_to_screen    ; &0EED
    LDA      #&13    ; &0EF0
    JSR      play_sound_id_if_enabled    ; &0EF2
    LDA      #&50    ; &0EF5
    JSR      wait_frames_count_a    ; &0EF7
    JMP      menu_attract_entry_loop_0e05    ; &0EFA

.byte_decoded_rts_before_tile_generator_0efd
    RTS    ; &0EFD

.draw_24byte_tile_or_sprite
    LDA      #&0    ; &0EFE
    STA      zp_screen_ptr_70_high    ; &0F00
    STX      zp_screen_ptr_70_low    ; &0F02
    TXA    ; &0F04
    JSR      add_a_to_pointer_70    ; &0F05
    TXA    ; &0F08
    JSR      add_a_to_pointer_70    ; &0F09
    INC      zp_screen_ptr_70_low    ; &0F0C
    LDX      #&3    ; &0F0E
    JSR      shift_tile_pointer_70_left_x_times    ; &0F10
    LDA      #&0    ; &0F13
    STA      zp_calc_ptr_72_high    ; &0F15
    STY      zp_calc_ptr_72_low    ; &0F17
    TYA    ; &0F19
    JSR      add_a_to_pointer_72    ; &0F1A
    TYA    ; &0F1D
    JSR      add_a_to_pointer_72    ; &0F1E
    TYA    ; &0F21
    JSR      add_a_to_pointer_72    ; &0F22
    TYA    ; &0F25
    JSR      add_a_to_pointer_72    ; &0F26
    LDX      #&7    ; &0F29
    JSR      shift_pointer_72_left_x_times    ; &0F2B
    CLC    ; &0F2E
    LDA      zp_screen_ptr_70_low    ; &0F2F
    ADC      zp_calc_ptr_72_low    ; &0F31
    STA      zp_screen_ptr_70_low    ; &0F33
    LDA      zp_screen_ptr_70_high    ; &0F35
    ADC      zp_calc_ptr_72_high    ; &0F37
    STA      zp_screen_ptr_70_high    ; &0F39
    CLC    ; &0F3B
    LDA      zp_screen_ptr_70_high    ; &0F3C
    ADC      #&30    ; &0F3E
    STA      zp_screen_ptr_70_high    ; &0F40
    LDA      #&0    ; &0F42
    STA      zp_indirect_74_low    ; &0F44
    STA      zp_scratch_77    ; &0F46
    LDY      #&17    ; &0F48
    LDA      room_tile_class_or_pattern    ; &0F4A
    BEQ      clear_24byte_tile_loop    ; &0F4C

.generate_next_compact_tile_row
    LDA      room_tile_class_or_pattern    ; &0F4E
    LSR      A    ; &0F50
    PHP    ; &0F51
    LSR      A    ; &0F52
    PLP    ; &0F53
    ROL      A    ; &0F54
    STA      zp_scratch_78    ; &0F55
    TAX    ; &0F57
    LDA      tile_generator_outer_index_table_0efe,X    ; &0F58
    TAY    ; &0F5B
    JSR      write_compact_tile_pattern_byte    ; &0F5C
    LDA      room_tile_class_or_pattern    ; &0F5F
    LSR      A    ; &0F61
    PHP    ; &0F62
    LSR      A    ; &0F63
    PLP    ; &0F64
    ROL      A    ; &0F65
    TAX    ; &0F66
    LDA      tile_generator_side_index_table_0efe,X    ; &0F67
    TAY    ; &0F6A
    JSR      write_compact_tile_pattern_byte    ; &0F6B

.generate_compact_tile_middle_bytes
    LDA      room_tile_class_or_pattern    ; &0F6E
    LSR      A    ; &0F70
    LSR      A    ; &0F71
    TAX    ; &0F72
    LDA      tile_generator_middle_index_table_0efe,X    ; &0F73
    TAY    ; &0F76
    JSR      write_compact_tile_pattern_byte    ; &0F77
    LDA      zp_scratch_77    ; &0F7A
    AND      #&7    ; &0F7C
    CMP      #&6    ; &0F7E
    BMI      generate_compact_tile_middle_bytes    ; &0F80
    LDA      room_tile_class_or_pattern    ; &0F82
    LSR      A    ; &0F84
    TAX    ; &0F85
    LDA      tile_generator_side_index_table_0efe,X    ; &0F86
    TAY    ; &0F89
    JSR      write_compact_tile_pattern_byte    ; &0F8A
    LDA      room_tile_class_or_pattern    ; &0F8D
    LSR      A    ; &0F8F
    TAX    ; &0F90
    LDA      tile_generator_outer_index_table_0efe,X    ; &0F91
    TAY    ; &0F94
    JSR      write_compact_tile_pattern_byte    ; &0F95
    INC      zp_indirect_74_low    ; &0F98
    LDA      zp_indirect_74_low    ; &0F9A
    CMP      #&3    ; &0F9C
    BNE      generate_next_compact_tile_row    ; &0F9E
    RTS    ; &0FA0

.clear_24byte_tile_loop
    STA      (zp_screen_ptr_70_low),Y    ; &0FA1
    DEY    ; &0FA3
    BPL      clear_24byte_tile_loop    ; &0FA4
    RTS    ; &0FA6

.add_a_to_pointer_72
    CLC    ; &0FA7
    ADC      zp_calc_ptr_72_low    ; &0FA8
    STA      zp_calc_ptr_72_low    ; &0FAA
    LDA      zp_calc_ptr_72_high    ; &0FAC
    ADC      #&0    ; &0FAE
    STA      zp_calc_ptr_72_high    ; &0FB0
    RTS    ; &0FB2

.shift_tile_pointer_70_left_x_times
    ASL      zp_screen_ptr_70_low    ; &0FB3
    ROL      zp_screen_ptr_70_high    ; &0FB5
    DEX    ; &0FB7
    BNE      shift_tile_pointer_70_left_x_times    ; &0FB8
    RTS    ; &0FBA

.write_compact_tile_pattern_byte
    LDA      #&2f    ; &0FBB
    STA      zp_scratch_76    ; &0FBD
    LDX      zp_indirect_74_low    ; &0FBF
    LDA      tile_generator_source_low_table_0efe,X    ; &0FC1
    STA      zp_indirect_74_high    ; &0FC4
    LDA      (zp_indirect_74_high),Y    ; &0FC6
    LDY      zp_scratch_77    ; &0FC8
    STA      (zp_screen_ptr_70_low),Y    ; &0FCA
    INC      zp_scratch_77    ; &0FCC
    RTS    ; &0FCE

.draw_object_by_index_0
    LDA      #&0    ; &0FCF
    STA      render_mode_or_text_scratch    ; &0FD1
    JMP      draw_object_by_index    ; &0FD3

.handle_collected_target_or_level_done
    LDA      #&0    ; &0FD6
    STA      renderer_collision_accumulator    ; &0FD8
    LDX      #&ff    ; &0FDA

.find_collected_target_slot
    INX    ; &0FDC
    LDA      room_area    ; &0FDD
    AND      #&f    ; &0FDF
    CMP      target_room_code,X    ; &0FE1
    BNE      find_collected_target_slot    ; &0FE4
    CPX      #&0    ; &0FE6
    BEQ      begin_required_target_completion_scan    ; &0FE8
    LDA      #&1    ; &0FEA
    STA      target_collected_status,X    ; &0FEC
    STX      zp_scratch_77    ; &0FEF
    TXA    ; &0FF1
    CLC    ; &0FF2
    ADC      #&36    ; &0FF3
    TAX    ; &0FF5
    JSR      draw_object_by_index_0    ; &0FF6
    LDA      #&5    ; &0FF9
    JSR      play_sound_id_if_enabled    ; &0FFB
    LDX      zp_scratch_77    ; &0FFE
    CPX      #&6    ; &1000
    BEQ      award_bonus_target_life    ; &1002
    LDA      target_collection_score_add_table_0fd6,X    ; &1004
    JMP      increment_four_char_score_or_counter    ; &1007

.award_bonus_target_life
    JSR      reroll_bonus_target_code    ; &100A
    INC      lives_status_count    ; &100D
    JMP      draw_lives_or_target_status    ; &1010

.begin_required_target_completion_scan
    LDX      #&0    ; &1013

.scan_next_required_target_status
    INX    ; &1015
    LDA      target_collected_status,X    ; &1016
    CMP      #&1    ; &1019
    BNE      test_required_target_scan_complete    ; &101B
    LDA      #&ff    ; &101D
    STA      target_collected_status,X    ; &101F
    INC      collected_target_count    ; &1022

.test_required_target_scan_complete
    CPX      highest_required_target_slot    ; &1024
    BNE      scan_next_required_target_status    ; &1026
    CPX      collected_target_count    ; &1028
    BEQ      advance_level_after_all_targets    ; &102A
    LDA      input_delta_x    ; &102C
    EOR      #&ff    ; &102E
    STA      input_delta_x    ; &1030
    INC      input_delta_x    ; &1032
    LDA      input_delta_y    ; &1034
    EOR      #&ff    ; &1036
    STA      input_delta_y    ; &1038
    INC      input_delta_y    ; &103A
    JSR      apply_input_delta_to_player_pair    ; &103C
    JMP      cancel_player_movement_delta    ; &103F

.advance_level_after_all_targets
    INC      lives_status_count    ; &1042
    INC      level_units_digit    ; &1045
    LDA      level_units_digit    ; &1048
    CMP      #&a    ; &104B
    BNE      enter_next_level_area    ; &104D
    LDA      #&0    ; &104F
    STA      level_units_digit    ; &1051
    INC      level_tens_digit    ; &1054

.enter_next_level_area
    LDA      room_area    ; &1057
    CLC    ; &1059
    ADC      #&10    ; &105A
    AND      #&30    ; &105C
    STA      room_area    ; &105E
    LDA      #&12    ; &1060
    JSR      play_sound_id_if_enabled    ; &1062
    LDA      #&32    ; &1065
    JSR      wait_frames_count_a    ; &1067
    PLA    ; &106A
    PLA    ; &106B
    PLA    ; &106C
    PLA    ; &106D
    JMP      begin_level_intro_setup_path_0e85    ; &106E

.draw_20char_buffer_as_bitmap_text
    LDA      #&0    ; &1071
    STA      object_x_by_index    ; &1073

.draw_next_text_character
    LDX      object_x_by_index    ; &1076
    LDA      text_buffer_20chars,X    ; &1079
    STA      zp_calc_ptr_72_low    ; &107C
    LDA      #&0    ; &107E
    STA      zp_calc_ptr_72_high    ; &1080
    LDX      #&3    ; &1082
    JSR      shift_pointer_72_left_x_times    ; &1084
    LDA      zp_calc_ptr_72_high    ; &1087
    CLC    ; &1089
    ADC      #&c0    ; &108A
    STA      zp_calc_ptr_72_high    ; &108C
    LDY      object_y_by_index    ; &108E

.load_character_font_quartet
    TYA    ; &1091
    AND      #&3    ; &1092
    TAX    ; &1094
    LDA      (zp_calc_ptr_72_low),Y    ; &1095
    STA      font_expand_work_bytes,X    ; &1097
    INY    ; &109A
    TYA    ; &109B
    AND      #&3    ; &109C
    BNE      load_character_font_quartet    ; &109E
    LDA      #&0    ; &10A0
    STA      movement_delta_x    ; &10A2

.draw_next_character_quarter
    LDA      #&0    ; &10A4
    STA      input_delta_y    ; &10A6
    LDY      #&0    ; &10A8

.draw_next_character_pixel_pair
    LDA      #&0    ; &10AA
    STA      render_mode_or_text_scratch    ; &10AC
    LDX      input_delta_y    ; &10AE
    LDA      font_expand_work_bytes,X    ; &10B0
    AND      #&80    ; &10B3
    BEQ      test_second_pixel_colour    ; &10B5
    LDA      text_render_colour_value    ; &10B7
    ASL      A    ; &10BA
    STA      render_mode_or_text_scratch    ; &10BB

.test_second_pixel_colour
    LDA      font_expand_work_bytes,X    ; &10BD
    AND      #&40    ; &10C0
    BEQ      store_expanded_pixel_pair    ; &10C2
    LDA      text_render_colour_value    ; &10C4
    ORA      render_mode_or_text_scratch    ; &10C7
    STA      render_mode_or_text_scratch    ; &10C9

.store_expanded_pixel_pair
    ASL      font_expand_work_bytes,X    ; &10CB
    ASL      font_expand_work_bytes,X    ; &10CE
    LDA      render_mode_or_text_scratch    ; &10D1
    STA      (zp_screen_ptr_70_low),Y    ; &10D3
    INY    ; &10D5
    STA      (zp_screen_ptr_70_low),Y    ; &10D6
    INC      input_delta_y    ; &10D8
    INY    ; &10DA
    CPY      #&8    ; &10DB
    BNE      draw_next_character_pixel_pair    ; &10DD
    LDA      #&8    ; &10DF
    JSR      add_a_to_pointer_70    ; &10E1
    INC      movement_delta_x    ; &10E4
    LDA      movement_delta_x    ; &10E6
    CMP      #&4    ; &10E8
    BNE      draw_next_character_quarter    ; &10EA
    INC      object_x_by_index    ; &10EC
    LDA      object_x_by_index    ; &10EF
    CMP      text_render_char_limit    ; &10F2
    BNE      continue_text_character_loop    ; &10F4
    RTS    ; &10F6

.continue_text_character_loop
    JMP      draw_next_text_character    ; &10F7

.draw_20char_buffer_two_rows
    LDA      #&14    ; &10FA
    STA      text_render_char_limit    ; &10FC
    LDA      #&0    ; &10FE
    STA      object_y_by_index    ; &1100
    JSR      draw_20char_buffer_as_bitmap_text    ; &1103
    LDA      #&4    ; &1106
    STA      object_y_by_index    ; &1108
    JMP      draw_20char_buffer_as_bitmap_text    ; &110B

.oswrch_zero_terminated_text_2600_x
    LDA      control_help_text,X    ; &110E
    BEQ      return_from_text_stream    ; &1111
    JSR      MOS_OSWRCH    ; &1113
    INX    ; &1116
    JMP      oswrch_zero_terminated_text_2600_x    ; &1117

.return_from_text_stream
    RTS    ; &111A

.copy_encoded_text_stream_to_buffer
    LDA      screen_copy_control_streams,X    ; &111B
    TAY    ; &111E
    INX    ; &111F

.copy_next_encoded_text_byte
    LDA      screen_copy_control_streams,X    ; &1120
    BMI      return_from_text_stream    ; &1123
    STA      text_buffer_20chars,Y    ; &1125
    INY    ; &1128
    INX    ; &1129
    JMP      copy_next_encoded_text_byte    ; &112A

.clear_20char_text_buffer
    LDY      #&13    ; &112D
    LDA      #&0    ; &112F

.clear_next_text_buffer_byte
    STA      text_buffer_20chars,Y    ; &1131
    DEY    ; &1134
    BPL      clear_next_text_buffer_byte    ; &1135
    RTS    ; &1137

.draw_encoded_text_stream_to_screen
    STA      zp_screen_ptr_70_low    ; &1138
    STY      zp_screen_ptr_70_high    ; &113A
    JSR      clear_20char_text_buffer    ; &113C
    JSR      copy_encoded_text_stream_to_buffer    ; &113F
    JMP      draw_20char_buffer_two_rows    ; &1142

.show_controls_and_start_prompt_screen
    LDA      #&4    ; &1145
    STA      text_render_colour_value    ; &1147
    LDX      #&0    ; &114A
    JSR      oswrch_zero_terminated_text_2600_x    ; &114C
    JSR      copy_current_score_to_best_if_not_lower    ; &114F
    JSR      update_title_score_glyph_tables    ; &1152
    LDA      #&10    ; &1155
    LDY      #&30    ; &1157
    LDX      #&7c    ; &1159
    JSR      draw_encoded_text_stream_to_screen    ; &115B
    LDA      #&80    ; &115E
    LDY      #&37    ; &1160
    LDX      #&f2    ; &1162
    JSR      draw_encoded_text_stream_to_screen    ; &1164
    LDA      #&4    ; &1167
    STA      text_render_colour_value    ; &1169
    LDX      #&87    ; &116C
    LDY      #&6e    ; &116E
    LDA      #&80    ; &1170
    JMP      draw_encoded_text_stream_to_screen    ; &1172

.show_object_legend_screen
    LDA      #&4    ; &1175
    STA      text_render_colour_value    ; &1177
    LDX      #&0    ; &117A

.draw_next_legend_text
    STX      zp_scratch_79    ; &117C
    LDY      object_legend_screen_high_bytes_1175,X    ; &117E
    LDA      object_legend_text_stream_offsets_1175,X    ; &1181
    STA      zp_scratch_78    ; &1184
    LDA      object_legend_screen_low_bytes_1175,X    ; &1186
    LDX      zp_scratch_78    ; &1189
    JSR      draw_encoded_text_stream_to_screen    ; &118B
    LDX      zp_scratch_79    ; &118E
    INX    ; &1190
    LDA      #&10    ; &1191
    STA      text_render_colour_value    ; &1193
    CPX      #&9    ; &1196
    BNE      draw_next_legend_text    ; &1198
    LDA      #&44    ; &119A
    STA      object_screen_high_by_index    ; &119C
    LDA      #&90    ; &119F
    STA      object_screen_low_by_index    ; &11A1
    LDA      #&1    ; &11A4
    STA      object_y_by_index    ; &11A6
    LDX      #&0    ; &11A9
    STX      render_mode_or_text_scratch    ; &11AB

.draw_next_legend_graphic
    STX      zp_scratch_79    ; &11AD
    LDA      object_legend_graphic_ids_1175,X    ; &11AF
    STA      object_graphic_id_by_index    ; &11B2
    LDX      #&0    ; &11B5
    JSR      draw_object_by_index    ; &11B7
    LDA      object_screen_low_by_index    ; &11BA
    CLC    ; &11BD
    ADC      #&80    ; &11BE
    STA      object_screen_low_by_index    ; &11C0
    LDA      object_screen_high_by_index    ; &11C3
    ADC      #&7    ; &11C6
    STA      object_screen_high_by_index    ; &11C8
    LDX      zp_scratch_79    ; &11CB
    INX    ; &11CD
    CPX      #&7    ; &11CE
    BNE      draw_next_legend_graphic    ; &11D0
    LDA      #&0    ; &11D2
    STA      object_y_by_index    ; &11D4
    LDA      #&3d    ; &11D7
    STA      object_screen_high_by_index    ; &11D9
    LDA      #&10    ; &11DC
    STA      object_screen_low_by_index    ; &11DE
    LDA      #&2e    ; &11E1
    STA      object_graphic_id_by_index    ; &11E3
    LDX      #&0    ; &11E6
    JSR      draw_object_by_index    ; &11E8
    LDA      #&3f    ; &11EB
    STA      object_screen_high_by_index    ; &11ED
    LDA      #&90    ; &11F0
    STA      object_screen_low_by_index    ; &11F2
    INC      object_graphic_id_by_index    ; &11F5
    LDX      #&0    ; &11F8
    JSR      draw_object_by_index    ; &11FA
    RTS    ; &11FD

.show_level_intro_and_required_targets
    LDA      #&1    ; &11FE
    STA      text_render_colour_value    ; &1200
    JSR      seed_required_target_codes    ; &1203
    JSR      apply_level_palette    ; &1206
    LDA      #&0    ; &1209
    STA      collected_target_count    ; &120B
    STA      render_mode_or_text_scratch    ; &120D
    LDX      #&b8    ; &120F
    JSR      oswrch_zero_terminated_text_2600_x    ; &1211
    JSR      clear_20char_text_buffer    ; &1214
    LDX      #&de    ; &1217
    JSR      copy_encoded_text_stream_to_buffer    ; &1219
    LDA      level_tens_digit    ; &121C
    BEQ      write_level_units_digit    ; &121F
    CLC    ; &1221
    ADC      #&10    ; &1222
    STA      &0CD6    ; &1224

.write_level_units_digit
    LDA      level_units_digit    ; &1227
    CLC    ; &122A
    ADC      #&10    ; &122B
    STA      &0CD7    ; &122D
    LDA      #&0    ; &1230
    STA      zp_screen_ptr_70_low    ; &1232
    LDA      #&49    ; &1234
    STA      zp_screen_ptr_70_high    ; &1236
    JSR      draw_20char_buffer_two_rows    ; &1238
    LDX      #&c6    ; &123B
    JSR      oswrch_zero_terminated_text_2600_x    ; &123D
    LDA      #&b0    ; &1240
    STA      object_screen_low_by_index    ; &1242
    LDA      #&60    ; &1245
    STA      object_screen_high_by_index    ; &1247
    LDA      level_tens_digit    ; &124A
    BNE      cap_level_intro_target_count    ; &124D
    LDA      level_units_digit    ; &124F
    CMP      #&6    ; &1252
    BMI      begin_level_intro_target_loop    ; &1254

.cap_level_intro_target_count
    LDA      #&5    ; &1256

.begin_level_intro_target_loop
    TAX    ; &1258
    DEX    ; &1259

.level_intro_draw_next_required_target
    STX      zp_scratch_79    ; &125A
    LDA      level_intro_required_graphic_table_11fe,X    ; &125C
    STA      object_graphic_id_by_index    ; &125F
    LDA      #&14    ; &1262
    JSR      wait_frames_count_a    ; &1264
    LDX      #&0    ; &1267
    JSR      draw_object_by_index    ; &1269
    LDA      object_screen_high_by_index    ; &126C
    CLC    ; &126F
    ADC      #&5    ; &1270
    STA      object_screen_high_by_index    ; &1272

.play_level_intro_required_target_sound
    LDA      #&d    ; &1275
    JSR      play_sound_id_if_enabled    ; &1277
    LDX      zp_scratch_79    ; &127A
    DEX    ; &127C
    BPL      level_intro_draw_next_required_target    ; &127D
    LDA      #&64    ; &127F
    JSR      wait_frames_count_a    ; &1281

.finish_level_intro_clear_screen
    JMP      oswrch_wrapper_from_a    ; &1284

.read_joystick_axes_and_fire
    LDA      #&80    ; &1287
    LDX      #&1    ; &1289
    JSR      MOS_OSBYTE    ; &128B
    CPY      #&40    ; &128E
    BCC      joystick_x_axis_positive_1287    ; &1290
    CPY      #&c0    ; &1292
    BCC      joystick_y_axis_scan_1287    ; &1294
    DEC      input_delta_x    ; &1296
    JMP      joystick_y_axis_scan_1287    ; &1298

.joystick_x_axis_positive_1287
    INC      input_delta_x    ; &129B

.joystick_y_axis_scan_1287
    LDA      #&80    ; &129D
    LDX      #&2    ; &129F
    JSR      MOS_OSBYTE    ; &12A1
    CPY      #&40    ; &12A4
    BCC      joystick_y_axis_positive_1287    ; &12A6
    CPY      #&c0    ; &12A8
    BCC      joystick_fire_scan_1287    ; &12AA
    DEC      input_delta_y    ; &12AC
    JMP      joystick_fire_scan_1287    ; &12AE

.joystick_y_axis_positive_1287
    INC      input_delta_y    ; &12B1

.joystick_fire_scan_1287
    LDA      #&80    ; &12B3
    LDX      #&0    ; &12B5
    JSR      MOS_OSBYTE    ; &12B7
    TXA    ; &12BA
    AND      #&1    ; &12BB
    TAX    ; &12BD
    RTS    ; &12BE

.seed_required_target_codes
    LDA      level_tens_digit    ; &12BF
    BNE      target_code_cap_to_slot5_12bf    ; &12C2
    LDX      level_units_digit    ; &12C4
    CPX      #&6    ; &12C7
    BMI      store_highest_required_target_slot_12bf    ; &12C9

.target_code_cap_to_slot5_12bf
    LDX      #&5    ; &12CB

.store_highest_required_target_slot_12bf
    STX      highest_required_target_slot    ; &12CD
    LDX      #&ff    ; &12CF

.seed_required_target_codes_loop_12bf
    JSR      random_unique_target_code    ; &12D1
    CPX      highest_required_target_slot    ; &12D4
    BMI      seed_required_target_codes_loop_12bf    ; &12D6

.reroll_bonus_target_code
    LDX      #&5    ; &12D8
    JMP      random_unique_target_code    ; &12DA

.random_unique_target_code
    INX    ; &12DD
    STX      object_x_by_index    ; &12DE

.random_target_code_reroll_12dd
    JSR      rng_next_byte    ; &12E1
    LDA      rng_output_byte    ; &12E4
    AND      #&f    ; &12E6
    LDX      object_x_by_index    ; &12E8
    STA      target_room_code,X    ; &12EB
    LDA      #&0    ; &12EE
    STA      target_collected_status,X    ; &12F0
    LDY      #&ff    ; &12F3

.target_code_uniqueness_scan_loop_12dd
    INY    ; &12F5
    CPY      object_x_by_index    ; &12F6
    BEQ      return_from_random_unique_target_code_12dd    ; &12F9
    LDA      target_room_code,Y    ; &12FB
    CMP      target_room_code,X    ; &12FE
    BEQ      random_target_code_reroll_12dd    ; &1301
    JMP      target_code_uniqueness_scan_loop_12dd    ; &1303

.return_from_random_unique_target_code_12dd
    RTS    ; &1306

.wait_frames_count_a
    STA      wait_frame_counter    ; &1307

.wait_frames_count_a_loop_1307
    JSR      wait_one_frame_tick    ; &1309
    DEC      wait_frame_counter    ; &130C
    BNE      wait_frames_count_a_loop_1307    ; &130E
    RTS    ; &1310

.test_player_spook_pair_overlap
    LDA      spook_release_timer    ; &1311
    BNE      return_from_player_spook_overlap_test_1311    ; &1314
    LDA      #&0    ; &1316
    STA      renderer_collision_accumulator    ; &1318
    LDA      player_x_first_cell    ; &131A
    SEC    ; &131D
    SBC      spook_first_cell_x    ; &131E
    BPL      player_spook_overlap_compare_x_range_1311    ; &1321
    EOR      #&ff    ; &1323
    CLC    ; &1325
    ADC      #&1    ; &1326

.player_spook_overlap_compare_x_range_1311
    CMP      #&3    ; &1328
    BPL      return_from_player_spook_overlap_test_1311    ; &132A
    LDA      player_y_first_cell    ; &132C
    SEC    ; &132F
    SBC      spook_first_cell_y    ; &1330
    BPL      player_spook_overlap_compare_y_range_1311    ; &1333
    EOR      #&ff    ; &1335
    CLC    ; &1337
    ADC      #&1    ; &1338

.player_spook_overlap_compare_y_range_1311
    CMP      #&4    ; &133A
    BPL      return_from_player_spook_overlap_test_1311    ; &133C
    INC      renderer_collision_accumulator    ; &133E

.return_from_player_spook_overlap_test_1311
    RTS    ; &1340

.draw_rotating_wait_text_strip
    LDA      zp_scratch_78    ; &1341
    CMP      #&18    ; &1343
    BNE      rotating_wait_text_pointer_setup_1341    ; &1345
    LDX      #&17    ; &1347

.clear_rotating_wait_text_edge_loop_1341
    LDA      #&0    ; &1349
    STA      &7B90,X    ; &134B
    STA      &7E10,X    ; &134E
    DEX    ; &1351
    BPL      clear_rotating_wait_text_edge_loop_1341    ; &1352

.rotating_wait_text_pointer_setup_1341
    LDY      #&7b    ; &1354
    STY      zp_screen_ptr_70_high    ; &1356
    LDA      zp_scratch_78    ; &1358
    CLC    ; &135A
    ADC      #&90    ; &135B
    STA      zp_screen_ptr_70_low    ; &135D
    JSR      clear_20char_text_buffer    ; &135F
    LDY      #&0    ; &1362
    LDX      zp_scratch_77    ; &1364

.copy_rotating_wait_text_chars_loop_1341
    LDA      scroll_or_animation_seed_table,X    ; &1366
    STA      text_buffer_20chars,Y    ; &1369
    INX    ; &136C
    TXA    ; &136D
    AND      #&3f    ; &136E
    TAX    ; &1370
    INY    ; &1371
    CPY      #&a    ; &1372
    BNE      copy_rotating_wait_text_chars_loop_1341    ; &1374
    JSR      wait_one_frame_tick    ; &1376
    LDA      #&0    ; &1379
    STA      object_y_by_index    ; &137B
    LDA      #&b    ; &137E
    STA      text_render_char_limit    ; &1380
    JSR      draw_20char_buffer_as_bitmap_text    ; &1382
    INC      zp_screen_ptr_70_high    ; &1385
    LDA      #&20    ; &1387
    JSR      add_a_to_pointer_70    ; &1389
    LDA      #&4    ; &138C
    STA      object_y_by_index    ; &138E
    JSR      draw_20char_buffer_as_bitmap_text    ; &1391
    LDA      zp_scratch_78    ; &1394
    SEC    ; &1396
    SBC      #&8    ; &1397
    AND      #&1f    ; &1399
    STA      zp_scratch_78    ; &139B
    CMP      #&18    ; &139D
    BNE      return_from_rotating_wait_text_1341    ; &139F
    INC      zp_scratch_77    ; &13A1
    LDA      zp_scratch_77    ; &13A3
    AND      #&3f    ; &13A5
    STA      zp_scratch_77    ; &13A7

.return_from_rotating_wait_text_1341
    RTS    ; &13A9

.scan_inkey_x
    LDA      #&81    ; &13AA
    LDY      #&ff    ; &13AC
    JSR      MOS_OSBYTE    ; &13AE
    CPX      #&0    ; &13B1
    RTS    ; &13B3

.early_init_sub_13b4
    LDX      #&b    ; &13B4

.early_init_vdu_byte_loop_13b4
    LDA      early_init_vdu_bytes_13b4,X    ; &13B6
    JSR      MOS_OSWRCH    ; &13B9
    DEX    ; &13BC
    BPL      early_init_vdu_byte_loop_13b4    ; &13BD
    RTS    ; &13BF

.add_a_to_pointer_70
    CLC    ; &13C0
    ADC      zp_screen_ptr_70_low    ; &13C1
    STA      zp_screen_ptr_70_low    ; &13C3
    LDA      zp_screen_ptr_70_high    ; &13C5
    ADC      #&0    ; &13C7
    STA      zp_screen_ptr_70_high    ; &13C9
    RTS    ; &13CB

.byte_decoded_add_a_to_pointer_72_copy
    CLC    ; &13CC
    ADC      zp_calc_ptr_72_low    ; &13CD
    STA      zp_calc_ptr_72_low    ; &13CF
    LDA      zp_calc_ptr_72_high    ; &13D1
    ADC      #&0    ; &13D3
    STA      zp_calc_ptr_72_high    ; &13D5
    RTS    ; &13D7

.shift_pointer_70_left_x_times
    ASL      zp_screen_ptr_70_low    ; &13D8
    ROL      zp_screen_ptr_70_high    ; &13DA
    DEX    ; &13DC
    BNE      shift_pointer_70_left_x_times    ; &13DD
    RTS    ; &13DF

.shift_pointer_72_left_x_times
    ASL      zp_calc_ptr_72_low    ; &13E0
    ROL      zp_calc_ptr_72_high    ; &13E2
    DEX    ; &13E4
    BNE      shift_pointer_72_left_x_times    ; &13E5
    RTS    ; &13E7

.draw_object_using_saved_screen_ptr
    LDA      saved_object_screen_low_by_index,X    ; &13E8
    STA      zp_screen_ptr_70_low    ; &13EB
    LDA      saved_object_screen_high_by_index,X    ; &13ED
    STA      zp_screen_ptr_70_high    ; &13F0
    LDA      saved_object_y_by_index,X    ; &13F2
    STA      object_render_y_or_parity    ; &13F5
    JMP      render_object_with_loaded_screen_ptr_1404    ; &13F8

.draw_object_by_index
    JSR      load_object_screen_ptr    ; &13FB
    LDA      object_y_by_index,X    ; &13FE
    STA      object_render_y_or_parity    ; &1401

.render_object_with_loaded_screen_ptr_1404
    LDY      render_mode_or_text_scratch    ; &1404
    LDA      renderer_store_vector_low_table,Y    ; &1406
    STA      zp_indirect_74_low    ; &1409
    LDA      renderer_store_vector_high_table,Y    ; &140B
    STA      zp_indirect_74_high    ; &140E
    LDY      object_graphic_id_by_index,X    ; &1410
    LDA      graphic_record_low_pointer_table_1404,Y    ; &1413
    STA      render_source_operand_low    ; &1416
    LDA      graphic_record_high_pointer_table_1404,Y    ; &1419
    STA      render_source_operand_high    ; &141C
    LDA      object_render_y_or_parity    ; &141F
    AND      #&1    ; &1422
    BNE      render_odd_y_split_setup_143a    ; &1424
    LDX      #&0    ; &1426
    LDY      #&0    ; &1428

.render_even_y_contiguous_loop_1426
    JSR      render_load_source_byte_and_jump_store_stub    ; &142A
    INY    ; &142D
    INX    ; &142E
    CPY      #&18    ; &142F
    BNE      render_even_y_contiguous_loop_1426    ; &1431
    RTS    ; &1433

.render_load_source_byte_and_jump_store_stub
    LDA      &FFFF,X    ; &1434
    JMP      (zp_indirect_74_low)    ; &1437

.render_odd_y_split_setup_143a
    LDX      #&0    ; &143A
    LDY      #&4    ; &143C

.render_odd_y_split_loop_143a
    JSR      render_load_source_byte_and_jump_store_stub    ; &143E
    INY    ; &1441
    INX    ; &1442
    TXA    ; &1443
    AND      #&3    ; &1444
    BNE      render_odd_y_split_progress_check_143a    ; &1446
    TXA    ; &1448
    CLC    ; &1449
    ADC      #&4    ; &144A
    TAX    ; &144C
    TYA    ; &144D
    ADC      #&4    ; &144E
    TAY    ; &1450

.render_odd_y_split_progress_check_143a
    CPY      #&98    ; &1451
    BEQ      return_from_object_render_walk_1404    ; &1453
    CPX      #&18    ; &1455
    BNE      render_odd_y_split_loop_143a    ; &1457
    LDX      #&4    ; &1459
    LDY      #&80    ; &145B
    INC      zp_screen_ptr_70_high    ; &145D
    INC      zp_screen_ptr_70_high    ; &145F
    JMP      render_odd_y_split_loop_143a    ; &1461

.return_from_object_render_walk_1404
    RTS    ; &1464

.render_store_eor_source
    EOR      (zp_screen_ptr_70_low),Y    ; &1465
    STA      (zp_screen_ptr_70_low),Y    ; &1467
    RTS    ; &1469

.render_store_eor_source_track_collision_bits
    STA      zp_calc_ptr_72_low    ; &146A
    LDA      (zp_screen_ptr_70_low),Y    ; &146C
    ORA      renderer_collision_accumulator    ; &146E
    STA      renderer_collision_accumulator    ; &1470
    LDA      zp_calc_ptr_72_low    ; &1472
    EOR      (zp_screen_ptr_70_low),Y    ; &1474
    STA      (zp_screen_ptr_70_low),Y    ; &1476
    RTS    ; &1478

.render_store_clear_byte
    LDA      #&0    ; &1479
    STA      (zp_screen_ptr_70_low),Y    ; &147B
    RTS    ; &147D

.render_collision_test_and_conditional_store
    LDA      (zp_screen_ptr_70_low),Y    ; &147E
    ORA      renderer_collision_accumulator    ; &1480
    STA      renderer_collision_accumulator    ; &1482
    LDA      (zp_screen_ptr_70_low),Y    ; &1484
    AND      #&55    ; &1486
    CMP      #&40    ; &1488
    BEQ      mark_renderer_player_collision_class    ; &148A
    CMP      #&45    ; &148C
    BEQ      mark_renderer_target_collect_collision_class    ; &148E
    LDA      (zp_screen_ptr_70_low),Y    ; &1490
    AND      #&aa    ; &1492
    CMP      #&80    ; &1494
    BEQ      mark_renderer_player_collision_class    ; &1496
    CMP      #&8a    ; &1498
    BEQ      mark_renderer_target_collect_collision_class    ; &149A
    RTS    ; &149C

.mark_renderer_player_collision_class
    LDA      #&1    ; &149D
    STA      player_collision_class_flag    ; &149F
    RTS    ; &14A2

.mark_renderer_target_collect_collision_class
    LDA      #&1    ; &14A3
    STA      target_collect_collision_flag    ; &14A5
    RTS    ; &14A7

.render_collision_accumulate_only
    LDA      (zp_screen_ptr_70_low),Y    ; &14A8
    ORA      renderer_collision_accumulator    ; &14AA
    STA      renderer_collision_accumulator    ; &14AC
    RTS    ; &14AE

.render_compare_source_to_screen
    CMP      (zp_screen_ptr_70_low),Y    ; &14AF
    BNE      render_compare_source_mismatch_14af    ; &14B1
    RTS    ; &14B3

.render_compare_source_mismatch_14af
    LDA      #&1    ; &14B4
    STA      renderer_collision_accumulator    ; &14B6
    RTS    ; &14B8

.load_packed_room_tile_nibble
    LDA      room_tile_y_index    ; &14B9
    ASL      A    ; &14BB
    ADC      room_tile_y_index    ; &14BC
    STA      room_tile_class_or_pattern    ; &14BE
    LDA      room_tile_x_index    ; &14C0
    LSR      A    ; &14C2
    CLC    ; &14C3
    ADC      room_tile_class_or_pattern    ; &14C4
    TAY    ; &14C6
    LDA      #&0    ; &14C7
    STA      zp_screen_ptr_70_high    ; &14C9
    LDA      room_area    ; &14CB
    STA      zp_screen_ptr_70_low    ; &14CD
    LDX      #&4    ; &14CF
    JSR      shift_pointer_70_left_x_times    ; &14D1
    LDA      room_area    ; &14D4
    JSR      add_a_to_pointer_70    ; &14D6
    LDA      room_area    ; &14D9
    JSR      add_a_to_pointer_70    ; &14DB
    LDA      #&e0    ; &14DE
    JSR      add_a_to_pointer_70    ; &14E0
    LDA      room_area    ; &14E3
    CMP      #&10    ; &14E5
    BPL      room_tile_area_ge_10_bank_adjust_14b9    ; &14E7
    LDA      #&27    ; &14E9
    CLC    ; &14EB
    ADC      zp_screen_ptr_70_high    ; &14EC
    STA      zp_screen_ptr_70_high    ; &14EE
    JMP      room_tile_read_packed_byte_14b9    ; &14F0

.room_tile_area_ge_10_bank_adjust_14b9
    LDA      #&2    ; &14F3
    CLC    ; &14F5
    ADC      zp_screen_ptr_70_high    ; &14F6
    STA      zp_screen_ptr_70_high    ; &14F8

.room_tile_read_packed_byte_14b9
    LDA      (zp_screen_ptr_70_low),Y    ; &14FA
    STA      room_tile_class_or_pattern    ; &14FC
    STA      zp_calc_ptr_72_low    ; &14FE
    LDA      room_tile_x_index    ; &1500
    AND      #&1    ; &1502
    BNE      room_tile_high_nibble_path_14b9    ; &1504
    LDA      room_tile_class_or_pattern    ; &1506
    AND      #&f    ; &1508
    STA      room_tile_class_or_pattern    ; &150A
    RTS    ; &150C

.room_tile_high_nibble_path_14b9
    LDA      room_tile_class_or_pattern    ; &150D
    LSR      A    ; &150F
    LSR      A    ; &1510
    LSR      A    ; &1511
    LSR      A    ; &1512
    STA      room_tile_class_or_pattern    ; &1513
    RTS    ; &1515

.draw_playfield_tiles
    LDA      #&0    ; &1516
    STA      room_tile_column_or_fill_index    ; &1518
    LDA      #&0    ; &151A
    STA      room_tile_x_index    ; &151C

.draw_playfield_major_column_setup_1516
    LDA      #&0    ; &151E
    STA      room_tile_y_index    ; &1520
    LDA      #&3    ; &1522
    STA      zp_scratch_3c    ; &1524

.draw_playfield_major_tile_loop_1516
    JSR      load_packed_room_tile_nibble    ; &1526
    AND      #&8    ; &1529
    LDY      room_tile_y_index    ; &152B
    STA      player_collision_class_flag,Y    ; &152D
    LDY      zp_scratch_3c    ; &1530
    LDX      room_tile_column_or_fill_index    ; &1532
    JSR      draw_24byte_tile_or_sprite    ; &1534
    LDA      room_tile_y_index    ; &1537
    CMP      #&5    ; &1539
    BEQ      fill_finished_major_column_gaps_1516    ; &153B
    LDA      #&4    ; &153D
    STA      zp_scratch_3d    ; &153F
    LDA      room_tile_class_or_pattern    ; &1541
    AND      #&2    ; &1543
    PHP    ; &1545
    LDA      #&0    ; &1546
    STA      room_tile_class_or_pattern    ; &1548
    PLP    ; &154A
    BEQ      draw_vertical_gap_cells_loop_1516    ; &154B
    LDA      #&3    ; &154D
    STA      room_tile_class_or_pattern    ; &154F

.draw_vertical_gap_cells_loop_1516
    INC      zp_scratch_3c    ; &1551
    LDY      zp_scratch_3c    ; &1553
    LDX      room_tile_column_or_fill_index    ; &1555
    JSR      draw_24byte_tile_or_sprite    ; &1557
    DEC      zp_scratch_3d    ; &155A
    BNE      draw_vertical_gap_cells_loop_1516    ; &155C
    INC      zp_scratch_3c    ; &155E
    INC      room_tile_y_index    ; &1560
    JMP      draw_playfield_major_tile_loop_1516    ; &1562

.fill_finished_major_column_gaps_1516
    JSR      fill_room_masked_offset_screen_gaps    ; &1565
    LDA      room_tile_x_index    ; &1568
    CMP      #&5    ; &156A
    BNE      draw_horizontal_gap_columns_setup_1516    ; &156C

.return_from_draw_playfield_tiles_1516
    RTS    ; &156E

.draw_horizontal_gap_columns_setup_1516
    LDA      #&4    ; &156F
    STA      room_gap_column_repeat_counter    ; &1571
    INC      room_tile_column_or_fill_index    ; &1573

.draw_horizontal_gap_column_setup_1516
    LDA      #&0    ; &1575
    STA      room_tile_y_index    ; &1577
    LDA      #&3    ; &1579
    STA      zp_scratch_3c    ; &157B

.draw_horizontal_gap_column_tile_loop_1516
    LDA      #&0    ; &157D
    STA      room_tile_class_or_pattern    ; &157F
    LDY      room_tile_y_index    ; &1581
    LDA      player_collision_class_flag,Y    ; &1583
    BEQ      draw_horizontal_gap_tile_1516    ; &1586
    LDA      #&c    ; &1588
    STA      room_tile_class_or_pattern    ; &158A

.draw_horizontal_gap_tile_1516
    LDY      zp_scratch_3c    ; &158C
    LDX      room_tile_column_or_fill_index    ; &158E
    JSR      draw_24byte_tile_or_sprite    ; &1590
    LDA      room_tile_y_index    ; &1593
    CMP      #&5    ; &1595
    BEQ      fill_finished_horizontal_gap_column_1516    ; &1597
    LDA      #&4    ; &1599
    STA      zp_scratch_3d    ; &159B
    LDA      #&0    ; &159D
    STA      room_tile_class_or_pattern    ; &159F

.draw_horizontal_gap_clear_vertical_run_loop_1516
    INC      zp_scratch_3c    ; &15A1
    LDY      zp_scratch_3c    ; &15A3
    LDX      room_tile_column_or_fill_index    ; &15A5
    JSR      draw_24byte_tile_or_sprite    ; &15A7
    DEC      zp_scratch_3d    ; &15AA
    BNE      draw_horizontal_gap_clear_vertical_run_loop_1516    ; &15AC
    INC      zp_scratch_3c    ; &15AE
    INC      room_tile_y_index    ; &15B0
    JMP      draw_horizontal_gap_column_tile_loop_1516    ; &15B2

.fill_finished_horizontal_gap_column_1516
    JSR      fill_room_masked_forward_screen_gaps    ; &15B5
    INC      room_tile_column_or_fill_index    ; &15B8
    DEC      room_gap_column_repeat_counter    ; &15BA
    BNE      draw_horizontal_gap_column_setup_1516    ; &15BC
    INC      room_tile_x_index    ; &15BE
    JMP      draw_playfield_major_column_setup_1516    ; &15C0

.read_game_input_and_pause
    JSR      handle_sound_on_off_keys    ; &15C3
    LDA      #&0    ; &15C6
    STA      input_delta_x    ; &15C8
    STA      input_delta_y    ; &15CA
    STA      input_scan_index    ; &15CC
    LDA      input_mode_keyboard_or_joystick    ; &15CF
    BNE      active_input_joystick_path_15c3    ; &15D2
    JSR      scan_movement_keys    ; &15D4
    JMP      active_input_fire_edge_check_15c3    ; &15D7

.active_input_joystick_path_15c3
    JSR      read_joystick_axes_and_fire    ; &15DA

.active_input_fire_edge_check_15c3
    LDA      previous_fire_input_latch    ; &15DD
    BNE      active_input_store_fire_latch_15c3    ; &15E0
    CPX      #&0    ; &15E2
    BEQ      active_input_store_fire_latch_15c3    ; &15E4
    LDA      #&1    ; &15E6
    STA      fire_edge_request    ; &15E8

.active_input_store_fire_latch_15c3
    STX      previous_fire_input_latch    ; &15EA
    JSR      scan_escape_key    ; &15ED
    BEQ      active_input_check_pause_key_15c3    ; &15F0
    PLA    ; &15F2
    PLA    ; &15F3
    PLA    ; &15F4
    PLA    ; &15F5
    JMP      menu_attract_entry_loop_0e05    ; &15F6

.active_input_check_pause_key_15c3
    LDX      #&c8    ; &15F9
    JSR      scan_inkey_current_x    ; &15FB
    BNE      active_input_wait_for_resume_key_15c3    ; &15FE
    RTS    ; &1600

.active_input_wait_for_resume_key_15c3
    LDX      #&cc    ; &1601
    JSR      scan_inkey_current_x    ; &1603
    BEQ      active_input_wait_for_resume_key_15c3    ; &1606
    RTS    ; &1608

.scan_movement_keys
    LDY      input_scan_index    ; &1609
    LDA      keyboard_inkey_codes_table_1609,Y    ; &160C
    TAX    ; &160F
    JSR      scan_inkey_current_x    ; &1610
    BEQ      keyboard_scan_next_key_1609    ; &1613
    LDY      input_scan_index    ; &1615
    LDA      input_delta_x    ; &1618
    CLC    ; &161A
    ADC      keyboard_input_delta_x_table_1609,Y    ; &161B
    STA      input_delta_x    ; &161E
    LDA      input_delta_y    ; &1620
    CLC    ; &1622
    ADC      keyboard_input_delta_y_table_1609,Y    ; &1623
    STA      input_delta_y    ; &1626

.keyboard_scan_next_key_1609
    INC      input_scan_index    ; &1628
    LDA      input_scan_index    ; &162B
    CMP      #&4    ; &162E
    BNE      scan_movement_keys    ; &1630
    LDX      #&9a    ; &1632
    JMP      scan_inkey_current_x    ; &1634

.byte_decoded_code_1637
    LDA      #&0    ; &1637
    STA      zp_screen_ptr_70_high    ; &1639
    LDA      zp_scratch_3d    ; &163B
    STA      zp_screen_ptr_70_low    ; &163D
    LDX      #&3    ; &163F
    JSR      shift_pointer_70_left_x_times    ; &1641
    LDA      zp_screen_ptr_70_high    ; &1644
    CLC    ; &1646
    ADC      #&30    ; &1647
    STA      zp_screen_ptr_70_high    ; &1649
    LDA      #&0    ; &164B
    STA      zp_scratch_3c    ; &164D

.byte_decoded_code_1637_loop_164f
    LDY      #&7    ; &164F

.byte_decoded_code_1637_loop_1651
    LDA      #&0    ; &1651
    STA      (zp_screen_ptr_70_low),Y    ; &1653
    DEY    ; &1655
    BPL      byte_decoded_code_1637_loop_1651    ; &1656
    LDA      #&80    ; &1658
    JSR      add_a_to_pointer_70    ; &165A
    INC      zp_screen_ptr_70_high    ; &165D
    INC      zp_screen_ptr_70_high    ; &165F
    INC      zp_scratch_3c    ; &1661
    LDA      zp_scratch_3c    ; &1663
    CMP      #&20    ; &1665
    BNE      byte_decoded_code_1637_loop_164f    ; &1667
    RTS    ; &1669

.compute_screen_ptr_for_object
    JSR      load_object_screen_ptr    ; &166A
    LDA      zp_screen_ptr_70_low    ; &166D
    STA      saved_object_screen_low_by_index,X    ; &166F
    LDA      zp_screen_ptr_70_high    ; &1672
    STA      saved_object_screen_high_by_index,X    ; &1674
    LDA      movement_delta_x    ; &1677
    BMI      compute_screen_ptr_x_negative_166a    ; &1679
    BEQ      compute_screen_ptr_y_delta_166a    ; &167B
    LDA      #&8    ; &167D
    JSR      add_a_to_pointer_70    ; &167F
    JMP      compute_screen_ptr_y_delta_166a    ; &1682

.compute_screen_ptr_x_negative_166a
    SEC    ; &1685
    LDA      zp_screen_ptr_70_low    ; &1686
    SBC      #&8    ; &1688
    STA      zp_screen_ptr_70_low    ; &168A
    LDA      zp_screen_ptr_70_high    ; &168C
    SBC      #&0    ; &168E
    STA      zp_screen_ptr_70_high    ; &1690

.compute_screen_ptr_y_delta_166a
    LDA      movement_delta_y    ; &1692
    BMI      compute_screen_ptr_y_negative_166a    ; &1694
    BEQ      return_from_compute_screen_ptr_166a    ; &1696
    LDA      object_y_by_index,X    ; &1698
    AND      #&1    ; &169B
    BNE      return_from_compute_screen_ptr_166a    ; &169D
    LDA      #&80    ; &169F
    JSR      add_a_to_pointer_70    ; &16A1
    INC      zp_screen_ptr_70_high    ; &16A4
    INC      zp_screen_ptr_70_high    ; &16A6
    RTS    ; &16A8

.compute_screen_ptr_y_negative_166a
    LDA      object_y_by_index,X    ; &16A9
    AND      #&1    ; &16AC
    BEQ      return_from_compute_screen_ptr_166a    ; &16AE
    SEC    ; &16B0
    LDA      zp_screen_ptr_70_low    ; &16B1
    SBC      #&80    ; &16B3
    STA      zp_screen_ptr_70_low    ; &16B5
    LDA      zp_screen_ptr_70_high    ; &16B7
    SBC      #&2    ; &16B9
    STA      zp_screen_ptr_70_high    ; &16BB

.return_from_compute_screen_ptr_166a
    RTS    ; &16BD

.move_object_and_update_screen_ptr
    LDA      movement_delta_x    ; &16BE
    CLC    ; &16C0
    ADC      object_x_by_index,X    ; &16C1
    STA      object_x_by_index,X    ; &16C4
    LDA      object_y_by_index,X    ; &16C7
    STA      saved_object_y_by_index,X    ; &16CA
    CLC    ; &16CD
    ADC      movement_delta_y    ; &16CE
    STA      object_y_by_index,X    ; &16D0
    JSR      compute_screen_ptr_for_object    ; &16D3
    LDA      zp_screen_ptr_70_low    ; &16D6
    STA      object_screen_low_by_index,X    ; &16D8
    LDA      zp_screen_ptr_70_high    ; &16DB
    STA      object_screen_high_by_index,X    ; &16DD
    RTS    ; &16E0

.apply_player_input_to_player_pair
    LDA      input_delta_x    ; &16E1
    BNE      player_input_nonzero_delta_16e1    ; &16E3
    LDA      input_delta_y    ; &16E5
    BNE      player_input_nonzero_delta_16e1    ; &16E7
    LDA      player_direction    ; &16E9
    ASL      A    ; &16EB
    ASL      A    ; &16EC
    CLC    ; &16ED
    ADC      #&2    ; &16EE
    STA      player_graphic_id_second_cell    ; &16F0
    JMP      apply_input_delta_to_player_pair    ; &16F3

.player_input_nonzero_delta_16e1
    LDX      input_delta_x    ; &16F6
    LDY      input_delta_y    ; &16F8
    JSR      direction_from_delta_xy    ; &16FA
    STA      player_direction    ; &16FD
    ASL      A    ; &16FF
    ASL      A    ; &1700
    STA      player_graphic_id_first_cell    ; &1701
    STA      zp_scratch_3d    ; &1704
    LDA      frame_phase    ; &1706
    LSR      A    ; &1708
    LSR      A    ; &1709
    CMP      #&3    ; &170A
    BNE      player_second_graphic_animation_store_16e1    ; &170C
    LDA      #&1    ; &170E

.player_second_graphic_animation_store_16e1
    CLC    ; &1710
    INC      zp_scratch_3d    ; &1711
    ADC      zp_scratch_3d    ; &1713
    STA      player_graphic_id_second_cell    ; &1715

.apply_input_delta_to_player_pair
    LDA      input_delta_x    ; &1718
    STA      movement_delta_x    ; &171A
    LDA      input_delta_y    ; &171C
    STA      movement_delta_y    ; &171E
    LDX      #&10    ; &1720
    JSR      move_object_and_update_screen_ptr    ; &1722
    LDX      #&11    ; &1725
    JMP      move_object_and_update_screen_ptr    ; &1727

.add_direction_score_or_state_delta
    STX      saved_level_loop_seed_or_status    ; &172A
    LDA      player_direction_graphic_delta_table_16e1,X    ; &172C
    CLC    ; &172F
    ADC      room_area    ; &1730
    STA      room_area    ; &1732
    RTS    ; &1734

.start_or_reset_player_and_level_objects
    JSR      apply_level_palette    ; &1735
    INC      current_level_intro_or_loop_flag    ; &1738
    LDA      current_level_intro_or_loop_flag    ; &173A
    CMP      #&18    ; &173C
    BNE      setup_remaining_object_score_gate_1735    ; &173E
    LDA      level_index_and_hazard_gate    ; &1740
    CMP      #&5    ; &1742
    BEQ      setup_remaining_object_score_gate_1735    ; &1744
    INC      level_index_and_hazard_gate    ; &1746

.setup_remaining_object_score_gate_1735
    LDA      remaining_active_object_count    ; &1748
    BNE      setup_player_start_state_1735    ; &174A
    LDA      #&19    ; &174C
    JSR      increment_four_char_score_or_counter    ; &174E

.setup_player_start_state_1735
    JSR      draw_playfield_tiles    ; &1751
    LDX      saved_level_loop_seed_or_status    ; &1754
    STX      level_loop_seed_or_status    ; &1756
    LDA      player_start_x_by_exit_1735,X    ; &1759
    STA      player_x_first_cell    ; &175C
    STA      &0A11    ; &175F
    LDA      player_start_direction_by_exit_1735,X    ; &1762
    STA      player_direction    ; &1765
    LDA      player_start_first_graphic_by_exit_1735,X    ; &1767
    STA      player_graphic_id_first_cell    ; &176A
    LDA      player_start_second_graphic_by_exit_1735,X    ; &176D
    STA      player_graphic_id_second_cell    ; &1770
    LDA      #&3    ; &1773
    STA      frame_phase    ; &1775
    LDA      player_start_y_by_exit_1735,X    ; &1777
    STA      player_y_first_cell    ; &177A
    CLC    ; &177D
    ADC      #&2    ; &177E
    STA      player_y_second_cell    ; &1780
    LDA      player_start_first_screen_low_by_exit_1735,X    ; &1783
    STA      player_screen_low_first_cell    ; &1786
    LDA      player_start_first_screen_high_by_exit_1735,X    ; &1789
    STA      player_screen_high_first_cell    ; &178C
    LDA      player_start_second_screen_low_by_exit_1735,X    ; &178F
    STA      player_screen_low_second_cell    ; &1792
    LDA      player_start_second_screen_high_by_exit_1735,X    ; &1795
    STA      player_screen_high_second_cell    ; &1798
    LDX      #&7    ; &179B

.clear_shot_hazard_seed_loop_1735
    LDA      #&0    ; &179D
    STA      shot_visible_flag_by_slot,X    ; &179F
    LDA      #&ff    ; &17A2
    STA      shot_direction_or_inactive_by_slot,X    ; &17A4
    DEX    ; &17A7
    BPL      clear_shot_hazard_seed_loop_1735    ; &17A8
    LDA      #&0    ; &17AA
    STA      active_player_shot_count    ; &17AC
    STA      active_spawned_hazard_count    ; &17AE
    JSR      draw_static_status_panel    ; &17B1
    JSR      setup_spinner_clone_cyberdroid_counts    ; &17B4
    JSR      place_target_code_objects_for_room    ; &17B7
    LDA      #&1    ; &17BA
    STA      bounds_or_outside_flag    ; &17BC
    RTS    ; &17BE

.frame_update_continue_or_delay
    LDA      transition_delay    ; &17BF
    CMP      #&1    ; &17C1
    BNE      transition_delay_active_countdown_17bf    ; &17C3
    RTS    ; &17C5

.transition_delay_active_countdown_17bf
    LDA      transition_delay    ; &17C6
    BEQ      advance_frame_phase_mod16_17bf    ; &17C8
    DEC      transition_delay    ; &17CA

.advance_frame_phase_mod16_17bf
    INC      frame_phase    ; &17CC
    LDA      frame_phase    ; &17CE
    AND      #&f    ; &17D0
    STA      frame_phase    ; &17D2
    BNE      phase_mod4_palette_gate_17bf    ; &17D4

.tick_spook_release_timer_on_phase0
    LDA      spook_release_timer    ; &17D6
    BEQ      phase_mod4_palette_gate_17bf    ; &17D9
    JSR      release_spook_pair_when_timer_expires    ; &17DB

.phase_mod4_palette_gate_17bf
    LDA      frame_phase    ; &17DE
    AND      #&3    ; &17E0
    BNE      phase_mod4_hit_animation_gate_17bf    ; &17E2

.cycle_active_palette_triplet
    LDY      palette_cycle_row_index    ; &17E4
    LDA      palette_cycle_logical13_values_17e4,Y    ; &17E7
    LDX      #&d    ; &17EA
    JSR      vdu19_set_palette_or_colour    ; &17EC
    LDA      palette_cycle_logical14_values_17e4,Y    ; &17EF
    INX    ; &17F2
    JSR      vdu19_set_palette_or_colour    ; &17F3
    LDA      palette_cycle_logical15_values_17e4,Y    ; &17F6
    INX    ; &17F9
    JSR      vdu19_set_palette_or_colour    ; &17FA
    INC      palette_cycle_row_index    ; &17FD
    LDA      palette_cycle_row_index    ; &1800
    CMP      #&3    ; &1803
    BNE      phase_mod4_hit_animation_gate_17bf    ; &1805
    LDA      #&0    ; &1807
    STA      palette_cycle_row_index    ; &1809

.phase_mod4_hit_animation_gate_17bf
    LDA      frame_phase    ; &180C
    AND      #&3    ; &180E
    BNE      run_active_object_scheduler_17bf    ; &1810

.erase_previous_hit_object_frame
    LDX      #&14    ; &1812
    LDA      #&0    ; &1814
    STA      render_mode_or_text_scratch    ; &1816

.erase_hit_object_loop_1812
    STX      active_object_index    ; &1818
    LDA      object_lifecycle_base_for_indexed_refs,X    ; &181A
    CMP      #&2    ; &181D
    BMI      erase_hit_object_next_slot_1812    ; &181F
    LDA      object_lifecycle_base_for_indexed_refs,X    ; &1821
    CMP      #&5    ; &1824
    BNE      erase_hit_object_draw_current_1812    ; &1826
    LDA      #&0    ; &1828
    STA      object_lifecycle_base_for_indexed_refs,X    ; &182A

.erase_hit_object_draw_current_1812
    JSR      draw_object_by_index    ; &182D

.erase_hit_object_next_slot_1812
    LDX      active_object_index    ; &1830
    INX    ; &1832
    CPX      #&20    ; &1833
    BNE      erase_hit_object_loop_1812    ; &1835

.run_active_object_scheduler_17bf
    JSR      update_active_spinner_clone_cyberdroid_objects    ; &1837
    LDA      frame_phase    ; &183A
    AND      #&3    ; &183C
    CMP      #&3    ; &183E
    BNE      frame_update    ; &1840
    LDA      transition_delay    ; &1842
    BNE      frame_update    ; &1844
    JSR      redraw_player_with_saved_graphic_pair    ; &1846

.frame_update
    LDA      frame_phase    ; &1849
    AND      #&3    ; &184B
    CMP      #&3    ; &184D
    BNE      after_visible_player_draw_gate_1849    ; &184F
    LDA      transition_delay    ; &1851
    BNE      after_visible_player_draw_gate_1849    ; &1853
    LDA      #&1    ; &1855
    STA      render_mode_or_text_scratch    ; &1857
    LDX      #&10    ; &1859
    JSR      draw_object_by_index    ; &185B
    LDX      #&11    ; &185E
    JSR      draw_object_by_index    ; &1860

.save_visible_player_graphic_pair_for_collision_redraw
    LDA      player_graphic_id_first_cell    ; &1863
    STA      saved_visible_player_graphic_id_first    ; &1866
    LDA      player_graphic_id_second_cell    ; &1868
    STA      saved_visible_player_graphic_id_second    ; &186B

.after_visible_player_draw_gate_1849
    JSR      move_spook_pair_towards_player    ; &186D
    LDA      frame_phase    ; &1870
    AND      #&3    ; &1872
    BNE      redraw_shot_hazard_slots_and_test_collisions    ; &1874

.advance_hit_object_animation_frame
    LDX      #&14    ; &1876
    LDA      #&0    ; &1878
    STA      render_mode_or_text_scratch    ; &187A

.advance_hit_object_animation_loop_1876
    STX      active_object_index    ; &187C
    LDA      object_lifecycle_base_for_indexed_refs,X    ; &187E
    CMP      #&2    ; &1881
    BMI      advance_hit_object_animation_next_slot_1876    ; &1883
    CMP      #&5    ; &1885
    BPL      advance_hit_object_animation_next_slot_1876    ; &1887
    CLC    ; &1889
    ADC      #&38    ; &188A
    STA      object_graphic_id_by_index,X    ; &188C
    INC      object_lifecycle_base_for_indexed_refs,X    ; &188F
    JSR      draw_object_by_index    ; &1892

.advance_hit_object_animation_next_slot_1876
    LDX      active_object_index    ; &1895
    INX    ; &1897
    CPX      #&20    ; &1898
    BNE      advance_hit_object_animation_loop_1876    ; &189A

.redraw_shot_hazard_slots_and_test_collisions
    LDX      #&7    ; &189C

.preinput_shot_hazard_scan_loop_189c
    STX      active_object_index    ; &189E
    JSR      erase_visible_shot_or_hazard_previous_bytes    ; &18A0
    JSR      draw_active_shot_or_hazard_and_test    ; &18A3
    LDX      active_object_index    ; &18A6
    DEX    ; &18A8
    BPL      preinput_shot_hazard_scan_loop_189c    ; &18A9

.consume_projectile_spook_pause_collision_flag
    LDA      projectile_spook_pause_collision_flag    ; &18AB
    BEQ      transition_delay_skip_input_gate_18c4    ; &18AD
    LDA      #&32    ; &18AF
    STA      spook_pause_counter    ; &18B1
    LDX      #&c    ; &18B4
    LDA      #&4    ; &18B6
    JSR      vdu19_set_palette_or_colour    ; &18B8
    LDA      #&0    ; &18BB
    STA      projectile_spook_pause_collision_flag    ; &18BD
    LDA      #&14    ; &18BF
    JSR      play_sound_id_if_enabled    ; &18C1

.transition_delay_skip_input_gate_18c4
    LDA      transition_delay    ; &18C4
    BEQ      input_bounds_and_player_collision_path_18cb    ; &18C6
    JMP      move_shot_hazard_slots_and_spawn_new    ; &18C8

.input_bounds_and_player_collision_path_18cb
    JSR      read_game_input_and_pause    ; &18CB
    JSR      test_player_bounds_and_restart_area    ; &18CE
    LDA      bounds_or_outside_flag    ; &18D1
    BNE      bounds_flag_restart_frame_18cb    ; &18D3
    STA      renderer_collision_accumulator    ; &18D5
    LDA      frame_phase    ; &18D7
    AND      #&3    ; &18D9
    CMP      #&3    ; &18DB
    BNE      move_shot_hazard_slots_and_spawn_new    ; &18DD

.player_collision_movement_window
    LDA      #&4    ; &18DF
    STA      render_mode_or_text_scratch    ; &18E1
    LDX      #&10    ; &18E3
    JSR      draw_object_by_index    ; &18E5
    LDX      #&11    ; &18E8
    JSR      draw_object_by_index    ; &18EA
    LDA      renderer_collision_accumulator    ; &18ED
    BNE      clear_player_before_life_loss_path_18df    ; &18EF
    JSR      test_player_spook_pair_overlap    ; &18F1
    LDA      renderer_collision_accumulator    ; &18F4
    BNE      clear_player_before_life_loss_path_18df    ; &18F6
    JSR      apply_player_input_to_player_pair    ; &18F8
    LDA      #&0    ; &18FB
    STA      player_collision_class_flag    ; &18FD
    STA      target_collect_collision_flag    ; &1900
    LDX      #&10    ; &1902
    LDA      #&3    ; &1904
    STA      render_mode_or_text_scratch    ; &1906
    JSR      draw_object_by_index    ; &1908
    LDX      #&11    ; &190B
    JSR      draw_object_by_index    ; &190D
    LDA      target_collect_collision_flag    ; &1910
    BEQ      player_collision_class_check_18df    ; &1912
    JSR      handle_collected_target_or_level_done    ; &1914
    JSR      draw_lives_or_target_status    ; &1917

.player_collision_class_check_18df
    LDA      player_collision_class_flag    ; &191A
    BEQ      renderer_collision_high_bits_check_18df    ; &191D
    JMP      player_collision_flash_sequence    ; &191F

.bounds_flag_restart_frame_18cb
    JMP      frame_update    ; &1922

.renderer_collision_high_bits_check_18df
    LDA      renderer_collision_accumulator    ; &1925
    AND      #&c0    ; &1927
    BEQ      move_shot_hazard_slots_and_spawn_new    ; &1929
    JSR      redraw_player_with_saved_graphic_pair    ; &192B
    JSR      lose_life_and_reset_player    ; &192E
    JMP      move_shot_hazard_slots_and_spawn_new    ; &1931

.clear_player_before_life_loss_path_18df
    JSR      clear_player_cells_before_life_loss    ; &1934

.move_shot_hazard_slots_and_spawn_new
    LDA      #&7    ; &1937
    STA      active_object_index    ; &1939

.move_shot_hazard_slots_loop_1937
    LDX      active_object_index    ; &193B
    JSR      move_active_shot_or_hazard    ; &193D
    DEC      active_object_index    ; &1940
    BPL      move_shot_hazard_slots_loop_1937    ; &1942
    LDA      transition_delay    ; &1944
    BNE      expire_shot_hazard_slots_after_draw    ; &1946
    JSR      spawn_player_shot_if_fire_pressed    ; &1948
    JSR      maybe_spawn_hazard_from_moving_object    ; &194B

.expire_shot_hazard_slots_after_draw
    LDA      #&7    ; &194E
    STA      active_object_index    ; &1950

.expire_shot_hazard_slots_loop_194e
    LDX      active_object_index    ; &1952
    JSR      expire_projectile_or_hazard_on_collision    ; &1954
    DEC      active_object_index    ; &1957
    BPL      expire_shot_hazard_slots_loop_194e    ; &1959
    JMP      frame_update_continue_or_delay    ; &195B

.byte_decoded_code_195e
    JSR      handle_player_hit_from_active_object    ; &195E
    JMP      move_shot_hazard_slots_and_spawn_new    ; &1961

.handle_player_hit_from_active_object
    LDA      frame_phase    ; &1964
    AND      #&3    ; &1966
    CMP      #&3    ; &1968
    BEQ      clear_player_cells_before_life_loss    ; &196A
    JSR      redraw_player_with_saved_graphic_pair    ; &196C
    JMP      jump_to_life_loss_after_player_redraw_1964    ; &196F

.clear_player_cells_before_life_loss
    LDA      #&0    ; &1972
    STA      render_mode_or_text_scratch    ; &1974
    LDX      #&10    ; &1976
    JSR      draw_object_by_index    ; &1978
    LDX      #&11    ; &197B
    JSR      draw_object_by_index    ; &197D

.jump_to_life_loss_after_player_redraw_1964
    JMP      lose_life_and_reset_player    ; &1980

.cancel_player_movement_delta
    LDA      #&0    ; &1983
    STA      input_delta_x    ; &1985
    STA      input_delta_y    ; &1987
    JMP      apply_input_delta_to_player_pair    ; &1989

.update_active_spinner_clone_cyberdroid_objects
    LDX      #&14    ; &198C

.addr_198E
    STX      active_object_index    ; &198E
    LDA      object_lifecycle_base_for_indexed_refs,X    ; &1990
    CMP      #&1    ; &1993
    BNE      addr_19EB    ; &1995
    LDA      object_graphic_id_by_index,X    ; &1997
    CMP      #&2a    ; &199A
    BNE      addr_19B1    ; &199C
    TXA    ; &199E
    AND      #&f    ; &199F
    CMP      frame_phase    ; &19A1
    BNE      addr_19B1    ; &19A3
    JSR      begin_target_enemy_move_test    ; &19A5
    JSR      move_spinner_towards_player_x_then_y    ; &19A8
    JSR      end_target_enemy_move_test    ; &19AB
    JMP      addr_19EB    ; &19AE

.addr_19B1
    LDA      object_graphic_id_by_index,X    ; &19B1
    CMP      #&2b    ; &19B4
    BNE      addr_19D1    ; &19B6
    TXA    ; &19B8
    AND      #&7    ; &19B9
    STA      zp_indirect_74_low    ; &19BB
    LDA      frame_phase    ; &19BD
    AND      #&7    ; &19BF
    CMP      zp_indirect_74_low    ; &19C1
    BNE      addr_19D1    ; &19C3
    JSR      begin_target_enemy_move_test    ; &19C5
    JSR      move_clone_continue_or_random    ; &19C8
    JSR      end_target_enemy_move_test    ; &19CB
    JMP      addr_19EB    ; &19CE

.addr_19D1
    LDA      object_graphic_id_by_index,X    ; &19D1
    CMP      #&2c    ; &19D4
    BNE      addr_19EB    ; &19D6
    TXA    ; &19D8
    AND      #&f    ; &19D9
    CMP      frame_phase    ; &19DB
    BNE      addr_19EB    ; &19DD
    JSR      begin_target_enemy_move_test    ; &19DF
    JSR      move_cyberdroid_persistent    ; &19E2
    JSR      end_target_enemy_move_test    ; &19E5
    JMP      addr_19EB    ; &19E8

.addr_19EB
    LDX      active_object_index    ; &19EB
    INX    ; &19ED
    CPX      #&20    ; &19EE
    BNE      addr_198E    ; &19F0
    RTS    ; &19F2

.player_collision_flash_sequence
    LDA      #&4    ; &19F3
    JSR      play_sound_id_if_enabled    ; &19F5
    LDA      player_graphic_id_first_cell    ; &19F8
    STA      movement_delta_x    ; &19FB
    LDA      player_graphic_id_second_cell    ; &19FD
    STA      movement_delta_y    ; &1A00
    LDA      #&32    ; &1A02
    STA      frame_phase    ; &1A04

.addr_1A06
    JSR      wait_one_frame_tick    ; &1A06
    LDA      frame_phase    ; &1A09
    AND      #&f    ; &1A0B
    LDX      #&8    ; &1A0D
    JSR      vdu19_set_palette_or_colour    ; &1A0F
    LDA      #&30    ; &1A12
    STA      player_graphic_id_first_cell    ; &1A14
    LDA      #&31    ; &1A17
    STA      player_graphic_id_second_cell    ; &1A19
    LDA      #&1    ; &1A1C
    STA      render_mode_or_text_scratch    ; &1A1E
    LDX      #&10    ; &1A20
    JSR      draw_object_using_saved_screen_ptr    ; &1A22
    LDX      #&11    ; &1A25
    JSR      draw_object_using_saved_screen_ptr    ; &1A27
    JSR      wait_one_frame_tick    ; &1A2A
    LDA      movement_delta_x    ; &1A2D
    STA      player_graphic_id_first_cell    ; &1A2F
    LDA      movement_delta_y    ; &1A32
    STA      player_graphic_id_second_cell    ; &1A34
    LDX      #&10    ; &1A37
    JSR      draw_object_using_saved_screen_ptr    ; &1A39
    LDX      #&11    ; &1A3C
    JSR      draw_object_using_saved_screen_ptr    ; &1A3E
    DEC      frame_phase    ; &1A41
    BPL      addr_1A06    ; &1A43
    LDA      #&2    ; &1A45
    STA      render_mode_or_text_scratch    ; &1A47
    LDX      #&10    ; &1A49
    JSR      draw_object_using_saved_screen_ptr    ; &1A4B
    LDX      #&11    ; &1A4E
    JSR      draw_object_using_saved_screen_ptr    ; &1A50
    JSR      lose_life_and_reset_player    ; &1A53
    JMP      move_shot_hazard_slots_and_spawn_new    ; &1A56

.lose_life_and_reset_player
    DEC      lives_status_count    ; &1A59
    JSR      draw_lives_or_target_status    ; &1A5C
    LDA      #&3    ; &1A5F
    JSR      play_sound_id_if_enabled    ; &1A61
    LDA      #&0    ; &1A64
    STA      render_mode_or_text_scratch    ; &1A66
    LDA      saved_player_second_screen_low    ; &1A68
    SEC    ; &1A6B
    SBC      #&8    ; &1A6C
    STA      player_screen_low_first_cell    ; &1A6E
    LDA      saved_player_second_screen_high    ; &1A71
    SBC      #&0    ; &1A74
    STA      player_screen_high_first_cell    ; &1A76
    LDA      &0BD1    ; &1A79
    STA      player_y_first_cell    ; &1A7C
    STA      player_y_second_cell    ; &1A7F
    LDA      saved_player_second_screen_low    ; &1A82
    CLC    ; &1A85
    ADC      #&10    ; &1A86
    STA      player_screen_low_second_cell    ; &1A88
    LDA      saved_player_second_screen_high    ; &1A8B
    ADC      #&0    ; &1A8E
    STA      player_screen_high_second_cell    ; &1A90
    LDA      #&33    ; &1A93
    STA      player_graphic_id_first_cell    ; &1A95
    LDA      #&34    ; &1A98
    STA      player_graphic_id_second_cell    ; &1A9A
    LDX      #&10    ; &1A9D
    JSR      draw_object_by_index    ; &1A9F
    LDX      #&11    ; &1AA2
    JSR      draw_object_by_index    ; &1AA4
    LDA      #&96    ; &1AA7
    STA      transition_delay    ; &1AA9
    RTS    ; &1AAB

.test_player_bounds_and_restart_area
    LDA      #&0    ; &1AAC
    STA      bounds_or_outside_flag    ; &1AAE
    LDA      player_x_first_cell    ; &1AB0
    CMP      #&2    ; &1AB3
    BPL      addr_1ABC    ; &1AB5
    LDX      #&1    ; &1AB7
    JMP      addr_1ADB    ; &1AB9

.addr_1ABC
    CMP      #&4c    ; &1ABC
    BMI      addr_1AC5    ; &1ABE
    LDX      #&0    ; &1AC0
    JMP      addr_1ADB    ; &1AC2

.addr_1AC5
    LDA      player_y_first_cell    ; &1AC5
    CMP      #&7    ; &1AC8
    BPL      addr_1AD1    ; &1ACA
    LDX      #&2    ; &1ACC
    JMP      addr_1ADB    ; &1ACE

.addr_1AD1
    CMP      #&36    ; &1AD1
    BMI      addr_1ADA    ; &1AD3
    LDX      #&3    ; &1AD5
    JMP      addr_1ADB    ; &1AD7

.addr_1ADA
    RTS    ; &1ADA

.addr_1ADB
    JSR      add_direction_score_or_state_delta    ; &1ADB
    JSR      clear_all_palette_entries    ; &1ADE
    LDA      #&c    ; &1AE1
    JSR      MOS_OSWRCH    ; &1AE3
    JMP      start_or_reset_player_and_level_objects    ; &1AE6

.erase_visible_shot_or_hazard_previous_bytes
    LDA      shot_visible_flag_by_slot,X    ; &1AE9
    BEQ      addr_1ADA    ; &1AEC
    LDA      shot_screen_low_previous,X    ; &1AEE
    STA      zp_screen_ptr_70_low    ; &1AF1
    LDA      shot_screen_high_previous,X    ; &1AF3
    STA      zp_screen_ptr_70_high    ; &1AF6
    LDY      #&1    ; &1AF8

.addr_1AFA
    LDA      (zp_screen_ptr_70_low),Y    ; &1AFA
    EOR      #&2a    ; &1AFC
    STA      (zp_screen_ptr_70_low),Y    ; &1AFE
    DEY    ; &1B00
    BPL      addr_1AFA    ; &1B01
    LDA      shot_direction_or_inactive_by_slot,X    ; &1B03
    BPL      addr_1B0D    ; &1B06
    LDA      #&0    ; &1B08
    STA      shot_visible_flag_by_slot,X    ; &1B0A

.addr_1B0D
    RTS    ; &1B0D

.draw_active_shot_or_hazard_and_test
    LDA      #&0    ; &1B0E
    STA      renderer_collision_accumulator    ; &1B10
    LDA      shot_direction_or_inactive_by_slot,X    ; &1B12
    BMI      addr_1ADA    ; &1B15
    LDA      #&1    ; &1B17
    STA      shot_visible_flag_by_slot,X    ; &1B19
    LDA      shot_screen_low_current,X    ; &1B1C
    STA      zp_screen_ptr_70_low    ; &1B1F
    LDA      shot_screen_high_current,X    ; &1B21
    STA      zp_screen_ptr_70_high    ; &1B24
    LDY      #&1    ; &1B26

.addr_1B28
    LDA      (zp_screen_ptr_70_low),Y    ; &1B28
    AND      #&aa    ; &1B2A
    ORA      renderer_collision_accumulator    ; &1B2C
    STA      renderer_collision_accumulator    ; &1B2E
    LDA      (zp_screen_ptr_70_low),Y    ; &1B30
    EOR      #&2a    ; &1B32
    STA      (zp_screen_ptr_70_low),Y    ; &1B34
    DEY    ; &1B36
    BPL      addr_1B28    ; &1B37
    LDA      renderer_collision_accumulator    ; &1B39
    BNE      addr_1B3E    ; &1B3B
    RTS    ; &1B3D

.addr_1B3E
    JMP      handle_shot_or_hazard_overlap_collisions    ; &1B3E

.expire_projectile_or_hazard_on_collision
    LDA      shot_direction_or_inactive_by_slot,X    ; &1B41
    BMI      addr_1ADA    ; &1B44
    LDA      #&0    ; &1B46
    STA      projectile_spook_pause_collision_flag    ; &1B48
    LDA      shot_screen_low_current,X    ; &1B4A
    STA      zp_screen_ptr_70_low    ; &1B4D
    LDA      shot_screen_high_current,X    ; &1B4F
    STA      zp_screen_ptr_70_high    ; &1B52
    LDY      #&1    ; &1B54

.addr_1B56
    LDA      (zp_screen_ptr_70_low),Y    ; &1B56
    AND      #&aa    ; &1B58
    CMP      #&a0    ; &1B5A
    BEQ      mark_projectile_spook_pause_collision    ; &1B5C
    CMP      #&80    ; &1B5E
    BEQ      deactivate_shot_or_hazard_slot    ; &1B60
    CMP      #&82    ; &1B62
    BEQ      deactivate_shot_or_hazard_slot    ; &1B64
    CMP      #&8a    ; &1B66
    BEQ      deactivate_shot_or_hazard_slot    ; &1B68
    DEY    ; &1B6A
    BPL      addr_1B56    ; &1B6B
    JSR      test_projectile_inside_playfield    ; &1B6D
    LDA      bounds_or_outside_flag    ; &1B70
    BNE      deactivate_shot_or_hazard_slot    ; &1B72
    RTS    ; &1B74

.mark_projectile_spook_pause_collision
    INC      projectile_spook_pause_collision_flag    ; &1B75

.deactivate_shot_or_hazard_slot
    LDA      #&ff    ; &1B77
    STA      shot_direction_or_inactive_by_slot,X    ; &1B79
    CPX      #&4    ; &1B7C
    BPL      addr_1B83    ; &1B7E
    DEC      active_player_shot_count    ; &1B80
    RTS    ; &1B82

.addr_1B83
    DEC      active_spawned_hazard_count    ; &1B83
    RTS    ; &1B86

.move_active_shot_or_hazard
    LDY      shot_direction_or_inactive_by_slot,X    ; &1B87
    BMI      addr_1BE2    ; &1B8A
    LDA      shot_screen_low_current,X    ; &1B8C
    STA      shot_screen_low_previous,X    ; &1B8F
    STA      zp_screen_ptr_70_low    ; &1B92
    LDA      shot_screen_high_current,X    ; &1B94
    STA      shot_screen_high_previous,X    ; &1B97
    STA      zp_screen_ptr_70_high    ; &1B9A
    LDA      shot_x_by_slot,X    ; &1B9C
    CLC    ; &1B9F
    ADC      projectile_grid_x_delta_by_dir_1b87,Y    ; &1BA0
    STA      shot_x_by_slot,X    ; &1BA3
    LDA      shot_y_by_slot,X    ; &1BA6
    CLC    ; &1BA9
    ADC      projectile_grid_y_delta_by_dir_1b87,Y    ; &1BAA
    STA      shot_y_by_slot,X    ; &1BAD
    CLC    ; &1BB0
    LDA      shot_screen_low_current,X    ; &1BB1
    ADC      projectile_ptr_low_delta_by_dir_1b87,Y    ; &1BB4
    STA      shot_screen_low_current,X    ; &1BB7
    LDA      shot_screen_high_current,X    ; &1BBA
    ADC      projectile_ptr_high_delta_by_dir_1b87,Y    ; &1BBD
    STA      shot_screen_high_current,X    ; &1BC0
    LDA      projectile_grid_y_delta_by_dir_1b87,Y    ; &1BC3
    BEQ      addr_1BE2    ; &1BC6
    BPL      addr_1BE3    ; &1BC8
    LDA      shot_y_by_slot,X    ; &1BCA
    AND      #&1    ; &1BCD
    BEQ      addr_1BE2    ; &1BCF
    LDA      shot_screen_low_current,X    ; &1BD1
    SEC    ; &1BD4
    SBC      #&78    ; &1BD5
    STA      shot_screen_low_current,X    ; &1BD7
    LDA      shot_screen_high_current,X    ; &1BDA
    SBC      #&2    ; &1BDD
    STA      shot_screen_high_current,X    ; &1BDF

.addr_1BE2
    RTS    ; &1BE2

.addr_1BE3
    LDA      shot_y_by_slot,X    ; &1BE3
    AND      #&1    ; &1BE6
    BNE      addr_1BE2    ; &1BE8
    LDA      shot_screen_low_current,X    ; &1BEA
    CLC    ; &1BED
    ADC      #&78    ; &1BEE
    STA      shot_screen_low_current,X    ; &1BF0
    LDA      shot_screen_high_current,X    ; &1BF3
    ADC      #&2    ; &1BF6
    STA      shot_screen_high_current,X    ; &1BF8
    RTS    ; &1BFB

.compute_shot_screen_ptr
    STX      zp_indirect_74_low    ; &1BFC
    LDA      shot_y_by_slot,X    ; &1BFE
    AND      #&fe    ; &1C01
    ASL      A    ; &1C03
    ASL      A    ; &1C04
    STA      zp_screen_ptr_70_low    ; &1C05
    LDA      #&0    ; &1C07
    STA      zp_screen_ptr_70_high    ; &1C09
    LDA      shot_y_by_slot,X    ; &1C0B
    AND      #&fe    ; &1C0E
    JSR      add_a_to_pointer_70    ; &1C10
    LDX      #&6    ; &1C13
    JSR      shift_pointer_70_left_x_times    ; &1C15
    LDX      zp_indirect_74_low    ; &1C18
    LDA      shot_y_by_slot,X    ; &1C1A
    AND      #&1    ; &1C1D
    BEQ      addr_1C26    ; &1C1F
    LDA      #&4    ; &1C21
    JSR      add_a_to_pointer_70    ; &1C23

.addr_1C26
    LDA      shot_x_by_slot,X    ; &1C26
    STA      zp_calc_ptr_72_low    ; &1C29
    LDA      #&0    ; &1C2B
    STA      zp_calc_ptr_72_high    ; &1C2D
    LDX      #&3    ; &1C2F
    JSR      shift_pointer_72_left_x_times    ; &1C31
    LDA      #&30    ; &1C34
    CLC    ; &1C36
    ADC      zp_screen_ptr_70_high    ; &1C37
    STA      zp_screen_ptr_70_high    ; &1C39
    LDX      zp_indirect_74_low    ; &1C3B
    LDA      zp_screen_ptr_70_low    ; &1C3D
    CLC    ; &1C3F
    ADC      zp_calc_ptr_72_low    ; &1C40
    STA      shot_screen_low_current,X    ; &1C42
    LDA      zp_screen_ptr_70_high    ; &1C45
    ADC      zp_calc_ptr_72_high    ; &1C47
    STA      shot_screen_high_current,X    ; &1C49
    RTS    ; &1C4C

.spawn_player_shot_if_fire_pressed
    LDA      fire_edge_request    ; &1C4D
    BEQ      addr_1C8C    ; &1C4F
    LDA      #&0    ; &1C51
    STA      fire_edge_request    ; &1C53
    LDA      active_player_shot_count    ; &1C55
    CMP      #&4    ; &1C57
    BEQ      addr_1C8C    ; &1C59
    INC      active_player_shot_count    ; &1C5B
    LDX      #&ff    ; &1C5D

.addr_1C5F
    INX    ; &1C5F
    LDA      shot_direction_or_inactive_by_slot,X    ; &1C60
    BPL      addr_1C5F    ; &1C63
    LDA      player_direction    ; &1C65
    STA      shot_direction_or_inactive_by_slot,X    ; &1C67
    TAY    ; &1C6A
    LDA      #&0    ; &1C6B
    STA      shot_visible_flag_by_slot,X    ; &1C6D
    LDA      player_x_first_cell    ; &1C70
    CLC    ; &1C73
    ADC      player_shot_x_offsets_1c4d,Y    ; &1C74
    STA      shot_x_by_slot,X    ; &1C77
    LDA      player_y_first_cell    ; &1C7A
    CLC    ; &1C7D
    ADC      player_shot_y_offsets_1c4d,Y    ; &1C7E
    STA      shot_y_by_slot,X    ; &1C81
    JSR      compute_shot_screen_ptr    ; &1C84
    LDA      #&0    ; &1C87
    JSR      play_sound_id_if_enabled    ; &1C89

.addr_1C8C
    RTS    ; &1C8C

.test_projectile_inside_playfield
    LDA      #&0    ; &1C8D
    STA      bounds_or_outside_flag    ; &1C8F
    LDA      shot_x_by_slot,X    ; &1C91
    CMP      #&2    ; &1C94
    BMI      addr_1CA8    ; &1C96
    CMP      #&4e    ; &1C98
    BPL      addr_1CA8    ; &1C9A
    LDA      shot_y_by_slot,X    ; &1C9C
    CMP      #&7    ; &1C9F
    BMI      addr_1CA8    ; &1CA1
    CMP      #&39    ; &1CA3
    BPL      addr_1CA8    ; &1CA5
    RTS    ; &1CA7

.addr_1CA8
    INC      bounds_or_outside_flag    ; &1CA8
    RTS    ; &1CAA

.draw_static_status_panel
    LDA      #&32    ; &1CAB
    STA      object_screen_high_by_index    ; &1CAD
    LDA      #&88    ; &1CB0
    STA      object_screen_low_by_index    ; &1CB2
    LDA      #&0    ; &1CB5
    STA      object_y_by_index    ; &1CB7
    LDA      #&25    ; &1CBA
    JSR      draw_status_glyph_at_current_ptr    ; &1CBC
    LDA      #&35    ; &1CBF
    JSR      draw_status_glyph_at_current_ptr    ; &1CC1
    LDA      #&20    ; &1CC4
    JSR      draw_status_glyph_at_current_ptr    ; &1CC6
    LDA      #&36    ; &1CC9
    JSR      draw_status_glyph_at_current_ptr    ; &1CCB
    LDA      #&37    ; &1CCE
    JSR      draw_status_glyph_at_current_ptr    ; &1CD0
    JSR      draw_score_counter_digits    ; &1CD3
    JSR      draw_lives_or_target_status    ; &1CD6
    LDA      #&2a    ; &1CD9
    STA      &34BA    ; &1CDB
    STA      &34BD    ; &1CDE
    LDA      #&34    ; &1CE1
    STA      object_screen_high_by_index    ; &1CE3
    LDA      #&8    ; &1CE6
    STA      object_screen_low_by_index    ; &1CE8
    LDA      #&36    ; &1CEB
    JSR      draw_status_glyph_at_current_ptr    ; &1CED
    LDA      #&20    ; &1CF0
    JSR      draw_status_glyph_at_current_ptr    ; &1CF2
    LDA      #&20    ; &1CF5
    JSR      draw_status_glyph_at_current_ptr    ; &1CF7
    LDA      #&38    ; &1CFA
    JSR      draw_status_glyph_at_current_ptr    ; &1CFC
    JSR      advance_status_glyph_ptr    ; &1CFF
    LDA      room_area    ; &1D02
    AND      #&f    ; &1D04
    CMP      #&9    ; &1D06
    BMI      addr_1D1C    ; &1D08
    LDA      #&21    ; &1D0A
    JSR      draw_status_glyph_at_current_ptr    ; &1D0C
    LDA      room_area    ; &1D0F
    AND      #&f    ; &1D11
    CLC    ; &1D13
    ADC      #&17    ; &1D14
    JSR      draw_status_glyph_at_current_ptr    ; &1D16
    JMP      addr_1D29    ; &1D19

.addr_1D1C
    JSR      advance_status_glyph_ptr    ; &1D1C
    LDA      room_area    ; &1D1F
    AND      #&f    ; &1D21
    CLC    ; &1D23
    ADC      #&21    ; &1D24
    JSR      draw_status_glyph_at_current_ptr    ; &1D26

.addr_1D29
    JSR      advance_status_glyph_ptr    ; &1D29
    LDA      level_tens_digit    ; &1D2C
    ADC      #&20    ; &1D2F
    JSR      draw_status_glyph_at_current_ptr    ; &1D31
    LDA      level_units_digit    ; &1D34
    ADC      #&20    ; &1D37
    JMP      draw_status_glyph_at_current_ptr    ; &1D39

.draw_status_glyph_at_current_ptr
    STA      object_graphic_id_by_index    ; &1D3C
    LDA      #&2    ; &1D3F
    STA      render_mode_or_text_scratch    ; &1D41
    LDX      #&0    ; &1D43
    JSR      draw_object_by_index    ; &1D45
    DEC      render_mode_or_text_scratch    ; &1D48
    LDX      #&0    ; &1D4A
    JSR      draw_object_by_index    ; &1D4C

.advance_status_glyph_ptr
    LDA      object_screen_low_by_index    ; &1D4F
    CLC    ; &1D52
    ADC      #&18    ; &1D53
    STA      object_screen_low_by_index    ; &1D55
    LDA      object_screen_high_by_index    ; &1D58
    ADC      #&0    ; &1D5B
    STA      object_screen_high_by_index    ; &1D5D
    RTS    ; &1D60

.rng_next_byte
    LDY      #&8    ; &1D61
    LDA      #&0    ; &1D63
    STA      rng_output_byte    ; &1D65

.addr_1D67
    LDA      &7A    ; &1D67
    AND      #&48    ; &1D69
    ADC      #&38    ; &1D6B
    ASL      A    ; &1D6D
    ASL      A    ; &1D6E
    ROL      &7C    ; &1D6F
    ROL      &7B    ; &1D71
    ROL      &7A    ; &1D73
    LDA      &7A    ; &1D75
    LSR      A    ; &1D77
    LSR      A    ; &1D78
    AND      #&1    ; &1D79
    ASL      rng_output_byte    ; &1D7B
    ORA      rng_output_byte    ; &1D7D
    STA      rng_output_byte    ; &1D7F
    DEY    ; &1D81
    BNE      addr_1D67    ; &1D82
    RTS    ; &1D84

.compute_item_screen_ptr
    STX      zp_indirect_74_low    ; &1D85
    LDA      object_y_by_index,X    ; &1D87
    AND      #&fe    ; &1D8A
    ASL      A    ; &1D8C
    ASL      A    ; &1D8D
    STA      zp_screen_ptr_70_low    ; &1D8E
    LDA      #&0    ; &1D90
    STA      zp_screen_ptr_70_high    ; &1D92
    LDA      object_y_by_index,X    ; &1D94
    AND      #&fe    ; &1D97
    JSR      add_a_to_pointer_70    ; &1D99
    LDX      #&6    ; &1D9C
    JSR      shift_pointer_70_left_x_times    ; &1D9E
    LDX      zp_indirect_74_low    ; &1DA1
    LDA      object_x_by_index,X    ; &1DA3
    STA      zp_calc_ptr_72_low    ; &1DA6
    LDA      #&0    ; &1DA8
    STA      zp_calc_ptr_72_high    ; &1DAA
    LDX      #&3    ; &1DAC
    JSR      shift_pointer_72_left_x_times    ; &1DAE
    LDA      #&30    ; &1DB1
    CLC    ; &1DB3
    ADC      zp_screen_ptr_70_high    ; &1DB4
    STA      zp_screen_ptr_70_high    ; &1DB6
    LDX      zp_indirect_74_low    ; &1DB8
    LDA      zp_screen_ptr_70_low    ; &1DBA
    CLC    ; &1DBC
    ADC      zp_calc_ptr_72_low    ; &1DBD
    STA      object_screen_low_by_index,X    ; &1DBF
    LDA      zp_screen_ptr_70_high    ; &1DC2
    ADC      zp_calc_ptr_72_high    ; &1DC4
    STA      object_screen_high_by_index,X    ; &1DC6
    LDA      #&7    ; &1DC9
    RTS    ; &1DCB

.set_item_graphic_and_random_place
    LDX      logical_item_slot_index    ; &1DCC
    STA      item_graphic_id_alias_object_14,X    ; &1DCE

.random_place_item
    JSR      rng_next_byte    ; &1DD1
    LDX      logical_item_slot_index    ; &1DD4
    AND      #&1f    ; &1DD6
    STA      item_x_alias_object_14,X    ; &1DD8
    JSR      rng_next_byte    ; &1DDB
    LDX      logical_item_slot_index    ; &1DDE
    AND      #&f    ; &1DE0
    CLC    ; &1DE2
    ADC      item_x_alias_object_14,X    ; &1DE3
    ADC      #&f    ; &1DE6
    STA      item_x_alias_object_14,X    ; &1DE8
    JSR      rng_next_byte    ; &1DEB
    LDX      logical_item_slot_index    ; &1DEE
    AND      #&1f    ; &1DF0
    CLC    ; &1DF2
    ADC      #&f    ; &1DF3
    STA      item_y_alias_object_14,X    ; &1DF5
    LDA      player_x_first_cell    ; &1DF8
    SBC      item_x_alias_object_14,X    ; &1DFB
    BPL      addr_1E02    ; &1DFE
    EOR      #&ff    ; &1E00

.addr_1E02
    CMP      #&8    ; &1E02
    BPL      addr_1E15    ; &1E04
    LDA      player_y_first_cell    ; &1E06
    SEC    ; &1E09
    SBC      item_y_alias_object_14,X    ; &1E0A
    BPL      addr_1E11    ; &1E0D
    EOR      #&ff    ; &1E0F

.addr_1E11
    CMP      #&5    ; &1E11
    BMI      random_place_item    ; &1E13

.addr_1E15
    TXA    ; &1E15
    CLC    ; &1E16
    ADC      #&14    ; &1E17
    TAX    ; &1E19
    STX      zp_scratch_77    ; &1E1A
    JSR      compute_item_screen_ptr    ; &1E1C
    LDA      #&0    ; &1E1F
    STA      renderer_collision_accumulator    ; &1E21
    LDA      #&5    ; &1E23
    STA      render_mode_or_text_scratch    ; &1E25
    JSR      draw_object_by_index    ; &1E27
    LDA      renderer_collision_accumulator    ; &1E2A
    BNE      random_place_item    ; &1E2C
    LDA      #&0    ; &1E2E
    STA      render_mode_or_text_scratch    ; &1E30
    LDX      zp_scratch_77    ; &1E32
    JSR      draw_object_by_index    ; &1E34
    INC      logical_item_slot_index    ; &1E37
    RTS    ; &1E39

.setup_spinner_clone_cyberdroid_counts
    LDA      #&2e    ; &1E3A
    STA      spook_graphic_id_first_cell    ; &1E3C
    LDA      #&2f    ; &1E3F
    STA      spook_graphic_id_second_cell    ; &1E41
    LDX      level_index_and_hazard_gate    ; &1E44
    LDA      spook_release_timer_by_level_index_1e3a,X    ; &1E46
    STA      spook_release_timer    ; &1E49
    LDA      spinner_count_by_level_index_1e3a,X    ; &1E4C
    STA      pending_spinner_count    ; &1E4F
    LDA      clone_count_by_level_index_1e3a,X    ; &1E52
    STA      pending_clone_count    ; &1E55
    LDA      cyberdroid_count_by_level_index_1e3a,X    ; &1E58
    STA      pending_cyberdroid_count    ; &1E5B
    LDX      #&2b    ; &1E5E
    LDA      #&0    ; &1E60

.addr_1E62
    STA      item_state_alias_object_14,X    ; &1E62
    STA      item_delta_x_by_slot,X    ; &1E65
    STA      item_delta_y_by_slot,X    ; &1E68
    DEX    ; &1E6B
    BPL      addr_1E62    ; &1E6C
    LDA      pending_spinner_count    ; &1E6E
    CLC    ; &1E71
    ADC      pending_clone_count    ; &1E72
    ADC      pending_cyberdroid_count    ; &1E75
    STA      logical_item_slot_index    ; &1E78
    STA      remaining_active_object_count    ; &1E7A
    TAX    ; &1E7C
    DEX    ; &1E7D
    LDA      #&1    ; &1E7E

.addr_1E80
    STA      item_state_alias_object_14,X    ; &1E80
    DEX    ; &1E83
    BPL      addr_1E80    ; &1E84
    LDA      #&0    ; &1E86
    STA      logical_item_slot_index    ; &1E88

.addr_1E8A
    DEC      pending_spinner_count    ; &1E8A
    BMI      addr_1E97    ; &1E8D
    LDA      #&2a    ; &1E8F
    JSR      set_item_graphic_and_random_place    ; &1E91
    JMP      addr_1E8A    ; &1E94

.addr_1E97
    DEC      pending_clone_count    ; &1E97
    BMI      addr_1EA4    ; &1E9A
    LDA      #&2b    ; &1E9C
    JSR      set_item_graphic_and_random_place    ; &1E9E
    JMP      addr_1E97    ; &1EA1

.addr_1EA4
    DEC      pending_cyberdroid_count    ; &1EA4
    BMI      addr_1EB1    ; &1EA7
    LDA      #&2c    ; &1EA9
    JSR      set_item_graphic_and_random_place    ; &1EAB
    JMP      addr_1EA4    ; &1EAE

.addr_1EB1
    RTS    ; &1EB1

.read_object0_screen_byte_at_temp_position
    LDX      #&0    ; &1EB2
    JSR      compute_item_screen_ptr    ; &1EB4
    LDA      object_screen_low_by_index    ; &1EB7
    STA      zp_screen_ptr_70_low    ; &1EBA
    LDA      object_screen_high_by_index    ; &1EBC
    STA      zp_screen_ptr_70_high    ; &1EBF
    LDY      #&0    ; &1EC1
    LDA      (zp_screen_ptr_70_low),Y    ; &1EC3
    STA      renderer_collision_accumulator    ; &1EC5
    RTS    ; &1EC7

.fill_room_masked_forward_screen_gaps
    LDX      room_area    ; &1EC8
    LDA      initial_screen_room_feature_mask_1ec8_1f19,X    ; &1ECA
    BNE      addr_1ED0    ; &1ECD
    RTS    ; &1ECF

.addr_1ED0
    LDA      room_tile_column_or_fill_index    ; &1ED0
    CLC    ; &1ED2
    ADC      room_tile_column_or_fill_index    ; &1ED3
    ADC      room_tile_column_or_fill_index    ; &1ED5
    ADC      #&1    ; &1ED7
    STA      object_x_by_index    ; &1ED9
    LDA      #&2d    ; &1EDC
    STA      object_graphic_id_by_index    ; &1EDE
    LDA      #&6    ; &1EE1
    STA      object_y_by_index    ; &1EE3
    LDA      #&0    ; &1EE6
    STA      &0C93    ; &1EE8
    STA      &0C94    ; &1EEB

.addr_1EEE
    JSR      read_object0_screen_byte_at_temp_position    ; &1EEE
    BEQ      addr_1EFE    ; &1EF1
    LDA      &0C93    ; &1EF3
    EOR      #&1    ; &1EF6
    STA      &0C93    ; &1EF8
    JMP      addr_1F06    ; &1EFB

.addr_1EFE
    LDA      &0C93    ; &1EFE
    BEQ      addr_1F06    ; &1F01
    JSR      copy_level_modulo_24byte_fill_pattern    ; &1F03

.addr_1F06
    LDA      renderer_collision_accumulator    ; &1F06
    STA      &0C94    ; &1F08
    INC      object_y_by_index    ; &1F0B
    INC      object_y_by_index    ; &1F0E
    LDA      object_y_by_index    ; &1F11
    CMP      #&3a    ; &1F14
    BMI      addr_1EEE    ; &1F16

.addr_1F18
    RTS    ; &1F18

.fill_room_masked_offset_screen_gaps
    LDX      room_area    ; &1F19
    LDA      initial_screen_room_feature_mask_1ec8_1f19,X    ; &1F1B
    BEQ      addr_1F18    ; &1F1E
    LDA      room_tile_column_or_fill_index    ; &1F20
    BEQ      addr_1F18    ; &1F22
    LDA      room_tile_column_or_fill_index    ; &1F24
    CLC    ; &1F26
    ADC      room_tile_column_or_fill_index    ; &1F27
    ADC      room_tile_column_or_fill_index    ; &1F29
    SEC    ; &1F2B
    SBC      #&2    ; &1F2C
    STA      object_x_by_index    ; &1F2E
    LDA      #&2d    ; &1F31
    STA      object_graphic_id_by_index    ; &1F33
    LDA      #&6    ; &1F36
    STA      object_y_by_index    ; &1F38

.addr_1F3B
    JSR      read_object0_screen_byte_at_temp_position    ; &1F3B
    BEQ      addr_1F58    ; &1F3E
    LDA      #&18    ; &1F40
    JSR      add_a_to_pointer_70    ; &1F42
    LDA      zp_screen_ptr_70_low    ; &1F45
    STA      object_screen_low_by_index    ; &1F47
    LDA      zp_screen_ptr_70_high    ; &1F4A
    STA      object_screen_high_by_index    ; &1F4C
    LDY      #&0    ; &1F4F
    LDA      (zp_screen_ptr_70_low),Y    ; &1F51
    BNE      addr_1F58    ; &1F53
    JSR      copy_level_modulo_24byte_fill_pattern    ; &1F55

.addr_1F58
    INC      object_y_by_index    ; &1F58
    INC      object_y_by_index    ; &1F5B
    LDA      object_y_by_index    ; &1F5E
    CMP      #&3a    ; &1F61
    BMI      addr_1F3B    ; &1F63
    RTS    ; &1F65

.clear_all_palette_entries
    LDX      #&f    ; &1F66
    LDA      #&0    ; &1F68

.clear_palette_entry_loop_1f66
    JSR      vdu19_set_palette_or_colour    ; &1F6A
    DEX    ; &1F6D
    BPL      clear_palette_entry_loop_1f66    ; &1F6E
    RTS    ; &1F70

.apply_level_palette
    LDX      #&f    ; &1F71

.apply_base_palette_entry_loop_1f71
    LDA      base_palette_table_1f71,X    ; &1F73
    JSR      vdu19_set_palette_or_colour    ; &1F76
    DEX    ; &1F79
    BPL      apply_base_palette_entry_loop_1f71    ; &1F7A
    LDA      level_units_digit    ; &1F7C
    AND      #&7    ; &1F7F
    LDX      #&9    ; &1F81
    JSR      vdu19_set_palette_or_colour    ; &1F83
    LDA      level_units_digit    ; &1F86
    AND      #&7    ; &1F89
    TAX    ; &1F8B
    LDA      level_palette_logical8_by_level_units_mod8,X    ; &1F8C
    LDX      #&8    ; &1F8F
    JMP      vdu19_set_palette_or_colour    ; &1F91

.byte_decoded_code_1f94
    LDA      #&0    ; &1F94
    STA      render_mode_or_text_scratch    ; &1F96
    JSR      draw_object_by_index    ; &1F98
    LDX      active_object_index    ; &1F9B
    LDA      #&5    ; &1F9D
    STA      render_mode_or_text_scratch    ; &1F9F

.restore_object_position_and_ptr
    LDA      saved_object_y_by_index,X    ; &1FA1
    STA      object_y_by_index,X    ; &1FA4
    LDA      saved_object_screen_low_by_index,X    ; &1FA7
    STA      object_screen_low_by_index,X    ; &1FAA
    LDA      saved_object_screen_high_by_index,X    ; &1FAD
    STA      object_screen_high_by_index,X    ; &1FB0
    LDA      object_x_by_index,X    ; &1FB3
    SEC    ; &1FB6
    SBC      movement_delta_x    ; &1FB7
    STA      object_x_by_index,X    ; &1FB9
    RTS    ; &1FBC

.test_object_inside_playfield
    LDA      #&0    ; &1FBD
    STA      bounds_or_outside_flag    ; &1FBF
    LDA      object_x_by_index,X    ; &1FC1
    CMP      #&4    ; &1FC4
    BMI      addr_1FD8    ; &1FC6
    CMP      #&4a    ; &1FC8
    BPL      addr_1FD8    ; &1FCA
    LDA      object_y_by_index,X    ; &1FCC
    CMP      #&8    ; &1FCF
    BMI      addr_1FD8    ; &1FD1
    CMP      #&37    ; &1FD3
    BPL      addr_1FD8    ; &1FD5
    RTS    ; &1FD7

.addr_1FD8
    INC      bounds_or_outside_flag    ; &1FD8
    RTS    ; &1FDA

.begin_target_enemy_move_test
    LDA      #&0    ; &1FDB
    STA      render_mode_or_text_scratch    ; &1FDD
    STA      movement_delta_x    ; &1FDF
    STA      movement_delta_y    ; &1FE1
    JSR      draw_object_by_index    ; &1FE3
    LDX      active_object_index    ; &1FE6
    LDA      #&5    ; &1FE8
    STA      render_mode_or_text_scratch    ; &1FEA
    RTS    ; &1FEC

.end_target_enemy_move_test
    LDX      active_object_index    ; &1FED
    LDA      #&0    ; &1FEF
    STA      render_mode_or_text_scratch    ; &1FF1
    JSR      draw_object_by_index    ; &1FF3
    RTS    ; &1FF6

.move_spinner_towards_player_x_then_y
    JSR      delta_towards_player_for_object_x    ; &1FF7
    JSR      try_move_object_with_collision    ; &1FFA
    LDA      object_movement_success_flag    ; &1FFD
    BEQ      addr_2003    ; &2000
    RTS    ; &2002

.addr_2003
    LDX      active_object_index    ; &2003
    JSR      restore_object_position_and_ptr    ; &2005
    LDA      #&0    ; &2008
    STA      movement_delta_x    ; &200A
    STA      movement_delta_y    ; &200C
    LDA      player_x_first_cell    ; &200E
    CMP      object_x_by_index,X    ; &2011
    BEQ      addr_2023    ; &2014
    BMI      addr_201F    ; &2016
    LDA      #&1    ; &2018
    STA      movement_delta_x    ; &201A
    JMP      addr_2023    ; &201C

.addr_201F
    LDA      #&ff    ; &201F
    STA      movement_delta_x    ; &2021

.addr_2023
    JSR      try_move_object_with_collision    ; &2023
    LDA      object_movement_success_flag    ; &2026
    BEQ      addr_202C    ; &2029
    RTS    ; &202B

.addr_202C
    LDX      active_object_index    ; &202C
    JSR      restore_object_position_and_ptr    ; &202E
    LDA      #&0    ; &2031
    STA      movement_delta_x    ; &2033
    STA      movement_delta_y    ; &2035
    LDA      player_y_first_cell    ; &2037
    CLC    ; &203A
    ADC      #&1    ; &203B
    CMP      object_y_by_index,X    ; &203D
    BEQ      addr_204F    ; &2040
    BMI      addr_204B    ; &2042
    LDA      #&1    ; &2044
    STA      movement_delta_y    ; &2046
    JMP      addr_204F    ; &2048

.addr_204B
    LDA      #&ff    ; &204B
    STA      movement_delta_y    ; &204D

.addr_204F
    JSR      try_move_object_with_collision    ; &204F
    LDA      object_movement_success_flag    ; &2052
    BEQ      addr_2058    ; &2055
    RTS    ; &2057

.addr_2058
    LDX      active_object_index    ; &2058
    JMP      restore_object_position_and_ptr    ; &205A

.try_move_object_with_collision
    LDA      #&0    ; &205D
    STA      object_movement_success_flag    ; &205F
    STA      renderer_collision_accumulator    ; &2062
    JSR      move_object_and_update_screen_ptr    ; &2064
    LDX      active_object_index    ; &2067
    JSR      draw_object_by_index    ; &2069
    LDA      renderer_collision_accumulator    ; &206C
    BNE      addr_207F    ; &206E
    LDX      active_object_index    ; &2070
    JSR      test_object_inside_playfield    ; &2072
    LDA      bounds_or_outside_flag    ; &2075
    BNE      addr_207F    ; &2077
    LDA      #&1    ; &2079
    STA      object_movement_success_flag    ; &207B
    RTS    ; &207E

.addr_207F
    RTS    ; &207F

.move_clone_continue_or_random
    JSR      rng_next_byte    ; &2080
    AND      #&7    ; &2083
    BEQ      addr_20A1    ; &2085
    LDX      active_object_index    ; &2087
    LDA      item_delta_x_by_slot,X    ; &2089
    STA      movement_delta_x    ; &208C
    LDA      item_delta_y_by_slot,X    ; &208E
    STA      movement_delta_y    ; &2091
    JSR      try_move_object_with_collision    ; &2093
    LDA      object_movement_success_flag    ; &2096
    BEQ      addr_209C    ; &2099
    RTS    ; &209B

.addr_209C
    LDX      active_object_index    ; &209C
    JSR      restore_object_position_and_ptr    ; &209E

.addr_20A1
    JSR      random_direction_delta    ; &20A1
    JSR      try_move_object_with_collision    ; &20A4
    LDA      object_movement_success_flag    ; &20A7
    BEQ      addr_20AD    ; &20AA
    RTS    ; &20AC

.addr_20AD
    LDX      active_object_index    ; &20AD
    JSR      restore_object_position_and_ptr    ; &20AF
    RTS    ; &20B2

.random_direction_delta
    JSR      rng_next_byte    ; &20B3
    AND      #&1    ; &20B6
    STA      movement_delta_x    ; &20B8
    JSR      rng_next_byte    ; &20BA
    AND      #&1    ; &20BD
    SEC    ; &20BF
    SBC      movement_delta_x    ; &20C0
    STA      movement_delta_x    ; &20C2
    LDX      active_object_index    ; &20C4
    STA      item_delta_x_by_slot,X    ; &20C6
    JSR      rng_next_byte    ; &20C9
    AND      #&1    ; &20CC
    STA      movement_delta_y    ; &20CE
    JSR      rng_next_byte    ; &20D0
    AND      #&1    ; &20D3
    SEC    ; &20D5
    SBC      movement_delta_y    ; &20D6
    STA      movement_delta_y    ; &20D8
    LDX      active_object_index    ; &20DA
    STA      item_delta_y_by_slot,X    ; &20DC
    RTS    ; &20DF

.move_cyberdroid_persistent
    LDA      item_delta_x_by_slot,X    ; &20E0
    BNE      addr_2104    ; &20E3
    LDA      item_delta_y_by_slot,X    ; &20E5
    BNE      addr_2104    ; &20E8
    JSR      random_direction_delta    ; &20EA
    JSR      try_move_object_with_collision    ; &20ED
    LDA      object_movement_success_flag    ; &20F0
    BEQ      addr_20F6    ; &20F3
    RTS    ; &20F5

.addr_20F6
    LDX      active_object_index    ; &20F6
    JSR      restore_object_position_and_ptr    ; &20F8
    LDA      #&0    ; &20FB
    STA      item_delta_x_by_slot,X    ; &20FD
    STA      item_delta_y_by_slot,X    ; &2100
    RTS    ; &2103

.addr_2104
    LDA      player_x_first_cell    ; &2104
    CMP      object_x_by_index,X    ; &2107
    BEQ      addr_211A    ; &210A
    LDA      player_y_first_cell    ; &210C
    CLC    ; &210F
    ADC      #&1    ; &2110
    CMP      object_y_by_index,X    ; &2112
    BEQ      addr_2133    ; &2115
    JMP      addr_2150    ; &2117

.addr_211A
    LDA      player_y_first_cell    ; &211A
    CLC    ; &211D
    ADC      #&1    ; &211E
    CMP      object_y_by_index,X    ; &2120
    BMI      addr_212C    ; &2123
    LDA      #&1    ; &2125
    STA      movement_delta_y    ; &2127
    JMP      addr_2146    ; &2129

.addr_212C
    LDA      #&ff    ; &212C
    STA      movement_delta_y    ; &212E
    JMP      addr_2146    ; &2130

.addr_2133
    LDA      player_x_first_cell    ; &2133
    CMP      object_x_by_index,X    ; &2136
    BMI      addr_2142    ; &2139
    LDA      #&1    ; &213B
    STA      movement_delta_x    ; &213D
    JMP      addr_2146    ; &213F

.addr_2142
    LDA      #&ff    ; &2142
    STA      movement_delta_x    ; &2144

.addr_2146
    LDA      movement_delta_x    ; &2146
    STA      item_delta_x_by_slot,X    ; &2148
    LDA      movement_delta_y    ; &214B
    STA      item_delta_y_by_slot,X    ; &214D

.addr_2150
    LDA      item_delta_x_by_slot,X    ; &2150
    STA      movement_delta_x    ; &2153
    LDA      item_delta_y_by_slot,X    ; &2155
    STA      movement_delta_y    ; &2158
    JSR      try_move_object_with_collision    ; &215A
    LDA      object_movement_success_flag    ; &215D
    BEQ      addr_20F6    ; &2160
    RTS    ; &2162

.handle_shot_or_hazard_overlap_collisions
    LDA      transition_delay    ; &2163
    BNE      addr_2187    ; &2165
    LDA      shot_x_by_slot,X    ; &2167
    SEC    ; &216A
    SBC      player_x_first_cell    ; &216B
    BMI      addr_2187    ; &216E
    CMP      #&3    ; &2170
    BPL      addr_2187    ; &2172
    LDA      shot_y_by_slot,X    ; &2174
    SEC    ; &2177
    SBC      player_y_first_cell    ; &2178
    BMI      addr_2187    ; &217B
    CMP      #&4    ; &217D
    BPL      addr_2187    ; &217F
    JSR      deactivate_and_erase_shot_or_hazard    ; &2181
    JMP      handle_player_hit_from_active_object    ; &2184

.addr_2187
    LDY      #&14    ; &2187

.addr_2189
    LDA      object_lifecycle_base_for_indexed_refs,Y    ; &2189
    CMP      #&1    ; &218C
    BNE      addr_21D2    ; &218E
    LDA      shot_x_by_slot,X    ; &2190
    SEC    ; &2193
    SBC      object_x_by_index,Y    ; &2194
    BMI      addr_21D2    ; &2197
    CMP      #&3    ; &2199
    BPL      addr_21D2    ; &219B
    LDA      shot_y_by_slot,X    ; &219D
    SEC    ; &21A0
    SBC      object_y_by_index,Y    ; &21A1
    BMI      addr_21D2    ; &21A4
    CMP      #&2    ; &21A6
    BPL      addr_21D2    ; &21A8
    LDA      #&2    ; &21AA
    STA      object_lifecycle_base_for_indexed_refs,Y    ; &21AC
    CPX      #&4    ; &21AF
    BPL      addr_21C2    ; &21B1
    LDA      object_graphic_id_by_index,Y    ; &21B3
    SEC    ; &21B6
    SBC      #&29    ; &21B7
    ASL      A    ; &21B9
    JSR      increment_four_char_score_or_counter    ; &21BA
    DEC      remaining_active_object_count    ; &21BD
    JMP      addr_21C8    ; &21BF

.addr_21C2
    LDA      object_graphic_id_by_index,Y    ; &21C2
    JSR      place_graphic_in_free_item_slot    ; &21C5

.addr_21C8
    LDX      active_object_index    ; &21C8
    JSR      deactivate_and_erase_shot_or_hazard    ; &21CA
    LDA      #&2    ; &21CD
    JMP      play_sound_id_if_enabled    ; &21CF

.addr_21D2
    INY    ; &21D2
    CPY      #&2c    ; &21D3
    BNE      addr_2189    ; &21D5
    RTS    ; &21D7

.deactivate_and_erase_shot_or_hazard
    LDA      shot_screen_low_current,X    ; &21D8
    STA      shot_screen_low_previous,X    ; &21DB
    LDA      shot_screen_high_current,X    ; &21DE
    STA      shot_screen_high_previous,X    ; &21E1
    JSR      deactivate_shot_or_hazard_slot    ; &21E4
    JMP      erase_visible_shot_or_hazard_previous_bytes    ; &21E7

.play_sound_id_if_enabled
    STA      zp_screen_ptr_70_low    ; &21EA
    LDA      sound_disabled_flag    ; &21EC
    BEQ      addr_21F2    ; &21EF
    RTS    ; &21F1

.addr_21F2
    LDA      #&0    ; &21F2
    STA      zp_screen_ptr_70_high    ; &21F4
    LDX      #&3    ; &21F6
    JSR      shift_pointer_70_left_x_times    ; &21F8
    LDX      zp_screen_ptr_70_low    ; &21FB
    LDA      #&b    ; &21FD
    ADC      zp_screen_ptr_70_high    ; &21FF
    TAY    ; &2201
    LDA      #&7    ; &2202
    JMP      MOS_OSWORD    ; &2204

.direction_from_delta_xy
    CPX      #&0    ; &2207
    BEQ      addr_222B    ; &2209
    BPL      addr_221C    ; &220B
    CPY      #&0    ; &220D
    BNE      addr_2214    ; &220F
    LDA      #&3    ; &2211
    RTS    ; &2213

.addr_2214
    BPL      addr_2219    ; &2214
    LDA      #&6    ; &2216
    RTS    ; &2218

.addr_2219
    LDA      #&7    ; &2219
    RTS    ; &221B

.addr_221C
    CPY      #&0    ; &221C
    BNE      addr_2223    ; &221E
    LDA      #&2    ; &2220
    RTS    ; &2222

.addr_2223
    BPL      addr_2228    ; &2223
    LDA      #&4    ; &2225
    RTS    ; &2227

.addr_2228
    LDA      #&5    ; &2228
    RTS    ; &222A

.addr_222B
    CPY      #&0    ; &222B
    BPL      addr_2232    ; &222D
    LDA      #&1    ; &222F
    RTS    ; &2231

.addr_2232
    LDA      #&0    ; &2232
    RTS    ; &2234

.maybe_spawn_hazard_from_moving_object
    LDA      active_spawned_hazard_count    ; &2235
    CMP      #&4    ; &2238
    BPL      addr_2262    ; &223A
    JSR      rng_next_byte    ; &223C
    AND      #&7    ; &223F
    CMP      level_index_and_hazard_gate    ; &2241
    BPL      addr_2262    ; &2243
    JSR      rng_next_byte    ; &2245
    AND      #&f    ; &2248
    CLC    ; &224A
    ADC      #&19    ; &224B
    STA      hazard_spawn_source_object_index    ; &224D
    TAX    ; &2250
    LDA      object_lifecycle_base_for_indexed_refs,X    ; &2251
    CMP      #&1    ; &2254
    BNE      addr_2262    ; &2256
    LDA      item_delta_x_by_slot,X    ; &2258
    BNE      addr_2263    ; &225B
    LDY      item_delta_y_by_slot,X    ; &225D
    BNE      addr_2263    ; &2260

.addr_2262
    RTS    ; &2262

.addr_2263
    LDY      item_delta_y_by_slot,X    ; &2263
    TAX    ; &2266
    JSR      direction_from_delta_xy    ; &2267
    STA      hazard_spawn_direction    ; &226A
    LDY      #&3    ; &226D

.addr_226F
    INY    ; &226F
    LDA      shot_direction_or_inactive_by_slot,Y    ; &2270
    BPL      addr_226F    ; &2273
    LDA      shot_visible_flag_by_slot,Y    ; &2275
    BNE      addr_2262    ; &2278
    STY      hazard_spawn_slot_index    ; &227A
    LDA      #&0    ; &227D
    STA      shot_visible_flag_by_slot,Y    ; &227F
    LDA      hazard_spawn_direction    ; &2282
    STA      shot_direction_or_inactive_by_slot,Y    ; &2285
    LDX      hazard_spawn_source_object_index    ; &2288
    TAY    ; &228B
    LDA      hazard_spawn_y_offsets_2235,Y    ; &228C
    CLC    ; &228F
    ADC      object_y_by_index,X    ; &2290
    LDY      hazard_spawn_slot_index    ; &2293
    STA      shot_y_by_slot,Y    ; &2296
    LDY      hazard_spawn_direction    ; &2299
    LDA      hazard_spawn_x_offsets_2235,Y    ; &229C
    CLC    ; &229F
    ADC      object_x_by_index,X    ; &22A0
    LDY      hazard_spawn_slot_index    ; &22A3
    STA      shot_x_by_slot,Y    ; &22A6
    TYA    ; &22A9
    TAX    ; &22AA
    JSR      compute_shot_screen_ptr    ; &22AB
    INC      active_spawned_hazard_count    ; &22AE

.hazard_spawn_escape_pulse_mode_check
    LDA      bootstrap_osbyte81_x_result_flag    ; &22B1
    BNE      play_hazard_spawn_sound    ; &22B4

.hazard_spawn_set_escape_condition
    LDA      #&7d    ; &22B6
    JSR      MOS_OSBYTE    ; &22B8

.hazard_spawn_acknowledge_escape_condition
    LDA      #&7e    ; &22BB
    JSR      MOS_OSBYTE    ; &22BD

.play_hazard_spawn_sound
    LDA      #&b    ; &22C0
    JMP      play_sound_id_if_enabled    ; &22C2

.find_free_item_slot
    LDX      #&ff    ; &22C5

.find_free_item_slot_scan_loop_22c5
    INX    ; &22C7
    LDA      item_state_alias_object_14,X    ; &22C8
    BNE      find_free_item_slot_scan_loop_22c5    ; &22CB
    STX      logical_item_slot_index    ; &22CD

.return_from_find_or_place_item_slot_22c5
    RTS    ; &22CF

.place_graphic_in_free_item_slot
    TAY    ; &22D0
    JSR      find_free_item_slot    ; &22D1
    CPX      #&c    ; &22D4
    BPL      return_from_find_or_place_item_slot_22c5    ; &22D6
    TYA    ; &22D8
    STA      item_graphic_id_alias_object_14,X    ; &22D9
    LDA      #&1    ; &22DC
    STA      item_state_alias_object_14,X    ; &22DE
    STX      logical_item_slot_index    ; &22E1
    JMP      random_place_item    ; &22E3

.increment_four_char_score_or_counter
    STA      zp_scratch_76    ; &22E6

.score_increment_outer_loop_22e6
    LDX      #&0    ; &22E8

.score_increment_digit_carry_loop_22e6
    INC      score_counter_chars,X    ; &22EA
    LDA      score_counter_chars,X    ; &22ED
    CMP      #&2a    ; &22F0
    BNE      score_upper_wrap_check_setup_22e6    ; &22F2
    LDA      #&20    ; &22F4
    STA      score_counter_chars,X    ; &22F6
    INX    ; &22F9
    CPX      #&4    ; &22FA
    BNE      score_increment_digit_carry_loop_22e6    ; &22FC

.score_upper_wrap_check_setup_22e6
    LDY      #&2    ; &22FE

.score_upper_wrap_check_loop_22e6
    LDA      score_counter_chars,Y    ; &2300
    CMP      #&20    ; &2303
    BNE      score_increment_next_unit_22e6    ; &2305
    DEY    ; &2307
    BPL      score_upper_wrap_check_loop_22e6    ; &2308
    LDA      #&15    ; &230A
    JSR      play_sound_id_if_enabled    ; &230C
    INC      lives_status_count    ; &230F
    JSR      draw_lives_or_target_status    ; &2312

.score_increment_next_unit_22e6
    DEC      zp_scratch_76    ; &2315
    BNE      score_increment_outer_loop_22e6    ; &2317

.draw_score_counter_digits
    LDA      #&33    ; &2319
    STA      object_screen_high_by_index    ; &231B
    LDA      #&18    ; &231E
    STA      object_screen_low_by_index    ; &2320
    STA      object_y_by_index    ; &2323
    LDX      #&3    ; &2326

.draw_score_digits_loop_2319
    STX      zp_scratch_76    ; &2328
    LDA      score_counter_chars,X    ; &232A
    JSR      draw_status_glyph_at_current_ptr    ; &232D
    LDX      zp_scratch_76    ; &2330
    DEX    ; &2332
    BPL      draw_score_digits_loop_2319    ; &2333
    LDA      #&20    ; &2335
    JMP      draw_status_glyph_at_current_ptr    ; &2337

.load_object_screen_ptr
    LDA      object_screen_low_by_index,X    ; &233A
    STA      zp_screen_ptr_70_low    ; &233D
    LDA      object_screen_high_by_index,X    ; &233F
    STA      zp_screen_ptr_70_high    ; &2342
    RTS    ; &2344

.draw_lives_or_target_status
    LDA      #&7b    ; &2345
    STA      object_screen_high_by_index    ; &2347
    LDA      #&8    ; &234A
    STA      object_screen_low_by_index    ; &234C
    STA      object_y_by_index    ; &234F
    LDX      lives_status_count    ; &2352
    BEQ      clear_empty_life_status_cell_2345    ; &2355
    BMI      target_status_scan_setup_2345    ; &2357

.draw_life_status_marker_loop_2345
    STX      zp_scratch_76    ; &2359
    LDA      #&39    ; &235B
    JSR      draw_status_glyph_at_current_ptr    ; &235D
    LDX      zp_scratch_76    ; &2360
    DEX    ; &2362
    BNE      draw_life_status_marker_loop_2345    ; &2363

.clear_empty_life_status_cell_2345
    JSR      load_object_screen_ptr    ; &2365
    LDY      #&17    ; &2368
    LDA      #&0    ; &236A

.clear_status_cell_byte_loop_2345
    STA      (zp_screen_ptr_70_low),Y    ; &236C
    DEY    ; &236E
    BPL      clear_status_cell_byte_loop_2345    ; &236F

.target_status_scan_setup_2345
    LDA      #&7d    ; &2371
    STA      object_screen_high_by_index    ; &2373
    LDA      #&60    ; &2376
    STA      object_screen_low_by_index    ; &2378
    LDX      #&0    ; &237B

.target_status_scan_loop_2345
    INX    ; &237D
    STX      zp_scratch_76    ; &237E
    LDA      target_collected_status,X    ; &2380
    BEQ      target_status_scan_next_2345    ; &2383
    LDA      target_status_graphic_ids_2345,X    ; &2385
    JSR      draw_status_glyph_at_current_ptr    ; &2388
    SEC    ; &238B
    LDA      object_screen_low_by_index    ; &238C
    SBC      #&38    ; &238F
    STA      object_screen_low_by_index    ; &2391
    LDA      object_screen_high_by_index    ; &2394
    SBC      #&0    ; &2397
    STA      object_screen_high_by_index    ; &2399

.target_status_scan_next_2345
    LDX      zp_scratch_76    ; &239C
    CPX      highest_required_target_slot    ; &239E
    BMI      target_status_scan_loop_2345    ; &23A0
    RTS    ; &23A2

.delta_towards_player_for_object_x
    LDA      player_x_first_cell    ; &23A3
    CMP      object_x_by_index,X    ; &23A6
    BEQ      delta_towards_player_compare_y_23a3    ; &23A9
    BMI      delta_towards_player_set_x_negative_23a3    ; &23AB
    LDA      #&1    ; &23AD
    STA      movement_delta_x    ; &23AF
    JMP      delta_towards_player_compare_y_23a3    ; &23B1

.delta_towards_player_set_x_negative_23a3
    LDA      #&ff    ; &23B4
    STA      movement_delta_x    ; &23B6

.delta_towards_player_compare_y_23a3
    LDA      player_y_first_cell    ; &23B8
    CLC    ; &23BB
    ADC      #&1    ; &23BC
    CMP      object_y_by_index,X    ; &23BE
    BEQ      return_from_delta_towards_player_23a3    ; &23C1
    BMI      delta_towards_player_set_y_negative_23a3    ; &23C3
    LDA      #&1    ; &23C5
    STA      movement_delta_y    ; &23C7
    RTS    ; &23C9

.delta_towards_player_set_y_negative_23a3
    LDA      #&ff    ; &23CA
    STA      movement_delta_y    ; &23CC

.return_from_delta_towards_player_23a3
    RTS    ; &23CE

.release_spook_pair_when_timer_expires
    DEC      spook_release_timer    ; &23CF
    BNE      return_from_spook_release_or_draw_23cf    ; &23D2
    LDA      #&0    ; &23D4
    STA      spook_pause_counter    ; &23D6
    STA      spook_first_cell_x    ; &23D9
    STA      spook_first_cell_y    ; &23DC
    STA      &0A8E    ; &23DF
    STA      &0A0F    ; &23E2
    LDA      #&30    ; &23E5
    STA      &0ACE    ; &23E7
    LDA      #&32    ; &23EA
    STA      &0ACF    ; &23EC
    LDA      #&80    ; &23EF
    STA      &0A8F    ; &23F1
    LDA      #&2    ; &23F4
    STA      &0A4F    ; &23F6
    JSR      draw_spook_pair_if_released    ; &23F9

.return_from_spook_release_or_draw_23cf
    RTS    ; &23FC

.draw_spook_pair_if_released
    LDA      spook_release_timer    ; &23FD
    BNE      return_from_spook_release_or_draw_23cf    ; &2400
    LDA      #&0    ; &2402
    STA      render_mode_or_text_scratch    ; &2404
    LDX      #&e    ; &2406
    JSR      draw_object_by_index    ; &2408
    LDX      #&f    ; &240B
    JMP      draw_object_by_index    ; &240D

.move_spook_pair_towards_player
    LDA      frame_phase    ; &2410
    AND      #&1    ; &2412
    BEQ      return_from_spook_release_or_draw_23cf    ; &2414
    LDA      spook_release_timer    ; &2416
    BNE      return_from_spook_release_or_draw_23cf    ; &2419
    LDA      spook_pause_counter    ; &241B
    BEQ      move_spook_pair_active_step_2410    ; &241E
    DEC      spook_pause_counter    ; &2420
    RTS    ; &2423

.move_spook_pair_active_step_2410
    LDA      #&7    ; &2424
    LDX      #&c    ; &2426
    JSR      vdu19_set_palette_or_colour    ; &2428
    JSR      draw_spook_pair_if_released    ; &242B
    LDX      #&e    ; &242E
    JSR      delta_towards_player_for_object_x    ; &2430
    JSR      move_object_and_update_screen_ptr    ; &2433
    LDX      #&f    ; &2436
    JSR      move_object_and_update_screen_ptr    ; &2438
    JMP      draw_spook_pair_if_released    ; &243B

.place_target_code_objects_for_room
    LDX      highest_required_target_slot    ; &243E

.place_target_code_object_scan_loop_243e
    JSR      place_one_target_code_object_if_due    ; &2440
    LDX      active_object_index    ; &2443
    DEX    ; &2445
    BPL      place_target_code_object_scan_loop_243e    ; &2446
    LDX      #&6    ; &2448

.place_one_target_code_object_if_due
    STX      active_object_index    ; &244A
    LDA      room_area    ; &244C
    AND      #&f    ; &244E
    CMP      target_room_code,X    ; &2450
    BNE      return_from_place_target_code_object_244a    ; &2453
    LDA      target_collected_status,X    ; &2455
    BNE      return_from_place_target_code_object_244a    ; &2458
    TXA    ; &245A
    CLC    ; &245B
    ADC      #&22    ; &245C
    STA      logical_item_slot_index    ; &245E
    JMP      random_place_item    ; &2460

.return_from_place_target_code_object_244a
    RTS    ; &2463

.scan_escape_key
    LDX      #&8f    ; &2464

.scan_inkey_current_x
    LDA      #&81    ; &2466
    LDY      #&ff    ; &2468
    JSR      MOS_OSBYTE    ; &246A
    CPX      #&0    ; &246D
    RTS    ; &246F

.handle_sound_on_off_keys
    LDX      #&ae    ; &2470
    JSR      scan_inkey_current_x    ; &2472
    BEQ      sound_toggle_check_sound_off_key_2470    ; &2475
    LDA      #&0    ; &2477
    STA      sound_disabled_flag    ; &2479

.sound_toggle_check_sound_off_key_2470
    LDX      #&ef    ; &247C
    JSR      scan_inkey_current_x    ; &247E
    BEQ      return_from_sound_toggle_2470    ; &2481
    LDA      #&c    ; &2483
    JSR      play_sound_id_if_enabled    ; &2485
    LDA      #&10    ; &2488
    JSR      play_sound_id_if_enabled    ; &248A
    LDA      #&1    ; &248D
    STA      sound_disabled_flag    ; &248F

.return_from_sound_toggle_2470
    RTS    ; &2492

.redraw_player_with_saved_graphic_pair
    LDA      player_graphic_id_first_cell    ; &2493
    STA      temp_player_graphic_id_first    ; &2496
    LDA      player_graphic_id_second_cell    ; &2498
    STA      temp_player_graphic_id_second    ; &249B
    LDA      saved_visible_player_graphic_id_second    ; &249D
    STA      player_graphic_id_second_cell    ; &249F
    LDA      saved_visible_player_graphic_id_first    ; &24A2
    STA      player_graphic_id_first_cell    ; &24A4
    LDA      #&0    ; &24A7
    STA      render_mode_or_text_scratch    ; &24A9
    LDX      #&10    ; &24AB
    JSR      draw_object_using_saved_screen_ptr    ; &24AD
    LDX      #&11    ; &24B0
    JSR      draw_object_using_saved_screen_ptr    ; &24B2
    LDA      temp_player_graphic_id_first    ; &24B5
    STA      player_graphic_id_first_cell    ; &24B7
    LDA      temp_player_graphic_id_second    ; &24BA
    STA      player_graphic_id_second_cell    ; &24BC
    RTS    ; &24BF

.vdu19_set_palette_or_colour
    PHA    ; &24C0
    LDA      #&13    ; &24C1
    JSR      MOS_OSWRCH    ; &24C3
    TXA    ; &24C6
    JSR      MOS_OSWRCH    ; &24C7
    PLA    ; &24CA
    JSR      MOS_OSWRCH    ; &24CB
    LDA      #&0    ; &24CE
    JSR      MOS_OSWRCH    ; &24D0
    JSR      MOS_OSWRCH    ; &24D3
    JMP      MOS_OSWRCH    ; &24D6

.runtime_data_padding_24d9
    ; zero padding/workspace tail between runtime code and resident data tables
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &24D9
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &24E1
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &24E9
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &24F1
    EQUB &00,&00,&00,&00,&00,&00,&00    ; &24F9

.screen_copy_control_streams
    ; byte stream consumed by screen/text copy helpers; not executable code
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2500
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2508
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2510
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2518
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2520
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2528
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2530
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2538
    EQUB &70,&34,&20,&4C,&44,&58,&73,&78    ; &2540
    EQUB &3A,&4C,&44    ; &2548

.player_start_second_graphic_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &0A,&0E,&06,&02    ; &254B

.player_start_first_graphic_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &08,&0C,&04,&00    ; &254F

.player_start_direction_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &02,&03,&01,&00    ; &2553

.object_legend_graphic_ids_1175
    ; legend_graphic_ids index0=SPINNER:$2A index1=CLONE:$2B index2=CYBERDROID:$2C index3=SAFE:$3D index4=KEY:$3F index5=POT_OF_GOLD:$32 index6=RING:$3E
    ; legend_graphic_screens index0=&4490 index1=&4C10 index2=&5390 index3=&5B10 index4=&6290 index5=&6A10 index6=&7190
    ; SPOOK uses immediate graphic ids $2E/$2F at $11E1/$11F5, outside this table
    EQUB &2A,&2B,&2C,&3D,&3F,&32,&3E    ; &2557

.object_legend_text_stream_offsets_1175
    ; legend text offset table paired with $2568/$2572 screen pointer bytes
    ; legend_text_row_0 screen=&3000 stream=&257C text=CYBERTRON
    ; legend_text_row_1 screen=&3C80 stream=&259D text=SPOOK
    ; legend_text_row_2 screen=&4400 stream=&25A4 text=SPINNER
    ; legend_text_row_3 screen=&4B80 stream=&25AD text=CLONE
    ; legend_text_row_4 screen=&5300 stream=&25B4 text=CYBERDROID
    ; legend_text_row_5 screen=&5A80 stream=&25C0 text=SAFE
    ; legend_text_row_6 screen=&6200 stream=&25D3 text=KEY
    ; legend_text_row_7 screen=&6980 stream=&25C6 text=POT_OF_GOLD
    ; legend_text_row_8 screen=&7100 stream=&25D8 text=RING
    ; extra_text_table_entry_9 screen=&7B00 stream=&2587 text=PRESS_SPACE_TO_START; $1175 exits after row 8
    EQUB &7C,&9D,&A4,&AD,&B4,&C0,&D3,&C6    ; &255E
    EQUB &D8,&87    ; &2566

.object_legend_screen_high_bytes_1175
    ; legend_screen_pointer_bytes pair with text offsets; report object_legend_text_table_1175 has full screen addresses
    ; legend_text_row_0 screen=&3000 stream=&257C text=CYBERTRON
    ; legend_text_row_1 screen=&3C80 stream=&259D text=SPOOK
    ; legend_text_row_2 screen=&4400 stream=&25A4 text=SPINNER
    ; legend_text_row_3 screen=&4B80 stream=&25AD text=CLONE
    ; legend_text_row_4 screen=&5300 stream=&25B4 text=CYBERDROID
    ; legend_text_row_5 screen=&5A80 stream=&25C0 text=SAFE
    ; legend_text_row_6 screen=&6200 stream=&25D3 text=KEY
    ; legend_text_row_7 screen=&6980 stream=&25C6 text=POT_OF_GOLD
    ; legend_text_row_8 screen=&7100 stream=&25D8 text=RING
    ; extra_text_table_entry_9 screen=&7B00 stream=&2587 text=PRESS_SPACE_TO_START; $1175 exits after row 8
    EQUB &30,&3C,&44,&4B,&53,&5A,&62,&69    ; &2568
    EQUB &71,&7B    ; &2570

.object_legend_screen_low_bytes_1175
    ; legend_screen_pointer_bytes pair with text offsets; report object_legend_text_table_1175 has full screen addresses
    ; legend_text_row_0 screen=&3000 stream=&257C text=CYBERTRON
    ; legend_text_row_1 screen=&3C80 stream=&259D text=SPOOK
    ; legend_text_row_2 screen=&4400 stream=&25A4 text=SPINNER
    ; legend_text_row_3 screen=&4B80 stream=&25AD text=CLONE
    ; legend_text_row_4 screen=&5300 stream=&25B4 text=CYBERDROID
    ; legend_text_row_5 screen=&5A80 stream=&25C0 text=SAFE
    ; legend_text_row_6 screen=&6200 stream=&25D3 text=KEY
    ; legend_text_row_7 screen=&6980 stream=&25C6 text=POT_OF_GOLD
    ; legend_text_row_8 screen=&7100 stream=&25D8 text=RING
    ; extra_text_table_entry_9 screen=&7B00 stream=&2587 text=PRESS_SPACE_TO_START; $1175 exits after row 8
    EQUB &00,&80,&00,&80,&00,&80,&00,&80    ; &2572
    EQUB &00,&00    ; &257A

.encoded_text_stream_cybertron
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&05 text="CYBERTRON"
    EQUB &05,&23,&39,&22,&25,&32,&34,&32    ; &257C
    EQUB &2F,&2E,&FF    ; &2584

.encoded_text_stream_press_space_to_start
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&00 text="PRESS SPACE TO START"
    EQUB &00,&30,&32,&25,&33,&33,&00,&33    ; &2587
    EQUB &30,&21,&23,&25,&00,&34,&2F,&00    ; &258F
    EQUB &33,&34,&21,&32,&34,&FF    ; &2597

.encoded_text_stream_spook
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SPOOK"
    EQUB &06,&33,&30,&2F,&2F,&2B,&FF    ; &259D

.encoded_text_stream_spinner
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SPINNER"
    EQUB &06,&33,&30,&29,&2E,&2E,&25,&32    ; &25A4
    EQUB &FF    ; &25AC

.encoded_text_stream_clone
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="CLONE"
    EQUB &06,&23,&2C,&2F,&2E,&25,&FF    ; &25AD

.encoded_text_stream_cyberdroid
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="CYBERDROID"
    EQUB &06,&23,&39,&22,&25,&32,&24,&32    ; &25B4
    EQUB &2F,&29,&24,&FF    ; &25BC

.encoded_text_stream_safe
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SAFE"
    EQUB &06,&33,&21,&26,&25,&FF    ; &25C0

.encoded_text_stream_pot_of_gold
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="POT OF GOLD"
    EQUB &06,&30,&2F,&34,&00,&2F,&26,&00    ; &25C6
    EQUB &27,&2F,&2C,&24,&FF    ; &25CE

.encoded_text_stream_key
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="KEY"
    EQUB &06,&2B,&25,&39,&FF    ; &25D3

.encoded_text_stream_ring
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="RING"
    EQUB &06,&32,&29,&2E,&27,&FF    ; &25D8

.encoded_text_stream_level
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="LEVEL"
    EQUB &06,&2C,&25,&36,&25,&2C,&FF    ; &25DE

.encoded_text_stream_end_of_game
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&04 text="END OF GAME"
    EQUB &04,&25,&2E,&24,&00,&2F,&26,&00    ; &25E5
    EQUB &27,&21,&2D,&25,&FF    ; &25ED

.encoded_text_stream_keys
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&08 text="KEYS"
    EQUB &08,&2B,&25,&39,&33,&FF    ; &25F2

.encoded_text_stream_status
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&07 text="STATUS"
    EQUB &07,&33,&34,&21,&34,&35,&33,&FF    ; &25F8

.control_help_text
    ; raw VDU/text stream for the controls screen
    ; printable_text_runs "UP" "DOWN" "LEFT" "RIGHT" "FIRE" "SOUND" "ON" "SOUND" "OFF" "PAUSE" "RESUME" "OR FIRE BUTTON"
    EQUB &11,&01,&1F,&03,&06,&41,&09,&09    ; &2600
    EQUB &55,&50,&1F,&03,&08,&5A,&09,&09    ; &2608
    EQUB &44,&4F,&57,&4E,&1F,&03,&0A,&3C    ; &2610
    EQUB &09,&09,&4C,&45,&46,&54,&1F,&03    ; &2618
    EQUB &0C,&3E,&09,&09,&52,&49,&47,&48    ; &2620
    EQUB &54,&1F,&03,&0E,&4D,&09,&09,&46    ; &2628
    EQUB &49,&52,&45,&1F,&03,&10,&53,&09    ; &2630
    EQUB &09,&53,&4F,&55,&4E,&44,&09,&4F    ; &2638
    EQUB &4E,&1F,&03,&12,&51,&09,&09,&53    ; &2640
    EQUB &4F,&55,&4E,&44,&09,&4F,&46,&46    ; &2648
    EQUB &1F,&03,&14,&50,&09,&09,&50,&41    ; &2650
    EQUB &55,&53,&45,&1F,&03,&16,&52,&09    ; &2658
    EQUB &09,&52,&45,&53,&55,&4D,&45,&1F    ; &2660
    EQUB &03,&1C,&4F,&52,&20,&46,&49,&52    ; &2668
    EQUB &45,&20,&42,&55,&54,&54,&4F,&4E    ; &2670

.scroll_or_animation_seed_table
    ; raw_printable_view ",!34" "3#/2%"
    EQUB &00,&00,&00,&2C,&21,&33,&34,&00    ; &2678
    EQUB &33,&23,&2F,&32,&25,&00    ; &2680

.current_score_title_digits
    ; title score/glyph buffer updated by $0D9C; bytes are renderer glyph ids, not plain text
    ; raw_printable_view "()'(" "3#/2%"
    EQUB &10,&10,&10,&10,&10,&00,&00,&00    ; &2686
    EQUB &28,&29,&27,&28,&00,&33,&23,&2F    ; &268E
    EQUB &32,&25,&00    ; &2696

.best_score_title_digits
    ; title best-score/glyph buffer updated by $0D80/$0D9C; bytes are renderer glyph ids, not plain text
    ; raw_printable_view "0ROGRAM" "0OWER" "#9"%242/."
    EQUB &10,&10,&10,&10,&10,&00,&00,&30    ; &2699
    EQUB &52,&4F,&47,&52,&41,&4D,&00,&30    ; &26A1
    EQUB &4F,&57,&45,&52,&00,&23,&39,&22    ; &26A9
    EQUB &25,&32,&34,&32,&2F,&2E,&00    ; &26B1

.zero_terminated_text_entering
    ; raw VDU/text stream terminated by $00
    ; printable_text_runs "ENTERING"
    EQUB &11,&04,&1F,&06,&06,&45,&4E,&54    ; &26B8
    EQUB &45,&52,&49,&4E,&47,&00    ; &26C0

.zero_terminated_text_find_the_following
    ; raw VDU/text stream terminated by $00
    ; printable_text_runs "FIND THE FOLLOWING"
    EQUB &11,&04,&1F,&01,&11,&46,&49,&4E    ; &26C6
    EQUB &44,&20,&54,&48,&45,&20,&46,&4F    ; &26CE
    EQUB &4C,&4C,&4F,&57,&49,&4E,&47,&00    ; &26D6

.hazard_spawn_y_offsets_2235
    ; signed_values +3, -2, +1, +1, -2, +3, -2, +3
    EQUB &03,&FE,&01,&01,&FE,&03,&FE,&03    ; &26DE

.hazard_spawn_x_offsets_2235
    ; signed_values +1, +1, +4, -2, +4, +4, -2, -2
    EQUB &01,&01,&04,&FE,&04,&04,&FE,&FE    ; &26E6

.unclassified_data_26ee
    ; raw_printable_view "IN"
    EQUB &49,&4E    ; &26EE

.base_palette_table_1f71
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&02,&03,&04,&05,&00,&07    ; &26F0
    EQUB &07,&00,&07,&03,&07,&01,&00,&00    ; &26F8

.level_intro_required_graphic_table_11fe
    ; required_target_graphics level_index_0=$3F:KEY level_index_1=$3E:RING level_index_2=$32:POT_OF_GOLD level_index_3=$3E:RING level_index_4=$32:POT_OF_GOLD level_index_5=$32:POT_OF_GOLD
    EQUB &3F,&3E,&32,&3E,&32,&32    ; &2700

.text_render_colour_value
    EQUB &01    ; &2706

.unclassified_palette_data_2707
    ; palette data table; values are logical colour/palette bytes
    EQUB &04,&05,&10,&11,&14,&15,&00    ; &2707

.palette_cycle_logical15_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&00,&01    ; &270E

.palette_cycle_logical14_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&00    ; &2711

.palette_cycle_logical13_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &01,&00,&00    ; &2714

.palette_data_2717
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&02,&03,&04,&05,&06,&07    ; &2717
    EQUB &07,&06,&05,&04,&03,&02,&01,&00    ; &271F

.early_init_vdu_bytes_13b4
    ; early init byte stream output by $13B4 through OSWRCH
    EQUB &00,&00,&00,&00,&00,&00,&20,&0A    ; &2727
    EQUB &00,&17,&02,&16,&00,&00,&00,&00    ; &272F

.target_collection_score_add_table_0fd6
    ; target collection score additions by target/status slot; slot0 and slot6 have special non-score paths
    ; score_add_slots slot0=0 slot1=10 slot2=50 slot3=100 slot4=50 slot5=100 slot6=0 slot7=0
    EQUB &00,&0A,&32,&64,&32,&64,&00,&00    ; &2737

.unclassified_level_render_data_273f
    ; raw_printable_view "Rbprint"
    EQUB &00,&52,&62,&70,&72,&69,&6E,&74    ; &273F
    EQUB &04,&08,&00,&04,&04,&00,&08,&08    ; &2747
    EQUB &00    ; &274F

.level_palette_logical8_by_level_units_mod8
    ; palette data table; values are logical colour/palette bytes
    ; logical colour 8 value selected by current level low three bits after $1F71 base palette setup
    EQUB &07,&07,&04,&05,&01,&02,&01,&04    ; &2750

.unclassified_level_render_data_2758
    EQUB &1C,&09,&09,&09,&09,&09,&09,&1C    ; &2758
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF    ; &2760
    EQUB &23,&FF,&FF,&FF,&FF,&FF,&FF,&23    ; &2768

.spook_release_timer_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=60 level1=80 level2=100 level3=100 level4=120 level5=120
    EQUB &3C,&50,&64,&64,&78,&78    ; &2770

.cyberdroid_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=0 level1=0 level2=2 level3=3 level4=4 level5=5
    EQUB &00,&00,&02,&03,&04,&05    ; &2776

.clone_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=0 level1=3 level2=3 level3=3 level4=4 level5=5
    EQUB &00,&03,&03,&03,&04,&05    ; &277C

.spinner_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=6 level1=3 level2=3 level3=2 level4=2 level5=2
    EQUB &06,&03,&03,&02,&02,&02    ; &2782

.player_shot_y_offsets_1c4d
    ; direction-indexed signed projectile/player-shot delta table
    ; direction table tuple: dir shot_dx shot_dy hazard_dx hazard_dy grid_dx grid_dy ptr_lo ptr_hi
    ; dir0 +1 +4 +1 +3 0 +1 +4 0
    ; dir1 +1 -1 +1 -2 0 -1 -4 -1
    ; dir2 +3 +2 +4 +1 +1 0 +8 0
    ; dir3 -1 +2 -2 +1 -1 0 -8 -1
    ; dir4 +3 +1 +4 -2 +1 -1 +4 0
    ; dir5 +4 +3 +4 +3 +1 +1 +12 0
    ; dir6 -1 +1 -2 -2 -1 -1 -12 -1
    ; dir7 -2 +3 -2 +3 -1 +1 -4 -1
    EQUB &04,&FF,&02,&02,&01,&03,&01,&03    ; &2788

.player_shot_x_offsets_1c4d
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +1, +1, +3, -1, +3, +4, -1, -2
    EQUB &01,&01,&03,&FF,&03,&04,&FF,&FE    ; &2790

.projectile_grid_y_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +1, -1, 0, 0, -1, +1, -1, +1
    EQUB &01,&FF,&00,&00,&FF,&01,&FF,&01    ; &2798

.projectile_grid_x_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values 0, 0, +1, -1, +1, +1, -1, -1
    EQUB &00,&00,&01,&FF,&01,&01,&FF,&FF    ; &27A0

.projectile_ptr_high_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values 0, -1, 0, -1, 0, 0, -1, -1
    EQUB &00,&FF,&00,&FF,&00,&00,&FF,&FF    ; &27A8

.projectile_ptr_low_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +4, -4, +8, -8, +4, +12, -12, -4
    EQUB &04,&FC,&08,&F8,&04,&0C,&F4,&FC    ; &27B0

.player_start_y_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; exit-indexed player start tuples: exit, x, y, first_gfx, second_gfx, dir, first_screen, second_screen
    ; start_exit_0 x=&07 y=&1E gfx=&08/&0A dir=&02 screen=&55B8/&5838
    ; start_exit_1 x=&45 y=&1E gfx=&0C/&0E dir=&03 screen=&57A8/&5A28
    ; start_exit_2 x=&27 y=&32 gfx=&04/&06 dir=&01 screen=&6FB8/&7238
    ; start_exit_3 x=&27 y=&0A gfx=&00/&02 dir=&00 screen=&3DB8/&4038
    EQUB &1E,&1E,&32,&0A    ; &27B8

.player_start_x_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &07,&45,&27,&27    ; &27BC

.player_start_second_screen_high_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &58,&5A,&72,&40    ; &27C0

.player_start_second_screen_low_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &38,&28,&38,&38    ; &27C4

.player_start_first_screen_high_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &55,&57,&6F,&3D    ; &27C8

.player_start_first_screen_low_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &B8,&A8,&B8,&B8    ; &27CC

.player_direction_graphic_delta_table_16e1
    ; signed_values +1, -1, -4, +4
    EQUB &01,&FF,&FC,&04    ; &27D0

.keyboard_input_delta_y_table_1609
    ; keyboard direction table used by the $1609 input scanner
    ; signed_values -1, +1, 0, 0
    EQUB &FF,&01,&00,&00    ; &27D4

.keyboard_input_delta_x_table_1609
    ; keyboard direction table used by the $1609 input scanner
    ; signed_values 0, 0, -1, +1
    EQUB &00,&00,&FF,&01    ; &27D8

.keyboard_inkey_codes_table_1609
    ; keyboard direction table used by the $1609 input scanner
    EQUB &BE,&9E,&99,&98    ; &27DC

.room_layout_bank0_runtime
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 b 5 a 6 9 5
    ; room_row_3 b 6 9 5 a 6
    ; room_row_4 3 9 6 a 5 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&5B,&6A    ; &27E0
    EQUB &59,&6B,&59,&6A,&93,&A6,&35,&C9    ; &27E8
    EQUB &95,&5C    ; &27F0

.room_layout_record_01
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 9 5 a 6 9 5
    ; room_row_3 a c 5 3 0 2
    ; room_row_4 3 0 a 5 0 3
    ; room_row_5 9 c 5 8 c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&59,&6A    ; &27F2
    EQUB &59,&CA,&35,&20,&03,&5A,&30,&C9    ; &27FA
    EQUB &85,&5C    ; &2802

.room_layout_record_02
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 9 5 0 0 9 5
    ; room_row_3 a 6 0 0 a 6
    ; room_row_4 3 9 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&59,&00    ; &2804
    EQUB &59,&6A,&00,&6A,&93,&CC,&35,&C9    ; &280C
    EQUB &CC,&5C    ; &2814

.room_layout_record_03
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 0 a c c 6 0
    ; room_row_1 a 5 2 2 9 6
    ; room_row_2 1 8 5 9 4 3
    ; room_row_3 2 8 6 a 4 3
    ; room_row_4 9 6 1 1 a 5
    ; room_row_5 0 9 4 8 5 0
    EQUB &A0,&CC,&06,&5A,&22,&69,&81,&95    ; &2816
    EQUB &34,&82,&A6,&34,&69,&11,&5A,&90    ; &281E
    EQUB &84,&05    ; &2826

.room_layout_record_04
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a e 4 a c 6
    ; room_row_1 3 9 4 3 2 3
    ; room_row_2 3 0 0 1 3 3
    ; room_row_3 3 8 c c 5 3
    ; room_row_4 b c 4 0 0 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &EA,&A4,&6C,&93,&34,&32,&03,&10    ; &2828
    EQUB &33,&83,&CC,&35,&CB,&04,&30,&C9    ; &2830
    EQUB &84,&5C    ; &2838

.room_layout_record_05
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 a c 6
    ; room_row_1 3 a c 5 2 3
    ; room_row_2 3 3 8 6 3 1
    ; room_row_3 3 3 8 5 3 2
    ; room_row_4 3 9 c 6 1 3
    ; room_row_5 9 c 4 9 c 5
    EQUB &CA,&A4,&6C,&A3,&5C,&32,&33,&68    ; &283A
    EQUB &13,&33,&58,&23,&93,&6C,&31,&C9    ; &2842
    EQUB &94,&5C    ; &284A

.room_layout_record_06
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 8 6 a 4 3
    ; room_row_2 1 0 9 5 2 1
    ; room_row_3 2 8 e c 5 2
    ; room_row_4 3 0 1 a 4 3
    ; room_row_5 9 c 4 9 c 5
    EQUB &CA,&CC,&6C,&83,&A6,&34,&01,&59    ; &284C
    EQUB &12,&82,&CE,&25,&03,&A1,&34,&C9    ; &2854
    EQUB &94,&5C    ; &285C

.room_layout_record_07
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 b c 5 9 e 7
    ; room_row_2 1 a c 6 3 3
    ; room_row_3 a 5 0 3 1 3
    ; room_row_4 b c c 5 0 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &CA,&A6,&6C,&CB,&95,&7E,&A1,&6C    ; &285E
    EQUB &33,&5A,&30,&31,&CB,&5C,&30,&C9    ; &2866
    EQUB &84,&5C    ; &286E

.room_layout_record_08
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 0 3 3 0 3
    ; room_row_2 3 a 5 9 c 5
    ; room_row_3 3 9 6 a c 6
    ; room_row_4 3 0 3 3 0 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&A6,&6C,&03,&33,&30,&A3,&95    ; &2870
    EQUB &5C,&93,&A6,&6C,&03,&33,&30,&C9    ; &2878
    EQUB &95,&5C    ; &2880

.room_layout_record_09
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a 4 8 6 3
    ; room_row_2 1 9 6 a 5 1
    ; room_row_3 2 a 5 9 6 2
    ; room_row_4 3 9 4 8 5 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &CA,&84,&6C,&A3,&84,&36,&91,&A6    ; &2882
    EQUB &15,&A2,&95,&26,&93,&84,&35,&C9    ; &288A
    EQUB &84,&5C    ; &2892

.room_layout_record_0a
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 b c 7 9 c 7
    ; room_row_2 1 0 3 a 6 3
    ; room_row_3 2 a 7 3 3 3
    ; room_row_4 3 9 5 9 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&CB,&97,&7C,&01,&A3    ; &2894
    EQUB &36,&A2,&37,&33,&93,&95,&35,&C9    ; &289C
    EQUB &CC,&5C    ; &28A4

.room_layout_record_0b
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 3 3 2 2 3 3
    ; room_row_3 3 3 3 3 3 3
    ; room_row_4 3 1 3 3 1 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&84,&6C,&A3,&CC,&36,&33,&22    ; &28A6
    EQUB &33,&33,&33,&33,&13,&33,&31,&C9    ; &28AE
    EQUB &95,&5C    ; &28B6

.room_layout_record_0c
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a 4 0 0 3
    ; room_row_2 3 3 8 e c 5
    ; room_row_3 3 9 6 3 0 2
    ; room_row_4 3 0 1 1 0 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&84,&6C,&A3,&04,&30,&33,&E8    ; &28B8
    EQUB &5C,&93,&36,&20,&03,&11,&30,&C9    ; &28C0
    EQUB &CC,&5C    ; &28C8

.room_layout_record_0d
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 a 5 9 6 3
    ; room_row_2 9 5 0 0 3 3
    ; room_row_3 a 6 0 0 3 3
    ; room_row_4 3 9 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&A3,&95,&36,&59,&00    ; &28CA
    EQUB &33,&6A,&00,&33,&93,&CC,&35,&C9    ; &28D2
    EQUB &CC,&5C    ; &28DA

.room_layout_record_0e
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c e 6
    ; room_row_1 3 a c 6 3 3
    ; room_row_2 3 9 4 3 3 1
    ; room_row_3 b c c 5 3 2
    ; room_row_4 3 8 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&CC,&6E,&A3,&6C,&33,&93,&34    ; &28DC
    EQUB &13,&CB,&5C,&23,&83,&CC,&35,&C9    ; &28E4
    EQUB &CC,&5C    ; &28EC

.room_layout_record_0f
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 0 3 3 0 3
    ; room_row_2 9 c 5 3 0 3
    ; room_row_3 a c c 5 0 3
    ; room_row_4 3 0 0 0 0 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&03,&33,&30,&C9,&35    ; &28EE
    EQUB &30,&CA,&5C,&30,&03,&00,&30,&C9    ; &28F6
    EQUB &CC,&5C    ; &28FE

.graphic_record_00
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F/$254B $1735 start index 3
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 3000 / 1010 / 1010 / 0000 / 0210 / 0210 / 2200
    ; graphic_strip_1_pixels 3300 / 1111 / 1111 / 1111 / 1111 / 0011 / 0011 / 1100
    ; graphic_strip_2_pixels 0000 / 0300 / 0101 / 0101 / 0000 / 2001 / 2001 / 2200
    EQUB &00,&11,&05,&05,&00,&24,&24,&30    ; &2900
    EQUB &33,&0F,&0F,&0F,&0F,&0C,&0C,&03    ; &2908
    EQUB &00,&22,&0A,&0A,&00,&18,&18,&30    ; &2910

.graphic_record_01
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2000 / 0010 / 0011 / 0011 / 0000 / 0000 / 0000 / 2211
    ; graphic_strip_1_pixels 1100 / 1100 / 1100 / 1100 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &10,&04,&0C,&0C,&00,&00,&00,&3C    ; &2918
    EQUB &03,&03,&03,&03,&00,&00,&00,&00    ; &2920
    EQUB &20,&08,&08,&08,&08,&08,&0C,&0C    ; &2928

.graphic_record_02
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 3 and stationary dir0
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2000 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 1100 / 1100 / 1100 / 1100 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &10,&04,&04,&04,&04,&04,&0C,&0C    ; &2930
    EQUB &03,&03,&03,&03,&00,&00,&00,&00    ; &2938
    EQUB &20,&08,&08,&08,&08,&08,&0C,&0C    ; &2940

.graphic_record_03
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2000 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 1100 / 1100 / 1100 / 1100 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0200 / 0001 / 0011 / 0011 / 0000 / 0000 / 0000 / 2211
    EQUB &10,&04,&04,&04,&04,&04,&0C,&0C    ; &2948
    EQUB &03,&03,&03,&03,&00,&00,&00,&00    ; &2950
    EQUB &20,&08,&0C,&0C,&00,&00,&00,&3C    ; &2958

.graphic_record_04
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 2
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 3000 / 3000 / 1010 / 0000 / 0210 / 0210 / 0210
    ; graphic_strip_1_pixels 3300 / 3300 / 3300 / 1111 / 1111 / 0011 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0300 / 0300 / 0101 / 0000 / 2001 / 2001 / 2001
    EQUB &00,&11,&11,&05,&00,&24,&24,&24    ; &2960
    EQUB &33,&33,&33,&0F,&0F,&0C,&0C,&0C    ; &2968
    EQUB &00,&22,&22,&0A,&00,&18,&18,&18    ; &2970

.graphic_record_05
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0010 / 0010 / 0011 / 0011 / 0000 / 0000 / 0000 / 2211
    ; graphic_strip_1_pixels 0011 / 0011 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0001 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &04,&04,&0C,&0C,&00,&00,&00,&3C    ; &2978
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00    ; &2980
    EQUB &08,&08,&08,&08,&08,&08,&0C,&0C    ; &2988

.graphic_record_06
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 2 and stationary dir1
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0010 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 0011 / 0011 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0001 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &04,&04,&04,&04,&04,&04,&0C,&0C    ; &2990
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00    ; &2998
    EQUB &08,&08,&08,&08,&08,&08,&0C,&0C    ; &29A0

.graphic_record_07
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0010 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 0011 / 0011 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0001 / 0001 / 0011 / 0011 / 0000 / 0000 / 0000 / 2211
    EQUB &04,&04,&04,&04,&04,&04,&0C,&0C    ; &29A8
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00    ; &29B0
    EQUB &08,&08,&0C,&0C,&00,&00,&00,&3C    ; &29B8

.graphic_record_08
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 0
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3000 / 1310 / 1310 / 1111 / 1010 / 2000 / 0210 / 0210
    ; graphic_strip_1_pixels 0300 / 1111 / 1111 / 1111 / 0101 / 0001 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0000 / 2211 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &11,&27,&27,&0F,&05,&10,&24,&24    ; &29C0
    EQUB &22,&0F,&0F,&0F,&0A,&08,&0C,&0C    ; &29C8
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00    ; &29D0

.graphic_record_09
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 2200 / 0010 / 0010 / 0010 / 0011 / 0011 / 0000
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0011 / 0011 / 0010 / 0010 / 0010
    ; graphic_strip_2_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0000 / 0001 / 0001
    EQUB &30,&30,&04,&04,&04,&0C,&0C,&00    ; &29D8
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&04    ; &29E0
    EQUB &03,&03,&00,&00,&00,&00,&08,&08    ; &29E8

.graphic_record_0a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 0 and stationary dir2
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 2200 / 0010 / 0010 / 0010 / 0010 / 0010 / 0010
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    ; graphic_strip_2_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0000 / 0000 / 2211
    EQUB &30,&30,&04,&04,&04,&04,&04,&04    ; &29F0
    EQUB &21,&21,&08,&08,&08,&08,&0C,&0C    ; &29F8
    EQUB &03,&03,&00,&00,&00,&00,&00,&3C    ; &2A00

.graphic_record_0b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 2200 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0011 / 0011 / 0010 / 0010 / 0000
    ; graphic_strip_2_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0001 / 0001 / 0000
    EQUB &30,&30,&04,&04,&04,&04,&0C,&0C    ; &2A08
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&00    ; &2A10
    EQUB &03,&03,&00,&00,&00,&08,&08,&00    ; &2A18

.graphic_record_0c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 1
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 2211 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 3000 / 1111 / 1111 / 1111 / 1010 / 0010 / 0011 / 0011
    ; graphic_strip_2_pixels 0300 / 3101 / 3101 / 1111 / 0101 / 0200 / 2001 / 2001
    EQUB &00,&3C,&00,&00,&00,&00,&00,&00    ; &2A20
    EQUB &11,&0F,&0F,&0F,&05,&04,&0C,&0C    ; &2A28
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&18    ; &2A30

.graphic_record_0d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0000 / 0010 / 0010
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0011 / 0011 / 0001 / 0001 / 0001
    ; graphic_strip_2_pixels 2200 / 2200 / 0001 / 0001 / 0001 / 0011 / 0011 / 0000
    EQUB &03,&03,&00,&00,&00,&00,&04,&04    ; &2A38
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&08    ; &2A40
    EQUB &30,&30,&08,&08,&08,&0C,&0C,&00    ; &2A48

.graphic_record_0e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 1 and stationary dir3
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0000 / 0000 / 2211
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_2_pixels 2200 / 2200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0001
    EQUB &03,&03,&00,&00,&00,&00,&00,&3C    ; &2A50
    EQUB &12,&12,&04,&04,&04,&04,&0C,&0C    ; &2A58
    EQUB &30,&30,&08,&08,&08,&08,&08,&08    ; &2A60

.graphic_record_0f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1100 / 1100 / 0000 / 0000 / 0000 / 0010 / 0010 / 0000
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0011 / 0011 / 0001 / 0001 / 0000
    ; graphic_strip_2_pixels 2200 / 2200 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &03,&03,&00,&00,&00,&04,&04,&00    ; &2A68
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&00    ; &2A70
    EQUB &30,&30,&08,&08,&08,&08,&0C,&0C    ; &2A78

.graphic_record_10
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3000 / 1310 / 1310 / 1111 / 1010 / 2000 / 0210 / 2200
    ; graphic_strip_1_pixels 0300 / 1111 / 1111 / 1111 / 0101 / 0001 / 1200 / 1200
    ; graphic_strip_2_pixels 0000 / 0000 / 2211 / 0000 / 1000 / 1100 / 0100 / 0000
    EQUB &11,&27,&27,&0F,&05,&10,&24,&30    ; &2A80
    EQUB &22,&0F,&0F,&0F,&0A,&08,&21,&21    ; &2A88
    EQUB &00,&00,&3C,&00,&01,&03,&02,&00    ; &2A90

.graphic_record_11
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011 / 0000
    ; graphic_strip_1_pixels 0011 / 0011 / 0001 / 0011 / 0011 / 0010 / 0010 / 0010
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0001 / 0001
    EQUB &30,&04,&04,&04,&04,&0C,&0C,&00    ; &2A98
    EQUB &0C,&0C,&08,&0C,&0C,&04,&04,&04    ; &2AA0
    EQUB &00,&00,&00,&00,&00,&00,&08,&08    ; &2AA8

.graphic_record_12
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0010 / 0010 / 0010
    ; graphic_strip_1_pixels 0011 / 0011 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 2211
    EQUB &30,&04,&04,&04,&04,&04,&04,&04    ; &2AB0
    EQUB &0C,&0C,&08,&08,&08,&08,&0C,&0C    ; &2AB8
    EQUB &00,&00,&00,&00,&00,&00,&00,&3C    ; &2AC0

.graphic_record_13
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 0011 / 0011 / 0001 / 0011 / 0011 / 0010 / 0010 / 0000
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0001 / 0001 / 0000
    EQUB &30,&04,&04,&04,&04,&04,&0C,&0C    ; &2AC8
    EQUB &0C,&0C,&08,&0C,&0C,&04,&04,&00    ; &2AD0
    EQUB &00,&00,&00,&00,&00,&08,&08,&00    ; &2AD8

.graphic_record_14
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3000 / 1310 / 1310 / 1111 / 1010 / 2000 / 0210 / 2200
    ; graphic_strip_1_pixels 0300 / 1111 / 1111 / 1111 / 0101 / 0001 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0000 / 2211 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &11,&27,&27,&0F,&05,&10,&24,&30    ; &2AE0
    EQUB &22,&0F,&0F,&0F,&0A,&08,&0C,&0C    ; &2AE8
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00    ; &2AF0

.graphic_record_15
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011 / 0000
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0011 / 0011 / 0010 / 0010 / 0010
    ; graphic_strip_2_pixels 0000 / 0100 / 1100 / 1000 / 0000 / 0000 / 0001 / 0001
    EQUB &30,&04,&04,&04,&04,&0C,&0C,&00    ; &2AF8
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&04    ; &2B00
    EQUB &00,&02,&03,&01,&00,&00,&08,&08    ; &2B08

.graphic_record_16
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0010 / 0010 / 0010
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0100 / 1100 / 1000 / 0000 / 0000 / 0000 / 2211
    EQUB &30,&04,&04,&04,&04,&04,&04,&04    ; &2B10
    EQUB &21,&21,&08,&08,&08,&08,&0C,&0C    ; &2B18
    EQUB &00,&02,&03,&01,&00,&00,&00,&3C    ; &2B20

.graphic_record_17
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 2200 / 0010 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_1_pixels 1200 / 1200 / 0001 / 0011 / 0011 / 0010 / 0010 / 0000
    ; graphic_strip_2_pixels 0000 / 0100 / 1100 / 1000 / 0000 / 0001 / 0001 / 0000
    EQUB &30,&04,&04,&04,&04,&04,&0C,&0C    ; &2B28
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&00    ; &2B30
    EQUB &00,&02,&03,&01,&00,&08,&08,&00    ; &2B38

.graphic_record_18
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 2211 / 0000 / 0100 / 1100 / 1000 / 0000
    ; graphic_strip_1_pixels 3000 / 1111 / 1111 / 1111 / 1010 / 0010 / 2100 / 2100
    ; graphic_strip_2_pixels 0300 / 3101 / 3101 / 1111 / 0101 / 0200 / 2001 / 2200
    EQUB &00,&00,&3C,&00,&02,&03,&01,&00    ; &2B40
    EQUB &11,&0F,&0F,&0F,&05,&04,&12,&12    ; &2B48
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&30    ; &2B50

.graphic_record_19
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0010 / 0010
    ; graphic_strip_1_pixels 0011 / 0011 / 0010 / 0011 / 0011 / 0001 / 0001 / 0001
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011 / 0000
    EQUB &00,&00,&00,&00,&00,&00,&04,&04    ; &2B58
    EQUB &0C,&0C,&04,&0C,&0C,&08,&08,&08    ; &2B60
    EQUB &30,&08,&08,&08,&08,&0C,&0C,&00    ; &2B68

.graphic_record_1a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 2211
    ; graphic_strip_1_pixels 0011 / 0011 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0001 / 0001
    EQUB &00,&00,&00,&00,&00,&00,&00,&3C    ; &2B70
    EQUB &0C,&0C,&04,&04,&04,&04,&0C,&0C    ; &2B78
    EQUB &30,&08,&08,&08,&08,&08,&08,&08    ; &2B80

.graphic_record_1b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0010 / 0010 / 0000
    ; graphic_strip_1_pixels 0011 / 0011 / 0010 / 0011 / 0011 / 0001 / 0001 / 0000
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &00,&00,&00,&00,&00,&04,&04,&00    ; &2B88
    EQUB &0C,&0C,&04,&0C,&0C,&08,&08,&00    ; &2B90
    EQUB &30,&08,&08,&08,&08,&08,&0C,&0C    ; &2B98

.graphic_record_1c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 2211 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 3000 / 1111 / 1111 / 1111 / 1010 / 0010 / 0011 / 0011
    ; graphic_strip_2_pixels 0300 / 3101 / 3101 / 1111 / 0101 / 0200 / 2001 / 2200
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00    ; &2BA0
    EQUB &11,&0F,&0F,&0F,&05,&04,&0C,&0C    ; &2BA8
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&30    ; &2BB0

.graphic_record_1d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1000 / 1100 / 0100 / 0000 / 0000 / 0010 / 0010
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0011 / 0011 / 0001 / 0001 / 0001
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011 / 0000
    EQUB &00,&01,&03,&02,&00,&00,&04,&04    ; &2BB8
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&08    ; &2BC0
    EQUB &30,&08,&08,&08,&08,&0C,&0C,&00    ; &2BC8

.graphic_record_1e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1000 / 1100 / 0100 / 0000 / 0000 / 0000 / 2211
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0010 / 0010 / 0010 / 0011 / 0011
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0001 / 0001
    EQUB &00,&01,&03,&02,&00,&00,&00,&3C    ; &2BD0
    EQUB &12,&12,&04,&04,&04,&04,&0C,&0C    ; &2BD8
    EQUB &30,&08,&08,&08,&08,&08,&08,&08    ; &2BE0

.graphic_record_1f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role no_current_assignment_site_keep_numeric
    ; graphic_usage status=raw_record_only role=no_current_assignment_site_keep_numeric sources=--
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1000 / 1100 / 0100 / 0000 / 0010 / 0010 / 0000
    ; graphic_strip_1_pixels 2100 / 2100 / 0010 / 0011 / 0011 / 0001 / 0001 / 0000
    ; graphic_strip_2_pixels 2200 / 0001 / 0001 / 0001 / 0001 / 0001 / 0011 / 0011
    EQUB &00,&01,&03,&02,&00,&04,&04,&00    ; &2BE8
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&00    ; &2BF0
    EQUB &30,&08,&08,&08,&08,&08,&0C,&0C    ; &2BF8

.graphic_record_20
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits; $1CAB fixed status blank/space and $2319 trailing glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 0000 / 3010 / 3010 / 3010 / 3311
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&2A,&2A,&2A,&2A,&2A,&2A,&3F    ; &2C00
    EQUB &3F,&00,&00,&00,&15,&15,&15,&3F    ; &2C08
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A    ; &2C10

.graphic_record_21
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 3010 / 3010 / 3010 / 3010 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2C18
    EQUB &15,&15,&15,&15,&3F,&3F,&3F,&3F    ; &2C20
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2C28

.graphic_record_22
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0000 / 0000 / 3311 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0000 / 0000 / 0301 / 0301
    EQUB &3F,&00,&00,&3F,&3F,&3F,&3F,&3F    ; &2C30
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F    ; &2C38
    EQUB &2A,&2A,&2A,&2A,&00,&00,&2A,&2A    ; &2C40

.graphic_record_23
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 3010 / 3010 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F    ; &2C48
    EQUB &3F,&00,&00,&3F,&15,&15,&3F,&3F    ; &2C50
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A    ; &2C58

.graphic_record_24
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0301 / 0301 / 0301 / 0301 / 3311 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 0000 / 0000 / 3311 / 3311 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0301 / 0000 / 0000 / 0000
    EQUB &2A,&2A,&2A,&2A,&3F,&00,&00,&00    ; &2C60
    EQUB &00,&00,&3F,&3F,&3F,&3F,&3F,&3F    ; &2C68
    EQUB &00,&00,&00,&00,&2A,&00,&00,&00    ; &2C70

.graphic_record_25
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits; $1CAB fixed status-panel glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 3010 / 3010 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0000 / 0000 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&2A,&2A,&3F,&00,&00,&3F,&3F    ; &2C78
    EQUB &3F,&00,&00,&3F,&15,&15,&3F,&3F    ; &2C80
    EQUB &2A,&00,&00,&2A,&2A,&2A,&2A,&2A    ; &2C88

.graphic_record_26
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 3311 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0000 / 0000 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&2A,&2A,&3F,&3F,&3F,&3F,&3F    ; &2C90
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F    ; &2C98
    EQUB &2A,&00,&00,&2A,&2A,&2A,&2A,&2A    ; &2CA0

.graphic_record_27
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 0000 / 3010 / 3010 / 3010 / 3010
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&00,&00,&00,&00,&00,&00,&00    ; &2CA8
    EQUB &3F,&00,&00,&00,&15,&15,&15,&15    ; &2CB0
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A    ; &2CB8

.graphic_record_28
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3010 / 3010 / 3010 / 3311 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &15,&15,&15,&3F,&3F,&3F,&3F,&3F    ; &2CC0
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F    ; &2CC8
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A    ; &2CD0

.graphic_record_29
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 3311 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 3010 / 3010 / 3010 / 3010
    ; graphic_strip_2_pixels 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&2A,&2A,&3F,&00,&00,&00,&00    ; &2CD8
    EQUB &3F,&00,&00,&3F,&15,&15,&15,&15    ; &2CE0
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A    ; &2CE8

.graphic_record_2a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPINNER
    ; graphic_usage status=assigned role=legend_and_enemy_SPINNER sources=$2557 legend table and $1E3A spinner placement
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3322 / 0303 / 3333 / 0203 / 2233 / 0302 / 3322 / 3333
    ; graphic_strip_1_pixels 2233 / 0203 / 0011 / 0011 / 0011 / 0011 / 2030 / 2233
    ; graphic_strip_2_pixels 3333 / 3322 / 3020 / 2233 / 2030 / 3333 / 3030 / 3322
    EQUB &F3,&AA,&FF,&A8,&FC,&A2,&F3,&FF    ; &2CF0
    EQUB &FC,&A8,&0C,&0C,&0C,&0C,&54,&FC    ; &2CF8
    EQUB &FF,&F3,&51,&FC,&54,&FF,&55,&F3    ; &2D00

.graphic_record_2b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role CLONE
    ; graphic_usage status=assigned role=legend_and_enemy_CLONE sources=$2557 legend table and $1E3A clone placement
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 2000 / 2200 / 2332 / 2332 / 2200 / 2000 / 0000
    ; graphic_strip_1_pixels 2200 / 2200 / 2200 / 3323 / 3323 / 2200 / 2200 / 2200
    ; graphic_strip_2_pixels 0000 / 0200 / 2200 / 3233 / 3233 / 2200 / 0200 / 0000
    EQUB &00,&10,&30,&F6,&F6,&30,&10,&00    ; &2D08
    EQUB &30,&30,&30,&FB,&FB,&30,&30,&30    ; &2D10
    EQUB &00,&20,&30,&FD,&FD,&30,&20,&00    ; &2D18

.graphic_record_2c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role CYBERDROID
    ; graphic_usage status=assigned role=legend_and_enemy_CYBERDROID sources=$2557 legend table and $1E3A cyberdroid placement
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1010 / 2302 / 2203 / 0303 / 3000 / 2300 / 3000
    ; graphic_strip_1_pixels 0033 / 1111 / 1111 / 2200 / 1111 / 3300 / 2200 / 3300
    ; graphic_strip_2_pixels 0000 / 0101 / 3220 / 2230 / 3030 / 0300 / 3200 / 0300
    EQUB &00,&05,&B2,&B8,&AA,&11,&32,&11    ; &2D20
    EQUB &CC,&0F,&0F,&30,&0F,&33,&30,&33    ; &2D28
    EQUB &00,&0A,&71,&74,&55,&22,&31,&22    ; &2D30

.graphic_record_2d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role bonus_target_status_and_room_fill_probe
    ; graphic_usage status=assigned role=bonus_target_status_and_room_fill_probe sources=$2F36 target/status slot 6 and $1EC8/$1F19 room fill probes
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1133 / 1030 / 1030 / 0103 / 3123 / 0103 / 2133 / 1030
    ; graphic_strip_1_pixels 0000 / 0000 / 0303 / 2030 / 0303 / 2030 / 3332 / 1133
    ; graphic_strip_2_pixels 1133 / 0103 / 0103 / 1030 / 1030 / 1332 / 1030 / 0103
    EQUB &CF,&45,&45,&8A,&DB,&8A,&DE,&45    ; &2D38
    EQUB &00,&00,&AA,&54,&AA,&54,&F7,&CF    ; &2D40
    EQUB &CF,&8A,&8A,&45,&45,&E7,&45,&8A    ; &2D48

.graphic_record_2e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPOOK_first_cell
    ; graphic_usage status=assigned role=legend_and_spook_pair sources=$1175 SPOOK immediate and $1E3A spook first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 2020 / 2020 / 2020 / 2222 / 2222 / 0202
    ; graphic_strip_1_pixels 2020 / 2222 / 2222 / 2020 / 2020 / 2222 / 2222 / 2222
    ; graphic_strip_2_pixels 0000 / 0202 / 2222 / 2020 / 2020 / 2222 / 2222 / 2222
    EQUB &00,&00,&50,&50,&50,&F0,&F0,&A0    ; &2D50
    EQUB &50,&F0,&F0,&50,&50,&F0,&F0,&F0    ; &2D58
    EQUB &00,&A0,&F0,&50,&50,&F0,&F0,&F0    ; &2D60

.graphic_record_2f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPOOK_second_cell
    ; graphic_usage status=assigned role=legend_and_spook_pair sources=$1175 SPOOK immediate and $1E3A spook second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0202 / 0000 / 0000 / 2020 / 2020 / 2020 / 2222 / 0202
    ; graphic_strip_1_pixels 2222 / 2222 / 2222 / 0202 / 0202 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 2020 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &A0,&00,&00,&50,&50,&50,&F0,&A0    ; &2D68
    EQUB &F0,&F0,&F0,&A0,&A0,&00,&00,&00    ; &2D70
    EQUB &50,&00,&00,&00,&00,&00,&00,&00    ; &2D78

.graphic_record_30
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_collision_flash
    ; graphic_usage status=assigned role=player_collision_flash sources=$19F3 player collision flash first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 3010 / 3010 / 3010 / 0000 / 3311 / 0000 / 0301
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 3311 / 0000 / 3311
    ; graphic_strip_2_pixels 0000 / 0301 / 0301 / 0301 / 0000 / 3311 / 0000 / 3010
    EQUB &00,&15,&15,&15,&00,&3F,&00,&2A    ; &2D80
    EQUB &3F,&00,&00,&3F,&00,&3F,&00,&3F    ; &2D88
    EQUB &00,&2A,&2A,&2A,&00,&3F,&00,&15    ; &2D90

.graphic_record_31
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_collision_flash
    ; graphic_usage status=assigned role=player_collision_flash sources=$19F3 player collision flash second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0301 / 0000 / 0000 / 3010 / 0000 / 3010 / 3010 / 3311
    ; graphic_strip_1_pixels 0000 / 3311 / 0000 / 3311 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 3010 / 0000 / 0000 / 0301 / 0000 / 0301 / 0301 / 3311
    EQUB &2A,&00,&00,&15,&00,&15,&15,&3F    ; &2D98
    EQUB &00,&3F,&00,&3F,&00,&00,&00,&00    ; &2DA0
    EQUB &15,&00,&00,&2A,&00,&2A,&2A,&3F    ; &2DA8

.graphic_record_32
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role POT_OF_GOLD
    ; graphic_usage status=assigned role=legend_and_required_target_POT_OF_GOLD sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1030 / 0000 / 1030 / 1133 / 1133 / 1030 / 0000
    ; graphic_strip_1_pixels 0000 / 1133 / 1133 / 1133 / 1133 / 1133 / 1133 / 1133
    ; graphic_strip_2_pixels 0000 / 0103 / 0000 / 0103 / 1133 / 1133 / 0103 / 0000
    EQUB &00,&45,&00,&45,&CF,&CF,&45,&00    ; &2DB0
    EQUB &00,&CF,&CF,&CF,&CF,&CF,&CF,&CF    ; &2DB8
    EQUB &00,&8A,&00,&8A,&CF,&CF,&8A,&00    ; &2DC0

.graphic_record_33
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_life_loss_reset
    ; graphic_usage status=assigned role=player_life_loss_reset sources=$1A59 player life-loss reset first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 1010 / 1310 / 1310 / 3300
    ; graphic_strip_1_pixels 0000 / 0000 / 0000 / 0000 / 0101 / 0101 / 2101 / 2101
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 1000 / 1001 / 2200 / 2200
    EQUB &00,&00,&00,&00,&05,&27,&27,&33    ; &2DC8
    EQUB &00,&00,&00,&00,&0A,&0A,&1A,&1A    ; &2DD0
    EQUB &00,&00,&00,&00,&01,&09,&30,&30    ; &2DD8

.graphic_record_34
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_life_loss_reset
    ; graphic_usage status=assigned role=player_life_loss_reset sources=$1A59 player life-loss reset second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0001 / 0011 / 0011
    ; graphic_strip_1_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0011 / 0011
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0010 / 0010 / 0011 / 0011
    EQUB &00,&00,&00,&00,&00,&08,&0C,&0C    ; &2DE0
    EQUB &00,&00,&00,&00,&00,&00,&0C,&0C    ; &2DE8
    EQUB &00,&00,&00,&00,&04,&04,&0C,&0C    ; &2DF0

.graphic_record_35
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 0301 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 3311
    ; graphic_strip_2_pixels 0301 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0301
    EQUB &3F,&2A,&2A,&2A,&3F,&3F,&3F,&3F    ; &2DF8
    EQUB &3F,&00,&00,&00,&00,&00,&00,&3F    ; &2E00
    EQUB &2A,&00,&00,&00,&00,&00,&00,&2A    ; &2E08

.graphic_record_36
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 0301 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 3010 / 3010 / 3010 / 3311 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0301 / 0301 / 0301 / 0301 / 0301
    EQUB &3F,&2A,&2A,&2A,&3F,&3F,&3F,&3F    ; &2E10
    EQUB &3F,&15,&15,&15,&3F,&00,&00,&00    ; &2E18
    EQUB &00,&00,&00,&2A,&2A,&2A,&2A,&2A    ; &2E20

.graphic_record_37
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3311 / 0301 / 0301 / 3311 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 0000 / 0000 / 3311 / 0000 / 0000 / 3311 / 3311
    ; graphic_strip_2_pixels 0301 / 0000 / 0000 / 0301 / 0000 / 0000 / 0301 / 0301
    EQUB &3F,&2A,&2A,&3F,&3F,&3F,&3F,&3F    ; &2E28
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F    ; &2E30
    EQUB &2A,&00,&00,&2A,&00,&00,&2A,&2A    ; &2E38

.graphic_record_38
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3010 / 3010 / 3010 / 3010 / 3311 / 3311 / 3311 / 3311
    ; graphic_strip_1_pixels 3311 / 3010 / 3010 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_2_pixels 3311 / 3010 / 3010 / 3010 / 3311 / 3311 / 3311 / 3311
    EQUB &15,&15,&15,&15,&3F,&3F,&3F,&3F    ; &2E40
    EQUB &3F,&15,&15,&00,&00,&00,&00,&00    ; &2E48
    EQUB &3F,&15,&15,&15,&3F,&3F,&3F,&3F    ; &2E50

.graphic_record_39
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role lives_status_marker
    ; graphic_usage status=assigned role=lives_status_marker sources=$2345 lives/status marker
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 3000 / 1010 / 2000 / 2000 / 0010 / 0010 / 0010 / 0010
    ; graphic_strip_1_pixels 0101 / 0101 / 0000 / 1200 / 0000 / 0000 / 0000 / 0001
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &11,&05,&10,&10,&04,&04,&04,&04    ; &2E58
    EQUB &0A,&0A,&00,&21,&00,&00,&00,&08    ; &2E60
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2E68

.graphic_record_3a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 2
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 1010 / 3010 / 1301 / 3010 / 1010 / 3010 / 0000
    ; graphic_strip_1_pixels 0000 / 1010 / 0100 / 1110 / 1101 / 1010 / 0000 / 0000
    ; graphic_strip_2_pixels 0000 / 0301 / 0000 / 0301 / 0000 / 0301 / 0000 / 0000
    EQUB &00,&05,&15,&2B,&15,&05,&15,&00    ; &2E70
    EQUB &00,&05,&02,&07,&0B,&05,&00,&00    ; &2E78
    EQUB &00,&2A,&00,&2A,&00,&2A,&00,&00    ; &2E80

.graphic_record_3b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 3
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1311 / 1010 / 1100 / 1311 / 1010 / 1000 / 1010 / 0101
    ; graphic_strip_1_pixels 1010 / 0100 / 1100 / 1100 / 1100 / 1111 / 1010 / 0301
    ; graphic_strip_2_pixels 3111 / 0301 / 0000 / 3111 / 0101 / 0100 / 0000 / 3111
    EQUB &2F,&05,&03,&2F,&05,&01,&05,&0A    ; &2E88
    EQUB &05,&02,&03,&03,&03,&0F,&05,&2A    ; &2E90
    EQUB &1F,&2A,&00,&1F,&0A,&02,&00,&1F    ; &2E98

.graphic_record_3c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 4
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 3010 / 3010 / 0301 / 0000 / 0301 / 3010 / 0000
    ; graphic_strip_1_pixels 3010 / 0000 / 0000 / 0000 / 0000 / 0000 / 3010 / 0301
    ; graphic_strip_2_pixels 0000 / 0301 / 3010 / 0000 / 0301 / 3010 / 0301 / 0000
    EQUB &00,&15,&15,&2A,&00,&2A,&15,&00    ; &2EA0
    EQUB &15,&00,&00,&00,&00,&00,&15,&2A    ; &2EA8
    EQUB &00,&2A,&15,&00,&2A,&15,&2A,&00    ; &2EB0

.graphic_record_3d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SAFE
    ; graphic_usage status=assigned role=legend_and_target_SAFE sources=$2557 legend table and $2F36 target/status slot 0
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1133 / 0103 / 0103 / 0103 / 0103 / 0103 / 0103 / 1133
    ; graphic_strip_1_pixels 1133 / 0000 / 0000 / 1030 / 0000 / 0000 / 0000 / 1133
    ; graphic_strip_2_pixels 1133 / 1030 / 1030 / 1030 / 1030 / 1030 / 1030 / 1133
    EQUB &CF,&8A,&8A,&8A,&8A,&8A,&8A,&CF    ; &2EB8
    EQUB &CF,&00,&00,&45,&00,&00,&00,&CF    ; &2EC0
    EQUB &CF,&45,&45,&45,&45,&45,&45,&CF    ; &2EC8

.graphic_record_3e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role RING
    ; graphic_usage status=assigned role=legend_and_required_target_RING sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 0000 / 0000 / 1030 / 0103 / 0103 / 0103 / 1030 / 0000
    ; graphic_strip_1_pixels 1133 / 1133 / 0000 / 0000 / 0000 / 0000 / 1133 / 0000
    ; graphic_strip_2_pixels 0000 / 0000 / 0103 / 1030 / 1030 / 1030 / 0103 / 0000
    EQUB &00,&00,&45,&8A,&8A,&8A,&45,&00    ; &2ED0
    EQUB &CF,&CF,&00,&00,&00,&00,&CF,&00    ; &2ED8
    EQUB &00,&00,&8A,&45,&45,&45,&8A,&00    ; &2EE0

.graphic_record_3f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role KEY
    ; graphic_usage status=assigned role=legend_and_required_target_KEY sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 5 renderer
    ; graphic_strip_0_pixels 1030 / 1030 / 1030 / 0000 / 0000 / 0000 / 0000 / 0000
    ; graphic_strip_1_pixels 1133 / 1030 / 1133 / 0103 / 0103 / 1133 / 0103 / 1133
    ; graphic_strip_2_pixels 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000 / 0000
    EQUB &45,&45,&45,&00,&00,&00,&00,&00    ; &2EE8
    EQUB &CF,&45,&CF,&8A,&8A,&CF,&8A,&CF    ; &2EF0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00    ; &2EF8

.object_graphic_id_by_index
    ; render-object graphic ids for object indices $00-$0D; indices $0E+ are split below by slot role
    ; slot_map $00-$0D utility/status/text/transient renderer slots; these are outside the logical item window
    EQUB &20,&53,&42,&43,&73,&78,&2B,&31    ; &2F00
    EQUB &34,&3A,&42,&50,&4C,&6C    ; &2F08

.spook_graphic_id_first_cell
    ; SPOOK pair graphic id seeded by $1E3A and moved by $23CF/$2410
    EQUB &2E    ; &2F0E

.spook_graphic_id_second_cell
    ; SPOOK pair graphic id seeded by $1E3A and moved by $23CF/$2410
    EQUB &2F    ; &2F0F

.player_graphic_id_first_cell
    ; current player pair graphic id, seeded by $1735 and updated by $16E1/$2493
    EQUB &00    ; &2F10

.player_graphic_id_second_cell
    ; current player pair graphic id, seeded by $1735 and updated by $16E1/$2493
    EQUB &03    ; &2F11

.reserved_transient_graphic_id_object_12
    ; reserved/transient render-object graphic id; no gameplay slot ownership currently proven
    EQUB &82    ; &2F12

.reserved_transient_graphic_id_object_13
    ; reserved/transient render-object graphic id; no gameplay slot ownership currently proven
    EQUB &23    ; &2F13

.item_graphic_id_alias_object_14
    ; logical slot $00-$0B graphic ids, rendered as object indices $14-$1F
    ; logical_slots $00-$0B -> render_objects $14-$1F; enemy scheduler window seeded by $1E3A/moved by $198C
    EQUB &3C,&3C,&3C,&3C,&3C,&3C,&3C,&3C    ; &2F14
    EQUB &41,&44,&43,&23    ; &2F1C

.extra_item_or_enemy_graphic_id_alias_object_20
    ; logical slot $0C-$17 graphic ids, rendered as object indices $20-$2B
    ; logical_slots $0C-$17 -> render_objects $20-$2B; placed item/extra enemy hit-scan window
    EQUB &31,&0D,&0F,&FA,&17,&2E,&6C,&70    ; &2F20
    EQUB &73,&31,&20,&43    ; &2F28

.unclassified_graphic_id_data_2f2c
    ; unclassified bytes between logical-slot graphic ids and target-status graphic table
    ; raw_printable_view "MP#3:BPLlp"
    EQUB &4D,&50,&23,&33,&3A,&42,&50,&4C    ; &2F2C
    EQUB &6C,&70    ; &2F34

.target_status_graphic_ids_2345
    ; target_status_graphics slot0=$3D:SAFE slot1=$3F:KEY slot2=$3E:RING slot3=$32:POT_OF_GOLD slot4=$3E:RING slot5=$32:POT_OF_GOLD slot6=$2D:bonus_target_status_and_room_fill_probe
    EQUB &3D,&3F,&3E,&32,&3E,&32,&2D    ; &2F36

.unclassified_data_2f3d
    ; raw_printable_view "LDA"
    EQUB &4C,&44,&41    ; &2F3D

.graphic_record_high_pointer_table_1404
    ; 64-entry graphic pointer table; graphic id Y maps to source address high[$2F40+Y]:low[$2F80+Y]
    ; selected_graphic_pointers $2A:SPINNER->&2CF0 $2B:CLONE->&2D08 $2C:CYBERDROID->&2D20 $2D:bonus_target_status_and_room_fill_probe->&2D38 $2E:SPOOK_first_cell->&2D50 $2F:SPOOK_second_cell->&2D68 $32:POT_OF_GOLD->&2DB0 $3D:SAFE->&2EB8 $3E:RING->&2ED0 $3F:KEY->&2EE8
    EQUB &29,&29,&29,&29,&29,&29,&29,&29    ; &2F40
    EQUB &29,&29,&29,&2A,&2A,&2A,&2A,&2A    ; &2F48
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2B,&2B    ; &2F50
    EQUB &2B,&2B,&2B,&2B,&2B,&2B,&2B,&2B    ; &2F58
    EQUB &2C,&2C,&2C,&2C,&2C,&2C,&2C,&2C    ; &2F60
    EQUB &2C,&2C,&2C,&2D,&2D,&2D,&2D,&2D    ; &2F68
    EQUB &2D,&2D,&2D,&2D,&2D,&2D,&2E,&2E    ; &2F70
    EQUB &2E,&2E,&2E,&2E,&2E,&2E,&2E,&2E    ; &2F78

.graphic_record_low_pointer_table_1404
    ; 64-entry graphic pointer table; graphic id Y maps to source address high[$2F40+Y]:low[$2F80+Y]
    EQUB &00,&18,&30,&48,&60,&78,&90,&A8    ; &2F80
    EQUB &C0,&D8,&F0,&08,&20,&38,&50,&68    ; &2F88
    EQUB &80,&98,&B0,&C8,&E0,&F8,&10,&28    ; &2F90
    EQUB &40,&58,&70,&88,&A0,&B8,&D0,&E8    ; &2F98
    EQUB &00,&18,&30,&48,&60,&78,&90,&A8    ; &2FA0
    EQUB &C0,&D8,&F0,&08,&20,&38,&50,&68    ; &2FA8
    EQUB &80,&98,&B0,&C8,&E0,&F8,&10,&28    ; &2FB0
    EQUB &40,&58,&70,&88,&A0,&B8,&D0,&E8    ; &2FB8
    EQUB &41,&23,&30,&3A,&53,&54,&41,&26    ; &2FC0

.tile_generator_source_low_table_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain oracle: keep class ids numeric; roles are collision/render obligations, not final visual names
    ; terrain oracle: class $0 is the only all-zero generated class; classes $1-$F are generated-solid
    ; terrain oracle: generated terrain never emits target/collect bytes $45/$8A or projectile mask $A0/$8A
    ; terrain_class_0 role=empty_generated_terrain cells=181 rooms=47 active_blocks=no_for_generated_tile_bytes player_exact=none projectile_masks=none
    ; terrain_class_1 role=solid_generated_terrain_with_both_player_edge_exact_bytes cells=50 rooms=29 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$40,$80 projectile_masks=$80=10 $82=13
    ; terrain_class_2 role=solid_generated_terrain_with_both_player_edge_exact_bytes cells=60 rooms=34 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$40,$80 projectile_masks=$80=10 $82=13
    ; terrain_class_3 role=solid_generated_terrain_without_player_exact_edge_byte cells=455 rooms=63 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=8 $82=16
    ; terrain_class_4 role=solid_generated_terrain_with_right/bottom_player_edge_exact_byte cells=54 rooms=24 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$80 projectile_masks=$80=8 $82=16
    ; terrain_class_5 role=solid_generated_terrain_with_right/bottom_player_edge_exact_byte cells=219 rooms=64 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$80 projectile_masks=$80=5 $82=19
    ; terrain_class_6 role=solid_generated_terrain_with_right/bottom_player_edge_exact_byte cells=204 rooms=64 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$80 projectile_masks=$80=5 $82=19
    ; terrain_class_7 role=solid_generated_terrain_without_player_exact_edge_byte cells=23 rooms=13 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=2 $82=22
    ; terrain_class_8 role=solid_generated_terrain_with_left/top_player_edge_exact_byte cells=67 rooms=32 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$40 projectile_masks=$80=10 $82=12
    ; terrain_class_9 role=solid_generated_terrain_with_left/top_player_edge_exact_byte cells=199 rooms=64 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$40 projectile_masks=$80=9 $82=14
    ; terrain_class_a role=solid_generated_terrain_with_left/top_player_edge_exact_byte cells=199 rooms=64 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=$40 projectile_masks=$80=9 $82=14
    ; terrain_class_b role=solid_generated_terrain_without_player_exact_edge_byte cells=35 rooms=21 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=8 $82=16
    ; terrain_class_c role=solid_generated_terrain_without_player_exact_edge_byte cells=522 rooms=63 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=6 $82=18
    ; terrain_class_d role=solid_generated_terrain_without_player_exact_edge_byte cells=11 rooms=9 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=4 $82=20
    ; terrain_class_e role=solid_generated_terrain_without_player_exact_edge_byte cells=16 rooms=15 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=4 $82=20
    ; terrain_class_f role=solid_generated_terrain_without_player_exact_edge_byte cells=9 rooms=7 active_blocks=yes_when_renderer_accumulator_touches_nonzero_byte player_exact=none projectile_masks=$80=2 $82=22
    EQUB &F5,&EA,&DF    ; &2FC8

.tile_generator_middle_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &02,&05,&08,&0A    ; &2FCB

.tile_generator_side_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &01,&02,&04,&05,&07,&08,&0A,&0A    ; &2FCF

.tile_generator_outer_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &00,&02,&03,&02,&06,&02,&09,&02    ; &2FD7

.tile_generator_pattern_source_0_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &80,&C0,&C2,&80,&C0,&C2,&C0,&C3    ; &2FDF
    EQUB &C3,&C0,&C3    ; &2FE7

.tile_generator_pattern_source_1_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &C0,&C3,&C3,&C0,&C3,&C3,&C0,&C3    ; &2FEA
    EQUB &C3,&C0,&C3    ; &2FF2

.tile_generator_pattern_source_2_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &40,&C0,&C1,&C0,&C3,&C3,&40,&C0    ; &2FF5
    EQUB &C1,&C0,&C3    ; &2FFD

runtime_end = *
SAVE "build/reconstruction/CYBRUN", runtime_start, runtime_end, runtime_entry
