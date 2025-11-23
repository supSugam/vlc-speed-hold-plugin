/*****************************************************************************
 * speed_hold.c : A plugin that allows to speed up a video by holding a mouse button
 *****************************************************************************
 * Copyright (C) 2025 supSugam
 *
 * Authors: supSugam
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>

#ifdef HAVE_CONFIG_H
# include "config.h"
#else
# define N_(str) (str)
#endif

#include <vlc/libvlc_version.h>
#include "version.h"

#if LIBVLC_VERSION_MAJOR >= 3
# define VLC_MODULE_LICENSE VLC_LICENSE_LGPL_2_1_PLUS
# define VLC_MODULE_COPYRIGHT VERSION_COPYRIGHT
#endif

#include <vlc_atomic.h>
#include <vlc_common.h>
#include <vlc_filter.h>
#include <vlc_input.h>
#include <vlc_messages.h>
#include <vlc_mouse.h>
#if LIBVLC_VERSION_MAJOR >= 4
# include <vlc_player.h>
#endif
#include <vlc_playlist.h>
#include <vlc_plugin.h>
#if LIBVLC_VERSION_MAJOR == 2
# include <vlc_spu.h>
#endif
#include <vlc_threads.h>
#include <vlc_vout.h>
#include <vlc_vout_osd.h>
#include <vlc_config.h>

#if LIBVLC_VERSION_MAJOR == 2 && LIBVLC_VERSION_MINOR == 1
# include "third_party/vlc/2.1.0/include/vlc_interface.h"
#elif LIBVLC_VERSION_MAJOR == 2 && LIBVLC_VERSION_MINOR == 2
# include "third_party/vlc/2.2.0/include/vlc_interface.h"
#elif LIBVLC_VERSION_MAJOR >= 3 && LIBVLC_VERSION_MINOR >= 0
# include <vlc_interface.h>
#else
# error "VLC version < 2.1 is not supported"
#endif

#define UNUSED(x) (void)(x)

static const char *const mouse_button_names[] = {N_("None"), N_("Left Button"), N_("Middle Button"), N_("Right Button"), N_("Scroll Up"), N_("Scroll Down"), N_("Scroll Left"), N_("Scroll Right")};
static const int mouse_button_values_index[] = {0, 1, 2, 3, 4, 5, 6, 7};
static const int mouse_button_values[] = {-1, 1, 4, 2, 8, 16, 32, 64};

#define CFG_PREFIX "speed-hold-"

#define MOUSE_BUTTON_CFG CFG_PREFIX "mouse-button"
#define MOUSE_BUTTON_DEFAULT 1 // MOUSE_BUTTON_LEFT

#define ACCELERATION_RATE_CFG CFG_PREFIX "rate"
#define ACCELERATION_RATE_DEFAULT 2.0f

#define HOLD_DELAY_CFG CFG_PREFIX "hold-delay"
#define HOLD_DELAY_DEFAULT 200

#define DISPLAY_SPEED_CFG CFG_PREFIX "display-speed"
#define DISPLAY_SPEED_DEFAULT true

#define REGIONAL_SPEED_CFG CFG_PREFIX "regional-speed"
#define REGIONAL_SPEED_DEFAULT false

#define EDGE_ACCELERATION_RATE_CFG CFG_PREFIX "edge-rate"
#define EDGE_ACCELERATION_RATE_DEFAULT 4.0f

static int OpenFilter(vlc_object_t *);
static void CloseFilter(vlc_object_t *);
static int OpenInterface(vlc_object_t *);
static void CloseInterface(vlc_object_t *);
static void SetRate(vlc_object_t *p_obj, float rate);
static void display_speed_text(vlc_object_t *p_obj, const char* text);

static intf_thread_t *p_intf = NULL;
static vlc_timer_t timer;
static bool timer_initialized = false;
static atomic_bool timer_scheduled;

struct filter_sys_t
{
    float original_rate;
    bool rate_changed_by_mouse;
    int mouse_x;
    int mouse_y;
};

// VLC 4.0 removed the advanced flag in 3716a7da5ba8dc30dbd752227c6a893c71a7495b
#if LIBVLC_VERSION_MAJOR >= 4
# define _add_bool(name, v, text, longtext, advc) \
    add_bool(name, v, text, longtext)
# define _add_integer(name, value, text, longtext, advc) \
    add_integer(name, value, text, longtext)
# define _add_integer_with_range(name, value, i_min, i_max, text, longtext, advc) \
    add_integer_with_range(name, value, i_min, i_max, text, longtext)
# define _add_float(name, value, text, longtext, advc) \
    add_float(name, value, text, longtext)
#else
# define _add_bool add_bool
# define _add_integer add_integer
# define _add_integer_with_range add_integer_with_range
# define _add_float add_float
#endif

// VLC 4.0 made set_help() render as a plain text, introducing set_html_help()
// for HTML
// faf8b85ac3e55bc95cfd80f914e8537c47d2c1a5
// caf143311e00acf24533b498890df2e57a7a80e2
#if LIBVLC_VERSION_MAJOR >= 4
# define _set_help(str) \
    set_help_html(str)
#else
# define _set_help(str) \
    set_help(str)
#endif

vlc_module_begin()
    set_description(N_("Click to pause/play, hold to increase playback speed"))
    set_shortname(N_("Pause/Speed Hold"))
#if LIBVLC_VERSION_MAJOR == 2
    set_capability("video filter2", 0)
#elif LIBVLC_VERSION_MAJOR == 3
    set_capability("video filter", 0)
#endif
// VLC 4.0 removed categories and changed the way video filter callbacks are set
// 6f68f894986e11e3f6215f6c2c25e5c0a3139429
// 94e23d51bb91cff1c14ef1079193920f04f48fd1
#if LIBVLC_VERSION_MAJOR >= 4
    set_callback_video_filter((vlc_filter_open) OpenFilter)
#else
    set_category(CAT_VIDEO)
    set_callbacks(OpenFilter, CloseFilter)
#endif
    set_subcategory(SUBCAT_VIDEO_VFILTER)
    _set_help(N_("<style>"
                 "p { margin:0.5em 0 0.5em 0; }"
                 "</style>"
                 "<p>"
                 "v" VERSION_STRING "<br>"
                 "Copyright " VERSION_COPYRIGHT
                 "</p>"
                 "<p>"
                 "Homepage: <a href=\"" VERSION_HOMEPAGE "\">" VERSION_HOMEPAGE "</a>"
                 "</p>"))
    set_section(N_("General"), NULL)
    /* _add_integer(MOUSE_BUTTON_CFG, MOUSE_BUTTON_DEFAULT,
                 N_("Action mouse button"),
                 N_("Defines the mouse button for all actions."), false)
    vlc_config_set(VLC_CONFIG_LIST, (size_t)(sizeof(mouse_button_values_index)/sizeof(int))-1,
                   mouse_button_values_index+1, mouse_button_names+1); */
    _add_float(ACCELERATION_RATE_CFG, ACCELERATION_RATE_DEFAULT,
              N_("Acceleration rate"),
              N_("Playback rate to set when acceleration is active."), false)
    _add_integer_with_range(HOLD_DELAY_CFG, HOLD_DELAY_DEFAULT, 100, 2000,
                            N_("Hold delay (ms)"),
                            N_("Time to hold the mouse button to trigger acceleration."), false)
    _add_bool(DISPLAY_SPEED_CFG, DISPLAY_SPEED_DEFAULT,
              N_("Display speed text"),
              N_("Show the current speed on screen when accelerating."), false)
    _add_bool(REGIONAL_SPEED_CFG, REGIONAL_SPEED_DEFAULT,
              N_("Enable regional speed control"),
              N_("Enable different speed controls based on mouse position."), false)
    set_section(N_("Regional Speed"), NULL)
    _add_float(EDGE_ACCELERATION_RATE_CFG, EDGE_ACCELERATION_RATE_DEFAULT,
              N_("Edge acceleration rate"),
              N_("Playback rate for the edges of the screen (first and last 20%). "
                 "Only used when regional speed control is enabled."), true)
        add_submodule()
        set_capability("interface", 0)
#if LIBVLC_VERSION_MAJOR <= 3
        set_category(CAT_INTERFACE)
#endif
        set_subcategory(SUBCAT_INTERFACE_CONTROL)
        set_callbacks(OpenInterface, CloseInterface)
vlc_module_end()

static void display_speed_text(vlc_object_t *p_obj, const char* text)
{
    if (!p_intf) {
        return;
    }

    if (!var_InheritBool(p_obj, DISPLAY_SPEED_CFG)) {
        if (text[0] == '\0') { // still allow clearing the text
            // fall through
        } else {
            return;
        }
    }

#if LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf));
    vlc_player_Lock(player);
    vout_thread_t** pp_vout;
    size_t i_vout;
    pp_vout = vlc_player_vout_HoldAll(player, &i_vout);
    if (!pp_vout) {
        vlc_player_Unlock(player);
        return;
    }
    for (size_t i = 0; i < i_vout; i ++) {
        vout_OSDText(pp_vout[i], VOUT_SPU_CHANNEL_OSD, VOUT_ALIGN_TOP | VOUT_ALIGN_RIGHT, INT64_MAX, text);
        vout_Release(pp_vout[i]);
    }
    vlc_player_Unlock(player);
    free(pp_vout);
#else
    playlist_t* p_playlist = pl_Get(p_intf);
    input_thread_t* p_input = playlist_CurrentInput(p_playlist);
    if (!p_input) {
        return;
    }

    vout_thread_t** pp_vout;
    size_t i_vout;
    if (input_Control(p_input, INPUT_GET_VOUTS, &pp_vout, &i_vout) != VLC_SUCCESS) {
        vlc_object_release(p_input);
        return;
    }
    for (size_t i = 0; i < i_vout; i ++) {
        vout_OSDText(pp_vout[i], VOUT_SPU_CHANNEL_OSD, VOUT_ALIGN_TOP | VOUT_ALIGN_RIGHT, INT64_MAX, text);
        vlc_object_release((vlc_object_t *)pp_vout[i]);
    }
    vlc_object_release(p_input);
    free(pp_vout);
#endif
}

#include <vlc_spu.h>
static void pause_play(void)
{
    if (!p_intf) {
        return;
    }

#if 2 <= LIBVLC_VERSION_MAJOR && LIBVLC_VERSION_MAJOR <= 3
    playlist_t* p_playlist = pl_Get(p_intf);
    playlist_status_t status = playlist_Status(p_playlist);
    playlist_Control(p_playlist, status == PLAYLIST_RUNNING ? PLAYLIST_PAUSE : PLAYLIST_PLAY , 0);
#elif LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf));
    vlc_player_Lock(player);
    int state = vlc_player_GetState(player);
    state == VLC_PLAYER_STATE_PLAYING ? vlc_player_Pause(player) : vlc_player_Resume(player);
    vlc_player_Unlock(player);
#endif
}

static void timer_callback(void* data)
{
    if (!atomic_load(&timer_scheduled)) {
        return;
    }
    atomic_store(&timer_scheduled, false);

    filter_t *p_filter = (filter_t *) data;
    filter_sys_t *p_sys = p_filter->p_sys;
    if (!p_sys) return;

    msg_Dbg(p_filter, "[Speed Hold] Timer fired, starting acceleration");

    if (!p_sys->rate_changed_by_mouse) {
        p_sys->rate_changed_by_mouse = true;
        
        float new_rate;
        bool regional_speed = var_InheritBool(p_filter, REGIONAL_SPEED_CFG);

        if (regional_speed) {
            int width = p_filter->fmt_in.video.i_width;
            float percentage = (float)p_sys->mouse_x / width;
            
            if (percentage < 0.2f || percentage > 0.8f) {
                new_rate = var_InheritFloat(p_filter, EDGE_ACCELERATION_RATE_CFG);
            } else {
                new_rate = var_InheritFloat(p_filter, ACCELERATION_RATE_CFG);
            }
        } else {
            new_rate = var_InheritFloat(p_filter, ACCELERATION_RATE_CFG);
        }

        msg_Dbg(p_filter, "[Speed Hold] Accelerating to rate: %f", new_rate);
        SetRate((vlc_object_t*)p_filter, new_rate);

        char text[32];
        if (new_rate == (float)(int)new_rate) {
            snprintf(text, sizeof(text), "%dx", (int)new_rate);
        } else {
            snprintf(text, sizeof(text), "%.2fx", new_rate);
        }
        display_speed_text((vlc_object_t*)p_filter, text);
    }
}

static void SetRate(vlc_object_t *p_obj, float rate)
{
    msg_Dbg(p_obj, "[Speed Hold] SetRate called with rate: %f", rate);
    if (!p_intf) {
        msg_Err(p_obj, "[Speed Hold] SetRate failed: p_intf is NULL");
        return;
    }

#if LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf));
    vlc_player_Lock(player);
    vlc_player_SetRate(player, rate);
    vlc_player_Unlock(player);
#else
    playlist_t* p_playlist = pl_Get(p_intf);
    input_thread_t *p_input = playlist_CurrentInput(p_playlist);
    if(p_input)
    {
        var_SetFloat(p_input, "rate", rate);
        vlc_object_release(p_input);
    } else {
        msg_Warn(p_obj, "[Speed Hold] SetRate failed: could not get p_input");
    }
#endif
    VLC_UNUSED(p_obj);
}



static int mouse(filter_t *p_filter, vlc_mouse_t *p_mouse_out, const vlc_mouse_t *p_mouse_old, const vlc_mouse_t *p_mouse_new)
{
    *p_mouse_out = *p_mouse_new;

    // Ignore mouse move events that don't involve a button press/release
    if (p_mouse_old->i_pressed == p_mouse_new->i_pressed)
        return VLC_SUCCESS;

    filter_sys_t *p_sys = p_filter->p_sys;
    if (!p_sys) return VLC_SUCCESS;

    msg_Dbg(p_filter, "[Speed Hold] mouse event: old_pressed=%d, new_pressed=%d", p_mouse_old->i_pressed, p_mouse_new->i_pressed);

    const int mouse_button = 1; // MOUSE_BUTTON_LEFT
    msg_Dbg(p_filter, "[Speed Hold] hardcoded mouse button: %d", mouse_button);

    bool is_pressed = p_mouse_new->i_pressed & mouse_button;
    bool was_pressed = p_mouse_old->i_pressed & mouse_button;

    if (is_pressed && !was_pressed) {
        msg_Dbg(p_filter, "[Speed Hold] Mouse button pressed, scheduling timer");
        p_sys->mouse_x = p_mouse_new->i_x;
        p_sys->mouse_y = p_mouse_new->i_y;
        atomic_store(&timer_scheduled, true);
        int64_t delay = var_InheritInteger(p_filter, HOLD_DELAY_CFG);
        vlc_timer_schedule(timer, false, delay * 1000, 0);

    } else if (!is_pressed && was_pressed) {
        msg_Dbg(p_filter, "[Speed Hold] Mouse button released");
        if (atomic_exchange(&timer_scheduled, false)) {
            // Timer was still scheduled, so it's a click
            msg_Dbg(p_filter, "[Speed Hold] Click detected, pausing/playing");
            vlc_timer_schedule(timer, false, 0, 0); // Unschedule
            pause_play();
        } else {
            // Timer already fired, so it was a hold
            if (p_sys->rate_changed_by_mouse) {
                p_sys->rate_changed_by_mouse = false;
                msg_Dbg(p_filter, "[Speed Hold] Restoring original rate: %f", p_sys->original_rate);
                SetRate((vlc_object_t*)p_filter, p_sys->original_rate);
                display_speed_text((vlc_object_t*)p_filter, "");
            }
        }
    }

    return VLC_SUCCESS;
}

static picture_t *filter(filter_t *p_filter, picture_t *p_pic_in)
{
    UNUSED(p_filter);
    return p_pic_in;
}

#if LIBVLC_VERSION_MAJOR >= 4
static int _mouse(filter_t *p_filter, vlc_mouse_t *p_mouse_new_out, const vlc_mouse_t *p_mouse_old)
{
    vlc_mouse_t p_mouse_new = *p_mouse_new_out;
    return mouse(p_filter, p_mouse_new_out, p_mouse_old, &p_mouse_new);
}

static const struct vlc_filter_operations filter_ops =
{
    .filter_video = filter,
    .video_mouse = _mouse,
    .close = (void (*)(filter_t *)) CloseFilter,
};
#endif

static void print_version(vlc_object_t *p_obj)
{
    msg_Dbg(p_obj, "v" VERSION_STRING ", " VERSION_COPYRIGHT ", " VERSION_LICENSE);
    msg_Dbg(p_obj, VERSION_HOMEPAGE);
}

static int OpenFilter(vlc_object_t *p_this)
{
    filter_t *p_filter = (filter_t *) p_this;

    print_version(p_this);
    msg_Dbg(p_filter, "[Speed Hold] filter sub-plugin opened");
    msg_Dbg(p_filter, "[Speed Hold] MOUSE_BUTTON_LEFT = %d", 1);
    msg_Dbg(p_filter, "[Speed Hold] MOUSE_BUTTON_RIGHT = %d", 2);
    msg_Dbg(p_filter, "[Speed Hold] MOUSE_BUTTON_CENTER = %d", 4);

    if (!p_intf) {
        msg_Err(p_filter, "[Speed Hold] interface sub-plugin is not initialized. "
                "Did you tick \"Speed Hold\" checkbox in "
                "Preferences -> All -> Interface -> Control interfaces? "
                "Don't forget to restart VLC afterwards");
        return VLC_EGENERIC;
    }

    filter_sys_t *p_sys = calloc(1, sizeof(filter_sys_t));
    if (!p_sys)
        return VLC_ENOMEM;

    p_filter->p_sys = p_sys;
    p_sys->rate_changed_by_mouse = false;

#if LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf));
    vlc_player_Lock(player);
    p_sys->original_rate = vlc_player_GetRate(player);
    vlc_player_Unlock(player);
#else
    playlist_t* p_playlist = pl_Get(p_intf);
    input_thread_t *p_input = playlist_CurrentInput(p_playlist);
    if(p_input)
    {
        p_sys->original_rate = var_GetFloat(p_input, "rate");
        vlc_object_release(p_input);
    } else {
        p_sys->original_rate = 1.0f;
        msg_Warn(p_filter, "[Speed Hold] Could not get current input, original_rate set to 1.0");
    }
#endif

    msg_Dbg(p_filter, "[Speed Hold] Original rate stored: %f", p_sys->original_rate);

    if (vlc_timer_create(&timer, timer_callback, p_filter) != VLC_SUCCESS)
    {
        msg_Err(p_filter, "Couldn't create a timer");
        free(p_sys);
        return VLC_EGENERIC;
    }
    timer_initialized = true;
    atomic_store(&timer_scheduled, false);

#if LIBVLC_VERSION_MAJOR >= 4
    p_filter->ops = &filter_ops;
#else
    p_filter->pf_video_filter = filter;
    p_filter->pf_video_mouse = mouse;
#endif

    return VLC_SUCCESS;
}

static void CloseFilter(vlc_object_t *p_this)
{
    filter_t *p_filter = (filter_t *)p_this;
    filter_sys_t *p_sys = p_filter->p_sys;

    msg_Dbg(p_this, "[Speed Hold] filter sub-plugin closed");

    if (timer_initialized) {
        vlc_timer_destroy(timer);
        timer_initialized = false;
    }

    if(p_sys)
    {
        if (p_sys->rate_changed_by_mouse) {
            msg_Dbg(p_this, "[Speed Hold] Restoring original rate on close: %f", p_sys->original_rate);
            SetRate(p_this, p_sys->original_rate);
            display_speed_text(p_this, "");
        }
        free(p_sys);
    }
}

static int OpenInterface(vlc_object_t *p_this)
{
    p_intf = (intf_thread_t*) p_this;

    print_version(p_this);
    msg_Dbg(p_intf, "[Speed Hold] interface sub-plugin opened");

    return VLC_SUCCESS;
}

static void CloseInterface(vlc_object_t *p_this)
{
    msg_Dbg(p_this, "[Speed Hold] interface sub-plugin closed");

    p_intf = NULL;
}




