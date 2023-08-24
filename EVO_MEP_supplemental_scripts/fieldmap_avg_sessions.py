# Average Field Maps Across Sessions to Create HCP Anatomical Pipeline Input Field Map
# Holland Brown

# Updated 2023-08-23
# Created 2023-08-23

# %%
import tqdm
from my_imaging_tools import fmri_tools

datadir = '/Volumes/LACIE-SHARE/EVO_MEP_data/WCM_MRI_data'
#sublist = f'{studydir}/subjectlist.txt'
#subs = read_sublist(sublist)

p = fmri_tools(datadir) # use p.subs to run all subjects in data dir

subs = ['97025'] # use subs to run one or a few subjects at a time
# subs = p.subs

# define file names (without extensions)
phase_in_fn1='FM_rads_S1_R1'
phase_in_fn2='FM_rads_S2_R1'

mag_in_fn1='FM_mag_brain_S1_R1'
mag_in_fn2='FM_mag_brain_S2_R1'

phase_out_fn='FM_rads_avg'
mag_out_fn='FM_mag_avg'

# %% 
cmd = [None] * 2
for sub in tqdm(subs):

    fm_dir = f'{datadir}/{sub}/field_maps' # define subject field map path

    # avg magnitude and phase imgs
    cmd[0] = f'fslmaths {fm_dir}/{phase_in_fn1} -add {fm_dir}/{phase_in_fn2} -div N {fm_dir}/{phase_out_fn}'
    cmd[1] = f'fslmaths {fm_dir}/{mag_in_fn1} -add {fm_dir}/{mag_in_fn2} -div N {fm_dir}/{mag_out_fn}'

    p.exec_cmds(cmd)