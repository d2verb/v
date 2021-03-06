// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module main

import time
import sokol
import sokol.sapp
import sokol.gfx
import sokol.sgl
import particle

const (
	used_import = sokol.used_import
)

fn main() {
	app := &App{
		width: 800
		height: 400
		pass_action: gfx.create_clear_pass(0.1, 0.1, 0.1, 1.0)
	}
	app.init()
	app.run()
}

struct App {
	pass_action C.sg_pass_action
mut:
	width       int
	height      int
	frame       i64
	last        i64
	ps          particle.System
}

fn (mut a App) init() {
	a.frame = 0
	a.last = time.ticks()
	a.ps = particle.System{a.width, a.height}
	a.ps.init(particle.SystemConfig{
		pool: 20000
	})
}

fn (mut a App) cleanup() {
	a.ps.free()
}

fn (a App) run() {
	title := 'V Particle Example'
	desc := C.sapp_desc{
		width: a.width
		height: a.height
		user_data: &a
		init_userdata_cb: init
		frame_userdata_cb: frame
		event_userdata_cb: event
		window_title: title.str
		html5_canvas_name: title.str
		cleanup_userdata_cb: cleanup
	}
	sapp.run(&desc)
}

fn (a App) draw() {
	a.ps.draw()
}

fn init(user_data voidptr) {
	desc := C.sg_desc{
		mtl_device: sapp.metal_get_device()
		mtl_renderpass_descriptor_cb: sapp.metal_get_renderpass_descriptor
		mtl_drawable_cb: sapp.metal_get_drawable
		d3d11_device: sapp.d3d11_get_device()
		d3d11_device_context: sapp.d3d11_get_device_context()
		d3d11_render_target_view_cb: sapp.d3d11_get_render_target_view
		d3d11_depth_stencil_view_cb: sapp.d3d11_get_depth_stencil_view
	}
	gfx.setup(&desc)
	sgl_desc := C.sgl_desc_t{
		max_vertices: 50 * 65536
	}
	sgl.setup(&sgl_desc)
}

fn cleanup(user_data voidptr) {
	mut app := &App(user_data)
	app.cleanup()
	gfx.shutdown()
}

fn frame(user_data voidptr) {
	mut app := &App(user_data)
	app.width = sapp.width()
	app.height = sapp.height()
	t := time.ticks()
	dt := f64(t - app.last) / 1000.0
	app.ps.update(dt)
	draw(app)
	gfx.begin_default_pass(&app.pass_action, app.width, app.height)
	sgl.draw()
	gfx.end_pass()
	gfx.commit()
	app.frame++
	app.last = t
}

fn event(ev &C.sapp_event, user_data voidptr) {
	mut app := &App(user_data)
	if ev.@type == .mouse_move {
		app.ps.explode(ev.mouse_x, ev.mouse_y)
	}
	if ev.@type == .mouse_up || ev.@type == .mouse_down {
		if ev.mouse_button == .left {
			is_pressed := ev.@type == .mouse_down
			if is_pressed {
				app.ps.explode(ev.mouse_x, ev.mouse_y)
			}
		}
	}
	if ev.@type == .key_up || ev.@type == .key_down {
		if ev.key_code == .r {
			is_pressed := ev.@type == .key_down
			if is_pressed {
				app.ps.reset()
			}
		}
	}
}

fn draw(a &App) {
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, f32(sapp.width()), f32(sapp.height()), 0.0, -1.0, 1.0)
	sgl.push_matrix()
	a.draw()
	sgl.pop_matrix()
}
