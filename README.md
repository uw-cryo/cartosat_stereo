# cartosat
Scripts for processing Cartosat imagery

## Main utilities
- `cartosat_stereo.sh`: wrapper around ASP, input argument is directory that contains A.tif, A_RPC.TXT, A_MET.TXT, etc.
- `cartosat_date.py`: reformat date/time from metadata
- `cartosat_stereo_int.py`: compute stereo intersection from corner coordinates in metadata (currently disabled)

## Batch processing
- `cartosat_qsub.sh`: script for batch job submission
- `cartosat_singlepair.pbs`: PBS job script
