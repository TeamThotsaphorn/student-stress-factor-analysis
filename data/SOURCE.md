# Data source

Files in this folder are from:

Hussen, F. M., Ibrahim, H. M., & Nafea, A. A. (2026). *Student Psychological Stress Survey Dataset (University of Anbar, Iraq)* (Version 2) [Data set]. Mendeley Data. https://doi.org/10.17632/428whwsk6c.2

- Dataset page: https://data.mendeley.com/datasets/428whwsk6c/2
- License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Changes: files renamed only (`Encoded_dataset.xlsx`, `Raw_dataset.xlsx`, `Student_Stress_Questionnaire.docx`); contents unmodified.
- `processed/` contains derived files: `stress_clean.csv` from `notebooks/01_data_preparation.ipynb` (answers recoded to 1–5, `id` added) and `stress_with_scores.csv` from `analysis/stress_fa.R` (factor scores appended).
