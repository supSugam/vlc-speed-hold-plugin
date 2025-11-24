#include <vlc_common.h>
#include <vlc_interface.h>
#include <vlc_input.h>
#if LIBVLC_VERSION_MAJOR >= 4
#include <vlc_player.h>
#endif
#include <vlc_playlist.h>
#include <vlc_vout_osd.h>
#include <vlc_spu.h>
#include "config.h"
#include "osd.h"

void display_speed_text(intf_thread_t *p_intf_thread, const char* text)
{
    if (!p_intf_thread) {
        return;
    }

    if (!var_InheritBool((vlc_object_t*)p_intf_thread, DISPLAY_SPEED_CFG)) {
        if (text[0] == '\0') { // still allow clearing the text
            // fall through
        } else {
            return;
        }
    }

#if LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf_thread));
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
    playlist_t* p_playlist = pl_Get(p_intf_thread);
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