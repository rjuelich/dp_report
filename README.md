This repository contains prototype code for the Beiwe Biomedical Research Platform backend analytics pipeline (https://www.hsph.harvard.edu/onnela-lab/beiwe-research-platform). The pipeline performs all datatype specific ETL ingest, data quality assurance, sparse data imputation, high-resolution data collapse, and computes summary statistics of interest. Input datatypes include GPS, accelerometer, call/sms logs, touchscreen activity, voice recordings, and surveys. All dumps are 100% raw. Output is a p x T matrix, where the p rows correspond to different daily summary statistics, and the T columns correspond to days. Output data structures provide input for supervised (mixed-effects modeling) and unsupervised (clustering, anomaly detection) machine
learning tasks, and create source files for compiling internal reports/dashboards, and interactive data visualizations.

# Datatype Descriptions:

GPS: Millisecond resolution raw GPS coordinates transformed/collapsed into 24-hour X n-days array of hourly mean distance from home

ACCELEROMETER: Millisecond resolution of raw XYZ coordinate vectors transformed/collapsed into 24-hour X n-days array of hourly mean timepoint-to-timepoint XYZ root-mean-squared deltas.

CALL/SMS LOGS: Currently just tallies hourly incoming/outgoing calls/texts. Much more to tap here.

VOICE RECORDINGS: Raw data in form of nightly "dear diary" logs. Currently using ffmpeg to extract the recording "voice envelope" (https://www.ncbi.nlm.nih.gov/pubmed/18595182).

MULTIPLE CHOICE SURVEYS: Responses to daily multiple-choice surveys. 


# Description of repo contents:

wrappers: Wrappers to compile/submit all data TYPE modules for given data SOURCE, for processing on high-performance cluster.

MODULES: Core processing modules for all available datatypes.

commons: Scripts to support visualization and final packaging of all datatypes.

ICONS: Icons used in final PDF output.

HTML_TEMPLATES: HTML templates used during packaging of final PDF output.



