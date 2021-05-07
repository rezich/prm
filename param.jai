#import "Basic";
#import "Window_Creation";
#import "System";
#import "Input";
#import "Math";
#import "String"; // For path_strip_filename.
#import "Sloppy_Math";
Simp    :: #import "Simp";
Pool    :: #import "Pool";
Texture :: Simp.Texture;

#load "box.jai";

WINDOW_WIDTH    : s32 : 640;
WINDOW_HEIGHT   : s32 : 480;

RENDER_WIDTH    : u32 : 640;
RENDER_HEIGHT   : u32 : 480;

HUD_HEIGHT      : u32 : 48;
GAME_PADDING    : u32 : 4;

FONT_HEIGHT_ADJUST :: -2;

C_MONEY  : Vector4 : .{1,0.8,0,1};
C_EXP    : Vector4 : .{0,1,0,1};
C_LIFE   : Vector4 : .{1,0.8,0,1};
C_ACT    : Vector4 : .{1,0,1,1};

TARGET_FPS :: 60;


current_mouse_x, current_mouse_y: int;

game: struct {
    pool: Pool.Pool;
    mode: enum {
        GAME;
        MENU;
    }
    should_quit := false;
    last_time: float64;
    elapsed_time: float64;
    fps := 0;
    fps_time := 0.0;
    fps_string : string;
    font: *Simp.Dynamic_Font;
    player: struct {
        exp: u32;
        gol: u32;
        lif: u32;
        lif_max: u32;
        stm: u32;
        stm_max: u32;
        rcv: u32;
        atk: u32;
        def: u32;
    }
}
init_game :: () {
    //Pool.set_allocators(*game.pool);
    using game.player;
    exp = 0;
    gol = 0;
    lif_max = 100;
    lif = lif_max;
    stm_max = 50;
    stm = stm_max;
    rcv = 10;
    atk = 10;
    def = 10;
}
fini_game :: () {
    //Pool.release(*game.pool);
}

main :: () {

    window := create_window(window_name="PARAMETERS clone", width=WINDOW_WIDTH, height=WINDOW_HEIGHT);
    Simp.simp_init(window, WINDOW_WIDTH, WINDOW_HEIGHT, xx RENDER_WIDTH, xx RENDER_HEIGHT);

    init_game();
    init_font();

    create_box_quest(4, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_quest(108, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_enemy(212, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);

    while true {
        reset_temporary_storage();
        if game.should_quit break;
        
        did_render_frame := do_frame(window);
        if did_render_frame {
            Simp.swap_buffers(window);
            update_window_events(); // here and not above?
        }
    }

    fini_game();
}

do_frame :: (window: Window_Type) -> did_render_frame: bool {
    for events_this_frame {
        if it.type == {
            case .QUIT;
                game.should_quit = true;
            case .KEYBOARD;
                // I guess we don't need this?
        }
    }
    per_frame_update_mouse_position();

    dt: float;
    now := get_time();
    if game.last_time dt = cast(float) (now - game.last_time);
    game.last_time = now;

    game.elapsed_time += dt;
    game.fps_time += dt;

    TICK_PERIOD : float64 : 1.0 / xx TARGET_FPS;
    need_to_render := false;
    while game.elapsed_time >= TICK_PERIOD {
        game.elapsed_time -= TICK_PERIOD;
        need_to_render = true;
        update(xx TICK_PERIOD);
    }
    if need_to_render {
        game.fps += 1;
        render(window);
    }
    if game.fps_time >= 1.0 {
        free(game.fps_string);
        game.fps_string = sprint("FPS: %", game.fps);
        game.fps_time -= 1.0;
        game.fps = 0;
    }

    //Pool.reset(*game.pool);

    return need_to_render;
}

update :: (dt: float) {
    update_boxes(dt);
}

render :: (window: Window_Type) {
    Simp.update_window(window, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT);
    Simp.clear_render_target(0.1, 0.1, 0.1, 1);

    render_hud();
    render_boxes();

    draw_text_outlined(game.font, 4, 4, game.fps_string);
}

draw_text_outlined :: (font: *Simp.Dynamic_Font, x: s64, y: s64, text: string, color := Vector4.{1,1,1,1}, background := Vector4.{0,0,0,1}, effect_flags: Simp.Font_Effects = 0) {
    using Simp;
    effect_flags = effect_flags & Font_Effects.NO_KERNING; // does nothing :(
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

init_font :: () {
    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    pixel_height := 8;
    game.font = Simp.get_font_at_size("data", "slkscr.ttf", "", pixel_height);
    assert(game.font != null);
}

per_frame_update_mouse_position :: () { 
    mouse_x, mouse_y, success := get_mouse_pointer_position(true);

    if success {
        current_mouse_x = mouse_x;
        current_mouse_y = mouse_y;
    }

    // print("mouse(%, %)\n", mouse_x, mouse_y);
    // print("current_mouse(%, %)\n\n", current_mouse_x, current_mouse_y);
}

input_pressed :: (key: Key_Code) -> bool {
    return cast(bool) (input_button_states[key] & Key_Current_State.START);
}

get_player_level :: () -> u32 {
    return game.player.exp / 100; //TODO: improve
}

render_hud :: () {
    Simp.set_shader_for_color();
    Simp.immediate_quad(0, xx RENDER_HEIGHT, xx RENDER_WIDTH, cast(float) RENDER_HEIGHT - xx HUD_HEIGHT, .{0.2,0.2,0.2,1});
    draw_text_outlined(game.font, xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - game.font.character_height, tprint("LVL. %", get_player_level()), .{1,1,1,1}, .{0,0,0,1});
    draw_text_outlined(game.font, xx GAME_PADDING + 64, RENDER_HEIGHT - xx GAME_PADDING - game.font.character_height, tprint("GOL. %", game.player.gol), C_MONEY, .{0,0,0,1});
    draw_text_outlined(game.font, xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - game.font.character_height - 10, tprint("EXP. %", game.player.exp), C_EXP, .{0,0,0,1});
    draw_text_outlined(game.font, xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - game.font.character_height - 20, tprint("LIFE %/%", game.player.lif, game.player.lif_max), C_LIFE, .{0,0,0,1});
    draw_text_outlined(game.font, xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - game.font.character_height - 30, tprint("STM. %/%", game.player.stm, game.player.stm_max), C_ACT, .{0,0,0,1});
    Simp.set_shader_for_color();
}
