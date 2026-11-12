# =============================================================================
# Factor Analysis of Psychological Stress among University Students
# Exploratory Factor Analysis (PCA extraction + Varimax) and group comparisons
# Data: Hussen, F. M., Ibrahim, H. M., & Nafea, A. A. (2026). Student Psychological Stress
#       Survey Dataset (University of Anbar, Iraq) (Version 2). Mendeley Data.
#       https://doi.org/10.17632/428whwsk6c.2  (CC BY 4.0) | n = 610, 15 items
# Run from the repository root:  source("analysis/stress_fa.R")
# =============================================================================

# การวิเคราะห์ปัจจัยความเครียดทางจิตใจในนักศึกษามหาวิทยาลัย
# ข้อมูล: Encoded_dataset.xlsx + Raw_dataset.xlsx (Student Psychological Stress Survey, University of Anbar; n = 610, 15 ข้อ, 1-5)
# ไฟล์ข้อมูลอยู่ในโฟลเดอร์ data/ ให้รันสคริปต์จากโฟลเดอร์หลักของโปรเจกต์
# ขั้นตอนและคำสั่งในการวิเคราะห์ปัจจัย
# install.packages(c("readxl", "psych", "Hmisc", "GGally", "REdaS"))

library(readxl)
library(psych)

stress <- read_excel("data/Encoded_dataset.xlsx")
stress <- data.frame(stress)
colnames(stress) <- paste0("Q", 1:15)

# ---- 4.2 สถิติพรรณนา ----
describe(stress)[, c("n", "median", "skew", "kurtosis")]
# ข้อมูลเรียงลำดับ: ร้อยละแต่ละระดับคำตอบ และร้อยละที่ตอบ 4-5 (บ่อย/เป็นประจำ)
round(t(sapply(stress, function(x) prop.table(table(factor(x, levels = 1:5))) * 100)), 1)
round(sapply(stress, function(x) mean(x >= 4) * 100), 1)

# ---- 4.2 เมทริกซ์สหสัมพันธ์ ----
library(Hmisc)
rcorr(as.matrix(stress))

library(GGally)
ggcorr(stress, method = c("pairwise", "pearson"),
       label = TRUE, label_alpha = TRUE, label_round = 2, name = expression(rho))

# ---- 4.3 ตรวจสอบข้อตกลงเบื้องต้น ----
library(REdaS)
bart_spher(stress)      # Bartlett's Test of Sphericity
KMO(stress)             # KMO รวม + MSA รายข้อ

# ---- 4.4 สกัดปัจจัย: วิธีส่วนประกอบหลัก ----
FA_PC <- principal(stress, nfactors = 15, rotate = "none")
FA_PC$values                                   # ค่าเฉพาะ
cumsum(FA_PC$values) / 15 * 100                # ร้อยละความแปรปรวนสะสม

eigen_values <- FA_PC$values
plot(1:15, eigen_values, pch = 20, type = "b", lwd = 2,
     main = "Scree Plot", xlab = "Factor", ylab = "Eigenvalues")
abline(h = mean(eigen_values), col = "red", lwd = 2)

# ---- 4.5 กำหนดจำนวนปัจจัย: พิจารณาค่าเฉพาะที่มากกว่า 1 ซึ่งได้ทั้งหมด 4ปัจจัย
# ---- 4.6 ค่าถ่วงปัจจัยก่อนหมุนแกน ----
print(principal(stress, 4, rotate = "none")$loadings, cutoff = 0.5)

# ---- 4.7 หมุนแกนด้วย Varimax ----
FA_PC_Varimax <- principal(stress, nfactors = 4, rotate = "varimax", method = "regression")
print(FA_PC_Varimax$loadings, cutoff = 0.5, sort = TRUE)
FA_PC_Varimax$communality

# ---- 4.8 คะแนนปัจจัย ----
head(FA_PC_Varimax$scores, 15)

# ---- เปรียบเทียบคะแนนปัจจัยระหว่างกลุ่ม ----
# ข้อมูลส่วนตัวจาก Raw_dataset.xlsx (เรียงแถวตรงกับ Encoded_dataset.xlsx)
raw  <- data.frame(read_excel("data/Raw_dataset.xlsx"))
demo <- data.frame(gender  = trimws(raw[, 1]), age = raw[, 2],
                   marital = raw[, 3], stage = raw[, 4])

# ตั้งชื่อคอลัมน์คะแนนปัจจัยตามข้อที่โหลดสูงสุด (กันปัญหา R เรียงลำดับ RC ต่างกัน)
L  <- unclass(FA_PC_Varimax$loadings)
sc <- data.frame(FA_PC_Varimax$scores)
pick <- function(q) which.max(abs(L[q, ]))
scores <- data.frame(exam_emotion = sc[, pick("Q6")],  social    = sc[, pick("Q12")],
                     academic     = sc[, pick("Q4")],  financial = sc[, pick("Q9")])
d <- cbind(demo, scores)

# เพศ (Welch t-test)
for (f in names(scores)) { cat("\n", f, "\n"); print(t.test(d[[f]] ~ d$gender)) }
# สถานภาพสมรส
for (f in names(scores)) { cat("\n", f, "\n"); print(t.test(d[[f]] ~ d$marital)) }

# ชั้นปี 1-4 (ตัด ป.โท 6 คน และ ป.เอก 1 คน เพราะกลุ่มเล็กเกินไป)
st <- subset(d, grepl("^Stage", stage))
for (f in names(scores)) {
  cat("\n=====", f, "=====\n")
  fit <- aov(st[[f]] ~ st$stage)
  print(summary(fit))
  print(TukeyHSD(fit))
  print(oneway.test(st[[f]] ~ st$stage, var.equal = FALSE))   # Welch ANOVA กรณีความแปรปรวนไม่เท่ากัน
}
aggregate(cbind(exam_emotion, social, academic, financial) ~ gender, data = d, FUN = mean)
aggregate(cbind(exam_emotion, social, academic, financial) ~ stage,  data = st, FUN = mean)

# หมายเหตุ: R อาจเรียงลำดับปัจจัย (RC1-RC4) หรือใส่เครื่องหมายต่างจากผลเบื้องต้น
# ให้ดูว่าข้อใดมีค่าถ่วงสูงในแต่ละปัจจัย