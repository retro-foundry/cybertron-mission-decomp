; Cybertron Acorn Electron runtime reconstruction

cpu 1

INCLUDE "source_acorn_electron/memory_map.inc"

org runtime_start

; This is reconstructed source, not original author source.
; Reconstructed routines are validated against the known CYBRUN length and SHA-256 digest.

; SCORE, STARTUP AND LEVEL CONTROL
; ================================

.copy_current_score_to_best_if_not_lower
    LDX      #SCORE_DIGIT_COUNT

.compare_score_digit_loop_0d80
    DEX
    BMI      copy_current_score_to_best_digits_0d80
    LDA      score_counter_chars,X
    CMP      best_score_counter_chars,X
    BEQ      compare_score_digit_loop_0d80
    BPL      copy_current_score_to_best_digits_0d80
    RTS

.copy_current_score_to_best_digits_0d80
    LDX      #SCORE_LAST_DIGIT_INDEX

.copy_current_score_to_best_loop_0d80
    LDA      score_counter_chars,X
    STA      best_score_counter_chars,X
    DEX
    BPL      copy_current_score_to_best_loop_0d80
    RTS

.update_title_score_glyph_tables
    LDX      #SCORE_LAST_DIGIT_INDEX
    LDY      #SCORE_FIRST_TITLE_GLYPH_INDEX

.update_title_score_glyph_loop_0d9c
    LDA      best_score_counter_chars,X
    SEC
    SBC      #SCORE_GLYPH_CODE_OFFSET
    STA      best_score_title_digits,Y
    LDA      score_counter_chars,X
    SEC
    SBC      #SCORE_GLYPH_CODE_OFFSET
    STA      current_score_title_digits,Y
    INY
    DEX
    BPL      update_title_score_glyph_loop_0d9c
    RTS

.oswrch_wrapper_from_a
    JSR      clear_all_palette_entries
    LDA      #VDU_CLEAR_SCREEN
    JMP      MOS_OSWRCH

.copy_level_modulo_24byte_fill_pattern
    LDA      level_units_digit
    AND      #LEVEL_FILL_PATTERN_SELECTOR_MASK
    STA      zp_scratch_76
    CLC
    ADC      zp_scratch_76
    ADC      zp_scratch_76
    ASL      A
    ASL      A
    ASL      A
    TAX
    LDY      #LEVEL_FILL_PATTERN_FIRST_BYTE_INDEX

.copy_level_fill_pattern_loop_0dbf
    LDA      initial_screen_level_modulo_fill_patterns_0dbf,X
    STA      (zp_screen_ptr_70_low),Y
    INY
    INX
    CPY      #LEVEL_FILL_PATTERN_BYTE_COUNT
    BNE      copy_level_fill_pattern_loop_0dbf
    RTS

.wait_one_frame_tick
    LDA      bootstrap_osbyte81_x_result_flag

.wait_frame_tick_mode_branch
    BEQ      wait_for_0224_tick_change

.wait_vsync_with_osbyte19
    LDA      #OSBYTE_WAIT_FOR_VSYNC
    JMP      MOS_OSBYTE

.wait_for_0224_tick_change
    LDA      polled_frame_tick_byte_0224

.wait_for_0224_tick_change_loop_0ddd
    CMP      polled_frame_tick_byte_0224
    BEQ      wait_for_0224_tick_change_loop_0ddd
    RTS

.runtime_pre_entry_unexecuted_bytes_0df0
    ; unused/pre-entry bytes before runtime_entry at $0E02; preserved byte-exact
    EQUB &68,&00,&8D,&78,&30,&00,&00,&B2
    EQUB &0C,&00,&8C,&5E,&70,&00,&00,&78

.runtime_entry_nop_padding
    NOP
    NOP

.runtime_entry_after_bootstrap
    JSR      early_init_sub_13b4

.menu_attract_entry_loop_0e05
    LDA      #SOUND_ID_ATTRACT_FIRST
    JSR      play_sound_id_if_enabled
    LDA      #SOUND_ID_ATTRACT_SECOND
    JSR      play_sound_id_if_enabled
    JSR      oswrch_wrapper_from_a
    JSR      show_controls_and_start_prompt_screen
    JSR      apply_level_palette
    JSR      wait_for_start_escape_fire_or_timeout
    BCS      start_level_or_round
    JSR      oswrch_wrapper_from_a
    JSR      show_object_legend_screen
    JSR      apply_level_palette
    JSR      wait_for_start_escape_fire_or_timeout
    BCS      start_level_or_round

.early_game_setup_path
    JMP      menu_attract_entry_loop_0e05

.wait_for_start_escape_fire_or_timeout
    LDA      #ATTRACT_TEXT_COLOUR
    STA      text_render_colour_value
    LDA      #ATTRACT_COUNTER_CLEAR
    STA      zp_scratch_76
    STA      zp_scratch_79
    STA      zp_scratch_78
    STA      zp_scratch_77
    LDA      #ATTRACT_TIMEOUT_OUTER_COUNT
    STA      zp_indirect_74_high
    LDA      bootstrap_osbyte81_x_result_flag
    BEQ      attract_wait_poll_loop_0e2e
    SEI

.attract_wait_poll_loop_0e2e
    LDA      #ATTRACT_POLL_DELAY_FRAMES
    JSR      wait_frames_count_a
    JSR      draw_rotating_wait_text_strip
    LDX      #INKEY_SPACE
    JSR      scan_inkey_x
    BEQ      attract_wait_check_escape_0e2e
    LDA      #INPUT_MODE_KEYBOARD
    STA      input_mode_keyboard_or_joystick
    CLI
    SEC
    RTS

.attract_wait_check_escape_0e2e
    LDX      #INKEY_ESCAPE
    JSR      scan_inkey_x
    BEQ      attract_wait_check_joystick_fire_0e2e
    CLC
    RTS

.attract_wait_check_joystick_fire_0e2e
    LDA      #OSBYTE_READ_ADC_CHANNEL
    LDX      #JOYSTICK_FIRE_ADC_CHANNEL
    JSR      MOS_OSBYTE
    TXA
    AND      #JOYSTICK_FIRE_RESULT_MASK
    BEQ      attract_wait_countdown_0e2e

.mark_status_and_return_carry_set
    LDA      #INPUT_MODE_JOYSTICK
    STA      input_mode_keyboard_or_joystick
    CLI
    SEC
    RTS

.attract_wait_countdown_0e2e
    DEC      zp_scratch_76
    BNE      attract_wait_poll_loop_0e2e
    DEC      zp_indirect_74_high
    BNE      attract_wait_poll_loop_0e2e
    CLC
    RTS

.start_level_or_round
    LDA      #INITIAL_LIVES_STATUS_COUNT
    STA      lives_status_count
    LDA      #INITIAL_ROOM_AREA
    STA      room_area
    LDA      #INITIAL_LEVEL_INDEX
    STA      level_index_and_hazard_gate
    STA      level_tens_digit
    LDA      #INITIAL_LEVEL_UNITS_DIGIT
    STA      level_units_digit
    LDA      #SCORE_BLANK_CHARACTER
    LDX      #SCORE_LAST_DIGIT_INDEX

.clear_score_counter_loop_0e85
    STA      score_counter_chars,X
    DEX
    BPL      clear_score_counter_loop_0e85

.begin_level_intro_setup_path_0e85
    JSR      oswrch_wrapper_from_a
    LDA      #LEVEL_LOOP_STATE_CLEAR
    STA      level_loop_seed_or_status
    STA      current_level_intro_or_loop_flag
    JSR      show_level_intro_and_required_targets
    LDA      level_tens_digit
    BNE      level_active_loop
    LDA      level_units_digit
    CMP      #INDEXED_DIFFICULTY_LEVEL_COUNT
    BPL      level_active_loop
    STA      level_index_and_hazard_gate
    DEC      level_index_and_hazard_gate

.level_active_loop
    LDA      level_loop_seed_or_status
    STA      saved_level_loop_seed_or_status
    LDA      #INITIAL_REMAINING_ACTIVE_OBJECT_COUNT
    STA      remaining_active_object_count
    JSR      start_or_reset_player_and_level_objects
    LDA      #FRAME_INPUT_STATE_CLEAR
    STA      transition_delay
    STA      fire_edge_request
    STA      input_delta_x
    STA      input_delta_y
    STA      projectile_spook_pause_collision_flag
    JSR      frame_update
    JSR      oswrch_wrapper_from_a
    LDA      lives_status_count
    BPL      level_active_loop
    JSR      apply_level_palette
    LDX      #END_OF_GAME_TEXT_STREAM_OFFSET
    LDA      #END_OF_GAME_SCREEN_LOW
    LDY      #END_OF_GAME_SCREEN_HIGH
    JSR      draw_encoded_text_stream_to_screen
    LDA      #SOUND_ID_END_OF_GAME
    JSR      play_sound_id_if_enabled
    LDA      #END_OF_GAME_DELAY_FRAMES
    JSR      wait_frames_count_a
    JMP      menu_attract_entry_loop_0e05

.unused_return_before_tile_generator
    ; Unreferenced one-byte routine retained from the original runtime.
    RTS

; TILE, TEXT AND OBJECT RENDERING
; ===============================

.draw_24byte_tile_or_sprite
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    STX      zp_screen_ptr_70_low
    TXA
    JSR      add_a_to_pointer_70
    TXA
    JSR      add_a_to_pointer_70
    INC      zp_screen_ptr_70_low
    LDX      #TILE_POINTER_X_SHIFT_COUNT
    JSR      shift_tile_pointer_70_left_x_times
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_calc_ptr_72_high
    STY      zp_calc_ptr_72_low
    TYA
    JSR      add_a_to_pointer_72
    TYA
    JSR      add_a_to_pointer_72
    TYA
    JSR      add_a_to_pointer_72
    TYA
    JSR      add_a_to_pointer_72
    LDX      #TILE_POINTER_Y_SHIFT_COUNT
    JSR      shift_pointer_72_left_x_times
    CLC
    LDA      zp_screen_ptr_70_low
    ADC      zp_calc_ptr_72_low
    STA      zp_screen_ptr_70_low
    LDA      zp_screen_ptr_70_high
    ADC      zp_calc_ptr_72_high
    STA      zp_screen_ptr_70_high
    CLC
    LDA      zp_screen_ptr_70_high
    ADC      #BITMAP_SCREEN_BASE_HIGH
    STA      zp_screen_ptr_70_high
    LDA      #TILE_GENERATOR_COUNTER_CLEAR
    STA      zp_indirect_74_low
    STA      zp_scratch_77
    LDY      #TILE_RECORD_LAST_BYTE_INDEX
    LDA      room_tile_class_or_pattern
    BEQ      clear_24byte_tile_loop

.generate_next_compact_tile_row
    LDA      room_tile_class_or_pattern
    LSR      A
    PHP
    LSR      A
    PLP
    ROL      A
    STA      zp_scratch_78
    TAX
    LDA      tile_generator_outer_index_table_0efe,X
    TAY
    JSR      write_compact_tile_pattern_byte
    LDA      room_tile_class_or_pattern
    LSR      A
    PHP
    LSR      A
    PLP
    ROL      A
    TAX
    LDA      tile_generator_side_index_table_0efe,X
    TAY
    JSR      write_compact_tile_pattern_byte

.generate_compact_tile_middle_bytes
    LDA      room_tile_class_or_pattern
    LSR      A
    LSR      A
    TAX
    LDA      tile_generator_middle_index_table_0efe,X
    TAY
    JSR      write_compact_tile_pattern_byte
    LDA      zp_scratch_77
    AND      #TILE_MIDDLE_POSITION_MASK
    CMP      #TILE_MIDDLE_END_POSITION
    BMI      generate_compact_tile_middle_bytes
    LDA      room_tile_class_or_pattern
    LSR      A
    TAX
    LDA      tile_generator_side_index_table_0efe,X
    TAY
    JSR      write_compact_tile_pattern_byte
    LDA      room_tile_class_or_pattern
    LSR      A
    TAX
    LDA      tile_generator_outer_index_table_0efe,X
    TAY
    JSR      write_compact_tile_pattern_byte
    INC      zp_indirect_74_low
    LDA      zp_indirect_74_low
    CMP      #TILE_GENERATED_ROW_COUNT
    BNE      generate_next_compact_tile_row
    RTS

.clear_24byte_tile_loop
    STA      (zp_screen_ptr_70_low),Y
    DEY
    BPL      clear_24byte_tile_loop
    RTS

.add_a_to_pointer_72
    CLC
    ADC      zp_calc_ptr_72_low
    STA      zp_calc_ptr_72_low
    LDA      zp_calc_ptr_72_high
    ADC      #POINTER_PAGE_CARRY
    STA      zp_calc_ptr_72_high
    RTS

.shift_tile_pointer_70_left_x_times
    ASL      zp_screen_ptr_70_low
    ROL      zp_screen_ptr_70_high
    DEX
    BNE      shift_tile_pointer_70_left_x_times
    RTS

.write_compact_tile_pattern_byte
    LDA      #TILE_PATTERN_SOURCE_PAGE_HIGH
    STA      zp_scratch_76
    LDX      zp_indirect_74_low
    LDA      tile_generator_source_low_table_0efe,X
    STA      zp_indirect_74_high
    LDA      (zp_indirect_74_high),Y
    LDY      zp_scratch_77
    STA      (zp_screen_ptr_70_low),Y
    INC      zp_scratch_77
    RTS

.draw_object_by_index_0
    LDA      #RENDER_MODE_DRAW
    STA      render_mode_or_text_scratch
    JMP      draw_object_by_index

.handle_collected_target_or_level_done
    LDA      #COLLISION_ACCUMULATOR_CLEAR
    STA      renderer_collision_accumulator
    LDX      #TARGET_SLOT_SEARCH_BEFORE_FIRST

.find_collected_target_slot
    INX
    LDA      room_area
    AND      #ROOM_AREA_LOW_NIBBLE_MASK
    CMP      target_room_code,X
    BNE      find_collected_target_slot
    CPX      #BONUS_TARGET_STATUS_SLOT
    BEQ      begin_required_target_completion_scan
    LDA      #TARGET_STATUS_COLLECTED
    STA      target_collected_status,X
    STX      zp_scratch_77
    TXA
    CLC
    ADC      #TARGET_STATUS_OBJECT_INDEX_BASE
    TAX
    JSR      draw_object_by_index_0
    LDA      #SOUND_ID_TARGET_COLLECTED
    JSR      play_sound_id_if_enabled
    LDX      zp_scratch_77
    CPX      #BONUS_TARGET_SLOT
    BEQ      award_bonus_target_life
    LDA      target_collection_score_add_table_0fd6,X
    JMP      increment_four_char_score_or_counter

.award_bonus_target_life
    JSR      reroll_bonus_target_code
    INC      lives_status_count
    JMP      draw_lives_or_target_status

.begin_required_target_completion_scan
    LDX      #REQUIRED_TARGET_SCAN_BEFORE_FIRST

.scan_next_required_target_status
    INX
    LDA      target_collected_status,X
    CMP      #TARGET_STATUS_COLLECTED
    BNE      test_required_target_scan_complete
    LDA      #TARGET_STATUS_CONSUMED
    STA      target_collected_status,X
    INC      collected_target_count

.test_required_target_scan_complete
    CPX      highest_required_target_slot
    BNE      scan_next_required_target_status
    CPX      collected_target_count
    BEQ      advance_level_after_all_targets
    LDA      input_delta_x
    EOR      #SIGNED_ONES_COMPLEMENT_MASK
    STA      input_delta_x
    INC      input_delta_x
    LDA      input_delta_y
    EOR      #SIGNED_ONES_COMPLEMENT_MASK
    STA      input_delta_y
    INC      input_delta_y
    JSR      apply_input_delta_to_player_pair
    JMP      cancel_player_movement_delta

.advance_level_after_all_targets
    INC      lives_status_count
    INC      level_units_digit
    LDA      level_units_digit
    CMP      #LEVEL_DECIMAL_RADIX
    BNE      enter_next_level_area
    LDA      #LEVEL_UNITS_ZERO
    STA      level_units_digit
    INC      level_tens_digit

.enter_next_level_area
    LDA      room_area
    CLC
    ADC      #ROOM_AREA_LEVEL_STEP
    AND      #ROOM_AREA_LEVEL_MASK
    STA      room_area
    LDA      #SOUND_ID_LEVEL_COMPLETE
    JSR      play_sound_id_if_enabled
    LDA      #LEVEL_COMPLETE_DELAY_FRAMES
    JSR      wait_frames_count_a
    PLA
    PLA
    PLA
    PLA
    JMP      begin_level_intro_setup_path_0e85

.draw_20char_buffer_as_bitmap_text
    LDA      #TEXT_FIRST_CHARACTER_INDEX
    STA      object_x_by_index

.draw_next_text_character
    LDX      object_x_by_index
    LDA      text_buffer_20chars,X
    STA      zp_calc_ptr_72_low
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_calc_ptr_72_high
    LDX      #FONT_GLYPH_SHIFT_COUNT
    JSR      shift_pointer_72_left_x_times
    LDA      zp_calc_ptr_72_high
    CLC
    ADC      #FONT_BITMAP_PAGE_HIGH
    STA      zp_calc_ptr_72_high
    LDY      object_y_by_index

.load_character_font_quartet
    TYA
    AND      #FONT_QUARTET_INDEX_MASK
    TAX
    LDA      (zp_calc_ptr_72_low),Y
    STA      font_expand_work_bytes,X
    INY
    TYA
    AND      #FONT_QUARTET_INDEX_MASK
    BNE      load_character_font_quartet
    LDA      #FONT_QUARTER_COUNTER_CLEAR
    STA      movement_delta_x

.draw_next_character_quarter
    LDA      #FONT_PIXEL_PAIR_COUNTER_CLEAR
    STA      input_delta_y
    LDY      #FONT_EXPANDED_BYTE_FIRST_INDEX

.draw_next_character_pixel_pair
    LDA      #FONT_PIXEL_PAIR_CLEAR
    STA      render_mode_or_text_scratch
    LDX      input_delta_y
    LDA      font_expand_work_bytes,X
    AND      #FONT_FIRST_PIXEL_MASK
    BEQ      test_second_pixel_colour
    LDA      text_render_colour_value
    ASL      A
    STA      render_mode_or_text_scratch

.test_second_pixel_colour
    LDA      font_expand_work_bytes,X
    AND      #FONT_SECOND_PIXEL_MASK
    BEQ      store_expanded_pixel_pair
    LDA      text_render_colour_value
    ORA      render_mode_or_text_scratch
    STA      render_mode_or_text_scratch

.store_expanded_pixel_pair
    ASL      font_expand_work_bytes,X
    ASL      font_expand_work_bytes,X
    LDA      render_mode_or_text_scratch
    STA      (zp_screen_ptr_70_low),Y
    INY
    STA      (zp_screen_ptr_70_low),Y
    INC      input_delta_y
    INY
    CPY      #FONT_EXPANDED_PAIR_BYTE_COUNT
    BNE      draw_next_character_pixel_pair
    LDA      #FONT_EXPANDED_PAIR_BYTE_COUNT
    JSR      add_a_to_pointer_70
    INC      movement_delta_x
    LDA      movement_delta_x
    CMP      #FONT_QUARTER_COUNT
    BNE      draw_next_character_quarter
    INC      object_x_by_index
    LDA      object_x_by_index
    CMP      text_render_char_limit
    BNE      continue_text_character_loop
    RTS

.continue_text_character_loop
    JMP      draw_next_text_character

.draw_20char_buffer_two_rows
    LDA      #TEXT_BUFFER_CHARACTER_COUNT
    STA      text_render_char_limit
    LDA      #TEXT_FIRST_ROW_FONT_OFFSET
    STA      object_y_by_index
    JSR      draw_20char_buffer_as_bitmap_text
    LDA      #TEXT_SECOND_ROW_FONT_OFFSET
    STA      object_y_by_index
    JMP      draw_20char_buffer_as_bitmap_text

.oswrch_zero_terminated_text_2600_x
    LDA      control_help_text,X
    BEQ      return_from_text_stream
    JSR      MOS_OSWRCH
    INX
    JMP      oswrch_zero_terminated_text_2600_x

.return_from_text_stream
    RTS

.copy_encoded_text_stream_to_buffer
    LDA      screen_copy_control_streams,X
    TAY
    INX

.copy_next_encoded_text_byte
    LDA      screen_copy_control_streams,X
    BMI      return_from_text_stream
    STA      text_buffer_20chars,Y
    INY
    INX
    JMP      copy_next_encoded_text_byte

.clear_20char_text_buffer
    LDY      #TEXT_BUFFER_LAST_CHARACTER_INDEX
    LDA      #TEXT_BUFFER_CLEAR_CHARACTER

.clear_next_text_buffer_byte
    STA      text_buffer_20chars,Y
    DEY
    BPL      clear_next_text_buffer_byte
    RTS

.draw_encoded_text_stream_to_screen
    STA      zp_screen_ptr_70_low
    STY      zp_screen_ptr_70_high
    JSR      clear_20char_text_buffer
    JSR      copy_encoded_text_stream_to_buffer
    JMP      draw_20char_buffer_two_rows

.show_controls_and_start_prompt_screen
    LDA      #TITLE_TEXT_COLOUR
    STA      text_render_colour_value
    LDX      #CONTROL_HELP_TEXT_START
    JSR      oswrch_zero_terminated_text_2600_x
    JSR      copy_current_score_to_best_if_not_lower
    JSR      update_title_score_glyph_tables
    LDA      #TITLE_CYBERTRON_SCREEN_LOW
    LDY      #TITLE_CYBERTRON_SCREEN_HIGH
    LDX      #TITLE_CYBERTRON_STREAM_OFFSET
    JSR      draw_encoded_text_stream_to_screen
    LDA      #TITLE_KEYS_SCREEN_LOW
    LDY      #TITLE_KEYS_SCREEN_HIGH
    LDX      #TITLE_KEYS_STREAM_OFFSET
    JSR      draw_encoded_text_stream_to_screen
    LDA      #TITLE_TEXT_COLOUR
    STA      text_render_colour_value
    LDX      #TITLE_START_STREAM_OFFSET
    LDY      #TITLE_START_SCREEN_HIGH
    LDA      #TITLE_START_SCREEN_LOW
    JMP      draw_encoded_text_stream_to_screen

.show_object_legend_screen
    LDA      #LEGEND_TEXT_COLOUR
    STA      text_render_colour_value
    LDX      #LEGEND_FIRST_OBJECT_INDEX

.draw_next_legend_text
    STX      zp_scratch_79
    LDY      object_legend_screen_high_bytes_1175,X
    LDA      object_legend_text_stream_offsets_1175,X
    STA      zp_scratch_78
    LDA      object_legend_screen_low_bytes_1175,X
    LDX      zp_scratch_78
    JSR      draw_encoded_text_stream_to_screen
    LDX      zp_scratch_79
    INX
    LDA      #LEGEND_FINAL_TEXT_COLOUR
    STA      text_render_colour_value
    CPX      #LEGEND_TEXT_COUNT
    BNE      draw_next_legend_text
    LDA      #LEGEND_FIRST_GRAPHIC_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #LEGEND_FIRST_GRAPHIC_SCREEN_LOW
    STA      object_screen_low_by_index
    LDA      #LEGEND_GRAPHIC_Y_OFFSET
    STA      object_y_by_index
    LDX      #LEGEND_FIRST_OBJECT_INDEX
    STX      render_mode_or_text_scratch

.draw_next_legend_graphic
    STX      zp_scratch_79
    LDA      object_legend_graphic_ids_1175,X
    STA      object_graphic_id_by_index
    LDX      #LEGEND_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      object_screen_low_by_index
    CLC
    ADC      #LEGEND_GRAPHIC_SCREEN_LOW_STEP
    STA      object_screen_low_by_index
    LDA      object_screen_high_by_index
    ADC      #LEGEND_GRAPHIC_SCREEN_HIGH_CARRY_STEP
    STA      object_screen_high_by_index
    LDX      zp_scratch_79
    INX
    CPX      #LEGEND_GRAPHIC_COUNT
    BNE      draw_next_legend_graphic
    LDA      #LEGEND_SPOOK_Y_OFFSET
    STA      object_y_by_index
    LDA      #LEGEND_SPOOK_FIRST_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #LEGEND_SPOOK_FIRST_SCREEN_LOW
    STA      object_screen_low_by_index
    LDA      #graphic_id_spook_first_cell
    STA      object_graphic_id_by_index
    LDX      #LEGEND_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      #LEGEND_SPOOK_SECOND_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #LEGEND_SPOOK_SECOND_SCREEN_LOW
    STA      object_screen_low_by_index
    INC      object_graphic_id_by_index
    LDX      #LEGEND_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    RTS

.show_level_intro_and_required_targets
    LDA      #LEVEL_INTRO_TEXT_COLOUR
    STA      text_render_colour_value
    JSR      seed_required_target_codes
    JSR      apply_level_palette
    LDA      #COLLECTED_TARGET_COUNT_CLEAR
    STA      collected_target_count
    STA      render_mode_or_text_scratch
    LDX      #LEVEL_INTRO_ENTERING_TEXT_OFFSET
    JSR      oswrch_zero_terminated_text_2600_x
    JSR      clear_20char_text_buffer
    LDX      #LEVEL_INTRO_LEVEL_STREAM_OFFSET
    JSR      copy_encoded_text_stream_to_buffer
    LDA      level_tens_digit
    BEQ      write_level_units_digit
    CLC
    ADC      #SCORE_GLYPH_CODE_OFFSET
    STA      level_intro_tens_digit_character

.write_level_units_digit
    LDA      level_units_digit
    CLC
    ADC      #SCORE_GLYPH_CODE_OFFSET
    STA      level_intro_units_digit_character
    LDA      #LEVEL_INTRO_SCREEN_LOW
    STA      zp_screen_ptr_70_low
    LDA      #LEVEL_INTRO_SCREEN_HIGH
    STA      zp_screen_ptr_70_high
    JSR      draw_20char_buffer_two_rows
    LDX      #LEVEL_INTRO_FIND_TEXT_OFFSET
    JSR      oswrch_zero_terminated_text_2600_x
    LDA      #LEVEL_INTRO_TARGET_SCREEN_LOW
    STA      object_screen_low_by_index
    LDA      #LEVEL_INTRO_TARGET_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      level_tens_digit
    BNE      cap_level_intro_target_count
    LDA      level_units_digit
    CMP      #INDEXED_DIFFICULTY_LEVEL_COUNT
    BMI      begin_level_intro_target_loop

.cap_level_intro_target_count
    LDA      #LEVEL_INTRO_TARGET_COUNT_CAP

.begin_level_intro_target_loop
    TAX
    DEX

.level_intro_draw_next_required_target
    STX      zp_scratch_79
    LDA      level_intro_required_graphic_table_11fe,X
    STA      object_graphic_id_by_index
    LDA      #LEVEL_INTRO_TARGET_DELAY_FRAMES
    JSR      wait_frames_count_a
    LDX      #LEGEND_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      object_screen_high_by_index
    CLC
    ADC      #LEVEL_INTRO_TARGET_SCREEN_HIGH_STEP
    STA      object_screen_high_by_index

.play_level_intro_required_target_sound
    LDA      #SOUND_ID_LEVEL_INTRO_TARGET
    JSR      play_sound_id_if_enabled
    LDX      zp_scratch_79
    DEX
    BPL      level_intro_draw_next_required_target
    LDA      #LEVEL_INTRO_FINAL_DELAY_FRAMES
    JSR      wait_frames_count_a

.finish_level_intro_clear_screen
    JMP      oswrch_wrapper_from_a

.read_joystick_axes_and_fire
    LDA      #OSBYTE_READ_ADC_CHANNEL
    LDX      #JOYSTICK_X_ADC_CHANNEL
    JSR      MOS_OSBYTE
    CPY      #JOYSTICK_AXIS_LOW_THRESHOLD
    BCC      joystick_x_axis_positive_1287
    CPY      #JOYSTICK_AXIS_HIGH_THRESHOLD
    BCC      joystick_y_axis_scan_1287
    DEC      input_delta_x
    JMP      joystick_y_axis_scan_1287

.joystick_x_axis_positive_1287
    INC      input_delta_x

.joystick_y_axis_scan_1287
    LDA      #OSBYTE_READ_ADC_CHANNEL
    LDX      #JOYSTICK_Y_ADC_CHANNEL
    JSR      MOS_OSBYTE
    CPY      #JOYSTICK_AXIS_LOW_THRESHOLD
    BCC      joystick_y_axis_positive_1287
    CPY      #JOYSTICK_AXIS_HIGH_THRESHOLD
    BCC      joystick_fire_scan_1287
    DEC      input_delta_y
    JMP      joystick_fire_scan_1287

.joystick_y_axis_positive_1287
    INC      input_delta_y

.joystick_fire_scan_1287
    LDA      #OSBYTE_READ_ADC_CHANNEL
    LDX      #JOYSTICK_FIRE_ADC_CHANNEL
    JSR      MOS_OSBYTE
    TXA
    AND      #JOYSTICK_FIRE_RESULT_MASK
    TAX
    RTS

.seed_required_target_codes
    LDA      level_tens_digit
    BNE      target_code_cap_to_slot5_12bf
    LDX      level_units_digit
    CPX      #INDEXED_DIFFICULTY_LEVEL_COUNT
    BMI      store_highest_required_target_slot_12bf

.target_code_cap_to_slot5_12bf
    LDX      #TARGET_SLOT_LIMIT

.store_highest_required_target_slot_12bf
    STX      highest_required_target_slot
    LDX      #TARGET_SLOT_BEFORE_FIRST

.seed_required_target_codes_loop_12bf
    JSR      random_unique_target_code
    CPX      highest_required_target_slot
    BMI      seed_required_target_codes_loop_12bf

.reroll_bonus_target_code
    LDX      #TARGET_SLOT_LIMIT
    JMP      random_unique_target_code

.random_unique_target_code
    INX
    STX      object_x_by_index

.random_target_code_reroll_12dd
    JSR      rng_next_byte
    LDA      rng_output_byte
    AND      #TARGET_CODE_MASK
    LDX      object_x_by_index
    STA      target_room_code,X
    LDA      #TARGET_STATUS_UNCOLLECTED
    STA      target_collected_status,X
    LDY      #TARGET_SLOT_BEFORE_FIRST

.target_code_uniqueness_scan_loop_12dd
    INY
    CPY      object_x_by_index
    BEQ      return_from_random_unique_target_code_12dd
    LDA      target_room_code,Y
    CMP      target_room_code,X
    BEQ      random_target_code_reroll_12dd
    JMP      target_code_uniqueness_scan_loop_12dd

.return_from_random_unique_target_code_12dd
    RTS

.wait_frames_count_a
    STA      wait_frame_counter

.wait_frames_count_a_loop_1307
    JSR      wait_one_frame_tick
    DEC      wait_frame_counter
    BNE      wait_frames_count_a_loop_1307
    RTS

.test_player_spook_pair_overlap
    LDA      spook_release_timer
    BNE      return_from_player_spook_overlap_test_1311
    LDA      #COLLISION_ACCUMULATOR_CLEAR
    STA      renderer_collision_accumulator
    LDA      player_x_first_cell
    SEC
    SBC      spook_first_cell_x
    BPL      player_spook_overlap_compare_x_range_1311
    EOR      #SIGNED_ONES_COMPLEMENT_MASK
    CLC
    ADC      #SIGNED_TWOS_COMPLEMENT_ADD

.player_spook_overlap_compare_x_range_1311
    CMP      #PLAYER_SPOOK_HORIZONTAL_EXTENT
    BPL      return_from_player_spook_overlap_test_1311
    LDA      player_y_first_cell
    SEC
    SBC      spook_first_cell_y
    BPL      player_spook_overlap_compare_y_range_1311
    EOR      #SIGNED_ONES_COMPLEMENT_MASK
    CLC
    ADC      #SIGNED_TWOS_COMPLEMENT_ADD

.player_spook_overlap_compare_y_range_1311
    CMP      #PLAYER_SPOOK_VERTICAL_EXTENT
    BPL      return_from_player_spook_overlap_test_1311
    INC      renderer_collision_accumulator

.return_from_player_spook_overlap_test_1311
    RTS

.draw_rotating_wait_text_strip
    LDA      zp_scratch_78
    CMP      #WAIT_STRIP_WRAP_POSITION
    BNE      rotating_wait_text_pointer_setup_1341
    LDX      #WAIT_STRIP_LAST_EDGE_BYTE

.clear_rotating_wait_text_edge_loop_1341
    LDA      #WAIT_STRIP_EDGE_CLEAR_BYTE
    STA      rotating_wait_text_top_edge,X
    STA      rotating_wait_text_bottom_edge,X
    DEX
    BPL      clear_rotating_wait_text_edge_loop_1341

.rotating_wait_text_pointer_setup_1341
    LDY      #WAIT_STRIP_SCREEN_HIGH
    STY      zp_screen_ptr_70_high
    LDA      zp_scratch_78
    CLC
    ADC      #WAIT_STRIP_SCREEN_LOW_BASE
    STA      zp_screen_ptr_70_low
    JSR      clear_20char_text_buffer
    LDY      #WAIT_STRIP_TEXT_START_INDEX
    LDX      zp_scratch_77

.copy_rotating_wait_text_chars_loop_1341
    LDA      scroll_or_animation_seed_table,X
    STA      text_buffer_20chars,Y
    INX
    TXA
    AND      #WAIT_STRIP_SOURCE_INDEX_MASK
    TAX
    INY
    CPY      #WAIT_STRIP_CHARACTER_COUNT
    BNE      copy_rotating_wait_text_chars_loop_1341
    JSR      wait_one_frame_tick
    LDA      #WAIT_STRIP_FIRST_ROW_FONT_OFFSET
    STA      object_y_by_index
    LDA      #WAIT_STRIP_RENDER_CHARACTER_LIMIT
    STA      text_render_char_limit
    JSR      draw_20char_buffer_as_bitmap_text
    INC      zp_screen_ptr_70_high
    LDA      #WAIT_STRIP_SECOND_ROW_PTR_STEP
    JSR      add_a_to_pointer_70
    LDA      #TEXT_SECOND_ROW_FONT_OFFSET
    STA      object_y_by_index
    JSR      draw_20char_buffer_as_bitmap_text
    LDA      zp_scratch_78
    SEC
    SBC      #WAIT_STRIP_SCROLL_STEP
    AND      #WAIT_STRIP_SCROLL_POSITION_MASK
    STA      zp_scratch_78
    CMP      #WAIT_STRIP_WRAP_POSITION
    BNE      return_from_rotating_wait_text_1341
    INC      zp_scratch_77
    LDA      zp_scratch_77
    AND      #WAIT_STRIP_SOURCE_INDEX_MASK
    STA      zp_scratch_77

.return_from_rotating_wait_text_1341
    RTS

.scan_inkey_x
    LDA      #OSBYTE_INKEY
    LDY      #INKEY_TIME_LIMIT
    JSR      MOS_OSBYTE
    CPX      #INKEY_NOT_PRESSED
    RTS

.early_init_sub_13b4
    LDX      #EARLY_INIT_VDU_LAST_INDEX

.early_init_vdu_byte_loop_13b4
    LDA      early_init_vdu_bytes_13b4,X
    JSR      MOS_OSWRCH
    DEX
    BPL      early_init_vdu_byte_loop_13b4
    RTS

.add_a_to_pointer_70
    CLC
    ADC      zp_screen_ptr_70_low
    STA      zp_screen_ptr_70_low
    LDA      zp_screen_ptr_70_high
    ADC      #POINTER_PAGE_CARRY
    STA      zp_screen_ptr_70_high
    RTS

.unused_add_a_to_pointer_72_copy
    ; Valid duplicate pointer-add routine with no direct caller in this runtime.
    CLC
    ADC      zp_calc_ptr_72_low
    STA      zp_calc_ptr_72_low
    LDA      zp_calc_ptr_72_high
    ADC      #POINTER_PAGE_CARRY
    STA      zp_calc_ptr_72_high
    RTS

.shift_pointer_70_left_x_times
    ASL      zp_screen_ptr_70_low
    ROL      zp_screen_ptr_70_high
    DEX
    BNE      shift_pointer_70_left_x_times
    RTS

.shift_pointer_72_left_x_times
    ASL      zp_calc_ptr_72_low
    ROL      zp_calc_ptr_72_high
    DEX
    BNE      shift_pointer_72_left_x_times
    RTS

.draw_object_using_saved_screen_ptr
    LDA      saved_object_screen_low_by_index,X
    STA      zp_screen_ptr_70_low
    LDA      saved_object_screen_high_by_index,X
    STA      zp_screen_ptr_70_high
    LDA      saved_object_y_by_index,X
    STA      object_render_y_or_parity
    JMP      render_object_with_loaded_screen_ptr_1404

.draw_object_by_index
    JSR      load_object_screen_ptr
    LDA      object_y_by_index,X
    STA      object_render_y_or_parity

.render_object_with_loaded_screen_ptr_1404
    LDY      render_mode_or_text_scratch
    LDA      renderer_store_vector_low_table,Y
    STA      zp_indirect_74_low
    LDA      renderer_store_vector_high_table,Y
    STA      zp_indirect_74_high
    LDY      object_graphic_id_by_index,X
    LDA      graphic_record_low_pointer_table_1404,Y
    STA      render_source_operand_low
    LDA      graphic_record_high_pointer_table_1404,Y
    STA      render_source_operand_high
    LDA      object_render_y_or_parity
    AND      #OBJECT_Y_PARITY_MASK
    BNE      render_odd_y_split_setup_143a
    LDX      #GRAPHIC_RECORD_FIRST_BYTE_INDEX
    LDY      #GRAPHIC_RECORD_FIRST_BYTE_INDEX

.render_even_y_contiguous_loop_1426
    JSR      render_load_source_byte_and_jump_store_stub
    INY
    INX
    CPY      #GRAPHIC_RECORD_BYTE_COUNT
    BNE      render_even_y_contiguous_loop_1426
    RTS

.render_load_source_byte_and_jump_store_stub
    LDA      render_source_address_placeholder,X
    JMP      (zp_indirect_74_low)

.render_odd_y_split_setup_143a
    LDX      #GRAPHIC_RECORD_FIRST_BYTE_INDEX
    LDY      #ODD_RENDER_FIRST_SCREEN_OFFSET

.render_odd_y_split_loop_143a
    JSR      render_load_source_byte_and_jump_store_stub
    INY
    INX
    TXA
    AND      #ODD_RENDER_GROUP_INDEX_MASK
    BNE      render_odd_y_split_progress_check_143a
    TXA
    CLC
    ADC      #ODD_RENDER_GROUP_SKIP
    TAX
    TYA
    ADC      #ODD_RENDER_GROUP_SKIP
    TAY

.render_odd_y_split_progress_check_143a
    CPY      #ODD_RENDER_END_SCREEN_OFFSET
    BEQ      return_from_object_render_walk_1404
    CPX      #GRAPHIC_RECORD_BYTE_COUNT
    BNE      render_odd_y_split_loop_143a
    LDX      #ODD_RENDER_SECOND_SOURCE_OFFSET
    LDY      #ODD_RENDER_SECOND_SCREEN_OFFSET
    INC      zp_screen_ptr_70_high
    INC      zp_screen_ptr_70_high
    JMP      render_odd_y_split_loop_143a

.return_from_object_render_walk_1404
    RTS

.render_store_eor_source
    EOR      (zp_screen_ptr_70_low),Y
    STA      (zp_screen_ptr_70_low),Y
    RTS

.render_store_eor_source_track_collision_bits
    STA      zp_calc_ptr_72_low
    LDA      (zp_screen_ptr_70_low),Y
    ORA      renderer_collision_accumulator
    STA      renderer_collision_accumulator
    LDA      zp_calc_ptr_72_low
    EOR      (zp_screen_ptr_70_low),Y
    STA      (zp_screen_ptr_70_low),Y
    RTS

.render_store_clear_byte
    LDA      #RENDER_CLEAR_BYTE
    STA      (zp_screen_ptr_70_low),Y
    RTS

.render_collision_test_and_conditional_store
    LDA      (zp_screen_ptr_70_low),Y
    ORA      renderer_collision_accumulator
    STA      renderer_collision_accumulator
    LDA      (zp_screen_ptr_70_low),Y
    AND      #MODE1_EVEN_PIXEL_MASK
    CMP      #MODE1_EVEN_PLAYER_PATTERN
    BEQ      mark_renderer_player_collision_class
    CMP      #MODE1_EVEN_TARGET_PATTERN
    BEQ      mark_renderer_target_collect_collision_class
    LDA      (zp_screen_ptr_70_low),Y
    AND      #MODE1_ODD_PIXEL_MASK
    CMP      #MODE1_ODD_PLAYER_PATTERN
    BEQ      mark_renderer_player_collision_class
    CMP      #MODE1_ODD_TARGET_PATTERN
    BEQ      mark_renderer_target_collect_collision_class
    RTS

.mark_renderer_player_collision_class
    LDA      #COLLISION_CLASS_PRESENT
    STA      player_collision_class_flag
    RTS

.mark_renderer_target_collect_collision_class
    LDA      #COLLISION_CLASS_PRESENT
    STA      target_collect_collision_flag
    RTS

.render_collision_accumulate_only
    LDA      (zp_screen_ptr_70_low),Y
    ORA      renderer_collision_accumulator
    STA      renderer_collision_accumulator
    RTS

.render_compare_source_to_screen
    CMP      (zp_screen_ptr_70_low),Y
    BNE      render_compare_source_mismatch_14af
    RTS

.render_compare_source_mismatch_14af
    LDA      #COLLISION_CLASS_PRESENT
    STA      renderer_collision_accumulator
    RTS

.load_packed_room_tile_nibble
    LDA      room_tile_y_index
    ASL      A
    ADC      room_tile_y_index
    STA      room_tile_class_or_pattern
    LDA      room_tile_x_index
    LSR      A
    CLC
    ADC      room_tile_class_or_pattern
    TAY
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    LDA      room_area
    STA      zp_screen_ptr_70_low
    LDX      #ROOM_LAYOUT_POINTER_SHIFT_COUNT
    JSR      shift_pointer_70_left_x_times
    LDA      room_area
    JSR      add_a_to_pointer_70
    LDA      room_area
    JSR      add_a_to_pointer_70
    LDA      #ROOM_LAYOUT_POINTER_LOW_BIAS
    JSR      add_a_to_pointer_70
    LDA      room_area
    CMP      #ROOM_LAYOUT_SECOND_BANK_AREA
    BPL      room_tile_area_ge_10_bank_adjust_14b9
    LDA      #ROOM_LAYOUT_FIRST_BANK_PAGE
    CLC
    ADC      zp_screen_ptr_70_high
    STA      zp_screen_ptr_70_high
    JMP      room_tile_read_packed_byte_14b9

.room_tile_area_ge_10_bank_adjust_14b9
    LDA      #ROOM_LAYOUT_SECOND_BANK_PAGE
    CLC
    ADC      zp_screen_ptr_70_high
    STA      zp_screen_ptr_70_high

.room_tile_read_packed_byte_14b9
    LDA      (zp_screen_ptr_70_low),Y
    STA      room_tile_class_or_pattern
    STA      zp_calc_ptr_72_low
    LDA      room_tile_x_index
    AND      #PACKED_ROOM_LOW_NIBBLE_SELECTOR
    BNE      room_tile_high_nibble_path_14b9
    LDA      room_tile_class_or_pattern
    AND      #PACKED_ROOM_NIBBLE_MASK
    STA      room_tile_class_or_pattern
    RTS

.room_tile_high_nibble_path_14b9
    LDA      room_tile_class_or_pattern
    LSR      A
    LSR      A
    LSR      A
    LSR      A
    STA      room_tile_class_or_pattern
    RTS

.draw_playfield_tiles
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_column_or_fill_index
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_x_index

.draw_playfield_major_column_setup_1516
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_y_index
    LDA      #PLAYFIELD_FIRST_TILE_ROW_SCREEN_INDEX
    STA      zp_scratch_3c

.draw_playfield_major_tile_loop_1516
    JSR      load_packed_room_tile_nibble
    AND      #ROOM_TILE_COLLISION_CLASS_MASK
    LDY      room_tile_y_index
    STA      player_collision_class_flag,Y
    LDY      zp_scratch_3c
    LDX      room_tile_column_or_fill_index
    JSR      draw_24byte_tile_or_sprite
    LDA      room_tile_y_index
    CMP      #PLAYFIELD_MAJOR_TILE_ROW_COUNT
    BEQ      fill_finished_major_column_gaps_1516
    LDA      #PLAYFIELD_GAP_CELL_COUNT
    STA      zp_scratch_3d
    LDA      room_tile_class_or_pattern
    AND      #ROOM_TILE_VERTICAL_GAP_PATTERN_MASK
    PHP
    LDA      #ROOM_TILE_EMPTY_PATTERN
    STA      room_tile_class_or_pattern
    PLP
    BEQ      draw_vertical_gap_cells_loop_1516
    LDA      #ROOM_TILE_VERTICAL_GAP_SOLID_PATTERN
    STA      room_tile_class_or_pattern

.draw_vertical_gap_cells_loop_1516
    INC      zp_scratch_3c
    LDY      zp_scratch_3c
    LDX      room_tile_column_or_fill_index
    JSR      draw_24byte_tile_or_sprite
    DEC      zp_scratch_3d
    BNE      draw_vertical_gap_cells_loop_1516
    INC      zp_scratch_3c
    INC      room_tile_y_index
    JMP      draw_playfield_major_tile_loop_1516

.fill_finished_major_column_gaps_1516
    JSR      fill_room_masked_offset_screen_gaps
    LDA      room_tile_x_index
    CMP      #PLAYFIELD_MAJOR_COLUMN_COUNT
    BNE      draw_horizontal_gap_columns_setup_1516

.return_from_draw_playfield_tiles_1516
    RTS

.draw_horizontal_gap_columns_setup_1516
    LDA      #PLAYFIELD_HORIZONTAL_GAP_COLUMN_COUNT
    STA      room_gap_column_repeat_counter
    INC      room_tile_column_or_fill_index

.draw_horizontal_gap_column_setup_1516
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_y_index
    LDA      #PLAYFIELD_FIRST_TILE_ROW_SCREEN_INDEX
    STA      zp_scratch_3c

.draw_horizontal_gap_column_tile_loop_1516
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_class_or_pattern
    LDY      room_tile_y_index
    LDA      player_collision_class_flag,Y
    BEQ      draw_horizontal_gap_tile_1516
    LDA      #ROOM_TILE_HORIZONTAL_GAP_SOLID_PATTERN
    STA      room_tile_class_or_pattern

.draw_horizontal_gap_tile_1516
    LDY      zp_scratch_3c
    LDX      room_tile_column_or_fill_index
    JSR      draw_24byte_tile_or_sprite
    LDA      room_tile_y_index
    CMP      #PLAYFIELD_MAJOR_TILE_ROW_COUNT
    BEQ      fill_finished_horizontal_gap_column_1516
    LDA      #PLAYFIELD_GAP_CELL_COUNT
    STA      zp_scratch_3d
    LDA      #PLAYFIELD_FIRST_INDEX
    STA      room_tile_class_or_pattern

.draw_horizontal_gap_clear_vertical_run_loop_1516
    INC      zp_scratch_3c
    LDY      zp_scratch_3c
    LDX      room_tile_column_or_fill_index
    JSR      draw_24byte_tile_or_sprite
    DEC      zp_scratch_3d
    BNE      draw_horizontal_gap_clear_vertical_run_loop_1516
    INC      zp_scratch_3c
    INC      room_tile_y_index
    JMP      draw_horizontal_gap_column_tile_loop_1516

.fill_finished_horizontal_gap_column_1516
    JSR      fill_room_masked_forward_screen_gaps
    INC      room_tile_column_or_fill_index
    DEC      room_gap_column_repeat_counter
    BNE      draw_horizontal_gap_column_setup_1516
    INC      room_tile_x_index
    JMP      draw_playfield_major_column_setup_1516

; INPUT AND PLAYER MOVEMENT
; =========================

.read_game_input_and_pause
    JSR      handle_sound_on_off_keys
    LDA      #INPUT_STATE_CLEAR
    STA      input_delta_x
    STA      input_delta_y
    STA      input_scan_index
    LDA      input_mode_keyboard_or_joystick
    BNE      active_input_joystick_path_15c3
    JSR      scan_movement_keys
    JMP      active_input_fire_edge_check_15c3

.active_input_joystick_path_15c3
    JSR      read_joystick_axes_and_fire

.active_input_fire_edge_check_15c3
    LDA      previous_fire_input_latch
    BNE      active_input_store_fire_latch_15c3
    CPX      #INKEY_NOT_PRESSED
    BEQ      active_input_store_fire_latch_15c3
    LDA      #FIRE_EDGE_REQUESTED
    STA      fire_edge_request

.active_input_store_fire_latch_15c3
    STX      previous_fire_input_latch
    JSR      scan_escape_key
    BEQ      active_input_check_pause_key_15c3
    PLA
    PLA
    PLA
    PLA
    JMP      menu_attract_entry_loop_0e05

.active_input_check_pause_key_15c3
    LDX      #INKEY_PAUSE
    JSR      scan_inkey_current_x
    BNE      active_input_wait_for_resume_key_15c3
    RTS

.active_input_wait_for_resume_key_15c3
    LDX      #INKEY_RESUME
    JSR      scan_inkey_current_x
    BEQ      active_input_wait_for_resume_key_15c3
    RTS

.scan_movement_keys
    LDY      input_scan_index
    LDA      keyboard_inkey_codes_table_1609,Y
    TAX
    JSR      scan_inkey_current_x
    BEQ      keyboard_scan_next_key_1609
    LDY      input_scan_index
    LDA      input_delta_x
    CLC
    ADC      keyboard_input_delta_x_table_1609,Y
    STA      input_delta_x
    LDA      input_delta_y
    CLC
    ADC      keyboard_input_delta_y_table_1609,Y
    STA      input_delta_y

.keyboard_scan_next_key_1609
    INC      input_scan_index
    LDA      input_scan_index
    CMP      #MOVEMENT_KEY_COUNT
    BNE      scan_movement_keys
    LDX      #INKEY_FIRE
    JMP      scan_inkey_current_x

.unused_clear_32_screen_rows_from_index
    ; Unreferenced screen clear: zp_scratch_3d selects an eight-byte column,
    ; then 32 character rows are cleared at the BBC bitmap row stride.
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    LDA      zp_scratch_3d
    STA      zp_screen_ptr_70_low
    LDX      #UNUSED_CLEAR_COLUMN_SHIFT_COUNT
    JSR      shift_pointer_70_left_x_times
    LDA      zp_screen_ptr_70_high
    CLC
    ADC      #BITMAP_SCREEN_BASE_HIGH
    STA      zp_screen_ptr_70_high
    LDA      #UNUSED_CLEAR_ROW_INDEX_CLEAR
    STA      zp_scratch_3c

.unused_clear_32_screen_rows_loop
    LDY      #UNUSED_CLEAR_FIRST_ROW_BYTE

.unused_clear_screen_row_bytes_loop
    LDA      #UNUSED_CLEAR_SCREEN_BYTE
    STA      (zp_screen_ptr_70_low),Y
    DEY
    BPL      unused_clear_screen_row_bytes_loop
    LDA      #UNUSED_CLEAR_ROW_STRIDE_LOW
    JSR      add_a_to_pointer_70
    INC      zp_screen_ptr_70_high
    INC      zp_screen_ptr_70_high
    INC      zp_scratch_3c
    LDA      zp_scratch_3c
    CMP      #UNUSED_CLEAR_ROW_COUNT
    BNE      unused_clear_32_screen_rows_loop
    RTS

.compute_screen_ptr_for_object
    JSR      load_object_screen_ptr
    LDA      zp_screen_ptr_70_low
    STA      saved_object_screen_low_by_index,X
    LDA      zp_screen_ptr_70_high
    STA      saved_object_screen_high_by_index,X
    LDA      movement_delta_x
    BMI      compute_screen_ptr_x_negative_166a
    BEQ      compute_screen_ptr_y_delta_166a
    LDA      #OBJECT_SCREEN_HORIZONTAL_BYTE_STEP
    JSR      add_a_to_pointer_70
    JMP      compute_screen_ptr_y_delta_166a

.compute_screen_ptr_x_negative_166a
    SEC
    LDA      zp_screen_ptr_70_low
    SBC      #OBJECT_SCREEN_HORIZONTAL_BYTE_STEP
    STA      zp_screen_ptr_70_low
    LDA      zp_screen_ptr_70_high
    SBC      #POINTER_PAGE_CARRY
    STA      zp_screen_ptr_70_high

.compute_screen_ptr_y_delta_166a
    LDA      movement_delta_y
    BMI      compute_screen_ptr_y_negative_166a
    BEQ      return_from_compute_screen_ptr_166a
    LDA      object_y_by_index,X
    AND      #OBJECT_Y_PARITY_MASK
    BNE      return_from_compute_screen_ptr_166a
    LDA      #OBJECT_SCREEN_VERTICAL_LOW_STEP
    JSR      add_a_to_pointer_70
    INC      zp_screen_ptr_70_high
    INC      zp_screen_ptr_70_high
    RTS

.compute_screen_ptr_y_negative_166a
    LDA      object_y_by_index,X
    AND      #OBJECT_Y_PARITY_MASK
    BEQ      return_from_compute_screen_ptr_166a
    SEC
    LDA      zp_screen_ptr_70_low
    SBC      #OBJECT_SCREEN_VERTICAL_LOW_STEP
    STA      zp_screen_ptr_70_low
    LDA      zp_screen_ptr_70_high
    SBC      #OBJECT_SCREEN_VERTICAL_HIGH_STEP
    STA      zp_screen_ptr_70_high

.return_from_compute_screen_ptr_166a
    RTS

.move_object_and_update_screen_ptr
    LDA      movement_delta_x
    CLC
    ADC      object_x_by_index,X
    STA      object_x_by_index,X
    LDA      object_y_by_index,X
    STA      saved_object_y_by_index,X
    CLC
    ADC      movement_delta_y
    STA      object_y_by_index,X
    JSR      compute_screen_ptr_for_object
    LDA      zp_screen_ptr_70_low
    STA      object_screen_low_by_index,X
    LDA      zp_screen_ptr_70_high
    STA      object_screen_high_by_index,X
    RTS

.apply_player_input_to_player_pair
    LDA      input_delta_x
    BNE      player_input_nonzero_delta_16e1
    LDA      input_delta_y
    BNE      player_input_nonzero_delta_16e1
    LDA      player_direction
    ASL      A
    ASL      A
    CLC
    ADC      #PLAYER_SECOND_GRAPHIC_STANDING_OFFSET
    STA      player_graphic_id_second_cell
    JMP      apply_input_delta_to_player_pair

.player_input_nonzero_delta_16e1
    LDX      input_delta_x
    LDY      input_delta_y
    JSR      direction_from_delta_xy
    STA      player_direction
    ASL      A
    ASL      A
    STA      player_graphic_id_first_cell
    STA      zp_scratch_3d
    LDA      frame_phase
    LSR      A
    LSR      A
    CMP      #PLAYER_ANIMATION_PHASE
    BNE      player_second_graphic_animation_store_16e1
    LDA      #PLAYER_ANIMATION_ALTERNATE_OFFSET

.player_second_graphic_animation_store_16e1
    CLC
    INC      zp_scratch_3d
    ADC      zp_scratch_3d
    STA      player_graphic_id_second_cell

.apply_input_delta_to_player_pair
    LDA      input_delta_x
    STA      movement_delta_x
    LDA      input_delta_y
    STA      movement_delta_y
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      move_object_and_update_screen_ptr
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JMP      move_object_and_update_screen_ptr

.add_direction_score_or_state_delta
    STX      saved_level_loop_seed_or_status
    LDA      player_direction_graphic_delta_table_16e1,X
    CLC
    ADC      room_area
    STA      room_area
    RTS

; FRAME SCHEDULER AND GAMEPLAY STATE
; ==================================

.start_or_reset_player_and_level_objects
    JSR      apply_level_palette
    INC      current_level_intro_or_loop_flag
    LDA      current_level_intro_or_loop_flag
    CMP      #LEVEL_AREA_ADVANCE_PERIOD
    BNE      setup_remaining_object_score_gate_1735
    LDA      level_index_and_hazard_gate
    CMP      #MAX_LEVEL_INDEX
    BEQ      setup_remaining_object_score_gate_1735
    INC      level_index_and_hazard_gate

.setup_remaining_object_score_gate_1735
    LDA      remaining_active_object_count
    BNE      setup_player_start_state_1735
    LDA      #ROOM_COMPLETION_SCORE_ADD
    JSR      increment_four_char_score_or_counter

.setup_player_start_state_1735
    JSR      draw_playfield_tiles
    LDX      saved_level_loop_seed_or_status
    STX      level_loop_seed_or_status
    LDA      player_start_x_by_exit_1735,X
    STA      player_x_first_cell
    STA      player_x_second_cell
    LDA      player_start_direction_by_exit_1735,X
    STA      player_direction
    LDA      player_start_first_graphic_by_exit_1735,X
    STA      player_graphic_id_first_cell
    LDA      player_start_second_graphic_by_exit_1735,X
    STA      player_graphic_id_second_cell
    LDA      #FRAME_PHASE_INITIAL
    STA      frame_phase
    LDA      player_start_y_by_exit_1735,X
    STA      player_y_first_cell
    CLC
    ADC      #PLAYER_CELL_Y_OFFSET
    STA      player_y_second_cell
    LDA      player_start_first_screen_low_by_exit_1735,X
    STA      player_screen_low_first_cell
    LDA      player_start_first_screen_high_by_exit_1735,X
    STA      player_screen_high_first_cell
    LDA      player_start_second_screen_low_by_exit_1735,X
    STA      player_screen_low_second_cell
    LDA      player_start_second_screen_high_by_exit_1735,X
    STA      player_screen_high_second_cell
    LDX      #SHOT_HAZARD_LAST_SLOT

.clear_shot_hazard_seed_loop_1735
    LDA      #SHOT_NOT_YET_VISIBLE
    STA      shot_visible_flag_by_slot,X
    LDA      #SHOT_HAZARD_INACTIVE_DIRECTION
    STA      shot_direction_or_inactive_by_slot,X
    DEX
    BPL      clear_shot_hazard_seed_loop_1735
    LDA      #ACTIVE_SHOT_COUNTS_CLEAR
    STA      active_player_shot_count
    STA      active_spawned_hazard_count
    JSR      draw_static_status_panel
    JSR      setup_spinner_clone_cyberdroid_counts
    JSR      place_target_code_objects_for_room
    LDA      #COLLISION_CLASS_PRESENT
    STA      bounds_or_outside_flag
    RTS

.frame_update_continue_or_delay
    LDA      transition_delay
    CMP      #TRANSITION_DELAY_FINAL_TICK
    BNE      transition_delay_active_countdown_17bf
    RTS

.transition_delay_active_countdown_17bf
    LDA      transition_delay
    BEQ      advance_frame_phase_mod16_17bf
    DEC      transition_delay

.advance_frame_phase_mod16_17bf
    INC      frame_phase
    LDA      frame_phase
    AND      #FRAME_PHASE_MASK
    STA      frame_phase
    BNE      phase_mod4_palette_gate_17bf

.tick_spook_release_timer_on_phase0
    LDA      spook_release_timer
    BEQ      phase_mod4_palette_gate_17bf
    JSR      release_spook_pair_when_timer_expires

.phase_mod4_palette_gate_17bf
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    BNE      phase_mod4_hit_animation_gate_17bf

.cycle_active_palette_triplet
    LDY      palette_cycle_row_index
    LDA      palette_cycle_logical13_values_17e4,Y
    LDX      #PALETTE_CYCLE_FIRST_LOGICAL_COLOUR
    JSR      vdu19_set_palette_or_colour
    LDA      palette_cycle_logical14_values_17e4,Y
    INX
    JSR      vdu19_set_palette_or_colour
    LDA      palette_cycle_logical15_values_17e4,Y
    INX
    JSR      vdu19_set_palette_or_colour
    INC      palette_cycle_row_index
    LDA      palette_cycle_row_index
    CMP      #PALETTE_CYCLE_VALUE_COUNT
    BNE      phase_mod4_hit_animation_gate_17bf
    LDA      #PALETTE_CYCLE_FIRST_ROW
    STA      palette_cycle_row_index

.phase_mod4_hit_animation_gate_17bf
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    BNE      run_active_object_scheduler_17bf

.erase_previous_hit_object_frame
    LDX      #FIRST_ITEM_OBJECT_INDEX
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch

.erase_hit_object_loop_1812
    STX      active_object_index
    LDA      object_lifecycle_base_for_indexed_refs,X
    CMP      #OBJECT_LIFECYCLE_HIT_FIRST_FRAME
    BMI      erase_hit_object_next_slot_1812
    LDA      object_lifecycle_base_for_indexed_refs,X
    CMP      #OBJECT_LIFECYCLE_HIT_END_EXCLUSIVE
    BNE      erase_hit_object_draw_current_1812
    LDA      #OBJECT_LIFECYCLE_INACTIVE
    STA      object_lifecycle_base_for_indexed_refs,X

.erase_hit_object_draw_current_1812
    JSR      draw_object_by_index

.erase_hit_object_next_slot_1812
    LDX      active_object_index
    INX
    CPX      #ITEM_OBJECT_END_EXCLUSIVE
    BNE      erase_hit_object_loop_1812

.run_active_object_scheduler_17bf
    JSR      update_active_spinner_clone_cyberdroid_objects
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    CMP      #FRAME_PLAYER_RENDER_PHASE
    BNE      frame_update
    LDA      transition_delay
    BNE      frame_update
    JSR      redraw_player_with_saved_graphic_pair

.frame_update
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    CMP      #FRAME_PLAYER_RENDER_PHASE
    BNE      after_visible_player_draw_gate_1849
    LDA      transition_delay
    BNE      after_visible_player_draw_gate_1849
    LDA      #RENDER_MODE_VISIBLE_PLAYER
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_by_index

.save_visible_player_graphic_pair_for_collision_redraw
    LDA      player_graphic_id_first_cell
    STA      saved_visible_player_graphic_id_first
    LDA      player_graphic_id_second_cell
    STA      saved_visible_player_graphic_id_second

.after_visible_player_draw_gate_1849
    JSR      move_spook_pair_towards_player
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    BNE      redraw_shot_hazard_slots_and_test_collisions

.advance_hit_object_animation_frame
    LDX      #FIRST_ITEM_OBJECT_INDEX
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch

.advance_hit_object_animation_loop_1876
    STX      active_object_index
    LDA      object_lifecycle_base_for_indexed_refs,X
    CMP      #OBJECT_LIFECYCLE_HIT_FIRST_FRAME
    BMI      advance_hit_object_animation_next_slot_1876
    CMP      #OBJECT_LIFECYCLE_HIT_END_EXCLUSIVE
    BPL      advance_hit_object_animation_next_slot_1876
    CLC
    ADC      #HIT_GRAPHIC_ID_BASE
    STA      object_graphic_id_by_index,X
    INC      object_lifecycle_base_for_indexed_refs,X
    JSR      draw_object_by_index

.advance_hit_object_animation_next_slot_1876
    LDX      active_object_index
    INX
    CPX      #ITEM_OBJECT_END_EXCLUSIVE
    BNE      advance_hit_object_animation_loop_1876

.redraw_shot_hazard_slots_and_test_collisions
    LDX      #SHOT_HAZARD_LAST_SLOT

.preinput_shot_hazard_scan_loop_189c
    STX      active_object_index
    JSR      erase_visible_shot_or_hazard_previous_bytes
    JSR      draw_active_shot_or_hazard_and_test
    LDX      active_object_index
    DEX
    BPL      preinput_shot_hazard_scan_loop_189c

.consume_projectile_spook_pause_collision_flag
    LDA      projectile_spook_pause_collision_flag
    BEQ      transition_delay_skip_input_gate_18c4
    LDA      #SPOOK_PAUSE_FRAME_COUNT
    STA      spook_pause_counter
    LDX      #SPOOK_PAUSE_PALETTE_LOGICAL_COLOUR
    LDA      #SPOOK_PAUSE_PALETTE_VALUE
    JSR      vdu19_set_palette_or_colour
    LDA      #PROJECTILE_SPOOK_COLLISION_CLEAR
    STA      projectile_spook_pause_collision_flag
    LDA      #SOUND_ID_SPOOK_COLLISION
    JSR      play_sound_id_if_enabled

.transition_delay_skip_input_gate_18c4
    LDA      transition_delay
    BEQ      input_bounds_and_player_collision_path_18cb
    JMP      move_shot_hazard_slots_and_spawn_new

.input_bounds_and_player_collision_path_18cb
    JSR      read_game_input_and_pause
    JSR      test_player_bounds_and_restart_area
    LDA      bounds_or_outside_flag
    BNE      bounds_flag_restart_frame_18cb
    STA      renderer_collision_accumulator
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    CMP      #FRAME_PLAYER_RENDER_PHASE
    BNE      move_shot_hazard_slots_and_spawn_new

.player_collision_movement_window
    LDA      #RENDER_MODE_PLAYER_COLLISION_TEST
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      renderer_collision_accumulator
    BNE      clear_player_before_life_loss_path_18df
    JSR      test_player_spook_pair_overlap
    LDA      renderer_collision_accumulator
    BNE      clear_player_before_life_loss_path_18df
    JSR      apply_player_input_to_player_pair
    LDA      #PLAYER_COLLISION_FLAGS_CLEAR
    STA      player_collision_class_flag
    STA      target_collect_collision_flag
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    LDA      #RENDER_MODE_TARGET_COLLISION_TEST
    STA      render_mode_or_text_scratch
    JSR      draw_object_by_index
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      target_collect_collision_flag
    BEQ      player_collision_class_check_18df
    JSR      handle_collected_target_or_level_done
    JSR      draw_lives_or_target_status

.player_collision_class_check_18df
    LDA      player_collision_class_flag
    BEQ      renderer_collision_high_bits_check_18df
    JMP      player_collision_flash_sequence

.bounds_flag_restart_frame_18cb
    JMP      frame_update

.renderer_collision_high_bits_check_18df
    LDA      renderer_collision_accumulator
    AND      #RENDERER_FATAL_COLLISION_MASK
    BEQ      move_shot_hazard_slots_and_spawn_new
    JSR      redraw_player_with_saved_graphic_pair
    JSR      lose_life_and_reset_player
    JMP      move_shot_hazard_slots_and_spawn_new

.clear_player_before_life_loss_path_18df
    JSR      clear_player_cells_before_life_loss

.move_shot_hazard_slots_and_spawn_new
    LDA      #SHOT_HAZARD_LAST_SLOT
    STA      active_object_index

.move_shot_hazard_slots_loop_1937
    LDX      active_object_index
    JSR      move_active_shot_or_hazard
    DEC      active_object_index
    BPL      move_shot_hazard_slots_loop_1937
    LDA      transition_delay
    BNE      expire_shot_hazard_slots_after_draw
    JSR      spawn_player_shot_if_fire_pressed
    JSR      maybe_spawn_hazard_from_moving_object

.expire_shot_hazard_slots_after_draw
    LDA      #SHOT_HAZARD_LAST_SLOT
    STA      active_object_index

.expire_shot_hazard_slots_loop_194e
    LDX      active_object_index
    JSR      expire_projectile_or_hazard_on_collision
    DEC      active_object_index
    BPL      expire_shot_hazard_slots_loop_194e
    JMP      frame_update_continue_or_delay

.unused_player_hit_dispatch_bridge
    ; Unreferenced alternate entry retained byte-for-byte.
    JSR      handle_player_hit_from_active_object
    JMP      move_shot_hazard_slots_and_spawn_new

.handle_player_hit_from_active_object
    LDA      frame_phase
    AND      #FRAME_QUARTER_MASK
    CMP      #FRAME_PLAYER_RENDER_PHASE
    BEQ      clear_player_cells_before_life_loss
    JSR      redraw_player_with_saved_graphic_pair
    JMP      jump_to_life_loss_after_player_redraw_1964

.clear_player_cells_before_life_loss
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_by_index

.jump_to_life_loss_after_player_redraw_1964
    JMP      lose_life_and_reset_player

.cancel_player_movement_delta
    LDA      #PLAYER_INPUT_DELTA_CLEAR
    STA      input_delta_x
    STA      input_delta_y
    JMP      apply_input_delta_to_player_pair

.update_active_spinner_clone_cyberdroid_objects
    LDX      #FIRST_ITEM_OBJECT_INDEX

.scan_next_active_moving_object
    STX      active_object_index
    LDA      object_lifecycle_base_for_indexed_refs,X
    CMP      #OBJECT_LIFECYCLE_ACTIVE
    BNE      advance_active_moving_object_slot
    LDA      object_graphic_id_by_index,X
    CMP      #graphic_id_spinner
    BNE      test_active_clone_object
    TXA
    AND      #FRAME_PHASE_MASK
    CMP      frame_phase
    BNE      test_active_clone_object
    JSR      begin_target_enemy_move_test
    JSR      move_spinner_towards_player_x_then_y
    JSR      end_target_enemy_move_test
    JMP      advance_active_moving_object_slot

.test_active_clone_object
    LDA      object_graphic_id_by_index,X
    CMP      #graphic_id_clone
    BNE      test_active_cyberdroid_object
    TXA
    AND      #CLONE_FRAME_PHASE_MASK
    STA      zp_indirect_74_low
    LDA      frame_phase
    AND      #CLONE_FRAME_PHASE_MASK
    CMP      zp_indirect_74_low
    BNE      test_active_cyberdroid_object
    JSR      begin_target_enemy_move_test
    JSR      move_clone_continue_or_random
    JSR      end_target_enemy_move_test
    JMP      advance_active_moving_object_slot

.test_active_cyberdroid_object
    LDA      object_graphic_id_by_index,X
    CMP      #graphic_id_cyberdroid
    BNE      advance_active_moving_object_slot
    TXA
    AND      #FRAME_PHASE_MASK
    CMP      frame_phase
    BNE      advance_active_moving_object_slot
    JSR      begin_target_enemy_move_test
    JSR      move_cyberdroid_persistent
    JSR      end_target_enemy_move_test
    JMP      advance_active_moving_object_slot

.advance_active_moving_object_slot
    LDX      active_object_index
    INX
    CPX      #ITEM_OBJECT_END_EXCLUSIVE
    BNE      scan_next_active_moving_object
    RTS

.player_collision_flash_sequence
    LDA      #SOUND_ID_PLAYER_COLLISION
    JSR      play_sound_id_if_enabled
    LDA      player_graphic_id_first_cell
    STA      movement_delta_x
    LDA      player_graphic_id_second_cell
    STA      movement_delta_y
    LDA      #PLAYER_COLLISION_FLASH_COUNT
    STA      frame_phase

.player_collision_flash_next_frame
    JSR      wait_one_frame_tick
    LDA      frame_phase
    AND      #FRAME_PHASE_MASK
    LDX      #PLAYER_COLLISION_FLASH_PALETTE_LOGICAL
    JSR      vdu19_set_palette_or_colour
    LDA      #PLAYER_COLLISION_FLASH_FIRST_GRAPHIC
    STA      player_graphic_id_first_cell
    LDA      #PLAYER_COLLISION_FLASH_SECOND_GRAPHIC
    STA      player_graphic_id_second_cell
    LDA      #RENDER_MODE_VISIBLE_PLAYER
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    JSR      wait_one_frame_tick
    LDA      movement_delta_x
    STA      player_graphic_id_first_cell
    LDA      movement_delta_y
    STA      player_graphic_id_second_cell
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    DEC      frame_phase
    BPL      player_collision_flash_next_frame
    LDA      #RENDER_MODE_FINAL_PLAYER_ERASE
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    JSR      lose_life_and_reset_player
    JMP      move_shot_hazard_slots_and_spawn_new

.lose_life_and_reset_player
    DEC      lives_status_count
    JSR      draw_lives_or_target_status
    LDA      #SOUND_ID_LIFE_LOST
    JSR      play_sound_id_if_enabled
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    LDA      saved_player_second_screen_low
    SEC
    SBC      #PLAYER_RESET_FIRST_SCREEN_LOW_DELTA
    STA      player_screen_low_first_cell
    LDA      saved_player_second_screen_high
    SBC      #POINTER_PAGE_CARRY
    STA      player_screen_high_first_cell
    LDA      saved_player_second_cell_y
    STA      player_y_first_cell
    STA      player_y_second_cell
    LDA      saved_player_second_screen_low
    CLC
    ADC      #PLAYER_RESET_SECOND_SCREEN_LOW_DELTA
    STA      player_screen_low_second_cell
    LDA      saved_player_second_screen_high
    ADC      #POINTER_PAGE_CARRY
    STA      player_screen_high_second_cell
    LDA      #PLAYER_RESET_FIRST_GRAPHIC
    STA      player_graphic_id_first_cell
    LDA      #PLAYER_RESET_SECOND_GRAPHIC
    STA      player_graphic_id_second_cell
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_by_index
    LDA      #PLAYER_RESET_TRANSITION_DELAY
    STA      transition_delay
    RTS

.test_player_bounds_and_restart_area
    LDA      #BOUNDS_INSIDE
    STA      bounds_or_outside_flag
    LDA      player_x_first_cell
    CMP      #PLAYER_LEFT_BOUNDARY
    BPL      test_player_right_boundary
    LDX      #AREA_EXIT_LEFT
    JMP      restart_after_area_transition

.test_player_right_boundary
    CMP      #PLAYER_RIGHT_BOUNDARY
    BMI      test_player_vertical_boundaries
    LDX      #AREA_EXIT_RIGHT
    JMP      restart_after_area_transition

.test_player_vertical_boundaries
    LDA      player_y_first_cell
    CMP      #PLAYER_TOP_BOUNDARY
    BPL      test_player_bottom_boundary
    LDX      #AREA_EXIT_TOP
    JMP      restart_after_area_transition

.test_player_bottom_boundary
    CMP      #PLAYER_BOTTOM_BOUNDARY
    BMI      return_from_bounds_or_invisible_shot
    LDX      #AREA_EXIT_BOTTOM
    JMP      restart_after_area_transition

.return_from_bounds_or_invisible_shot
    RTS

.restart_after_area_transition
    JSR      add_direction_score_or_state_delta
    JSR      clear_all_palette_entries
    LDA      #VDU_CLEAR_SCREEN
    JSR      MOS_OSWRCH
    JMP      start_or_reset_player_and_level_objects

; SHOTS AND MOVING HAZARDS
; ========================

.erase_visible_shot_or_hazard_previous_bytes
    LDA      shot_visible_flag_by_slot,X
    BEQ      return_from_bounds_or_invisible_shot
    LDA      shot_screen_low_previous,X
    STA      zp_screen_ptr_70_low
    LDA      shot_screen_high_previous,X
    STA      zp_screen_ptr_70_high
    LDY      #SHOT_LAST_BITMAP_BYTE

.erase_next_shot_or_hazard_byte
    LDA      (zp_screen_ptr_70_low),Y
    EOR      #SHOT_XOR_BITMAP
    STA      (zp_screen_ptr_70_low),Y
    DEY
    BPL      erase_next_shot_or_hazard_byte
    LDA      shot_direction_or_inactive_by_slot,X
    BPL      return_from_shot_or_hazard_deactivation
    LDA      #SHOT_NOT_YET_VISIBLE
    STA      shot_visible_flag_by_slot,X

.return_from_shot_or_hazard_deactivation
    RTS

.draw_active_shot_or_hazard_and_test
    LDA      #COLLISION_ACCUMULATOR_CLEAR
    STA      renderer_collision_accumulator
    LDA      shot_direction_or_inactive_by_slot,X
    BMI      return_from_bounds_or_invisible_shot
    LDA      #SHOT_VISIBLE
    STA      shot_visible_flag_by_slot,X
    LDA      shot_screen_low_current,X
    STA      zp_screen_ptr_70_low
    LDA      shot_screen_high_current,X
    STA      zp_screen_ptr_70_high
    LDY      #SHOT_LAST_BITMAP_BYTE

.accumulate_next_shot_collision_byte
    LDA      (zp_screen_ptr_70_low),Y
    AND      #SHOT_COLLISION_PIXEL_MASK
    ORA      renderer_collision_accumulator
    STA      renderer_collision_accumulator
    LDA      (zp_screen_ptr_70_low),Y
    EOR      #SHOT_XOR_BITMAP
    STA      (zp_screen_ptr_70_low),Y
    DEY
    BPL      accumulate_next_shot_collision_byte
    LDA      renderer_collision_accumulator
    BNE      dispatch_shot_or_hazard_collisions
    RTS

.dispatch_shot_or_hazard_collisions
    JMP      handle_shot_or_hazard_overlap_collisions

.expire_projectile_or_hazard_on_collision
    LDA      shot_direction_or_inactive_by_slot,X
    BMI      return_from_bounds_or_invisible_shot
    LDA      #PROJECTILE_SPOOK_COLLISION_CLEAR
    STA      projectile_spook_pause_collision_flag
    LDA      shot_screen_low_current,X
    STA      zp_screen_ptr_70_low
    LDA      shot_screen_high_current,X
    STA      zp_screen_ptr_70_high
    LDY      #SHOT_LAST_BITMAP_BYTE

.inspect_next_shot_collision_byte
    LDA      (zp_screen_ptr_70_low),Y
    AND      #SHOT_COLLISION_PIXEL_MASK
    CMP      #SHOT_COLLISION_SPOOK_PATTERN
    BEQ      mark_projectile_spook_pause_collision
    CMP      #SHOT_COLLISION_PLAYER_PATTERN
    BEQ      deactivate_shot_or_hazard_slot
    CMP      #SHOT_COLLISION_PLAYER_EDGE_PATTERN
    BEQ      deactivate_shot_or_hazard_slot
    CMP      #SHOT_COLLISION_TARGET_PATTERN
    BEQ      deactivate_shot_or_hazard_slot
    DEY
    BPL      inspect_next_shot_collision_byte
    JSR      test_projectile_inside_playfield
    LDA      bounds_or_outside_flag
    BNE      deactivate_shot_or_hazard_slot
    RTS

.mark_projectile_spook_pause_collision
    INC      projectile_spook_pause_collision_flag

.deactivate_shot_or_hazard_slot
    LDA      #SHOT_HAZARD_INACTIVE_DIRECTION
    STA      shot_direction_or_inactive_by_slot,X
    CPX      #FIRST_HAZARD_SLOT
    BPL      decrement_active_hazard_count
    DEC      active_player_shot_count
    RTS

.decrement_active_hazard_count
    DEC      active_spawned_hazard_count
    RTS

.move_active_shot_or_hazard
    LDY      shot_direction_or_inactive_by_slot,X
    BMI      return_from_shot_screen_pointer_update
    LDA      shot_screen_low_current,X
    STA      shot_screen_low_previous,X
    STA      zp_screen_ptr_70_low
    LDA      shot_screen_high_current,X
    STA      shot_screen_high_previous,X
    STA      zp_screen_ptr_70_high
    LDA      shot_x_by_slot,X
    CLC
    ADC      projectile_grid_x_delta_by_dir_1b87,Y
    STA      shot_x_by_slot,X
    LDA      shot_y_by_slot,X
    CLC
    ADC      projectile_grid_y_delta_by_dir_1b87,Y
    STA      shot_y_by_slot,X
    CLC
    LDA      shot_screen_low_current,X
    ADC      projectile_ptr_low_delta_by_dir_1b87,Y
    STA      shot_screen_low_current,X
    LDA      shot_screen_high_current,X
    ADC      projectile_ptr_high_delta_by_dir_1b87,Y
    STA      shot_screen_high_current,X
    LDA      projectile_grid_y_delta_by_dir_1b87,Y
    BEQ      return_from_shot_screen_pointer_update
    BPL      adjust_even_y_shot_screen_row
    LDA      shot_y_by_slot,X
    AND      #SHOT_ROW_PARITY_MASK
    BEQ      return_from_shot_screen_pointer_update
    LDA      shot_screen_low_current,X
    SEC
    SBC      #SHOT_ODD_ROW_WRAP_LOW
    STA      shot_screen_low_current,X
    LDA      shot_screen_high_current,X
    SBC      #SHOT_ODD_ROW_WRAP_HIGH
    STA      shot_screen_high_current,X

.return_from_shot_screen_pointer_update
    RTS

.adjust_even_y_shot_screen_row
    LDA      shot_y_by_slot,X
    AND      #SHOT_ROW_PARITY_MASK
    BNE      return_from_shot_screen_pointer_update
    LDA      shot_screen_low_current,X
    CLC
    ADC      #SHOT_ODD_ROW_WRAP_LOW
    STA      shot_screen_low_current,X
    LDA      shot_screen_high_current,X
    ADC      #SHOT_ODD_ROW_WRAP_HIGH
    STA      shot_screen_high_current,X
    RTS

.compute_shot_screen_ptr
    STX      zp_indirect_74_low
    LDA      shot_y_by_slot,X
    AND      #SHOT_EVEN_Y_MASK
    ASL      A
    ASL      A
    STA      zp_screen_ptr_70_low
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    LDA      shot_y_by_slot,X
    AND      #SHOT_EVEN_Y_MASK
    JSR      add_a_to_pointer_70
    LDX      #SHOT_SCREEN_Y_SHIFT_COUNT
    JSR      shift_pointer_70_left_x_times
    LDX      zp_indirect_74_low
    LDA      shot_y_by_slot,X
    AND      #SHOT_ROW_PARITY_MASK
    BEQ      add_shot_horizontal_screen_offset
    LDA      #SHOT_ODD_SCANLINE_OFFSET
    JSR      add_a_to_pointer_70

.add_shot_horizontal_screen_offset
    LDA      shot_x_by_slot,X
    STA      zp_calc_ptr_72_low
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_calc_ptr_72_high
    LDX      #SHOT_SCREEN_X_SHIFT_COUNT
    JSR      shift_pointer_72_left_x_times
    LDA      #BITMAP_SCREEN_BASE_HIGH
    CLC
    ADC      zp_screen_ptr_70_high
    STA      zp_screen_ptr_70_high
    LDX      zp_indirect_74_low
    LDA      zp_screen_ptr_70_low
    CLC
    ADC      zp_calc_ptr_72_low
    STA      shot_screen_low_current,X
    LDA      zp_screen_ptr_70_high
    ADC      zp_calc_ptr_72_high
    STA      shot_screen_high_current,X
    RTS

.spawn_player_shot_if_fire_pressed
    LDA      fire_edge_request
    BEQ      return_from_player_shot_request
    LDA      #FIRE_EDGE_CLEAR
    STA      fire_edge_request
    LDA      active_player_shot_count
    CMP      #PLAYER_SHOT_LIMIT
    BEQ      return_from_player_shot_request
    INC      active_player_shot_count
    LDX      #PLAYER_SHOT_SLOT_BEFORE_FIRST

.find_inactive_player_shot_slot
    INX
    LDA      shot_direction_or_inactive_by_slot,X
    BPL      find_inactive_player_shot_slot
    LDA      player_direction
    STA      shot_direction_or_inactive_by_slot,X
    TAY
    LDA      #SOUND_ID_PLAYER_SHOT
    STA      shot_visible_flag_by_slot,X
    LDA      player_x_first_cell
    CLC
    ADC      player_shot_x_offsets_1c4d,Y
    STA      shot_x_by_slot,X
    LDA      player_y_first_cell
    CLC
    ADC      player_shot_y_offsets_1c4d,Y
    STA      shot_y_by_slot,X
    JSR      compute_shot_screen_ptr
    LDA      #SOUND_ID_PLAYER_SHOT
    JSR      play_sound_id_if_enabled

.return_from_player_shot_request
    RTS

.test_projectile_inside_playfield
    LDA      #BOUNDS_INSIDE
    STA      bounds_or_outside_flag
    LDA      shot_x_by_slot,X
    CMP      #PROJECTILE_LEFT_BOUNDARY
    BMI      mark_projectile_outside_playfield
    CMP      #PROJECTILE_RIGHT_BOUNDARY
    BPL      mark_projectile_outside_playfield
    LDA      shot_y_by_slot,X
    CMP      #PROJECTILE_TOP_BOUNDARY
    BMI      mark_projectile_outside_playfield
    CMP      #PROJECTILE_BOTTOM_BOUNDARY
    BPL      mark_projectile_outside_playfield
    RTS

.mark_projectile_outside_playfield
    INC      bounds_or_outside_flag
    RTS

; STATUS, RANDOM PLACEMENT AND ROOM TRANSITIONS
; =============================================

.draw_static_status_panel
    LDA      #STATUS_PANEL_FIRST_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #STATUS_PANEL_FIRST_SCREEN_LOW
    STA      object_screen_low_by_index
    LDA      #STATUS_PANEL_Y_OFFSET
    STA      object_y_by_index
    LDA      #STATUS_LABEL_GRAPHIC_0
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_LABEL_GRAPHIC_1
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_LABEL_GRAPHIC_2
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_LABEL_GRAPHIC_3
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_LABEL_GRAPHIC_4
    JSR      draw_status_glyph_at_current_ptr
    JSR      draw_score_counter_digits
    JSR      draw_lives_or_target_status
    LDA      #STATUS_FIXED_PIXEL_PATTERN
    STA      status_panel_fixed_pixel_left
    STA      status_panel_fixed_pixel_right
    LDA      #STATUS_PANEL_SECOND_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #STATUS_PANEL_SECOND_SCREEN_LOW
    STA      object_screen_low_by_index
    LDA      #STATUS_SECOND_LABEL_GRAPHIC_0
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_SECOND_LABEL_GRAPHIC_1
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_SECOND_LABEL_GRAPHIC_2
    JSR      draw_status_glyph_at_current_ptr
    LDA      #STATUS_SECOND_LABEL_GRAPHIC_3
    JSR      draw_status_glyph_at_current_ptr
    JSR      advance_status_glyph_ptr
    LDA      room_area
    AND      #ROOM_AREA_LOW_NIBBLE_MASK
    CMP      #ROOM_NUMBER_DOUBLE_DIGIT_THRESHOLD
    BMI      draw_single_digit_room_number
    LDA      #ROOM_NUMBER_TENS_ONE_GRAPHIC
    JSR      draw_status_glyph_at_current_ptr
    LDA      room_area
    AND      #ROOM_AREA_LOW_NIBBLE_MASK
    CLC
    ADC      #ROOM_NUMBER_DOUBLE_DIGIT_UNITS_OFFSET
    JSR      draw_status_glyph_at_current_ptr
    JMP      draw_status_level_number

.draw_single_digit_room_number
    JSR      advance_status_glyph_ptr
    LDA      room_area
    AND      #ROOM_AREA_LOW_NIBBLE_MASK
    CLC
    ADC      #ROOM_NUMBER_SINGLE_DIGIT_OFFSET
    JSR      draw_status_glyph_at_current_ptr

.draw_status_level_number
    JSR      advance_status_glyph_ptr
    LDA      level_tens_digit
    ADC      #LEVEL_NUMBER_DIGIT_GRAPHIC_OFFSET
    JSR      draw_status_glyph_at_current_ptr
    LDA      level_units_digit
    ADC      #LEVEL_NUMBER_DIGIT_GRAPHIC_OFFSET
    JMP      draw_status_glyph_at_current_ptr

.draw_status_glyph_at_current_ptr
    STA      object_graphic_id_by_index
    LDA      #RENDER_MODE_STATUS_ERASE
    STA      render_mode_or_text_scratch
    LDX      #STATUS_RENDER_OBJECT_INDEX
    JSR      draw_object_by_index
    DEC      render_mode_or_text_scratch
    LDX      #STATUS_RENDER_OBJECT_INDEX
    JSR      draw_object_by_index

.advance_status_glyph_ptr
    LDA      object_screen_low_by_index
    CLC
    ADC      #STATUS_GLYPH_SCREEN_STEP
    STA      object_screen_low_by_index
    LDA      object_screen_high_by_index
    ADC      #POINTER_PAGE_CARRY
    STA      object_screen_high_by_index
    RTS

.rng_next_byte
    LDY      #RNG_OUTPUT_BIT_COUNT
    LDA      #RNG_OUTPUT_CLEAR
    STA      rng_output_byte

.generate_next_rng_output_bit
    LDA      rng_shift_register_low
    AND      #RNG_FEEDBACK_TAP_MASK
    ADC      #RNG_FEEDBACK_ADC_BIAS
    ASL      A
    ASL      A
    ROL      rng_shift_register_high
    ROL      rng_shift_register_middle
    ROL      rng_shift_register_low
    LDA      rng_shift_register_low
    LSR      A
    LSR      A
    AND      #RNG_OUTPUT_TAP_MASK
    ASL      rng_output_byte
    ORA      rng_output_byte
    STA      rng_output_byte
    DEY
    BNE      generate_next_rng_output_bit
    RTS

.compute_item_screen_ptr
    STX      zp_indirect_74_low
    LDA      object_y_by_index,X
    AND      #ITEM_SCREEN_Y_MASK
    ASL      A
    ASL      A
    STA      zp_screen_ptr_70_low
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    LDA      object_y_by_index,X
    AND      #ITEM_SCREEN_Y_MASK
    JSR      add_a_to_pointer_70
    LDX      #ITEM_SCREEN_Y_SHIFT_COUNT
    JSR      shift_pointer_70_left_x_times
    LDX      zp_indirect_74_low
    LDA      object_x_by_index,X
    STA      zp_calc_ptr_72_low
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_calc_ptr_72_high
    LDX      #ITEM_SCREEN_X_SHIFT_COUNT
    JSR      shift_pointer_72_left_x_times
    LDA      #BITMAP_SCREEN_BASE_HIGH
    CLC
    ADC      zp_screen_ptr_70_high
    STA      zp_screen_ptr_70_high
    LDX      zp_indirect_74_low
    LDA      zp_screen_ptr_70_low
    CLC
    ADC      zp_calc_ptr_72_low
    STA      object_screen_low_by_index,X
    LDA      zp_screen_ptr_70_high
    ADC      zp_calc_ptr_72_high
    STA      object_screen_high_by_index,X
    LDA      #ITEM_SCREEN_POINTER_RETURN_A
    RTS

.set_item_graphic_and_random_place
    LDX      logical_item_slot_index
    STA      item_graphic_id_alias_object_14,X

.random_place_item
    JSR      rng_next_byte
    LDX      logical_item_slot_index
    AND      #RANDOM_ITEM_COORDINATE_MASK
    STA      item_x_alias_object_14,X
    JSR      rng_next_byte
    LDX      logical_item_slot_index
    AND      #RANDOM_ITEM_X_SECOND_MASK
    CLC
    ADC      item_x_alias_object_14,X
    ADC      #RANDOM_ITEM_COORDINATE_BIAS
    STA      item_x_alias_object_14,X
    JSR      rng_next_byte
    LDX      logical_item_slot_index
    AND      #RANDOM_ITEM_COORDINATE_MASK
    CLC
    ADC      #RANDOM_ITEM_COORDINATE_BIAS
    STA      item_y_alias_object_14,X
    LDA      player_x_first_cell
    SBC      item_x_alias_object_14,X
    BPL      compare_item_horizontal_distance
    EOR      #SIGNED_ONES_COMPLEMENT_MASK

.compare_item_horizontal_distance
    CMP      #RANDOM_ITEM_MINIMUM_X_DISTANCE
    BPL      test_item_candidate_position
    LDA      player_y_first_cell
    SEC
    SBC      item_y_alias_object_14,X
    BPL      compare_item_vertical_distance
    EOR      #SIGNED_ONES_COMPLEMENT_MASK

.compare_item_vertical_distance
    CMP      #RANDOM_ITEM_MINIMUM_Y_DISTANCE
    BMI      random_place_item

.test_item_candidate_position
    TXA
    CLC
    ADC      #LOGICAL_ITEM_TO_OBJECT_INDEX
    TAX
    STX      zp_scratch_77
    JSR      compute_item_screen_ptr
    LDA      #COLLISION_ACCUMULATOR_CLEAR
    STA      renderer_collision_accumulator
    LDA      #RENDER_MODE_PLACEMENT_COLLISION_TEST
    STA      render_mode_or_text_scratch
    JSR      draw_object_by_index
    LDA      renderer_collision_accumulator
    BNE      random_place_item
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    LDX      zp_scratch_77
    JSR      draw_object_by_index
    INC      logical_item_slot_index
    RTS

.setup_spinner_clone_cyberdroid_counts
    LDA      #graphic_id_spook_first_cell
    STA      spook_graphic_id_first_cell
    LDA      #graphic_id_spook_second_cell
    STA      spook_graphic_id_second_cell
    LDX      level_index_and_hazard_gate
    LDA      spook_release_timer_by_level_index_1e3a,X
    STA      spook_release_timer
    LDA      spinner_count_by_level_index_1e3a,X
    STA      pending_spinner_count
    LDA      clone_count_by_level_index_1e3a,X
    STA      pending_clone_count
    LDA      cyberdroid_count_by_level_index_1e3a,X
    STA      pending_cyberdroid_count
    LDX      #ITEM_ENEMY_STATE_LAST_INDEX
    LDA      #ITEM_ENEMY_STATE_CLEAR

.clear_item_and_enemy_state_loop
    STA      item_state_alias_object_14,X
    STA      item_delta_x_by_slot,X
    STA      item_delta_y_by_slot,X
    DEX
    BPL      clear_item_and_enemy_state_loop
    LDA      pending_spinner_count
    CLC
    ADC      pending_clone_count
    ADC      pending_cyberdroid_count
    STA      logical_item_slot_index
    STA      remaining_active_object_count
    TAX
    DEX
    LDA      #OBJECT_LIFECYCLE_ACTIVE

.mark_initial_active_enemy_slots_loop
    STA      item_state_alias_object_14,X
    DEX
    BPL      mark_initial_active_enemy_slots_loop
    LDA      #FIRST_LOGICAL_ITEM_SLOT
    STA      logical_item_slot_index

.place_next_spinner
    DEC      pending_spinner_count
    BMI      place_next_clone
    LDA      #graphic_id_spinner
    JSR      set_item_graphic_and_random_place
    JMP      place_next_spinner

.place_next_clone
    DEC      pending_clone_count
    BMI      place_next_cyberdroid
    LDA      #graphic_id_clone
    JSR      set_item_graphic_and_random_place
    JMP      place_next_clone

.place_next_cyberdroid
    DEC      pending_cyberdroid_count
    BMI      return_from_enemy_placement
    LDA      #graphic_id_cyberdroid
    JSR      set_item_graphic_and_random_place
    JMP      place_next_cyberdroid

.return_from_enemy_placement
    RTS

.read_object0_screen_byte_at_temp_position
    LDX      #STATUS_RENDER_OBJECT_INDEX
    JSR      compute_item_screen_ptr
    LDA      object_screen_low_by_index
    STA      zp_screen_ptr_70_low
    LDA      object_screen_high_by_index
    STA      zp_screen_ptr_70_high
    LDY      #GRAPHIC_RECORD_FIRST_BYTE_INDEX
    LDA      (zp_screen_ptr_70_low),Y
    STA      renderer_collision_accumulator
    RTS

.fill_room_masked_forward_screen_gaps
    LDX      room_area
    LDA      initial_screen_room_feature_mask_1ec8_1f19,X
    BNE      setup_forward_room_gap_scan
    RTS

.setup_forward_room_gap_scan
    LDA      room_tile_column_or_fill_index
    CLC
    ADC      room_tile_column_or_fill_index
    ADC      room_tile_column_or_fill_index
    ADC      #ROOM_GAP_FORWARD_X_BIAS
    STA      object_x_by_index
    LDA      #graphic_id_room_fill_probe
    STA      object_graphic_id_by_index
    LDA      #ROOM_GAP_FIRST_SCREEN_Y
    STA      object_y_by_index
    LDA      #ROOM_GAP_STATE_CLEAR
    STA      room_gap_transition_pending
    STA      room_gap_previous_screen_byte

.scan_next_forward_room_gap_position
    JSR      read_object0_screen_byte_at_temp_position
    BEQ      fill_forward_gap_after_transition
    LDA      room_gap_transition_pending
    EOR      #ROOM_GAP_TRANSITION_TOGGLE_MASK
    STA      room_gap_transition_pending
    JMP      advance_forward_room_gap_scan

.fill_forward_gap_after_transition
    LDA      room_gap_transition_pending
    BEQ      advance_forward_room_gap_scan
    JSR      copy_level_modulo_24byte_fill_pattern

.advance_forward_room_gap_scan
    LDA      renderer_collision_accumulator
    STA      room_gap_previous_screen_byte
    INC      object_y_by_index
    INC      object_y_by_index
    LDA      object_y_by_index
    CMP      #ROOM_GAP_END_Y
    BMI      scan_next_forward_room_gap_position

.return_from_room_gap_fill
    RTS

.fill_room_masked_offset_screen_gaps
    LDX      room_area
    LDA      initial_screen_room_feature_mask_1ec8_1f19,X
    BEQ      return_from_room_gap_fill
    LDA      room_tile_column_or_fill_index
    BEQ      return_from_room_gap_fill
    LDA      room_tile_column_or_fill_index
    CLC
    ADC      room_tile_column_or_fill_index
    ADC      room_tile_column_or_fill_index
    SEC
    SBC      #ROOM_GAP_OFFSET_X_BIAS
    STA      object_x_by_index
    LDA      #graphic_id_room_fill_probe
    STA      object_graphic_id_by_index
    LDA      #ROOM_GAP_FIRST_SCREEN_Y
    STA      object_y_by_index

.scan_next_offset_room_gap_position
    JSR      read_object0_screen_byte_at_temp_position
    BEQ      advance_offset_room_gap_scan
    LDA      #ROOM_GAP_ADJACENT_SCREEN_STEP
    JSR      add_a_to_pointer_70
    LDA      zp_screen_ptr_70_low
    STA      object_screen_low_by_index
    LDA      zp_screen_ptr_70_high
    STA      object_screen_high_by_index
    LDY      #GRAPHIC_RECORD_FIRST_BYTE_INDEX
    LDA      (zp_screen_ptr_70_low),Y
    BNE      advance_offset_room_gap_scan
    JSR      copy_level_modulo_24byte_fill_pattern

.advance_offset_room_gap_scan
    INC      object_y_by_index
    INC      object_y_by_index
    LDA      object_y_by_index
    CMP      #ROOM_GAP_END_Y
    BMI      scan_next_offset_room_gap_position
    RTS

; PALETTE AND MOVING ENTITY BEHAVIOUR
; ===================================

.clear_all_palette_entries
    LDX      #PALETTE_LAST_LOGICAL_COLOUR
    LDA      #PALETTE_CLEAR_VALUE

.clear_palette_entry_loop_1f66
    JSR      vdu19_set_palette_or_colour
    DEX
    BPL      clear_palette_entry_loop_1f66
    RTS

.apply_level_palette
    LDX      #PALETTE_LAST_LOGICAL_COLOUR

.apply_base_palette_entry_loop_1f71
    LDA      base_palette_table_1f71,X
    JSR      vdu19_set_palette_or_colour
    DEX
    BPL      apply_base_palette_entry_loop_1f71
    LDA      level_units_digit
    AND      #LEVEL_PALETTE_INDEX_MASK
    LDX      #LEVEL_PALETTE_LOGICAL_COLOUR_9
    JSR      vdu19_set_palette_or_colour
    LDA      level_units_digit
    AND      #LEVEL_PALETTE_INDEX_MASK
    TAX
    LDA      level_palette_logical8_by_level_units_mod8,X
    LDX      #LEVEL_PALETTE_LOGICAL_COLOUR_8
    JMP      vdu19_set_palette_or_colour

.unused_erase_object_then_restore_entry
    ; Unreferenced entry that erases the active object, selects render mode 5,
    ; and falls through to restore_object_position_and_ptr.
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    JSR      draw_object_by_index
    LDX      active_object_index
    LDA      #RENDER_MODE_OBJECT_COLLISION_TEST
    STA      render_mode_or_text_scratch

.restore_object_position_and_ptr
    LDA      saved_object_y_by_index,X
    STA      object_y_by_index,X
    LDA      saved_object_screen_low_by_index,X
    STA      object_screen_low_by_index,X
    LDA      saved_object_screen_high_by_index,X
    STA      object_screen_high_by_index,X
    LDA      object_x_by_index,X
    SEC
    SBC      movement_delta_x
    STA      object_x_by_index,X
    RTS

.test_object_inside_playfield
    LDA      #OBJECT_MOVEMENT_FAILED
    STA      bounds_or_outside_flag
    LDA      object_x_by_index,X
    CMP      #OBJECT_LEFT_BOUNDARY
    BMI      mark_object_outside_playfield
    CMP      #OBJECT_RIGHT_BOUNDARY
    BPL      mark_object_outside_playfield
    LDA      object_y_by_index,X
    CMP      #OBJECT_TOP_BOUNDARY
    BMI      mark_object_outside_playfield
    CMP      #OBJECT_BOTTOM_BOUNDARY
    BPL      mark_object_outside_playfield
    RTS

.mark_object_outside_playfield
    INC      bounds_or_outside_flag
    RTS

.begin_target_enemy_move_test
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    STA      movement_delta_x
    STA      movement_delta_y
    JSR      draw_object_by_index
    LDX      active_object_index
    LDA      #RENDER_MODE_OBJECT_COLLISION_TEST
    STA      render_mode_or_text_scratch
    RTS

.end_target_enemy_move_test
    LDX      active_object_index
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    JSR      draw_object_by_index
    RTS

.move_spinner_towards_player_x_then_y
    JSR      delta_towards_player_for_object_x
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      retry_spinner_move_on_horizontal_axis
    RTS

.retry_spinner_move_on_horizontal_axis
    LDX      active_object_index
    JSR      restore_object_position_and_ptr
    LDA      #MOVEMENT_DELTA_NONE
    STA      movement_delta_x
    STA      movement_delta_y
    LDA      player_x_first_cell
    CMP      object_x_by_index,X
    BEQ      try_spinner_horizontal_move
    BMI      set_spinner_horizontal_delta_negative
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_x
    JMP      try_spinner_horizontal_move

.set_spinner_horizontal_delta_negative
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_x

.try_spinner_horizontal_move
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      retry_spinner_move_on_vertical_axis
    RTS

.retry_spinner_move_on_vertical_axis
    LDX      active_object_index
    JSR      restore_object_position_and_ptr
    LDA      #MOVEMENT_DELTA_NONE
    STA      movement_delta_x
    STA      movement_delta_y
    LDA      player_y_first_cell
    CLC
    ADC      #PLAYER_TO_OBJECT_Y_BIAS
    CMP      object_y_by_index,X
    BEQ      try_spinner_vertical_move
    BMI      set_spinner_vertical_delta_negative
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_y
    JMP      try_spinner_vertical_move

.set_spinner_vertical_delta_negative
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_y

.try_spinner_vertical_move
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      restore_spinner_after_failed_move
    RTS

.restore_spinner_after_failed_move
    LDX      active_object_index
    JMP      restore_object_position_and_ptr

.try_move_object_with_collision
    LDA      #OBJECT_MOVEMENT_FAILED
    STA      object_movement_success_flag
    STA      renderer_collision_accumulator
    JSR      move_object_and_update_screen_ptr
    LDX      active_object_index
    JSR      draw_object_by_index
    LDA      renderer_collision_accumulator
    BNE      return_from_object_move_collision_test
    LDX      active_object_index
    JSR      test_object_inside_playfield
    LDA      bounds_or_outside_flag
    BNE      return_from_object_move_collision_test
    LDA      #OBJECT_MOVEMENT_SUCCEEDED
    STA      object_movement_success_flag
    RTS

.return_from_object_move_collision_test
    RTS

.move_clone_continue_or_random
    JSR      rng_next_byte
    AND      #CLONE_RANDOM_TURN_MASK
    BEQ      try_clone_random_direction
    LDX      active_object_index
    LDA      item_delta_x_by_slot,X
    STA      movement_delta_x
    LDA      item_delta_y_by_slot,X
    STA      movement_delta_y
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      restore_clone_before_random_move
    RTS

.restore_clone_before_random_move
    LDX      active_object_index
    JSR      restore_object_position_and_ptr

.try_clone_random_direction
    JSR      random_direction_delta
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      restore_clone_after_failed_random_move
    RTS

.restore_clone_after_failed_random_move
    LDX      active_object_index
    JSR      restore_object_position_and_ptr
    RTS

.random_direction_delta
    JSR      rng_next_byte
    AND      #RANDOM_DIRECTION_BIT_MASK
    STA      movement_delta_x
    JSR      rng_next_byte
    AND      #RANDOM_DIRECTION_BIT_MASK
    SEC
    SBC      movement_delta_x
    STA      movement_delta_x
    LDX      active_object_index
    STA      item_delta_x_by_slot,X
    JSR      rng_next_byte
    AND      #RANDOM_DIRECTION_BIT_MASK
    STA      movement_delta_y
    JSR      rng_next_byte
    AND      #RANDOM_DIRECTION_BIT_MASK
    SEC
    SBC      movement_delta_y
    STA      movement_delta_y
    LDX      active_object_index
    STA      item_delta_y_by_slot,X
    RTS

.move_cyberdroid_persistent
    LDA      item_delta_x_by_slot,X
    BNE      select_cyberdroid_axis_towards_player
    LDA      item_delta_y_by_slot,X
    BNE      select_cyberdroid_axis_towards_player
    JSR      random_direction_delta
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      reset_cyberdroid_direction_after_block
    RTS

.reset_cyberdroid_direction_after_block
    LDX      active_object_index
    JSR      restore_object_position_and_ptr
    LDA      #MOVEMENT_DELTA_NONE
    STA      item_delta_x_by_slot,X
    STA      item_delta_y_by_slot,X
    RTS

.select_cyberdroid_axis_towards_player
    LDA      player_x_first_cell
    CMP      object_x_by_index,X
    BEQ      set_cyberdroid_vertical_direction
    LDA      player_y_first_cell
    CLC
    ADC      #PLAYER_TO_OBJECT_Y_BIAS
    CMP      object_y_by_index,X
    BEQ      set_cyberdroid_horizontal_direction
    JMP      try_cyberdroid_persistent_move

.set_cyberdroid_vertical_direction
    LDA      player_y_first_cell
    CLC
    ADC      #PLAYER_TO_OBJECT_Y_BIAS
    CMP      object_y_by_index,X
    BMI      set_cyberdroid_vertical_delta_negative
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_y
    JMP      store_cyberdroid_direction

.set_cyberdroid_vertical_delta_negative
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_y
    JMP      store_cyberdroid_direction

.set_cyberdroid_horizontal_direction
    LDA      player_x_first_cell
    CMP      object_x_by_index,X
    BMI      set_cyberdroid_horizontal_delta_negative
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_x
    JMP      store_cyberdroid_direction

.set_cyberdroid_horizontal_delta_negative
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_x

.store_cyberdroid_direction
    LDA      movement_delta_x
    STA      item_delta_x_by_slot,X
    LDA      movement_delta_y
    STA      item_delta_y_by_slot,X

.try_cyberdroid_persistent_move
    LDA      item_delta_x_by_slot,X
    STA      movement_delta_x
    LDA      item_delta_y_by_slot,X
    STA      movement_delta_y
    JSR      try_move_object_with_collision
    LDA      object_movement_success_flag
    BEQ      reset_cyberdroid_direction_after_block
    RTS

.handle_shot_or_hazard_overlap_collisions
    LDA      transition_delay
    BNE      scan_shot_or_hazard_object_overlaps
    LDA      shot_x_by_slot,X
    SEC
    SBC      player_x_first_cell
    BMI      scan_shot_or_hazard_object_overlaps
    CMP      #SHOT_PLAYER_HORIZONTAL_EXTENT
    BPL      scan_shot_or_hazard_object_overlaps
    LDA      shot_y_by_slot,X
    SEC
    SBC      player_y_first_cell
    BMI      scan_shot_or_hazard_object_overlaps
    CMP      #SHOT_PLAYER_VERTICAL_EXTENT
    BPL      scan_shot_or_hazard_object_overlaps
    JSR      deactivate_and_erase_shot_or_hazard
    JMP      handle_player_hit_from_active_object

.scan_shot_or_hazard_object_overlaps
    LDY      #FIRST_ITEM_OBJECT_INDEX

.test_next_object_for_shot_or_hazard_overlap
    LDA      object_lifecycle_base_for_indexed_refs,Y
    CMP      #OBJECT_LIFECYCLE_ACTIVE
    BNE      advance_shot_or_hazard_object_scan
    LDA      shot_x_by_slot,X
    SEC
    SBC      object_x_by_index,Y
    BMI      advance_shot_or_hazard_object_scan
    CMP      #SHOT_OBJECT_HORIZONTAL_EXTENT
    BPL      advance_shot_or_hazard_object_scan
    LDA      shot_y_by_slot,X
    SEC
    SBC      object_y_by_index,Y
    BMI      advance_shot_or_hazard_object_scan
    CMP      #SHOT_OBJECT_VERTICAL_EXTENT
    BPL      advance_shot_or_hazard_object_scan
    LDA      #OBJECT_LIFECYCLE_HIT
    STA      object_lifecycle_base_for_indexed_refs,Y
    CPX      #FIRST_HAZARD_SLOT
    BPL      convert_hazard_hit_object_to_item
    LDA      object_graphic_id_by_index,Y
    SEC
    SBC      #ENEMY_SCORE_GRAPHIC_ID_BIAS
    ASL      A
    JSR      increment_four_char_score_or_counter
    DEC      remaining_active_object_count
    JMP      finish_shot_or_hazard_object_hit

.convert_hazard_hit_object_to_item
    LDA      object_graphic_id_by_index,Y
    JSR      place_graphic_in_free_item_slot

.finish_shot_or_hazard_object_hit
    LDX      active_object_index
    JSR      deactivate_and_erase_shot_or_hazard
    LDA      #SOUND_ID_OBJECT_HIT
    JMP      play_sound_id_if_enabled

.advance_shot_or_hazard_object_scan
    INY
    CPY      #object_slot_count
    BNE      test_next_object_for_shot_or_hazard_overlap
    RTS

.deactivate_and_erase_shot_or_hazard
    LDA      shot_screen_low_current,X
    STA      shot_screen_low_previous,X
    LDA      shot_screen_high_current,X
    STA      shot_screen_high_previous,X
    JSR      deactivate_shot_or_hazard_slot
    JMP      erase_visible_shot_or_hazard_previous_bytes

.play_sound_id_if_enabled
    STA      zp_screen_ptr_70_low
    LDA      sound_disabled_flag
    BEQ      issue_sound_osword
    RTS

.issue_sound_osword
    LDA      #POINTER_HIGH_CLEAR
    STA      zp_screen_ptr_70_high
    LDX      #SOUND_ID_POINTER_SHIFT_COUNT
    JSR      shift_pointer_70_left_x_times
    LDX      zp_screen_ptr_70_low
    LDA      #SOUND_TABLE_PAGE_HIGH_BASE
    ADC      zp_screen_ptr_70_high
    TAY
    LDA      #OSWORD_SOUND
    JMP      MOS_OSWORD

.direction_from_delta_xy
    CPX      #DELTA_ZERO
    BEQ      return_vertical_direction_from_delta
    BPL      return_rightward_direction_from_delta
    CPY      #DELTA_ZERO
    BNE      return_left_diagonal_direction_from_delta
    LDA      #direction_left
    RTS

.return_left_diagonal_direction_from_delta
    BPL      return_down_left_direction
    LDA      #direction_up_left
    RTS

.return_down_left_direction
    LDA      #direction_down_left
    RTS

.return_rightward_direction_from_delta
    CPY      #DELTA_ZERO
    BNE      return_right_diagonal_direction_from_delta
    LDA      #direction_right
    RTS

.return_right_diagonal_direction_from_delta
    BPL      return_down_right_direction
    LDA      #direction_up_right
    RTS

.return_down_right_direction
    LDA      #direction_down_right
    RTS

.return_vertical_direction_from_delta
    CPY      #DELTA_ZERO
    BPL      return_down_direction
    LDA      #direction_up
    RTS

.return_down_direction
    LDA      #direction_down
    RTS

.maybe_spawn_hazard_from_moving_object
    LDA      active_spawned_hazard_count
    CMP      #HAZARD_LIMIT
    BPL      return_without_hazard_spawn
    JSR      rng_next_byte
    AND      #HAZARD_LEVEL_RNG_MASK
    CMP      level_index_and_hazard_gate
    BPL      return_without_hazard_spawn
    JSR      rng_next_byte
    AND      #HAZARD_SOURCE_RNG_MASK
    CLC
    ADC      #HAZARD_SOURCE_OBJECT_INDEX_BASE
    STA      hazard_spawn_source_object_index
    TAX
    LDA      object_lifecycle_base_for_indexed_refs,X
    CMP      #OBJECT_LIFECYCLE_ACTIVE
    BNE      return_without_hazard_spawn
    LDA      item_delta_x_by_slot,X
    BNE      spawn_hazard_from_object_delta
    LDY      item_delta_y_by_slot,X
    BNE      spawn_hazard_from_object_delta

.return_without_hazard_spawn
    RTS

.spawn_hazard_from_object_delta
    LDY      item_delta_y_by_slot,X
    TAX
    JSR      direction_from_delta_xy
    STA      hazard_spawn_direction
    LDY      #HAZARD_SLOT_BEFORE_FIRST

.find_inactive_hazard_slot
    INY
    LDA      shot_direction_or_inactive_by_slot,Y
    BPL      find_inactive_hazard_slot
    LDA      shot_visible_flag_by_slot,Y
    BNE      return_without_hazard_spawn
    STY      hazard_spawn_slot_index
    LDA      #SHOT_NOT_YET_VISIBLE
    STA      shot_visible_flag_by_slot,Y
    LDA      hazard_spawn_direction
    STA      shot_direction_or_inactive_by_slot,Y
    LDX      hazard_spawn_source_object_index
    TAY
    LDA      hazard_spawn_y_offsets_2235,Y
    CLC
    ADC      object_y_by_index,X
    LDY      hazard_spawn_slot_index
    STA      shot_y_by_slot,Y
    LDY      hazard_spawn_direction
    LDA      hazard_spawn_x_offsets_2235,Y
    CLC
    ADC      object_x_by_index,X
    LDY      hazard_spawn_slot_index
    STA      shot_x_by_slot,Y
    TYA
    TAX
    JSR      compute_shot_screen_ptr
    INC      active_spawned_hazard_count

.hazard_spawn_escape_pulse_mode_check
    LDA      bootstrap_osbyte81_x_result_flag
    BNE      play_hazard_spawn_sound

.hazard_spawn_set_escape_condition
    LDA      #OSBYTE_ESCAPE_CONDITION_SET
    JSR      MOS_OSBYTE

.hazard_spawn_acknowledge_escape_condition
    LDA      #OSBYTE_ESCAPE_CONDITION_ACKNOWLEDGE
    JSR      MOS_OSBYTE

.play_hazard_spawn_sound
    LDA      #SOUND_ID_HAZARD_SPAWN
    JMP      play_sound_id_if_enabled

.find_free_item_slot
    LDX      #FREE_ITEM_SLOT_BEFORE_FIRST

.find_free_item_slot_scan_loop_22c5
    INX
    LDA      item_state_alias_object_14,X
    BNE      find_free_item_slot_scan_loop_22c5
    STX      logical_item_slot_index

.return_from_find_or_place_item_slot_22c5
    RTS

.place_graphic_in_free_item_slot
    TAY
    JSR      find_free_item_slot
    CPX      #PLACED_ITEM_SLOT_LIMIT
    BPL      return_from_find_or_place_item_slot_22c5
    TYA
    STA      item_graphic_id_alias_object_14,X
    LDA      #ITEM_STATE_ACTIVE
    STA      item_state_alias_object_14,X
    STX      logical_item_slot_index
    JMP      random_place_item

.increment_four_char_score_or_counter
    STA      zp_scratch_76

.score_increment_outer_loop_22e6
    LDX      #SCORE_FIRST_DIGIT_INDEX

.score_increment_digit_carry_loop_22e6
    INC      score_counter_chars,X
    LDA      score_counter_chars,X
    CMP      #SCORE_DIGIT_WRAP
    BNE      score_upper_wrap_check_setup_22e6
    LDA      #SCORE_BLANK_CHARACTER
    STA      score_counter_chars,X
    INX
    CPX      #SCORE_DIGIT_COUNT
    BNE      score_increment_digit_carry_loop_22e6

.score_upper_wrap_check_setup_22e6
    LDY      #SCORE_UPPER_WRAP_FIRST_INDEX

.score_upper_wrap_check_loop_22e6
    LDA      score_counter_chars,Y
    CMP      #SCORE_BLANK_CHARACTER
    BNE      score_increment_next_unit_22e6
    DEY
    BPL      score_upper_wrap_check_loop_22e6
    LDA      #SOUND_ID_SCORE_LIFE_BONUS
    JSR      play_sound_id_if_enabled
    INC      lives_status_count
    JSR      draw_lives_or_target_status

.score_increment_next_unit_22e6
    DEC      zp_scratch_76
    BNE      score_increment_outer_loop_22e6

.draw_score_counter_digits
    LDA      #SCORE_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #SCORE_SCREEN_LOW
    STA      object_screen_low_by_index
    STA      object_y_by_index
    LDX      #SCORE_LAST_DIGIT_INDEX

.draw_score_digits_loop_2319
    STX      zp_scratch_76
    LDA      score_counter_chars,X
    JSR      draw_status_glyph_at_current_ptr
    LDX      zp_scratch_76
    DEX
    BPL      draw_score_digits_loop_2319
    LDA      #SCORE_BLANK_CHARACTER
    JMP      draw_status_glyph_at_current_ptr

.load_object_screen_ptr
    LDA      object_screen_low_by_index,X
    STA      zp_screen_ptr_70_low
    LDA      object_screen_high_by_index,X
    STA      zp_screen_ptr_70_high
    RTS

.draw_lives_or_target_status
    LDA      #LIVES_STATUS_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #LIVES_STATUS_SCREEN_LOW
    STA      object_screen_low_by_index
    STA      object_y_by_index
    LDX      lives_status_count
    BEQ      clear_empty_life_status_cell_2345
    BMI      target_status_scan_setup_2345

.draw_life_status_marker_loop_2345
    STX      zp_scratch_76
    LDA      #LIFE_STATUS_GRAPHIC
    JSR      draw_status_glyph_at_current_ptr
    LDX      zp_scratch_76
    DEX
    BNE      draw_life_status_marker_loop_2345

.clear_empty_life_status_cell_2345
    JSR      load_object_screen_ptr
    LDY      #STATUS_CELL_LAST_BYTE
    LDA      #STATUS_CELL_CLEAR_BYTE

.clear_status_cell_byte_loop_2345
    STA      (zp_screen_ptr_70_low),Y
    DEY
    BPL      clear_status_cell_byte_loop_2345

.target_status_scan_setup_2345
    LDA      #TARGET_STATUS_SCREEN_HIGH
    STA      object_screen_high_by_index
    LDA      #TARGET_STATUS_SCREEN_LOW
    STA      object_screen_low_by_index
    LDX      #TARGET_STATUS_FIRST_SLOT

.target_status_scan_loop_2345
    INX
    STX      zp_scratch_76
    LDA      target_collected_status,X
    BEQ      target_status_scan_next_2345
    LDA      target_status_graphic_ids_2345,X
    JSR      draw_status_glyph_at_current_ptr
    SEC
    LDA      object_screen_low_by_index
    SBC      #TARGET_STATUS_SCREEN_REWIND
    STA      object_screen_low_by_index
    LDA      object_screen_high_by_index
    SBC      #POINTER_PAGE_CARRY
    STA      object_screen_high_by_index

.target_status_scan_next_2345
    LDX      zp_scratch_76
    CPX      highest_required_target_slot
    BMI      target_status_scan_loop_2345
    RTS

.delta_towards_player_for_object_x
    LDA      player_x_first_cell
    CMP      object_x_by_index,X
    BEQ      delta_towards_player_compare_y_23a3
    BMI      delta_towards_player_set_x_negative_23a3
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_x
    JMP      delta_towards_player_compare_y_23a3

.delta_towards_player_set_x_negative_23a3
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_x

.delta_towards_player_compare_y_23a3
    LDA      player_y_first_cell
    CLC
    ADC      #PLAYER_TO_OBJECT_Y_BIAS
    CMP      object_y_by_index,X
    BEQ      return_from_delta_towards_player_23a3
    BMI      delta_towards_player_set_y_negative_23a3
    LDA      #MOVEMENT_DELTA_POSITIVE
    STA      movement_delta_y
    RTS

.delta_towards_player_set_y_negative_23a3
    LDA      #MOVEMENT_DELTA_NEGATIVE
    STA      movement_delta_y

.return_from_delta_towards_player_23a3
    RTS

.release_spook_pair_when_timer_expires
    DEC      spook_release_timer
    BNE      return_from_spook_release_or_draw_23cf
    LDA      #SPOOK_STATE_CLEAR
    STA      spook_pause_counter
    STA      spook_first_cell_x
    STA      spook_first_cell_y
    STA      spook_first_cell_screen_low
    STA      spook_second_cell_x
    LDA      #SPOOK_FIRST_SCREEN_HIGH_INITIAL
    STA      spook_first_cell_screen_high
    LDA      #SPOOK_SECOND_SCREEN_HIGH_INITIAL
    STA      spook_second_cell_screen_high
    LDA      #SPOOK_SECOND_SCREEN_LOW_INITIAL
    STA      spook_second_cell_screen_low
    LDA      #SPOOK_SECOND_CELL_Y_OFFSET
    STA      spook_second_cell_y
    JSR      draw_spook_pair_if_released

.return_from_spook_release_or_draw_23cf
    RTS

.draw_spook_pair_if_released
    LDA      spook_release_timer
    BNE      return_from_spook_release_or_draw_23cf
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    LDX      #SPOOK_FIRST_OBJECT_INDEX
    JSR      draw_object_by_index
    LDX      #SPOOK_SECOND_OBJECT_INDEX
    JMP      draw_object_by_index

.move_spook_pair_towards_player
    LDA      frame_phase
    AND      #SPOOK_MOVEMENT_PHASE_MASK
    BEQ      return_from_spook_release_or_draw_23cf
    LDA      spook_release_timer
    BNE      return_from_spook_release_or_draw_23cf
    LDA      spook_pause_counter
    BEQ      move_spook_pair_active_step_2410
    DEC      spook_pause_counter
    RTS

.move_spook_pair_active_step_2410
    LDA      #SPOOK_ACTIVE_PALETTE_VALUE
    LDX      #SPOOK_ACTIVE_PALETTE_LOGICAL
    JSR      vdu19_set_palette_or_colour
    JSR      draw_spook_pair_if_released
    LDX      #SPOOK_FIRST_OBJECT_INDEX
    JSR      delta_towards_player_for_object_x
    JSR      move_object_and_update_screen_ptr
    LDX      #SPOOK_SECOND_OBJECT_INDEX
    JSR      move_object_and_update_screen_ptr
    JMP      draw_spook_pair_if_released

.place_target_code_objects_for_room
    LDX      highest_required_target_slot

.place_target_code_object_scan_loop_243e
    JSR      place_one_target_code_object_if_due
    LDX      active_object_index
    DEX
    BPL      place_target_code_object_scan_loop_243e
    LDX      #BONUS_TARGET_OBJECT_SLOT

.place_one_target_code_object_if_due
    STX      active_object_index
    LDA      room_area
    AND      #ROOM_AREA_LOW_NIBBLE_MASK
    CMP      target_room_code,X
    BNE      return_from_place_target_code_object_244a
    LDA      target_collected_status,X
    BNE      return_from_place_target_code_object_244a
    TXA
    CLC
    ADC      #TARGET_SLOT_TO_LOGICAL_ITEM_BIAS
    STA      logical_item_slot_index
    JMP      random_place_item

.return_from_place_target_code_object_244a
    RTS

.scan_escape_key
    LDX      #INKEY_ESCAPE

.scan_inkey_current_x
    LDA      #OSBYTE_INKEY
    LDY      #INKEY_TIME_LIMIT
    JSR      MOS_OSBYTE
    CPX      #INKEY_NOT_PRESSED
    RTS

.handle_sound_on_off_keys
    LDX      #INKEY_SOUND_ON
    JSR      scan_inkey_current_x
    BEQ      sound_toggle_check_sound_off_key_2470
    LDA      #SOUND_ENABLED
    STA      sound_disabled_flag

.sound_toggle_check_sound_off_key_2470
    LDX      #INKEY_SOUND_OFF
    JSR      scan_inkey_current_x
    BEQ      return_from_sound_toggle_2470
    LDA      #SOUND_ID_ATTRACT_FIRST
    JSR      play_sound_id_if_enabled
    LDA      #SOUND_ID_ATTRACT_SECOND
    JSR      play_sound_id_if_enabled
    LDA      #SOUND_DISABLED
    STA      sound_disabled_flag

.return_from_sound_toggle_2470
    RTS

.redraw_player_with_saved_graphic_pair
    LDA      player_graphic_id_first_cell
    STA      temp_player_graphic_id_first
    LDA      player_graphic_id_second_cell
    STA      temp_player_graphic_id_second
    LDA      saved_visible_player_graphic_id_second
    STA      player_graphic_id_second_cell
    LDA      saved_visible_player_graphic_id_first
    STA      player_graphic_id_first_cell
    LDA      #RENDER_MODE_ERASE_OBJECT
    STA      render_mode_or_text_scratch
    LDX      #PLAYER_FIRST_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    LDX      #PLAYER_SECOND_OBJECT_INDEX
    JSR      draw_object_using_saved_screen_ptr
    LDA      temp_player_graphic_id_first
    STA      player_graphic_id_first_cell
    LDA      temp_player_graphic_id_second
    STA      player_graphic_id_second_cell
    RTS

.vdu19_set_palette_or_colour
    PHA
    LDA      #VDU_DEFINE_LOGICAL_COLOUR
    JSR      MOS_OSWRCH
    TXA
    JSR      MOS_OSWRCH
    PLA
    JSR      MOS_OSWRCH
    LDA      #VDU_PALETTE_MODE_DEFAULT
    JSR      MOS_OSWRCH
    JSR      MOS_OSWRCH
    JMP      MOS_OSWRCH

; STATIC TEXT AND GAMEPLAY TABLES
; ===============================

.runtime_data_padding_24d9
    ; zero padding/workspace tail between runtime code and resident data tables
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00

.screen_copy_control_streams
    ; byte stream consumed by screen/text copy helpers; not executable code
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &70,&34,&20,&4C,&44,&58,&73,&78
    EQUB &3A,&4C,&44

.player_start_second_graphic_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &0A,&0E,&06,&02

.player_start_first_graphic_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &08,&0C,&04,&00

.player_start_direction_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; start_exit_0 first_gfx=&08 second_gfx=&0A dir_seed=&02
    ; start_exit_1 first_gfx=&0C second_gfx=&0E dir_seed=&03
    ; start_exit_2 first_gfx=&04 second_gfx=&06 dir_seed=&01
    ; start_exit_3 first_gfx=&00 second_gfx=&02 dir_seed=&00
    EQUB &02,&03,&01,&00

.object_legend_graphic_ids_1175
    ; legend_graphic_ids index0=SPINNER:$2A index1=CLONE:$2B index2=CYBERDROID:$2C index3=SAFE:$3D index4=KEY:$3F index5=POT_OF_GOLD:$32 index6=RING:$3E
    ; legend_graphic_screens index0=&4490 index1=&4C10 index2=&5390 index3=&5B10 index4=&6290 index5=&6A10 index6=&7190
    ; SPOOK uses immediate graphic ids $2E/$2F at $11E1/$11F5, outside this table
    EQUB &2A,&2B,&2C,&3D,&3F,&32,&3E

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
    EQUB &7C,&9D,&A4,&AD,&B4,&C0,&D3,&C6
    EQUB &D8,&87

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
    EQUB &30,&3C,&44,&4B,&53,&5A,&62,&69
    EQUB &71,&7B

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
    EQUB &00,&80,&00,&80,&00,&80,&00,&80
    EQUB &00,&00

.encoded_text_stream_cybertron
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&05 text="CYBERTRON"
    EQUB &05,&23,&39,&22,&25,&32,&34,&32
    EQUB &2F,&2E,&FF

.encoded_text_stream_press_space_to_start
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&00 text="PRESS SPACE TO START"
    EQUB &00,&30,&32,&25,&33,&33,&00,&33
    EQUB &30,&21,&23,&25,&00,&34,&2F,&00
    EQUB &33,&34,&21,&32,&34,&FF

.encoded_text_stream_spook
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SPOOK"
    EQUB &06,&33,&30,&2F,&2F,&2B,&FF

.encoded_text_stream_spinner
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SPINNER"
    EQUB &06,&33,&30,&29,&2E,&2E,&25,&32
    EQUB &FF

.encoded_text_stream_clone
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="CLONE"
    EQUB &06,&23,&2C,&2F,&2E,&25,&FF

.encoded_text_stream_cyberdroid
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="CYBERDROID"
    EQUB &06,&23,&39,&22,&25,&32,&24,&32
    EQUB &2F,&29,&24,&FF

.encoded_text_stream_safe
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="SAFE"
    EQUB &06,&33,&21,&26,&25,&FF

.encoded_text_stream_pot_of_gold
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="POT OF GOLD"
    EQUB &06,&30,&2F,&34,&00,&2F,&26,&00
    EQUB &27,&2F,&2C,&24,&FF

.encoded_text_stream_key
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="KEY"
    EQUB &06,&2B,&25,&39,&FF

.encoded_text_stream_ring
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="RING"
    EQUB &06,&32,&29,&2E,&27,&FF

.encoded_text_stream_level
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&06 text="LEVEL"
    EQUB &06,&2C,&25,&36,&25,&2C,&FF

.encoded_text_stream_end_of_game
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&04 text="END OF GAME"
    EQUB &04,&25,&2E,&24,&00,&2F,&26,&00
    EQUB &27,&21,&2D,&25,&FF

.encoded_text_stream_keys
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&08 text="KEYS"
    EQUB &08,&2B,&25,&39,&33,&FF

.encoded_text_stream_status
    ; encoded text stream: first byte is colour/position control, $FF terminates
    ; decoded_text control=&07 text="STATUS"
    EQUB &07,&33,&34,&21,&34,&35,&33,&FF

.control_help_text
    ; raw VDU/text stream for the controls screen
    ; printable_text_runs "UP" "DOWN" "LEFT" "RIGHT" "FIRE" "SOUND" "ON" "SOUND" "OFF" "PAUSE" "RESUME" "OR FIRE BUTTON"
    EQUB &11,&01,&1F,&03,&06,&41,&09,&09
    EQUB &55,&50,&1F,&03,&08,&5A,&09,&09
    EQUB &44,&4F,&57,&4E,&1F,&03,&0A,&3C
    EQUB &09,&09,&4C,&45,&46,&54,&1F,&03
    EQUB &0C,&3E,&09,&09,&52,&49,&47,&48
    EQUB &54,&1F,&03,&0E,&4D,&09,&09,&46
    EQUB &49,&52,&45,&1F,&03,&10,&53,&09
    EQUB &09,&53,&4F,&55,&4E,&44,&09,&4F
    EQUB &4E,&1F,&03,&12,&51,&09,&09,&53
    EQUB &4F,&55,&4E,&44,&09,&4F,&46,&46
    EQUB &1F,&03,&14,&50,&09,&09,&50,&41
    EQUB &55,&53,&45,&1F,&03,&16,&52,&09
    EQUB &09,&52,&45,&53,&55,&4D,&45,&1F
    EQUB &03,&1C,&4F,&52,&20,&46,&49,&52
    EQUB &45,&20,&42,&55,&54,&54,&4F,&4E

.scroll_or_animation_seed_table
    ; raw_printable_view ",!34" "3#/2%"
    EQUB &00,&00,&00,&2C,&21,&33,&34,&00
    EQUB &33,&23,&2F,&32,&25,&00

.current_score_title_digits
    ; title score/glyph buffer updated by $0D9C; bytes are renderer glyph ids, not plain text
    ; raw_printable_view "()'(" "3#/2%"
    EQUB &10,&10,&10,&10,&10,&00,&00,&00
    EQUB &28,&29,&27,&28,&00,&33,&23,&2F
    EQUB &32,&25,&00

.best_score_title_digits
    ; title best-score/glyph buffer updated by $0D80/$0D9C; bytes are renderer glyph ids, not plain text
    ; raw_printable_view "0ROGRAM" "0OWER" "#9"%242/."
    EQUB &10,&10,&10,&10,&10,&00,&00,&30
    EQUB &52,&4F,&47,&52,&41,&4D,&00,&30
    EQUB &4F,&57,&45,&52,&00,&23,&39,&22
    EQUB &25,&32,&34,&32,&2F,&2E,&00

.zero_terminated_text_entering
    ; raw VDU/text stream terminated by $00
    ; printable_text_runs "ENTERING"
    EQUB &11,&04,&1F,&06,&06,&45,&4E,&54
    EQUB &45,&52,&49,&4E,&47,&00

.zero_terminated_text_find_the_following
    ; raw VDU/text stream terminated by $00
    ; printable_text_runs "FIND THE FOLLOWING"
    EQUB &11,&04,&1F,&01,&11,&46,&49,&4E
    EQUB &44,&20,&54,&48,&45,&20,&46,&4F
    EQUB &4C,&4C,&4F,&57,&49,&4E,&47,&00

.hazard_spawn_y_offsets_2235
    ; signed_values +3, -2, +1, +1, -2, +3, -2, +3
    EQUB &03,&FE,&01,&01,&FE,&03,&FE,&03

.hazard_spawn_x_offsets_2235
    ; signed_values +1, +1, +4, -2, +4, +4, -2, -2
    EQUB &01,&01,&04,&FE,&04,&04,&FE,&FE

.unused_intertable_bytes_26ee
    ; Unreferenced source-owned bytes between the hazard offsets and palette.
    EQUB &49,&4E

.base_palette_table_1f71
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&02,&03,&04,&05,&00,&07
    EQUB &07,&00,&07,&03,&07,&01,&00,&00

.level_intro_required_graphic_table_11fe
    ; required_target_graphics level_index_0=$3F:KEY level_index_1=$3E:RING level_index_2=$32:POT_OF_GOLD level_index_3=$3E:RING level_index_4=$32:POT_OF_GOLD level_index_5=$32:POT_OF_GOLD
    EQUB &3F,&3E,&32,&3E,&32,&32

.text_render_colour_value
    EQUB &01

.unused_intertable_bytes_2707
    ; Unreferenced source-owned bytes between active palette tables.
    EQUB &04,&05,&10,&11,&14,&15,&00

.palette_cycle_logical15_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&00,&01

.palette_cycle_logical14_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&00

.palette_cycle_logical13_values_17e4
    ; palette data table; values are logical colour/palette bytes
    EQUB &01,&00,&00

.palette_data_2717
    ; palette data table; values are logical colour/palette bytes
    EQUB &00,&01,&02,&03,&04,&05,&06,&07
    EQUB &07,&06,&05,&04,&03,&02,&01,&00

.early_init_vdu_bytes_13b4
    ; early init byte stream output by $13B4 through OSWRCH
    EQUB &00,&00,&00,&00,&00,&00,&20,&0A
    EQUB &00,&17,&02,&16,&00,&00,&00,&00

.target_collection_score_add_table_0fd6
    ; target collection score additions by target/status slot; slot0 and slot6 have special non-score paths
    ; score_add_slots slot0=0 slot1=10 slot2=50 slot3=100 slot4=50 slot5=100 slot6=0 slot7=0
    EQUB &00,&0A,&32,&64,&32,&64,&00,&00

.unused_intertable_bytes_273f
    ; Unreferenced source-owned bytes between score and level palette tables.
    EQUB &00,&52,&62,&70,&72,&69,&6E,&74
    EQUB &04,&08,&00,&04,&04,&00,&08,&08
    EQUB &00

.level_palette_logical8_by_level_units_mod8
    ; palette data table; values are logical colour/palette bytes
    ; logical colour 8 value selected by current level low three bits after $1F71 base palette setup
    EQUB &07,&07,&04,&05,&01,&02,&01,&04

.unused_24byte_graphic_record_2758
    ; Unreferenced 24-byte bitmap-shaped record retained from the original.
    EQUB &1C,&09,&09,&09,&09,&09,&09,&1C
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &23,&FF,&FF,&FF,&FF,&FF,&FF,&23

.spook_release_timer_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=60 level1=80 level2=100 level3=100 level4=120 level5=120
    EQUB &3C,&50,&64,&64,&78,&78

.cyberdroid_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=0 level1=0 level2=2 level3=3 level4=4 level5=5
    EQUB &00,&00,&02,&03,&04,&05

.clone_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=0 level1=3 level2=3 level3=3 level4=4 level5=5
    EQUB &00,&03,&03,&03,&04,&05

.spinner_count_by_level_index_1e3a
    ; level-indexed setup/count table used by $1E3A
    ; level_index_values level0=6 level1=3 level2=3 level3=2 level4=2 level5=2
    EQUB &06,&03,&03,&02,&02,&02

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
    EQUB &04,&FF,&02,&02,&01,&03,&01,&03

.player_shot_x_offsets_1c4d
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +1, +1, +3, -1, +3, +4, -1, -2
    EQUB &01,&01,&03,&FF,&03,&04,&FF,&FE

.projectile_grid_y_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +1, -1, 0, 0, -1, +1, -1, +1
    EQUB &01,&FF,&00,&00,&FF,&01,&FF,&01

.projectile_grid_x_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values 0, 0, +1, -1, +1, +1, -1, -1
    EQUB &00,&00,&01,&FF,&01,&01,&FF,&FF

.projectile_ptr_high_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values 0, -1, 0, -1, 0, 0, -1, -1
    EQUB &00,&FF,&00,&FF,&00,&00,&FF,&FF

.projectile_ptr_low_delta_by_dir_1b87
    ; direction-indexed signed projectile/player-shot delta table
    ; signed_values +4, -4, +8, -8, +4, +12, -12, -4
    EQUB &04,&FC,&08,&F8,&04,&0C,&F4,&FC

.player_start_y_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    ; exit-indexed player start tuples: exit, x, y, first_gfx, second_gfx, dir, first_screen, second_screen
    ; start_exit_0 x=&07 y=&1E gfx=&08/&0A dir=&02 screen=&55B8/&5838
    ; start_exit_1 x=&45 y=&1E gfx=&0C/&0E dir=&03 screen=&57A8/&5A28
    ; start_exit_2 x=&27 y=&32 gfx=&04/&06 dir=&01 screen=&6FB8/&7238
    ; start_exit_3 x=&27 y=&0A gfx=&00/&02 dir=&00 screen=&3DB8/&4038
    EQUB &1E,&1E,&32,&0A

.player_start_x_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &07,&45,&27,&27

.player_start_second_screen_high_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &58,&5A,&72,&40

.player_start_second_screen_low_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &38,&28,&38,&38

.player_start_first_screen_high_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &55,&57,&6F,&3D

.player_start_first_screen_low_by_exit_1735
    ; four-entry player start/reset table indexed by room-exit direction
    EQUB &B8,&A8,&B8,&B8

.player_direction_graphic_delta_table_16e1
    ; signed_values +1, -1, -4, +4
    EQUB &01,&FF,&FC,&04

.keyboard_input_delta_y_table_1609
    ; keyboard direction table used by the $1609 input scanner
    ; signed_values -1, +1, 0, 0
    EQUB &FF,&01,&00,&00

.keyboard_input_delta_x_table_1609
    ; keyboard direction table used by the $1609 input scanner
    ; signed_values 0, 0, -1, +1
    EQUB &00,&00,&FF,&01

.keyboard_inkey_codes_table_1609
    ; keyboard direction table used by the $1609 input scanner
    EQUB &BE,&9E,&99,&98

; ROOM LAYOUT RECORDS
; ===================

.room_layout_bank0_runtime
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 b 5 a 6 9 5
    ; room_row_3 b 6 9 5 a 6
    ; room_row_4 3 9 6 a 5 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&5B,&6A
    EQUB &59,&6B,&59,&6A,&93,&A6,&35,&C9
    EQUB &95,&5C

.room_layout_record_01
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 9 5 a 6 9 5
    ; room_row_3 a c 5 3 0 2
    ; room_row_4 3 0 a 5 0 3
    ; room_row_5 9 c 5 8 c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&59,&6A
    EQUB &59,&CA,&35,&20,&03,&5A,&30,&C9
    EQUB &85,&5C

.room_layout_record_02
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 9 5 0 0 9 5
    ; room_row_3 a 6 0 0 a 6
    ; room_row_4 3 9 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&CC,&6C,&A3,&CC,&36,&59,&00
    EQUB &59,&6A,&00,&6A,&93,&CC,&35,&C9
    EQUB &CC,&5C

.room_layout_record_03
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 0 a c c 6 0
    ; room_row_1 a 5 2 2 9 6
    ; room_row_2 1 8 5 9 4 3
    ; room_row_3 2 8 6 a 4 3
    ; room_row_4 9 6 1 1 a 5
    ; room_row_5 0 9 4 8 5 0
    EQUB &A0,&CC,&06,&5A,&22,&69,&81,&95
    EQUB &34,&82,&A6,&34,&69,&11,&5A,&90
    EQUB &84,&05

.room_layout_record_04
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a e 4 a c 6
    ; room_row_1 3 9 4 3 2 3
    ; room_row_2 3 0 0 1 3 3
    ; room_row_3 3 8 c c 5 3
    ; room_row_4 b c 4 0 0 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &EA,&A4,&6C,&93,&34,&32,&03,&10
    EQUB &33,&83,&CC,&35,&CB,&04,&30,&C9
    EQUB &84,&5C

.room_layout_record_05
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 a c 6
    ; room_row_1 3 a c 5 2 3
    ; room_row_2 3 3 8 6 3 1
    ; room_row_3 3 3 8 5 3 2
    ; room_row_4 3 9 c 6 1 3
    ; room_row_5 9 c 4 9 c 5
    EQUB &CA,&A4,&6C,&A3,&5C,&32,&33,&68
    EQUB &13,&33,&58,&23,&93,&6C,&31,&C9
    EQUB &94,&5C

.room_layout_record_06
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c c 6
    ; room_row_1 3 8 6 a 4 3
    ; room_row_2 1 0 9 5 2 1
    ; room_row_3 2 8 e c 5 2
    ; room_row_4 3 0 1 a 4 3
    ; room_row_5 9 c 4 9 c 5
    EQUB &CA,&CC,&6C,&83,&A6,&34,&01,&59
    EQUB &12,&82,&CE,&25,&03,&A1,&34,&C9
    EQUB &94,&5C

.room_layout_record_07
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 b c 5 9 e 7
    ; room_row_2 1 a c 6 3 3
    ; room_row_3 a 5 0 3 1 3
    ; room_row_4 b c c 5 0 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &CA,&A6,&6C,&CB,&95,&7E,&A1,&6C
    EQUB &33,&5A,&30,&31,&CB,&5C,&30,&C9
    EQUB &84,&5C

.room_layout_record_08
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 0 3 3 0 3
    ; room_row_2 3 a 5 9 c 5
    ; room_row_3 3 9 6 a c 6
    ; room_row_4 3 0 3 3 0 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&A6,&6C,&03,&33,&30,&A3,&95
    EQUB &5C,&93,&A6,&6C,&03,&33,&30,&C9
    EQUB &95,&5C

.room_layout_record_09
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a 4 8 6 3
    ; room_row_2 1 9 6 a 5 1
    ; room_row_3 2 a 5 9 6 2
    ; room_row_4 3 9 4 8 5 3
    ; room_row_5 9 c 4 8 c 5
    EQUB &CA,&84,&6C,&A3,&84,&36,&91,&A6
    EQUB &15,&A2,&95,&26,&93,&84,&35,&C9
    EQUB &84,&5C

.room_layout_record_0a
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 b c 7 9 c 7
    ; room_row_2 1 0 3 a 6 3
    ; room_row_3 2 a 7 3 3 3
    ; room_row_4 3 9 5 9 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&CB,&97,&7C,&01,&A3
    EQUB &36,&A2,&37,&33,&93,&95,&35,&C9
    EQUB &CC,&5C

.room_layout_record_0b
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a c c 6 3
    ; room_row_2 3 3 2 2 3 3
    ; room_row_3 3 3 3 3 3 3
    ; room_row_4 3 1 3 3 1 3
    ; room_row_5 9 c 5 9 c 5
    EQUB &CA,&84,&6C,&A3,&CC,&36,&33,&22
    EQUB &33,&33,&33,&33,&13,&33,&31,&C9
    EQUB &95,&5C

.room_layout_record_0c
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 4 8 c 6
    ; room_row_1 3 a 4 0 0 3
    ; room_row_2 3 3 8 e c 5
    ; room_row_3 3 9 6 3 0 2
    ; room_row_4 3 0 1 1 0 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&84,&6C,&A3,&04,&30,&33,&E8
    EQUB &5C,&93,&36,&20,&03,&11,&30,&C9
    EQUB &CC,&5C

.room_layout_record_0d
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 a 5 9 6 3
    ; room_row_2 9 5 0 0 3 3
    ; room_row_3 a 6 0 0 3 3
    ; room_row_4 3 9 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&A3,&95,&36,&59,&00
    EQUB &33,&6A,&00,&33,&93,&CC,&35,&C9
    EQUB &CC,&5C

.room_layout_record_0e
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c c c e 6
    ; room_row_1 3 a c 6 3 3
    ; room_row_2 3 9 4 3 3 1
    ; room_row_3 b c c 5 3 2
    ; room_row_4 3 8 c c 5 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&CC,&6E,&A3,&6C,&33,&93,&34
    EQUB &13,&CB,&5C,&23,&83,&CC,&35,&C9
    EQUB &CC,&5C

.room_layout_record_0f
    ; 18-byte packed room record decoded by $14B9 as a 6x6 nibble grid
    ; room_row_0 a c 6 a c 6
    ; room_row_1 3 0 3 3 0 3
    ; room_row_2 9 c 5 3 0 3
    ; room_row_3 a c c 5 0 3
    ; room_row_4 3 0 0 0 0 3
    ; room_row_5 9 c c c c 5
    EQUB &CA,&A6,&6C,&03,&33,&30,&C9,&35
    EQUB &30,&CA,&5C,&30,&03,&00,&30,&C9
    EQUB &CC,&5C

; 24-BYTE OBJECT GRAPHIC RECORDS
; ==============================
; Records remain numerically named unless decoded artwork or a consumer proves
; a stronger identity. Graphic IDs select these records through the tables at
; graphic_record_high_pointer_table_1404 and graphic_record_low_pointer_table_1404.

.graphic_record_00
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F/$254B $1735 start index 3
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&11,&05,&05,&00,&24,&24,&30
    EQUB &33,&0F,&0F,&0F,&0F,&0C,&0C,&03
    EQUB &00,&22,&0A,&0A,&00,&18,&18,&30

.graphic_record_01
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &10,&04,&0C,&0C,&00,&00,&00,&3C
    EQUB &03,&03,&03,&03,&00,&00,&00,&00
    EQUB &20,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_02
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 3 and stationary dir0
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &10,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &03,&03,&03,&03,&00,&00,&00,&00
    EQUB &20,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_03
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &10,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &03,&03,&03,&03,&00,&00,&00,&00
    EQUB &20,&08,&0C,&0C,&00,&00,&00,&3C

.graphic_record_04
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 2
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&11,&11,&05,&00,&24,&24,&24
    EQUB &33,&33,&33,&0F,&0F,&0C,&0C,&0C
    EQUB &00,&22,&22,&0A,&00,&18,&18,&18

.graphic_record_05
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &04,&04,&0C,&0C,&00,&00,&00,&3C
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00
    EQUB &08,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_06
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 2 and stationary dir1
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &04,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00
    EQUB &08,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_07
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &04,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &0C,&0C,&00,&00,&00,&00,&00,&00
    EQUB &08,&08,&0C,&0C,&00,&00,&00,&3C

.graphic_record_08
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 0
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &11,&27,&27,&0F,&05,&10,&24,&24
    EQUB &22,&0F,&0F,&0F,&0A,&08,&0C,&0C
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00

.graphic_record_09
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&30,&04,&04,&04,&0C,&0C,&00
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&04
    EQUB &03,&03,&00,&00,&00,&00,&08,&08

.graphic_record_0a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 0 and stationary dir2
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&30,&04,&04,&04,&04,&04,&04
    EQUB &21,&21,&08,&08,&08,&08,&0C,&0C
    EQUB &03,&03,&00,&00,&00,&00,&00,&3C

.graphic_record_0b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&30,&04,&04,&04,&04,&0C,&0C
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&00
    EQUB &03,&03,&00,&00,&00,&08,&08,&00

.graphic_record_0c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254F $1735 start index 1
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&3C,&00,&00,&00,&00,&00,&00
    EQUB &11,&0F,&0F,&0F,&05,&04,&0C,&0C
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&18

.graphic_record_0d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &03,&03,&00,&00,&00,&00,&04,&04
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&08
    EQUB &30,&30,&08,&08,&08,&0C,&0C,&00

.graphic_record_0e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame; $254B $1735 start index 1 and stationary dir3
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &03,&03,&00,&00,&00,&00,&00,&3C
    EQUB &12,&12,&04,&04,&04,&04,&0C,&0C
    EQUB &30,&30,&08,&08,&08,&08,&08,&08

.graphic_record_0f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 dynamic player direction/frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &03,&03,&00,&00,&00,&04,&04,&00
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&00
    EQUB &30,&30,&08,&08,&08,&08,&0C,&0C

.graphic_record_10
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &11,&27,&27,&0F,&05,&10,&24,&30
    EQUB &22,&0F,&0F,&0F,&0A,&08,&21,&21
    EQUB &00,&00,&3C,&00,&01,&03,&02,&00

.graphic_record_11
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&0C,&0C,&00
    EQUB &0C,&0C,&08,&0C,&0C,&04,&04,&04
    EQUB &00,&00,&00,&00,&00,&00,&08,&08

.graphic_record_12
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&04,&04,&04
    EQUB &0C,&0C,&08,&08,&08,&08,&0C,&0C
    EQUB &00,&00,&00,&00,&00,&00,&00,&3C

.graphic_record_13
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and retained initial lower frame
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &0C,&0C,&08,&0C,&0C,&04,&04,&00
    EQUB &00,&00,&00,&00,&00,&08,&08,&00

.graphic_record_14
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &11,&27,&27,&0F,&05,&10,&24,&30
    EQUB &22,&0F,&0F,&0F,&0A,&08,&0C,&0C
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00

.graphic_record_15
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&0C,&0C,&00
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&04
    EQUB &00,&02,&03,&01,&00,&00,&08,&08

.graphic_record_16
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&04,&04,&04
    EQUB &21,&21,&08,&08,&08,&08,&0C,&0C
    EQUB &00,&02,&03,&01,&00,&00,&00,&3C

.graphic_record_17
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=structural role=player_direction_frame_family sources=family-aligned fourth record; no active selector proved
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &30,&04,&04,&04,&04,&04,&0C,&0C
    EQUB &21,&21,&08,&0C,&0C,&04,&04,&00
    EQUB &00,&02,&03,&01,&00,&08,&08,&00

.graphic_record_18
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&3C,&00,&02,&03,&01,&00
    EQUB &11,&0F,&0F,&0F,&05,&04,&12,&12
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&30

.graphic_record_19
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&00,&00,&04,&04
    EQUB &0C,&0C,&04,&0C,&0C,&08,&08,&08
    EQUB &30,&08,&08,&08,&08,&0C,&0C,&00

.graphic_record_1a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&00,&00,&00,&3C
    EQUB &0C,&0C,&04,&04,&04,&04,&0C,&0C
    EQUB &30,&08,&08,&08,&08,&08,&08,&08

.graphic_record_1b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=structural role=player_direction_frame_family sources=family-aligned fourth record; no active selector proved
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&00,&04,&04,&00
    EQUB &0C,&0C,&04,&0C,&0C,&08,&08,&00
    EQUB &30,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_1c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&3C,&00,&00,&00,&00,&00
    EQUB &11,&0F,&0F,&0F,&05,&04,&0C,&0C
    EQUB &22,&1B,&1B,&0F,&0A,&20,&18,&30

.graphic_record_1d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&01,&03,&02,&00,&00,&04,&04
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&08
    EQUB &30,&08,&08,&08,&08,&0C,&0C,&00

.graphic_record_1e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=assigned role=player_direction_frame_family sources=$16E1 direction code times four and lower-frame offsets
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&01,&03,&02,&00,&00,&00,&3C
    EQUB &12,&12,&04,&04,&04,&04,&0C,&0C
    EQUB &30,&08,&08,&08,&08,&08,&08,&08

.graphic_record_1f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_direction_frame_family
    ; graphic_usage status=structural role=player_direction_frame_family sources=family-aligned fourth record; no active selector proved
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&01,&03,&02,&00,&04,&04,&00
    EQUB &12,&12,&04,&0C,&0C,&08,&08,&00
    EQUB &30,&08,&08,&08,&08,&08,&0C,&0C

.graphic_record_20
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits; $1CAB fixed status blank/space and $2319 trailing glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&2A,&2A,&2A,&2A,&3F
    EQUB &3F,&00,&00,&00,&15,&15,&15,&3F
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A

.graphic_record_21
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &15,&15,&15,&15,&3F,&3F,&3F,&3F
    EQUB &00,&00,&00,&00,&00,&00,&00,&00

.graphic_record_22
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&00,&00,&3F,&3F,&3F,&3F,&3F
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F
    EQUB &2A,&2A,&2A,&2A,&00,&00,&2A,&2A

.graphic_record_23
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F
    EQUB &3F,&00,&00,&3F,&15,&15,&3F,&3F
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A

.graphic_record_24
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &2A,&2A,&2A,&2A,&3F,&00,&00,&00
    EQUB &00,&00,&3F,&3F,&3F,&3F,&3F,&3F
    EQUB &00,&00,&00,&00,&2A,&00,&00,&00

.graphic_record_25
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits; $1CAB fixed status-panel glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&3F,&00,&00,&3F,&3F
    EQUB &3F,&00,&00,&3F,&15,&15,&3F,&3F
    EQUB &2A,&00,&00,&2A,&2A,&2A,&2A,&2A

.graphic_record_26
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&3F,&3F,&3F,&3F,&3F
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F
    EQUB &2A,&00,&00,&2A,&2A,&2A,&2A,&2A

.graphic_record_27
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&00,&00,&00,&00,&00,&00,&00
    EQUB &3F,&00,&00,&00,&15,&15,&15,&15
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A

.graphic_record_28
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &15,&15,&15,&3F,&3F,&3F,&3F,&3F
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A

.graphic_record_29
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role status_score_room_level_character_glyph
    ; graphic_usage status=assigned role=status_score_room_level_character_glyph sources=$22E6/$2319 score character range and $1D0A-$1D34 room/level digits
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&3F,&00,&00,&00,&00
    EQUB &3F,&00,&00,&3F,&15,&15,&15,&15
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&2A

.graphic_record_2a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPINNER
    ; graphic_usage status=assigned role=legend_and_enemy_SPINNER sources=$2557 legend table and $1E3A spinner placement
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &F3,&AA,&FF,&A8,&FC,&A2,&F3,&FF
    EQUB &FC,&A8,&0C,&0C,&0C,&0C,&54,&FC
    EQUB &FF,&F3,&51,&FC,&54,&FF,&55,&F3

.graphic_record_2b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role CLONE
    ; graphic_usage status=assigned role=legend_and_enemy_CLONE sources=$2557 legend table and $1E3A clone placement
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&10,&30,&F6,&F6,&30,&10,&00
    EQUB &30,&30,&30,&FB,&FB,&30,&30,&30
    EQUB &00,&20,&30,&FD,&FD,&30,&20,&00

.graphic_record_2c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role CYBERDROID
    ; graphic_usage status=assigned role=legend_and_enemy_CYBERDROID sources=$2557 legend table and $1E3A cyberdroid placement
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&05,&B2,&B8,&AA,&11,&32,&11
    EQUB &CC,&0F,&0F,&30,&0F,&33,&30,&33
    EQUB &00,&0A,&71,&74,&55,&22,&31,&22

.graphic_record_2d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role bonus_target_status_and_room_fill_probe
    ; graphic_usage status=assigned role=bonus_target_status_and_room_fill_probe sources=$2F36 target/status slot 6 and $1EC8/$1F19 room fill probes
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &CF,&45,&45,&8A,&DB,&8A,&DE,&45
    EQUB &00,&00,&AA,&54,&AA,&54,&F7,&CF
    EQUB &CF,&8A,&8A,&45,&45,&E7,&45,&8A

.graphic_record_2e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPOOK_first_cell
    ; graphic_usage status=assigned role=legend_and_spook_pair sources=$1175 SPOOK immediate and $1E3A spook first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&50,&50,&50,&F0,&F0,&A0
    EQUB &50,&F0,&F0,&50,&50,&F0,&F0,&F0
    EQUB &00,&A0,&F0,&50,&50,&F0,&F0,&F0

.graphic_record_2f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SPOOK_second_cell
    ; graphic_usage status=assigned role=legend_and_spook_pair sources=$1175 SPOOK immediate and $1E3A spook second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &A0,&00,&00,&50,&50,&50,&F0,&A0
    EQUB &F0,&F0,&F0,&A0,&A0,&00,&00,&00
    EQUB &50,&00,&00,&00,&00,&00,&00,&00

.graphic_record_30
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_collision_flash
    ; graphic_usage status=assigned role=player_collision_flash sources=$19F3 player collision flash first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&15,&15,&15,&00,&3F,&00,&2A
    EQUB &3F,&00,&00,&3F,&00,&3F,&00,&3F
    EQUB &00,&2A,&2A,&2A,&00,&3F,&00,&15

.graphic_record_31
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_collision_flash
    ; graphic_usage status=assigned role=player_collision_flash sources=$19F3 player collision flash second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &2A,&00,&00,&15,&00,&15,&15,&3F
    EQUB &00,&3F,&00,&3F,&00,&00,&00,&00
    EQUB &15,&00,&00,&2A,&00,&2A,&2A,&3F

.graphic_record_32
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role POT_OF_GOLD
    ; graphic_usage status=assigned role=legend_and_required_target_POT_OF_GOLD sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&45,&00,&45,&CF,&CF,&45,&00
    EQUB &00,&CF,&CF,&CF,&CF,&CF,&CF,&CF
    EQUB &00,&8A,&00,&8A,&CF,&CF,&8A,&00

.graphic_record_33
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_life_loss_reset
    ; graphic_usage status=assigned role=player_life_loss_reset sources=$1A59 player life-loss reset first cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&05,&27,&27,&33
    EQUB &00,&00,&00,&00,&0A,&0A,&1A,&1A
    EQUB &00,&00,&00,&00,&01,&09,&30,&30

.graphic_record_34
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role player_life_loss_reset
    ; graphic_usage status=assigned role=player_life_loss_reset sources=$1A59 player life-loss reset second cell
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&00,&00,&00,&08,&0C,&0C
    EQUB &00,&00,&00,&00,&00,&00,&0C,&0C
    EQUB &00,&00,&00,&00,&04,&04,&0C,&0C

.graphic_record_35
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&2A,&3F,&3F,&3F,&3F
    EQUB &3F,&00,&00,&00,&00,&00,&00,&3F
    EQUB &2A,&00,&00,&00,&00,&00,&00,&2A

.graphic_record_36
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&2A,&3F,&3F,&3F,&3F
    EQUB &3F,&15,&15,&15,&3F,&00,&00,&00
    EQUB &00,&00,&00,&2A,&2A,&2A,&2A,&2A

.graphic_record_37
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &3F,&2A,&2A,&3F,&3F,&3F,&3F,&3F
    EQUB &3F,&00,&00,&3F,&00,&00,&3F,&3F
    EQUB &2A,&00,&00,&2A,&00,&00,&2A,&2A

.graphic_record_38
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role static_status_panel_glyph
    ; graphic_usage status=assigned role=static_status_panel_glyph sources=$1CAB fixed status-panel glyph and $2F36 target table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &15,&15,&15,&15,&3F,&3F,&3F,&3F
    EQUB &3F,&15,&15,&00,&00,&00,&00,&00
    EQUB &3F,&15,&15,&15,&3F,&3F,&3F,&3F

.graphic_record_39
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role lives_status_marker
    ; graphic_usage status=assigned role=lives_status_marker sources=$2345 lives/status marker
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &11,&05,&10,&10,&04,&04,&04,&04
    EQUB &0A,&0A,&00,&21,&00,&00,&00,&08
    EQUB &00,&00,&00,&00,&00,&00,&00,&00

.graphic_record_3a
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 2
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&05,&15,&2B,&15,&05,&15,&00
    EQUB &00,&05,&02,&07,&0B,&05,&00,&00
    EQUB &00,&2A,&00,&2A,&00,&2A,&00,&00

.graphic_record_3b
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 3
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &2F,&05,&03,&2F,&05,&01,&05,&0A
    EQUB &05,&02,&03,&03,&03,&0F,&05,&2A
    EQUB &1F,&2A,&00,&1F,&0A,&02,&00,&1F

.graphic_record_3c
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role object_hit_animation_frame
    ; graphic_usage status=assigned role=object_hit_animation_frame sources=$1876 object hit animation state 4
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&15,&15,&2A,&00,&2A,&15,&00
    EQUB &15,&00,&00,&00,&00,&00,&15,&2A
    EQUB &00,&2A,&15,&00,&2A,&15,&2A,&00

.graphic_record_3d
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role SAFE
    ; graphic_usage status=assigned role=legend_and_target_SAFE sources=$2557 legend table and $2F36 target/status slot 0
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &CF,&8A,&8A,&8A,&8A,&8A,&8A,&CF
    EQUB &CF,&00,&00,&45,&00,&00,&00,&CF
    EQUB &CF,&45,&45,&45,&45,&45,&45,&CF

.graphic_record_3e
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role RING
    ; graphic_usage status=assigned role=legend_and_required_target_RING sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &00,&00,&45,&8A,&8A,&8A,&45,&00
    EQUB &CF,&CF,&00,&00,&00,&00,&CF,&00
    EQUB &00,&00,&8A,&45,&45,&45,&8A,&00

.graphic_record_3f
    ; 24-byte renderer graphic record consumed through the $2F40/$2F80 pointer tables
    ; graphic_role KEY
    ; graphic_usage status=assigned role=legend_and_required_target_KEY sources=$2557 legend table, $2700 level intro, and $2F36 target/status table
    ; graphic_record layout: three 8-byte strips used by the Mode 2 renderer
    EQUB &45,&45,&45,&00,&00,&00,&00,&00
    EQUB &CF,&45,&CF,&8A,&8A,&CF,&8A,&CF
    EQUB &00,&00,&00,&00,&00,&00,&00,&00

; INITIAL OBJECT GRAPHIC IDS AND STATUS IDS
; =========================================

.object_graphic_id_by_index
    ; render-object graphic ids for object indices $00-$0D; indices $0E+ are split below by slot role
    ; slot_map $00-$0D utility/status/text/transient renderer slots; these are outside the logical item window
    EQUB &20,&53,&42,&43,&73,&78,&2B,&31
    EQUB &34,&3A,&42,&50,&4C,&6C

.spook_graphic_id_first_cell
    ; SPOOK pair graphic id seeded by $1E3A and moved by $23CF/$2410
    EQUB &2E

.spook_graphic_id_second_cell
    ; SPOOK pair graphic id seeded by $1E3A and moved by $23CF/$2410
    EQUB &2F

.player_graphic_id_first_cell
    ; current player pair graphic id, seeded by $1735 and updated by $16E1/$2493
    EQUB &00

.player_graphic_id_second_cell
    ; current player pair graphic id, seeded by $1735 and updated by $16E1/$2493
    EQUB &03

.reserved_transient_graphic_id_object_12
    ; reserved/transient render-object graphic id; no gameplay slot ownership currently proven
    EQUB &82

.reserved_transient_graphic_id_object_13
    ; reserved/transient render-object graphic id; no gameplay slot ownership currently proven
    EQUB &23

.item_graphic_id_alias_object_14
    ; logical slot $00-$0B graphic ids, rendered as object indices $14-$1F
    ; logical_slots $00-$0B -> render_objects $14-$1F; enemy scheduler window seeded by $1E3A/moved by $198C
    EQUB &3C,&3C,&3C,&3C,&3C,&3C,&3C,&3C
    EQUB &41,&44,&43,&23

.extra_item_or_enemy_graphic_id_alias_object_20
    ; logical slot $0C-$17 graphic ids, rendered as object indices $20-$2B
    ; logical_slots $0C-$17 -> render_objects $20-$2B; placed item/extra enemy hit-scan window
    EQUB &31,&0D,&0F,&FA,&17,&2E,&6C,&70
    EQUB &73,&31,&20,&43

.unused_object_table_padding_2f2c
    ; Unreferenced source-owned bytes after the complete 44-entry object
    ; graphic-id array and before the target-status graphic table.
    EQUB &4D,&50,&23,&33,&3A,&42,&50,&4C
    EQUB &6C,&70

.target_status_graphic_ids_2345
    ; target_status_graphics slot0=$3D:SAFE slot1=$3F:KEY slot2=$3E:RING slot3=$32:POT_OF_GOLD slot4=$3E:RING slot5=$32:POT_OF_GOLD slot6=$2D:bonus_target_status_and_room_fill_probe
    EQUB &3D,&3F,&3E,&32,&3E,&32,&2D

.unused_pointer_table_alignment_2f3d
    ; Three unreferenced bytes aligning the pointer tables at $2F40.
    EQUB &4C,&44,&41

; GRAPHIC POINTER AND TILE GENERATOR TABLES
; =========================================

.graphic_record_high_pointer_table_1404
    ; 64-entry graphic pointer table; graphic id Y maps to source address high[$2F40+Y]:low[$2F80+Y]
    ; selected_graphic_pointers $2A:SPINNER->&2CF0 $2B:CLONE->&2D08 $2C:CYBERDROID->&2D20 $2D:bonus_target_status_and_room_fill_probe->&2D38 $2E:SPOOK_first_cell->&2D50 $2F:SPOOK_second_cell->&2D68 $32:POT_OF_GOLD->&2DB0 $3D:SAFE->&2EB8 $3E:RING->&2ED0 $3F:KEY->&2EE8
    EQUB &29,&29,&29,&29,&29,&29,&29,&29
    EQUB &29,&29,&29,&2A,&2A,&2A,&2A,&2A
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2B,&2B
    EQUB &2B,&2B,&2B,&2B,&2B,&2B,&2B,&2B
    EQUB &2C,&2C,&2C,&2C,&2C,&2C,&2C,&2C
    EQUB &2C,&2C,&2C,&2D,&2D,&2D,&2D,&2D
    EQUB &2D,&2D,&2D,&2D,&2D,&2D,&2E,&2E
    EQUB &2E,&2E,&2E,&2E,&2E,&2E,&2E,&2E

.graphic_record_low_pointer_table_1404
    ; 64-entry graphic pointer table; graphic id Y maps to source address high[$2F40+Y]:low[$2F80+Y]
    EQUB &00,&18,&30,&48,&60,&78,&90,&A8
    EQUB &C0,&D8,&F0,&08,&20,&38,&50,&68
    EQUB &80,&98,&B0,&C8,&E0,&F8,&10,&28
    EQUB &40,&58,&70,&88,&A0,&B8,&D0,&E8
    EQUB &00,&18,&30,&48,&60,&78,&90,&A8
    EQUB &C0,&D8,&F0,&08,&20,&38,&50,&68
    EQUB &80,&98,&B0,&C8,&E0,&F8,&10,&28
    EQUB &40,&58,&70,&88,&A0,&B8,&D0,&E8
    EQUB &41,&23,&30,&3A,&53,&54,&41,&26

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
    EQUB &F5,&EA,&DF

.tile_generator_middle_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &02,&05,&08,&0A

.tile_generator_side_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &01,&02,&04,&05,&07,&08,&0A,&0A

.tile_generator_outer_index_table_0efe
    ; generated terrain/tile source table used by $0EFE
    EQUB &00,&02,&03,&02,&06,&02,&09,&02

.tile_generator_pattern_source_0_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &80,&C0,&C2,&80,&C0,&C2,&C0,&C3
    EQUB &C3,&C0,&C3

.tile_generator_pattern_source_1_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &C0,&C3,&C3,&C0,&C3,&C3,&C0,&C3
    EQUB &C3,&C0,&C3

.tile_generator_pattern_source_2_0efe
    ; generated terrain/tile source table used by $0EFE
    ; terrain pattern source run used by $0EFE to synthesize classes $1-$F; class $0 clears 24 bytes
    EQUB &40,&C0,&C1,&C0,&C3,&C3,&40,&C0
    EQUB &C1,&C0,&C3

runtime_end = *
SAVE "build/reconstruction/CYBRUN", runtime_start, runtime_end, runtime_entry
