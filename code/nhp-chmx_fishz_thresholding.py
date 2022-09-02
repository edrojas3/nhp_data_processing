import os
import sys
import numpy as np
import nibabel as nib
from glob import glob
from scipy.stats import norm

roidir = sys.argv[1]
roifiles = glob(roidir + '/WB_Z_ROI*BRIK') 

for rf in roifiles:
    brik = nib.load(rf)
    data = brik.get_fdata()

    data_1D = data.reshape(np.prod(data.shape), 1 )
    data_1D = data_1D[data_1D != 0 ]
    data_mean = data_1D.mean()
    data_sd = data_1D.std()
    
    alpha = 0.05
    scale = abs(norm.ppf(alpha/2))
    
    ci_bounds = [data_mean - scale*data_sd, data_mean + scale*data_sd]

    low_bound_mask = data <= ci_bounds[0]
    high_bound_mask = data >= ci_bounds[1]
    mask = low_bound_mask + high_bound_mask
    data_thresh = data*mask

    basename = os.path.splitext(rf)
    filename = basename[0]
    outname = filename.split("+")[0] + '_thresh+tlrc.nii.gz'

    data_nii = nib.Nifti1Image(data_thresh, brik.affine)
    nib.save(data_nii, outname)



