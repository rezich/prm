#import "Basic";
#import "Window_Creation";
#import "System";
#import "Input";
#import "Math";
#import "String"; // For path_strip_filename.
#import "Sloppy_Math";
#import "Random";
Simp    :: #import "Simp";
Pool    :: #import "Pool";
Texture :: Simp.Texture;

#load "box.jai";
#load "pickup.jai";

WINDOW_WIDTH    : s32 : 640;
WINDOW_HEIGHT   : s32 : 480;

RENDER_WIDTH    : u32 : 640;
RENDER_HEIGHT   : u32 : 480;

HUD_HEIGHT      : u32 : 0; // remove?
HUD_WIDTH       : u32 : 72;
GAME_PADDING    : u32 : 4;

/*FONT_FILENAME :: "5Monopix.ttf";
FONT_TTFSIZE  :: 4;
FONT_SIZE     :: 6;*/
FONT_FILENAME :: "type_writer.ttf";
FONT_TTFSIZE  :: 8;
FONT_SIZE     :: 7;

C_GOL    : Vector4 : .{1,0.8,0,1};
C_EXP    : Vector4 : .{1,0,1,1};
C_LIF    : Vector4 : .{0,0.66,0,1}; //.{1,0.8,0,1};
C_STM    : Vector4 : .{0,0.5,0.5,1};
C_STM_50 : Vector4 : .{0,0.25,0.25,1};

C_ATK    : Vector4 : .{0.88,0,0,1};//.{0.75,0.15,0.15,1};
C_DEF    : Vector4 : .{0,0.88,0,1};
C_RCV    : Vector4 : .{0,1,1,1};
C_KEY    : Vector4 : .{0.75,0.5,0,1};

C_BACKGROUND     : Vector4 : .{0.05,0.05,0.05,1};
C_HUD_BACKGROUND : Vector4 : .{0.1,0.1,0.1,1};

TARGET_FPS :: 60;

TEMP_PLAYER_STM_RECOVERY_TIME :: 0.1;


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
        stm_timer: float;
        rcv: u32;
        atk: u32;
        def: u32;
        key: u32;
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
    stm_timer = TEMP_PLAYER_STM_RECOVERY_TIME;
    rcv = 10;
    atk = 10;
    def = 10;
    key = 0;
    random_seed(xx get_time());
}
fini_game :: () {
    //Pool.release(*game.pool);
}

main :: () {

    window := create_window(window_name="PRM", width=WINDOW_WIDTH, height=WINDOW_HEIGHT);
    Simp.simp_init(window, WINDOW_WIDTH, WINDOW_HEIGHT, xx RENDER_WIDTH, xx RENDER_HEIGHT);

    init_game();
    init_font();

    create_box_quest(HUD_WIDTH + GAME_PADDING + 0, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_quest(HUD_WIDTH + GAME_PADDING + 104, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_enemy(HUD_WIDTH + GAME_PADDING + 208, RENDER_HEIGHT - HUD_HEIGHT - GAME_PADDING - 25, 100, 25);

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
    update_pickups(dt);
    update_player(dt);
    update_boxes(dt);
}

render :: (window: Window_Type) {
    Simp.update_window(window, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT);
    Simp.clear_render_target(C_BACKGROUND.x, C_BACKGROUND.y, C_BACKGROUND.z, C_BACKGROUND.w);

    render_hud();
    render_boxes();
    render_pickups();

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
    game.font = Simp.get_font_at_size("data", FONT_FILENAME, "", FONT_TTFSIZE);
    assert(game.font != null);
}

per_frame_update_mouse_position :: () { 
    mouse_x, mouse_y, success := get_mouse_pointer_position(true);

    if success {
        current_mouse_x = max(mouse_x, 0);
        current_mouse_y = max(mouse_y, 0);
    }
}

input_pressed :: (key: Key_Code) -> bool {
    return cast(bool) (input_button_states[key] & Key_Current_State.START);
}

render_hud :: () {
    Simp.set_shader_for_color();
    Simp.immediate_quad(0, 0, xx HUD_WIDTH, xx RENDER_HEIGHT, C_HUD_BACKGROUND);
    LINE_SIZE :: FONT_SIZE + 5;
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE, 100, "LVL", tprint("%", get_player_level()), .{1,1,1,1}, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE, 98, "EXP", tprint("%", game.player.exp), C_EXP, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 2, 98, "LIF", tprint("%/%", game.player.lif, game.player.lif_max), C_LIF, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 3, 98, "STM", tprint("%/%", game.player.stm, game.player.stm_max), C_STM, 0.0);
    
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 5, 58, "ATK", tprint("%", game.player.atk), C_ATK, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 6, 58, "DEF", tprint("%", game.player.def), C_DEF, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 7, 58, "RCV", tprint("%", game.player.rcv), C_RCV, 0.0);

    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 9, 58, "GOL", tprint("%", game.player.gol), C_GOL, 0.0);
    draw_hud_stat(xx GAME_PADDING, RENDER_HEIGHT - xx GAME_PADDING - FONT_SIZE - LINE_SIZE * 10, 58, "KEY", tprint("%", game.player.key), C_KEY, 0.0);
    Simp.set_shader_for_color();
}

draw_hud_stat :: (x: s64, y: s64, width: s64, label: string, value_label: string, color: Vector4, progress: float) {
    Simp.set_shader_for_color();
    Simp.immediate_quad(xx x - 2.0, cast(float) y + xx FONT_SIZE + 2.0, cast(float) x + xx string_width(label) + 2.0, cast(float) y - 2.0, color);
    Simp.draw_text(game.font, x, y, label, .{0,0,0,1});
    Simp.draw_text(game.font, x + string_width(label) + 4, y, value_label, color);
}

string_width :: (str: string) -> int {
    return Simp.get_string_width_in_pixels(game.font, str) - 1;
}

update_player :: (dt: float) {
    using game.player;
    if stm < stm_max {
        stm_timer -= dt;
        if stm_timer <= 0 {
            stm_timer += TEMP_PLAYER_STM_RECOVERY_TIME;
            stm += 1;
        }
    }
}

try_spending_stm :: (amount: u32) -> bool {
    if game.player.stm >= amount {
        game.player.stm -= amount;
        return true;
    }
    return false;
}
get_player_level :: () -> u32 {
    return 1 + game.player.exp / 100; //TODO: improve
}
give_exp :: (amount: u32) {
    // the following is Probably Not Very Good
    lvl := get_player_level();
    game.player.exp += amount;
    if get_player_level() > lvl then level_up();
}
give_gol :: (amount: u32) {
    game.player.gol += amount;
}
level_up :: () {
    using game.player;
    stm = stm_max;
    lif = lif_max;
}
