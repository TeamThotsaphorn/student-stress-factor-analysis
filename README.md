# Factor Analysis of Psychological Stress among University Students

**English** | [ภาษาไทย](README.th.md)

What are the main sources of stress for university students, and do they differ by gender, year of study, or marital status?

This project applies **Exploratory Factor Analysis (EFA)** to a public survey of 610 students. It reduces 15 stress items to 4 interpretable factors, then compares factor scores across student groups.

> Team project (5 members), *Applied Multivariate Analysis* course, October 2026.
> **My role:** I wrote the R analysis, interpreted the results, and co-presented the findings.

---

## Key findings

- **4 factors explain 63.1% of the total variance:** exam & emotion (21.2%), social (16.1%), academic (13.8%), and financial (12.1%).
- **Exam & emotion is the largest source of stress.** Exam anxiety, sleep problems, and irritability cluster together, so emotional stress is tied to exam periods.
- **Female students report much higher exam & emotion stress** than male students (mean factor score +0.29 vs −0.43, Welch t = 8.93, p < 0.001).
- **The pattern differs by year of study.** First-year students report the *lowest* exam stress but the *highest* academic stress (ANOVA p = 0.001 and p = 0.015, Tukey HSD).
- **Married students report higher financial stress** than single students (+0.28 vs −0.03, p = 0.018).

| Scree plot | Rotated loadings |
|---|---|
| ![Scree plot](figures/scree_plot.png) | ![Rotated loadings](figures/rotated_loadings.png) |

![Factor scores by gender](figures/factor_scores_by_gender.png)

---

## Data

The data is the [**Student Psychological Stress Survey Dataset (University of Anbar, Iraq), Version 2**](https://doi.org/10.17632/428whwsk6c.2) by Hussen, Ibrahim & Nafea (2026), published on Mendeley Data under CC BY 4.0: 610 respondents and 15 items on a 5-point frequency scale (1 = Never … 5 = Always). It also records gender, age, marital status, and year of study.

| File | Contents |
|---|---|
| `data/Raw_dataset.xlsx` | Demographics plus text responses (main source) |
| `data/Encoded_dataset.xlsx` | 610 × 15 numeric responses (1–5), used to check the recoding |
| `data/Student_Stress_Questionnaire.docx` | Questionnaire wording |
| `data/processed/stress_clean.csv` | Prepared table: id, demographics, Q1–Q15 (created by the notebook) |
| `data/processed/stress_with_scores.csv` | Prepared table plus the 4 factor scores (created by the script) |

### Data preparation

Data preparation is done in a separate notebook, **[`notebooks/01_data_preparation.ipynb`](notebooks/01_data_preparation.ipynb)** (Python, pandas). GitHub shows every step with its output, so you can follow it without running anything.

All the information comes from **one file, `Raw_dataset.xlsx`**: four demographic columns plus the 15 answers stored as text. The notebook builds a single tidy table from it *before* any analysis. The authors' `Encoded_dataset.xlsx` is used only to check the recoding.

| Step | What happens | Result |
|---|---|---|
| 1 | Read the raw file; check size, missing values, column names | 610 rows × 19 columns, no missing values; one column name has a trailing space (`'Gender '`) |
| 2 | Rename columns and strip whitespace from text | Short names: `gender`, `age`, `marital`, `stage`, `Q1`–`Q15` |
| 3 | List all answer values, then recode (Never = 1 … Always = 5) | Exactly 5 answer values; every answer recoded |
| 4 | Compare the recoded answers with the authors' encoded file | 0 mismatches out of 9,150 cells, so the recoding and row order are correct |
| 5 | Add an `id` column | `id` = 1 to 610 |
| 6 | Check duplicates | 3 students gave identical answers, but their demographics differ, so they are different people |
| 7 | Check straight-lining (the same answer on all 15 items) | 5 students (0.8%). Kept: too few to affect results, and no evidence of careless answering. Noted as a limitation |
| 8 | Check group sizes | Female 368 / Male 242; Single 547 / Married 63; years 1–4 = 603 (6 master's and 1 PhD student excluded only from the year comparison) |
| 9 | Save and re-read to verify | `data/processed/stress_clean.csv`: 610 rows × 20 columns |

The R script reads `stress_clean.csv`, runs the factor analysis on the Q1–Q15 columns, and adds the four factor scores to the same table as new columns (`stress_with_scores.csv`). Each student's scores therefore stay on their own row.

Example: the first student

| Stage | id | Gender | Age | Marital | Year | Answers / factor scores |
|---|---|---|---|---|---|---|
| Raw file | – | Female | 24 | Single | Stage 4 | Always, Always, Sometimes, Sometimes, … |
| `stress_clean.csv` | 1 | Female | 24 | Single | Stage 4 | Q1–Q4 = 5, 5, 3, 3, … |
| `stress_with_scores.csv` | 1 | Female | 24 | Single | Stage 4 | exam & emotion **+1.51** · social **+1.14** · academic **−1.20** · financial **+1.19** |

---

## Method

1. **Descriptive statistics.** Likert items are ordinal, so I report the percentage at each response level and the median.
2. **Correlation matrix.** `rcorr`, `ggcorr`.
3. **Assumption checks.** Bartlett's test of sphericity gave p < 0.001. KMO was 0.84 ("good"), and every item had MSA > 0.5.
4. **Factor extraction.** Principal component method, `psych::principal`.
5. **Number of factors.** I compared three criteria:
   - Eigenvalue > 1 gives **4**. This is the chosen number, because a component with an eigenvalue below 1 explains less variance than a single standardized item (1/15 = 6.7%).
   - The scree plot elbow is at about 2. That solution explains only 47.3% and merges the social and financial items.
   - Cumulative variance ≥ 80% needs 8, and that solution cannot be interpreted.
6. **Rotation.** Varimax, with each factor named from items loading ≥ 0.5.
7. **Factor scores.** Regression method, standardized so the mean is 0 and the SD is 1.
8. **Group comparisons.**
   - Gender and marital status: Welch's t-test.
   - Year of study (years 1–4): one-way ANOVA with Tukey HSD, plus Welch ANOVA as a robustness check.

---

## How to run

**1. Data preparation (Python)**

```bash
pip install pandas openpyxl jupyter
cd notebooks
jupyter notebook 01_data_preparation.ipynb   # run all cells
```

**2. Analysis and figures (R)**, from the repository root

```r
install.packages(c("psych", "Hmisc", "GGally", "REdaS", "ggplot2"))
source("analysis/stress_fa.R")
```

---

## Repository structure

```
├── notebooks/01_data_preparation.ipynb   # data preparation (Python)
├── analysis/stress_fa.R      # factor analysis, group tests, figures (R)
├── data/                     # original dataset + questionnaire (CC BY 4.0)
│   └── processed/            # prepared data (created by the notebook and script)
├── figures/                  # charts used in this README
└── slides/presentation.pdf   # class presentation (Thai)
```

## Limitations

- **Single source.** The data comes from one university in Iraq, so the factor structure may not generalize to other populations.
- **Exploratory only.** A follow-up Confirmatory Factor Analysis (CFA), ideally on Thai students, is needed to confirm the structure.
- **Straight-lining.** 5 students (0.8%) gave the same answer to all 15 items; they were kept, but a sensitivity check without them would strengthen the results.
- **Cross-loading item.** Item Q7 (course too difficult) loads similarly on two factors (0.48 academic vs 0.44 exam & emotion).

## Data source and license

Hussen, F. M., Ibrahim, H. M., & Nafea, A. A. (2026). *Student Psychological Stress Survey Dataset (University of Anbar, Iraq)* (Version 2) [Data set]. Mendeley Data. https://doi.org/10.17632/428whwsk6c.2

Original dataset page: https://data.mendeley.com/datasets/428whwsk6c/2 (published 27 March 2026).

The dataset is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) and is redistributed here with attribution.
