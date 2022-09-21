
# -------------- IMPORTS --------------
import os
import sys
import numpy as np
import nibabel as nib
from glob import glob
from scipy.stats import norm


# -------------- READ INPUTS FROM TERMINAL --------------
netcorr_dir = sys.argv[1]

if len(sys.argv) > 2:
    alpha = float(sys.argv[2])
else:
    alpha = 0.05


# -------------- SEARCH FOR FILES --------------
rois_left = glob(netcorr_dir + '/netcorr_left_000_INDIV/WB_Z_ROI*BRIK') 
rois_right = glob(netcorr_dir + '/netcorr_right_000_INDIV/WB_Z_ROI*BRIK') 


# -------------- THRESHOLD DATA OF EACH ROI USING CIs --------------
rois_n = len(rois_left)
for left,right in zip(rois_left, rois_right): #np.arange(rois_n):

# LOAD DATA
    left_brik = nib.load(left)
    left_data = left_brik.get_fdata()

    right_brik = nib.load(right)
    right_data = right_brik.get_fdata()

# SOME PREPROCESSING
    left_data_1D = left_data.reshape(np.prod(left_data.shape), 1 )
    left_data_1D = left_data_1D[left_data_1D != 0 ]

    right_data_1D = right_data.reshape(np.prod(right_data.shape), 1 )
    right_data_1D = right_data_1D[right_data_1D != 0 ]

# CALCULATE CIs
## Descriptive stats
    left_data_mean = left_data_1D.mean()
    left_data_sd   = left_data_1D.std()

    right_data_mean = right_data_1D.mean()
    right_data_sd   = right_data_1D.std()

## CI
    scale = abs(norm.ppf(alpha/2))
    left_ci_bounds  = [left_data_mean - scale*left_data_sd, left_data_mean + scale*left_data_sd]
    right_ci_bounds = [right_data_mean - scale*right_data_sd, right_data_mean + scale*right_data_sd]

# THRESHOLDING 
    left_low_bound_mask  = left_data <= left_ci_bounds[0]
    left_high_bound_mask = left_data >= left_ci_bounds[1]
    left_mask            = left_low_bound_mask + left_high_bound_mask
    left_data_thresh     = left_data * left_mask

    right_low_bound_mask  = right_data <= right_ci_bounds[0]
    right_high_bound_mask = right_data >= right_ci_bounds[1]
    right_mask            = right_low_bound_mask + right_high_bound_mask
    right_data_thresh     = right_data * right_mask

# SAVE THRESHOLDED DATA AS NIFTI
    left_basename = os.path.splitext(left)
    left_filename = left_basename[0]
    left_outname  = left_filename.split("+")[0] + '_thresh.nii.gz'
    left_data_nii = nib.Nifti1Image(left_data_thresh, left_brik.affine)
    nib.save(left_data_nii, left_outname)

    right_basename = os.path.splitext(right)
    right_filename = right_basename[0]
    right_outname  = right_filename.split("+")[0] + '_thresh.nii.gz'
    right_data_nii = nib.Nifti1Image(right_data_thresh, right_brik.affine)
    nib.save(right_data_nii, right_outname)


