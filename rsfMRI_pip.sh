foreach subj ()  # add all of the subjects pcodes that are in the file name inside the ()

echo $subj

#set top_dir = /media/dbermudez/Fortress/$subj

#3dWarp -deoblique -prefix $subj.EPI1_deob.nii $top_dir/SZ_Raw/$subj/impmo1.d+orig.HEAD
#3dWarp -deoblique -prefix $subj.EPI2_deob.nii $top_dir/SZ_Raw/$subj/impmo2.d+orig.HEAD
#3dWarp -deoblique -prefix $subj.MPRAGE_deob.nii $top_dir/SZ_Raw/$subj/mprage.d+orig.HEAD

# pre-process resting state fMRI data

afni_proc.py -subj_id $subj.REST \
	-dsets "$subj""_rest_EPI".nii \
	-copy_anat "T1w_""$subj"".nii" \
	-blocks despike tshift align tlrc volreg blur mask regress \
	-tcat_remove_first_trs 0 \
	-volreg_align_e2a \
	-volreg_tlrc_warp \
	--blur_size 6.0   \
	-regress_anaticor \
	-regress_censor_motion 0.2 \
	-regress_censor_outliers 0.1 \
	-regress_bandpass 0.01 0.1 \
	-regress_apply_mot_types demean deriv \
		-regress_motion_per_run	  \
		-regress_censor_motion 0.5   \
		-regress_censor_outliers 0.1 \
	-regress_apply_mask  	\
	-regress_run_clustsim no \
	-regress_est_blur_epits \
	-regress_est_blur_errts  

# run script generated for the afni_proc.py function

tcsh -xef proc.$subj.REST |& tee output.proc.$subj.REST

# Display all the atlases and atlas ROI codes avalible on AFNI

echo Displaying all available atlas codes

whereami -show_atlas_code | less

# Ask user to pick the atlas code for the brain reagion of interest to generate the ROI mask

echo Pick a atlas ROI: ; set x=$< ; echo $x

# File name for saving selected ROI with file type expension

echo "Name of file for saving ROI (with .nii extension)": ; set y=$< ; echo $y

# Generate a mask of the selected ROI from AFNI selection of atlases

whereami -mask_atlas_region $x -prefix $subj.REST.results/$y

# Ask user for the name to be used for saving the resample ROI including the file type extension

echo "Name of file to save resampled ROI (with .nii extension)": ; set z=$< ; echo $z

# resample the mask so the grid spacing matches that of the errts dataset

3dresample -master $subj.REST.results/errts.$subj.REST.anaticor+tlrc -inset $subj.REST.results/$y -prefix $subj.REST.results/$z

# Extract mean time series within ROI

3dROIstats -mask $subj.REST.results/$z -1Dformat $subj.REST.results/errts.$subj.REST.anaticor+tlrc >  $subj.REST.results/$y:r.1D

# Generate Pearson correlation between mean time series and all other voxels

3dTcorr1D -pearson -prefix $subj.REST.results/"$subj"_$y:r.Tcorr1D.nii $subj.REST.results/errts.$subj.REST.anaticor+tlrc $subj.REST.results/$y:r.1D


#Convert r scores to a z score

3dcalc -a $subj.REST.results/"$subj"_$y:r.Tcorr1D.nii -expr 'atanh(a)' -prefix $subj.REST.results/"$subj"_$y:r.z.nii










