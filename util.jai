draw_text_outlined :: (font: *Simp.Dynamic_Font, x: s64, y: s64, text: string, color := Vector4.{1,1,1,1}, background := Vector4.{0,0,0,1}, effect_flags: Simp.Font_Effects = 0) {
    using Simp;
    draw_text(font, x-1, y,   text, background, effect_flags);
    draw_text(font, x-1, y-1, text, background, effect_flags);
    draw_text(font, x,   y-1, text, background, effect_flags);
    draw_text(font, x+1, y-1, text, background, effect_flags);
    draw_text(font, x+1, y,   text, background, effect_flags);
    draw_text(font, x+1, y+1, text, background, effect_flags);
    draw_text(font, x,   y+1, text, background, effect_flags);
    draw_text(font, x-1, y+1, text, background, effect_flags);
    draw_text(font, x, y, text, color, effect_flags);
}

current_mouse_x, current_mouse_y: int;

per_frame_update_mouse_position :: () { 
    mouse_x, mouse_y, success := get_mouse_pointer_position(true);

    if success {
        current_mouse_x = max(mouse_x, 0);
        current_mouse_y = max(mouse_y, 0);
    }
}

/*string_width :: (str: string) -> int #deprecated "This needs to be factored out at some point." {
    return Simp.get_string_width_in_pixels(game.font, str) - 1;
}

instead, do: 
    width := Simp.prepare_text(font, text);
    Simp.generate_quads_for_prepared_text(font, x, y, 0);
    Simp.draw_generated_quads(font, color);
*/

input_pressed :: (key: Key_Code) -> bool {
    return cast(bool) (input_button_states[key] & Key_Current_State.START);
}
