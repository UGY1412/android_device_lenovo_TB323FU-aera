/*
 * Copyright (C) 2026 AERA Recovery Project contributors
 * SPDX-License-Identifier: Apache-2.0
 *
 * aera-aw-hal — diagnostic/fallback bridge to the Awinic HAL that stock
 * libar-pal.so carries for the AW882xx smart-PA (AW_ALGO_AUTH / cali / hmute).
 *
 * The stock PAL runtime has no public headers in this recovery tree, so this
 * tool only *probes* the exported Awinic entry points and prints what is
 * available. It intentionally does not guess ABI signatures of the internal
 * aw_ar_* wrappers; enabling the experimental mutations requires the caller to
 * pass --experimental and is expected to be done only from a debug shell.
 *
 * Environment: LD_LIBRARY_PATH must put /AERA/audio/abi and /AERA/audio/lib64
 * before /system/lib64, exactly like aera-palplayer.
 *
 * Usage:
 *   aera-aw-hal --list
 *   aera-aw-hal --list --library /path/to/libar-pal.so
 *   aera-aw-hal --experimental-noop
 */

#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

static const char* const kDefaultLibrary = "libar-pal.so";

/* Symbols observed exported by the stock Android 17 libar-pal.so. */
static const char* const kCandidates[] = {
    "aw_ar_dsp_platform_init",
    "aw_ar_dsp_get_dsp_info",
    "aw_ar_dsp_get_miid",
    "aw_ar_dsp_get_msg_num",
    "aw_ar_dsp_cali_en",
    "aw_ar_dsp_algo_en",
    "aw_ar_dsp_hmute_en",
    "aw_ar_dsp_noise_en",
    "aw_ar_dsp_set_mixer_en",
    "aw_ar_dsp_write_cali_re",
    "aw_ar_dsp_write_cali_re_array",
    "aw_ar_dsp_read_cali_re",
    "aw_ar_dsp_read_algo_auth_data",
    "aw_ar_dsp_write_algo_auth_data",
    "aw_ar_kmsg_ctl_get_auth_data",
    "aw_ar_kmsg_ctl_set_auth_data",
    "aw_ar_dsp_read_f0",
    "aw_ar_dsp_read_f0_q",
    "aw_ar_dsp_read_r0",
    "aw_ar_dsp_read_te",
    "aw_ar_dsp_read_st",
    "aw_ar_dsp_read_spin",
    "aw_ar_dsp_read_vmax",
    "aw_ar_dsp_write_vmax",
    "aw_ar_dsp_write_vol_offset",
    "aw_audioreach_dsp_algo_auth",
    "aw_audioreach_set_cali_re_time",
    "aw_audioreach_set_single_cali_en",
    "pal_custom_spk_get_cali",
    "pal_custom_spk_set_cali",
    "pal_custom_spk_set_cali_to_file",
    "pal_custom_spk_set_audio_mode",
    "pal_custom_spk_get_degree",
};

static void Log(const char* message) {
  fprintf(stderr, "AERA aw-hal: %s\n", message);
}

int main(int argc, char** argv) {
  const char* library_path = kDefaultLibrary;
  bool list_only = false;
  bool experimental = false;

  for (int index = 1; index < argc; ++index) {
    if (strcmp(argv[index], "--list") == 0) {
      list_only = true;
    } else if (strcmp(argv[index], "--experimental-noop") == 0) {
      experimental = true;
    } else if (strcmp(argv[index], "--library") == 0 && index + 1 < argc) {
      library_path = argv[++index];
    } else {
      fprintf(stderr,
              "Usage: aera-aw-hal [--list] [--experimental-noop] "
              "[--library <path>]\n");
      return 64;
    }
  }

  void* library = dlopen(library_path, RTLD_NOW | RTLD_LOCAL);
  if (library == NULL) {
    fprintf(stderr, "AERA aw-hal: cannot load %s: %s\n", library_path,
            dlerror());
    return 70;
  }

  int found = 0;
  const int total =
      (int)(sizeof(kCandidates) / sizeof(kCandidates[0]));
  for (int index = 0; index < total; ++index) {
    void* symbol = dlsym(library, kCandidates[index]);
    if (symbol != NULL) {
      ++found;
      printf("FOUND %s\n", kCandidates[index]);
    } else {
      printf("MISS  %s\n", kCandidates[index]);
    }
  }
  printf("SUMMARY %d/%d exported symbols found in %s\n", found, total,
         library_path);

  if (experimental && !list_only) {
    /* Do not call unknown-ABI symbols; print the follow-up plan instead. */
    Log("experimental mode is intentionally a no-op in this build");
    Log("the next step is a disassembly-derived signature for "
        "aw_ar_dsp_platform_init / aw_ar_dsp_write_algo_auth_data");
  }

  dlclose(library);
  return found == total ? 0 : (found > 0 ? 1 : 2);
}
