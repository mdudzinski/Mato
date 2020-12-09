$gtk.ffi_misc.gtk_dlopen("ext")

class GTK::Inputs
  def left_right
    return  0 if !self.left == !self.right
    return -1 if self.left
    return  1 if self.right
  end
  def up_down
    return  0 if !(self.up || self.keyboard.space) == !self.down
    return  1 if self.up || self.keyboard.space
    return -1 if self.down
  end
end


# @param args [GTK::Args]
def tick args
  args.state.map_seed       ||= 0
  args.state.map_slice      ||= 0
  args.state.brush_material ||= "XHST"
  args.state.vert_move      ||= 0
  args.state.horz_move      ||= 0
  args.state.sprite_x       ||= 0

  if Kernel.tick_count == 0 || args.inputs.keyboard.t
    FFI::MatoCore::generate_terrain(args.state.map_seed.to_i, args.state.map_slice.to_i)
    args.state.map_slice += 1
  else
    FFI::MatoCore::update_terrain
  end

  args.state.player_ptr ||= FFI::MatoCore::spawn_player(640.0, 360.0, 1.0, 0.3, 0.3)
  args.state.sprite_x   = (args.state.sprite_x*0.9 + 0.1*(FFI::MatoCore::player_x_pos(args.state.player_ptr) - 640)).to_i.clamp(0, 1280 * 3)

  FFI::MatoCore::destroy_terrain((args.inputs.mouse.x + args.state.sprite_x).to_i, args.inputs.mouse.y.to_i, 5) if args.inputs.mouse.button_right
  FFI::MatoCore::create_terrain((args.inputs.mouse.x + args.state.sprite_x).to_i, args.inputs.mouse.y.to_i, 3, args.state.brush_material) if args.inputs.mouse.button_left

  vert_move_ratio      = 0
  horz_move_ratio      = 0.5
  args.state.vert_move = args.state.vert_move * vert_move_ratio + args.inputs.up_down * (1 - vert_move_ratio)
  args.state.vert_move = 0 if args.inputs.up_down <= 0
  args.state.horz_move = args.state.horz_move * horz_move_ratio + args.inputs.left_right * (1 - horz_move_ratio)

  args.state.vert_move = 0 if args.state.vert_move.abs < 0.1 && args.inputs.up_down == 0
  args.state.horz_move = 0 if args.state.horz_move.abs < 0.1 && args.inputs.left_right == 0

  FFI::MatoCore::player_input(args.state.player_ptr, args.state.vert_move.to_f, args.state.horz_move.to_f)
  FFI::MatoCore::player_tick(args.state.player_ptr)

  FFI::MatoCore::draw_terrain
  FFI::MatoCore::draw_player(args.state.player_ptr)

  FFI::MatoCore::screen_to_sprite("screen")

  args.outputs.sprites << [-args.state.sprite_x, 0, 1280 * 4, 720, :screen].sprite
  args.outputs.debug << [
      [0, 40.from_top, 80, 40, 0, 0, 0, 255].solid,
      {x: 10, y: 10.from_top, text: "#{($gtk.current_framerate + 0.5).to_i} FPS", r: 255, g: 255, b: 255}.label
  ]
end


GTK::Console.const_set("XHST", "XHST")
GTK::Console.const_set("SMKE", "SMKE")
GTK::Console.const_set("SAND", "SAND")
GTK::Console.const_set("DIRT", "DIRT")
GTK::Console.const_set("NONE", "NONE")

def brushtype material = ""
  old                        = $args.state.brush_material
  $args.state.brush_material = material
  if material == "XHST"
    "Terrain brush set to exhaust (XHST)"
  elsif material == "SMKE"
    "Terrain brush set to smoke (SMKE)"
  elsif material == "DIRT"
    "Terrain brush set to dirt (DIRT)"
  elsif material == "SAND"
    "Terrain brush set to sand (SAND)"
  elsif material == "NONE"
    "Terrain brush disabled"
  else
    $args.state.brush_material = old
    "USAGE: brushtype [MATERIAL]\n     Valid materials: XHST, SMKE, DIRT, SAND, NONE"
  end
end

def spawn_player
  FFI::MatoCore::spawn_player((Kernel.rand * (1280 - 32)).to_f, 360.to_f, Kernel.rand.to_f, Kernel.rand.to_f, Kernel.rand.to_f)
end