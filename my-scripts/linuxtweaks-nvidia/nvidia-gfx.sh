#!/bin/bash
# tolga erok - hardened boot-safe NVIDIA env setup

### NVIDIA Rendering Options
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
export __GL_SYNC_TO_VBLANK=1
export __GL_MaxFramesAllowed=1
export __GL_SHADER_CACHE=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH=/tmp
export __GLX_VENDOR_LIBRARY_NAME=nvidia

### Vulkan & Video Acceleration
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia
# export GBM_BACKEND=nvidia-drm   <-- Disabled to prevent early boot hangs

### Wayland & Compositor
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
export MOZ_ENABLE_WAYLAND=1
export NIXOS_OZONE_WL=1
export OBS_USE_EGL=1

### Misc
export QT_LOGGING_RULES="*=false"

# Unset sensitive vars moved to user session:
# unset VK_ICD_FILENAMES
# unset KWIN_DRM_USE_EGL_STREAMS
# unset KWIN_DRM_NO_AMS
