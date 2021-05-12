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
#load "util.jai";
#load "game.jai";

WINDOW_WIDTH    : s32 : 640;
WINDOW_HEIGHT   : s32 : 480;

RENDER_WIDTH    : u32 : 640;
RENDER_HEIGHT   : u32 : 480;

HUD_WIDTH       : u32 : 72;
GAME_PADDING    : u32 : 4;

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

main :: () {
    window := create_window(window_name="PRM", width=WINDOW_WIDTH, height=WINDOW_HEIGHT);
    Simp.simp_init(window, WINDOW_WIDTH, WINDOW_HEIGHT, xx RENDER_WIDTH, xx RENDER_HEIGHT);

    init_game();
    init_font();

    create_box_quest(HUD_WIDTH + GAME_PADDING + 0, RENDER_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_quest(HUD_WIDTH + GAME_PADDING + 104, RENDER_HEIGHT - GAME_PADDING - 25, 100, 25);
    create_box_enemy(HUD_WIDTH + GAME_PADDING + 208, RENDER_HEIGHT - GAME_PADDING - 25, 100, 25);

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
