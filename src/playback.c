#include <vlc_common.h>
#include <vlc_interface.h>
#include <vlc_input.h>
#if LIBVLC_VERSION_MAJOR >= 4
#include <vlc_player.h>
#endif
#include <vlc_playlist.h>

#include "playback.h"

void SetRate(intf_thread_t *p_intf_thread, float rate)
{
    if (!p_intf_thread) {
        return;
    }

#if LIBVLC_VERSION_MAJOR >= 4
    vlc_player_t* player = vlc_playlist_GetPlayer(vlc_intf_GetMainPlaylist(p_intf_thread));
    vlc_player_Lock(player);
    vlc_player_SetRate(player, rate);
    vlc_player_Unlock(player);
#else
    playlist_t* p_playlist = pl_Get(p_intf_thread);
    input_thread_t *p_input = playlist_CurrentInput(p_playlist);
    if(p_input)
    {
        var_SetFloat(p_input, "rate", rate);
        vlc_object_release(p_input);
    }
#endif
}
