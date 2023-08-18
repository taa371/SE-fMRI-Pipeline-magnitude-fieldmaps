# Prepare Field Maps for Multi-Echo Pipeline
# Holland Brown

# Updated 2023-08-15
# Created 2023-07-10

# NOTE: raw magnitude images have 2 volumes; phase images have 1 volume
# 2023-08-15: changed filenames to reflect multiecho pipeline filenames 

# %%
import glob
from my_imaging_tools import fmri_tools

datadir = '/Volumes/LACIE-SHARE/EVO_MEP_data/WCM_MRI_data'
#sublist = f'{studydir}/subjectlist.txt'
#subs = read_sublist(sublist)

p = fmri_tools(datadir) # use p.subs to run all subjects in data dir

# subs = ['97025'] # use subs to run one or a few subjects at a time
session_num = '2' # session number
run_num = '1' # run number


# %% Brain-extract magnitude images
# NOTE: must be a tight brain extraction, erring on the side of excluding brain voxels
cmd = [None]
for sub in p.subs:
# for sub in subs:
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    magnitude_imgs = glob.glob(f'{fm_dir}/*mag*.nii.gz')
    print(len(magnitude_imgs))
    for mag_img in magnitude_imgs:
        filename = mag_img.split('/')
        file_n = filename[-1]
        file_n_list = file_n.split('.')
        fn = file_n_list[0] # filename without NIFTI extension
        fn_list = fn.split('_')
        filename_new = f"{fn_list[0]}_{fn_list[1]}_brain_{fn_list[-2]}_{fn_list[-1]}"
        # cmd[0] = f'bet {mag_img} {fm_dir}/{filename_new} -f 0.6 -m -B' # use bet command with bias-neck cleanup option
        cmd[0] = f'bet2 {mag_img} {fm_dir}/{filename_new} -f 0.6 -m' # use bet2 command instead
        p.exec_cmds(cmd)
    cmd = [None]


# %% Prepare SIEMENS phase field maps for FSL Fugue
# NOTE: need TE difference in ms from JSON files
# NOTE: for Estia/EVO study, NKI TE is 2.46; UW TE is 4.901
TE_diff = '2.46' # TE1 - TE2, in ms
cmd = [None]
for sub in p.subs:
# for sub in subs:
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    bet_magnitude_img = f'{fm_dir}/FM_mag_brain_S{session_num}_R{run_num}.nii.gz' # /path/to/BetMagnitudeNIFTI
    phase_img = f'{fm_dir}/FM_phase_S{session_num}_R{run_num}.nii.gz'
    out_img = f'{fm_dir}/FM_rads_S{session_num}_R{run_num}' # /path/to/OutputRadsFilename

    cmd[0] = f'fsl_prepare_fieldmap SIEMENS {phase_img} {bet_magnitude_img} {out_img} {TE_diff}'
    print(cmd[0])
    p.exec_cmds(cmd)


# %% SIEMENS Fugue: Distortion correction using the preprocessed field maps
# NOTE: for Estia/EVO study, this part is done in the multi-echo pipeline -> DON'T RUN
dwelltime = '0.69' # a.k.a. echo-spacing
asymtime = '2.46' # a.k.a. TE difference
sigma = '0.5' # see options for different types of smoothing (0.5 is 2D Gaussian smoothing, the default, more conservative smoothing)
echo_num = '1' # echo number for resting state NIFTI

cmd = [None]
for sub in p.subs:
# for sub in subs:
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    epi = f'{datadir}/{sub}/func/unprocessed/Rest_S{session_num}_R{run_num}_E{echo_num}.nii.gz' # resting-state functional
    unwrappedphase = f'{fm_dir}/FM_rads_S{session_num}_R{run_num}.nii.gz' # field map after fsl_prepare_fieldmap
    result = f'{fm_dir}/Rest_S{session_num}_R{run_num}_E{echo_num}_distortcorr.nii.gz'
    cmd[0] = f'fugue -i {epi} -p {unwrappedphase} --dwell={dwelltime} --asym={asymtime} -s {sigma} -u {result}'
    p.exec_cmds(cmd)
