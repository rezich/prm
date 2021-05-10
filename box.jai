BoxUpdateFunction :: #type(box: *Box, dt: float);
BoxClickFunction :: #type(box: *Box);

BOX_PADDING :: 3;
BOX_FOREGROUND_LERP_SPEED :: 10.0;

Box :: struct {
    value: u32;
    value_max: u32;
    value_mode: enum {
        PERCENT;
        FRACTION;
    }
    x: float;
    y: float;
    width: u32;
    height: u32;
    background_color: Vector4 = .{0,0,0,1};
    foreground_color: Vector4 = .{0.5,0.5,0.5,1};
    border_color: Vector4;
    border_size: u32 = 1;
    text_color: Vector4 = .{1,1,1,1};
    text_outline_color : Vector4 = .{0,0,0,1};
    foreground_progress: float;
    update: BoxUpdateFunction;
    click: BoxClickFunction;
    timer: float;
}

live_boxes : [..] *Box;

render_boxes :: () {
    for live_boxes {
        using it;
        Simp.set_shader_for_color();
        Simp.immediate_quad(x, y, x + xx width, y + xx height, border_color);
        Simp.immediate_quad(x + xx border_size, y + xx border_size, x + xx width - xx border_size, y + xx height - xx border_size, background_color);
        Simp.immediate_quad(x + xx border_size, y + xx border_size, x + xx border_size + xx (width - border_size * 2) * foreground_progress, y + xx height - xx border_size, foreground_color);
        
        value_string: string;
        if value_mode == {
            case .PERCENT;
                value_string = tprint("%1%%", trim(tprint("%", formatFloat(cast(float) value / cast(float) value_max * 100.0, trailing_width=2))));
            case .FRACTION;
                value_string = tprint("%/%", value, value_max);
        };

        draw_text_outlined(
            game.font,
            xx x + BOX_PADDING,
            xx y + cast(int) height - FONT_SIZE - BOX_PADDING,
            value_string,
            text_color,
            text_outline_color
        );
        /*Simp.set_shader_for_color();
        Simp.immediate_quad(
            x + xx BOX_PADDING,
            y + xx height - xx FONT_SIZE - xx BOX_PADDING,
            x + xx BOX_PADDING + xx string_width(value_string),
            y + xx height - xx BOX_PADDING,
            .{1,0,0,1}
        );*/
    }
}

update_boxes :: (dt: float) {
    for live_boxes {
        using it;
        foreground_progress = lerp(foreground_progress, cast(float) value / cast(float) value_max, BOX_FOREGROUND_LERP_SPEED * dt);
        if box_is_full(it) then foreground_progress = 1.0;
        if input_pressed(.MOUSE_BUTTON_LEFT) && click && mouse_in_box(it)
            click(it);
        if it.update
            update(it, dt);
    }
}

mouse_in_box :: (box: *Box) -> bool {
    using box;
    return
        xx current_mouse_x >= x &&
        xx current_mouse_y >= y &&
        xx current_mouse_x < x + width &&
        xx current_mouse_y < y + height;
}

box_is_full :: (box: *Box) -> bool {
    return box.value == box.value_max && is_approximately_zero(1.0 - box.foreground_progress, 0.04);
}
box_is_empty :: (box: *Box) -> bool {
    return box.value == 0 && is_approximately_zero(box.foreground_progress, 0.04);
}

create_box_quest :: (x: u32, y: u32, width: u32, height: u32) {
    box := New(Box);
    box.value_max = 17;
    box.x = xx x;
    box.y = xx y;
    box.width = width;
    box.height = height;
    box.update = (box: *Box, dt: float) {
        using box;
        value_maxed := box_is_full(box);
        if mouse_in_box(box) {
            if (value_maxed)
                border_color = .{0.75,0.75,0.75,1};
            else
                border_color = .{1,1,1,1};
        }
        else {
            if (value_maxed)
                border_color = .{0.4,0.4,0.4,1};
            else
                border_color = .{0.5,0.5,0.5,1};
        }
        if (value_maxed) {
            foreground_color = C_STM_50;//.{0.45,0.33,0.05,1};
            text_color = .{0.8,0.8,0.8,1};
        }
        else {
            foreground_color = C_RCV;//.{1,0,1,1};
            text_color = .{1,1,1,1};
        }
    };
    box.click = (box: *Box) {
        if box.value < box.value_max && try_spending_stm(7) then box.value += 1;
    };
    array_add(*live_boxes, box);
}

create_box_enemy :: (x: u32, y: u32, width: u32, height: u32) {
    TEMP_ENEMY_HEAL_TIME :: 1.0;
    box := New(Box);
    box.value_max = 17;
    box.value = box.value_max;
    box.value_mode = .FRACTION;
    box.foreground_progress = 1.0;
    box.x = xx x;
    box.y = xx y;
    box.width = width;
    box.height = height;
    box.timer = TEMP_ENEMY_HEAL_TIME;
    box.foreground_color = C_LIF;//.{1,0.8,0,1};
    box.background_color = .{0.75,0.15,0.15,1};
    box.update = (box: *Box, dt: float) {
        using box;
        if !box_is_empty(box) && !box_is_full(box) {
            timer -= dt;
            if timer <= 0 {
                value += 1;
                timer += TEMP_ENEMY_HEAL_TIME;
            }
        }
        value_maxed := box_is_empty(box);
        if (value_maxed)
            border_color = .{0.2,0.2,0.2,1};
        else if mouse_in_box(box) {
            border_color = .{1,1,1,1};
        }
        else {
            border_color = .{0.5,0.5,0.5,1};
        }
        if (value_maxed) {
            background_color = .{0.13,0.13,0.13,1};
            text_color = .{0.4,0.4,0.4,1};
        }
        else {
            box.background_color = .{0.75,0.15,0.15,1};
            text_color = .{1,1,1,1};
        }
    };
    box.click = (box: *Box) {
        if box.value > 0 && try_spending_stm(7) {
            box.value -= 1;
            create_pickup(xx current_mouse_x, xx current_mouse_y, Pickup_Type.EXP, 4);
            create_pickup(xx current_mouse_x, xx current_mouse_y, Pickup_Type.GOL, 4);
        }
    };
    array_add(*live_boxes, box);
}
