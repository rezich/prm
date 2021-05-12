#import "Windows";

game: struct {
    window: Window_Type;
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
    x := GetSystemMetrics(SM_CXSCREEN) / 2 - WINDOW_WIDTH / 2;
    y := GetSystemMetrics(SM_CYSCREEN) / 2 - WINDOW_HEIGHT / 2;
    game.window = create_window(window_name="PRM", width=WINDOW_WIDTH, height=WINDOW_HEIGHT, window_x=x, window_y=y);
    Simp.simp_init(game.window, WINDOW_WIDTH, WINDOW_HEIGHT, xx RENDER_WIDTH, xx RENDER_HEIGHT);
    init_font();
    reset_game();
}

reset_game :: () {
    game.mode = .GAME;
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
