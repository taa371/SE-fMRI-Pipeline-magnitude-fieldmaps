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

subs = ['97018','97028','97030','97035'] # use subs to run one or a few subjects at a time
# subs = p.subs # use p.subs to run all subs in data dir

phase_in_fn1='FM_rads_S1_R1'
phase_in_fn2='FM_rads_S2_R1'

mag_in_fn1='FM_mag_brain_S1_R1'
mag_in_fn2='FM_mag_brain_S2_R1'

phase_out_fn='FM_rads_avg'
mag_out_fn='FM_mag_avg'

# %% 
cmd = [None] * 2
for sub in tqdm(subs):

    # define subject paths
    phase_input1 = f'{datadir}/{sub}/field_maps/{phase_in_fn1}'
    phase_input2 = f'{datadir}/{sub}/field_maps/{phase_in_fn2}'

    mag_input1 = f'{datadir}/{sub}/field_maps/{mag_in_fn1}'
    mag_input2 = f'{datadir}/{sub}/field_maps/{mag_in_fn2}'

    phase_out = f'{datadir}/{sub}/field_maps/{phase_out_fn}'
    mag_out = f'{datadir}/{sub}/field_maps/{mag_out_fn}'

    # avg magnitude and phase imgs
    cmd[0] = f'fslmaths {phase_in_fn1} -add {phase_in_fn2} -div N {phase_out}'
    cmd[1] = f'fslmaths {mag_in_fn1} -add {mag_in_fn2} -div N {mag_out}'

    p.exec_cmds(cmd)