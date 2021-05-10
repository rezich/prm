PickupCollectFunction :: #type(pickup: *Pickup);

PICKUP_BOUNCES         :: 2;
PICKUP_WIDTH           :: 3;
PICKUP_MARGIN          :: 2;
PICKUP_LIFETIME        :: 3.0;
PICKUP_INVINCIBLE_TIME :: 0.25;

PICKUP_X_VELOCITY_MAX  :: 2.25;
PICKUP_FRICTION        :: 1.25;

PICKUP_Y_VELOCITY_MIN  :: 3.0;
PICKUP_Y_VELOCITY_MAX  :: 6.0;
PICKUP_GRAVITY         :: 15.0;
PICKUP_BOUNCE_DECAY    :: 0.75;

Pickup_Type :: enum {
    EXP;
    GOL;
}

Pickup :: struct {
    x: u32;
    y: u32;
    y_initial: u32;
    x_velocity: float;
    y_velocity: float;
    bounces_remaining: u32;
    value: u32;
    type: Pickup_Type;
    collect: PickupCollectFunction;
    timer: float;
    invincible_timer: float;
}

live_pickups : [..] *Pickup;

render_pickups :: () {
    for live_pickups {
        using it;
        color: Vector4;
        if type == {
            case .EXP;
                color = C_EXP;
            case .GOL;
                color = C_GOL;
        }
        draw_text_outlined(
            game.font,
            x - 1, // temporary?
            y - FONT_SIZE / 2,
            tprint("%", value),
            color,
            .{0,0,0,1}
        );
    }
}

update_pickups :: (dt: float) {
    for live_pickups {
        using it;
        // invincible timer
        invincible_timer = max(invincible_timer - dt, 0.0);
        // timer
        timer -= dt;
        if timer <= 0 {
            array_unordered_remove_by_value(*live_pickups, it);
            continue;
        }
        else {
            // move
            if y > y_initial {
                y_velocity -= PICKUP_GRAVITY * dt;
            }
            else if bounces_remaining > 0 {
                y_velocity = -y_velocity * PICKUP_BOUNCE_DECAY;
                bounces_remaining -= 1;
            }
            else {
                y_velocity = 0;
            }
            if x_velocity > 0 then x_velocity = max(x_velocity - PICKUP_FRICTION * dt, 0);
            if x_velocity < 0 then x_velocity = min(x_velocity + PICKUP_FRICTION * dt, 0);
            x += xx x_velocity;
            y = max(y + xx y_velocity, y_initial);
        }
        // collect
        if invincible_timer == 0.0 && mouse_in_pickup(it) {
            if type == {
                case .EXP;
                    give_exp(value);
                case .GOL;
                    give_gol(value);
            }
            array_unordered_remove_by_value(*live_pickups, it);
            continue;
        }
    }
}

create_pickup :: (x: u32, y: u32, type: Pickup_Type, value: u32) {
    pickup := New(Pickup);
    pickup.x = x;
    pickup.y = y + 1; // hack?
    pickup.y_initial = y;
    pickup.x_velocity = random_get_within_range(-PICKUP_X_VELOCITY_MAX, PICKUP_X_VELOCITY_MAX);
    pickup.y_velocity = random_get_within_range(PICKUP_Y_VELOCITY_MIN, PICKUP_Y_VELOCITY_MAX);
    pickup.value = value;
    pickup.type = type;
    pickup.bounces_remaining = PICKUP_BOUNCES;
    pickup.timer = PICKUP_LIFETIME;
    pickup.invincible_timer = PICKUP_INVINCIBLE_TIME;
    array_add(*live_pickups, pickup);
}

mouse_in_pickup :: (pickup: *Pickup) -> bool {
    using pickup;
    return
        xx current_mouse_x >= x - PICKUP_MARGIN &&
        xx current_mouse_y >= y - PICKUP_MARGIN &&
        xx current_mouse_x < x + PICKUP_WIDTH + PICKUP_MARGIN &&
        xx current_mouse_y < y + FONT_SIZE + PICKUP_MARGIN;
}
